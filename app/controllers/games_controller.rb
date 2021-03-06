class GamesController < ApplicationController
  @@neighbors = { 
    "101" => ["102", "106", "506"],
    "102" => ["101", "106", "107", "109"],
    "103" => ["104", "109", "204"],
    "104" => ["103", "108", "107", "109"],
    "105" => ["106", "107", "108", "502"],
    "106" => ["101", "102", "105", "107"],
    "107" => ["102", "104", "105", "106", "108", "109"],
    "108" => ["104", "105", "107"],
    "109" => ["102", "103", "104", "107"]
  }
    
  @@queuedGame = nil
  @@lastPlayer = nil
  @@firstPlayer = nil
  @@firstTerritorySelected = nil

  def join
    @game = getQueuedGame
    @player = Player.create
    @player.update(game_id: @game.id, reinforcements: 5)
    @game.update(num_players: @game.num_players + 1)
    if (@game.num_players == 1)
      @@firstPlayer = @player.id
    end
    unless @@lastPlayer.nil?
      @@lastPlayer.update(next_player: @player.id )
    end
    @gamechannel = "game-channel-#{@game.id}"

    if (@game.num_players >=3)
      @player.update(next_player: @@firstPlayer)
      @game.update(game_state: 0)
      @game.update(turn: @@firstPlayer)
        message(@game.turn, @game.game_state, "this is a message")
      Pusher[@gamechannel].trigger('state', {player_id: @game.turn})
      @@queuedGame = @@lastPlayer = @@firstPlayer = nil
    else
      Pusher[@gamechannel].trigger('count', {amount:@game.num_players})
    end
    @@lastPlayer = @player
  end

  def select
     render nothing: true
     getContext
     terr_id = params[:territory_id]
     if (@player.id == @game.turn)
       @game.update(turn: @player.next_player)
       #terr_id = params[:territory_id]
       puts "TERRITORY SELECTED: " + terr_id
       puts "Game ID: " + @game.id.to_s
       puts "Game State = #{@game.game_state}"
       case @game.game_state
	when 0 #START OF GAME TERRITORIES SELECT
          
	  puts "GAME SELECT TERRITORIES STATE"

	  if(hasOwner?(terr_id))
            #Selected Territory has Owner
	    puts "TERRITORY HAS A OWNER"
	    #Pick different Territory
          else
            #Claim Territories
	    claimTerritory(terr_id)
          end

	  #If all territories are taken move to GAME REINFORCEMENT STATE
	  if(allGameTerrTaken?) then changeGameState(1) end

	when 1 #START OF GAME REINFORCEMENTS

	  puts "GAME REINFORCEMENT STATE"

	  #Reinforcement Territory
	  reinforceTerritory(terr_id)

	  #If all reinforcments are gone move to TURN ATTACK STATE
	  if(allGameReinforceGone?) then changeGameState(3) end

	when 2 #START of TURN REINFORCEMENTS
	  #check player reinforcements (if no reinforcements then TURN ATTACK)

	when 3 #TURN ATTACK

          puts "ATTACK TURN STATE"

	  

	when 4 #TURN FORTIFY
	  
	  #after fortifing, state = TURN REINFORCEMENT for next player
	else #BAD CALL/ERROR 
        
       end
       Pusher[@gamechannel].trigger('state', {player_id:@player.next_player})
     end
  end

  def getQueuedGame
    if (@@queuedGame.nil?)
      @@queuedGame = Game.create
      @@queuedGame.update(num_players: 0, game_state: -1)
        @@neighbors.each do |key|
            
            territory = Territory.create
            territory.update(owner_id: -1, geo_state: key.first.to_i,
                             game_id: @@queuedGame.id, num_armies: 0)
            territory.save
            puts territory.inspect
        end
        
    end
    @@queuedGame
  end

  def changeGameState(num)
    game = Game.find_by(id: @game.id)
    if(game == nil) then puts "GAME NOT FOUND!" end
    game.update(game_state: num)
    game.save
    puts game.inspect
  end

  def allGameReinforceGone?
    players = Player.where(game_id: @game.id, reinforcements: 0)
    if(players.length == 3)
      puts "ALL REINFORCEMENTS GONE" 
      return true
    end
    puts "REINFORCEMENTS STILL LEFT"
    return false
  end 

  #Returns TRUE if all territories are taken and FALSE if there is at least on avaible
  def allGameTerrTaken?
    territory = Territory.find_by(game_id: @game.id, owner_id: -1)
    print "ALL GAME TERRITORIES TAKEN? "
    if(territory == nil)
	print  "True\n"
	return true 
    end
    print  "False\n"
    return false
  end

  def hasOwner?(geoState)
    #puts "HASOWNER? GEOSTATE PASSED = #{geoState}"
    territory = Territory.where(game_id: @game.id, geo_state: geoState, owner_id: -1)
    if(territory == nil)
	puts "GEOSTATE #{geoState} HAS OWNER"
	return true
    end
    puts "GEOSTATE #{geoState} HAS NO OWNER"
    return false
  end

  def reinforceTerritory(geoState)
    territory = Territory.find_by(game_id: @game.id, geo_state: geoState)
    puts "REINFORCE TERRITORY" + territory.inspect
    if(territory == nil)
      puts "Territory #{geoState} Not Found!"
    else
      puts territory.num_armies
      territory.update_attributes(num_armies: territory.num_armies + 1)
    end
    territory.save
    puts territory.inspect
  end

  def claimTerritory(geoState)
    #Territory
    territory = Territory.find_by(game_id: @game.id, geo_state: geoState, owner_id: -1)
    if(territory == nil) then puts "Territory #{geoState} Not Found!" end
    territory.update_attributes(owner_id: @player.id, num_armies: 1)
    territory.save
    puts territory.inspect
    #Reduced Player REINFORCEMENTS
    player = Player.find_by(game_id: @game.id, id: @player.id)
    if(player == nil) then puts "Player #{@player.id} Not Found!" end
    player.update_attributes(reinforcements: @player.reinforcements - 1)
    puts player.inspect
    puts "Player #{@player.id} HAS CLAIMED #{geoState}!"
  end

  def isNeighbor?(geostate1, geostate2)
    @@neigbors[geostate1.to_s].include?(geostate2.to_s) ? true : false
  end

  def roll
    rand(6)+1
  end

  def rollDice(n)
    a= []
    n.times {|i| a.push(roll)}
    return a.sort! 
  end  

  def attack(attGeoState,defGeoState)
    
  end

  def getContext
     @game = Game.find_by(id: params[:game_id])
     @player = Player.find_by(id: params[:player_id])
     @gamechannel = "game-channel-#{@game.id}"
  end
    
    def message(playerId, stateId, message)
        d_stuff_101 = Territory.find_by(game_id: @game.id, geo_state: 101)
        d_stuff_102 = Territory.find_by(game_id: @game.id, geo_state: 102)
        d_stuff_103 = Territory.find_by(game_id: @game.id, geo_state: 103)
        d_stuff_104 = Territory.find_by(game_id: @game.id, geo_state: 104)
        d_stuff_105 = Territory.find_by(game_id: @game.id, geo_state: 105)
        d_stuff_106 = Territory.find_by(game_id: @game.id, geo_state: 106)
        d_stuff_107 = Territory.find_by(game_id: @game.id, geo_state: 107)
        d_stuff_108 = Territory.find_by(game_id: @game.id, geo_state: 108)
        d_stuff_109 = Territory.find_by(game_id: @game.id, geo_state: 109)

        messageHash = {
            player_id: @player.id,
            state_id: "101",
            game_id: @game.id,
            message: message,
            geo_num_101: d_stuff_101.num_armies,
            geo_owner_101: d_stuff_101.owner_id,
            geo_num_102: d_stuff_102.num_armies,
            geo_owner_102: d_stuff_102.owner_id,
            geo_num_103: d_stuff_103.num_armies,
            geo_owner_103: d_stuff_103.owner_id,
            geo_num_104: d_stuff_104.num_armies,
            geo_owner_104: d_stuff_104.owner_id,
            geo_num_105: d_stuff_105.num_armies,
            geo_owner_105: d_stuff_105.owner_id,
            geo_num_106: d_stuff_106.num_armies,
            geo_owner_106: d_stuff_106.owner_id,
            geo_num_107: d_stuff_107.num_armies,
            geo_owner_107: d_stuff_107.owner_id,
            geo_num_108: d_stuff_108.num_armies,
            geo_owner_108: d_stuff_108.owner_id,
            geo_num_109: d_stuff_109.num_armies,
            geo_owner_109: d_stuff_109.owner_id

        }
        
        Pusher[@gamechannel].trigger('state', {new: messageHash})
        
    end

end
