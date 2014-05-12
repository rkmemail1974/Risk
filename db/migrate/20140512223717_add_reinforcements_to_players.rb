class AddReinforcementsToPlayers < ActiveRecord::Migration
  def change
    add_column :players, :reinforcements, :integer
  end
end
