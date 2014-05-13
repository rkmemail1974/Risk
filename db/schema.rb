# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140512223717) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "games", force: true do |t|
    t.integer  "turn"
    t.integer  "game_state"
    t.integer  "num_players"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "players", force: true do |t|
    t.integer  "game_id"
    t.integer  "color"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "next_player"
    t.integer  "reinforcements"
  end

  create_table "territories", force: true do |t|
    t.integer  "owner_id"
    t.integer  "num_armies"
    t.integer  "geo_state"
    t.integer  "game_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.string   "name"
    t.string   "email"
    t.integer  "army"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "worlds", force: true do |t|
    t.integer  "breen"
    t.integer  "blue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
