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

  def join
    @game = getQueuedGame
    @player = Player.create
    @player.update(game_id: @game.id, reinforcements: 9)
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
          
	  if(hasOwner?(terr_id))
            #Selected Territory has Owner
	    puts "TERRITORY HAS A OWNER"
	    #Pick different Territory
          else
            #Claim Territories
	    claimTerritory(terr_id)
          end

	  #If all territories are taken move to GAME REINFORCEMENT STATE
	  if(allGameTerrTaken?) then @game.game_state = 1 end

	when 1 #START OF GAME REINFORCEMENTS

	  #
	  

	  #check reinforcements (if no reinforcements then TURN ATTACK)
	    if(allGameReinforceGone?) then @game.game_state = 3 end

	when 2 #START of TURN REINFORCEMENTS
	  #check player reinforcements (if no reinforcements then TURN ATTACK)

	when 3 #TURN ATTACK

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
                             game_id: @@queuedGame.id)
            territory.save
            puts territory.inspect
        end
        
    end
    @@queuedGame
  end

  def allGameReinforceGone?
    player = Player.find_by(game_id: @game.id, reinforcements: 0)
    if(player == nil)
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
end
