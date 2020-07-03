# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_07_01_132914) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "activity_stream_logs", force: :cascade do |t|
    t.datetime "run_time"
    t.integer "activity_stream_items"
    t.string "status"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "retrieved_records"
  end

  create_table "dependent_objects", force: :cascade do |t|
    t.string "dependent_uri"
    t.string "parent_object_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "metadata_source"
    t.index ["parent_object_id"], name: "index_dependent_objects_on_parent_object_id"
  end

  create_table "oid_imports", force: :cascade do |t|
    t.text "csv"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "parent_objects", force: :cascade do |t|
    t.string "oid"
    t.string "bib"
    t.string "holding"
    t.string "item"
    t.string "barcode"
    t.string "aspace_uri"
    t.datetime "last_ladybird_update"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "last_id_update"
    t.datetime "last_voyager_update"
    t.datetime "last_aspace_update"
    t.string "visibility"
    t.index ["oid"], name: "index_parent_objects_on_oid", unique: true
  end

end
