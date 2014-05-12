class AddNextPlayerToPlayers < ActiveRecord::Migration
  def change
    add_column :players, :next_player, :integer
  end
end
