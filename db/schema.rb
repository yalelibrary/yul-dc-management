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

ActiveRecord::Schema.define(version: 2020_07_16_141702) do

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

  create_table "metadata_samples", force: :cascade do |t|
    t.string "metadata_source"
    t.integer "number_of_samples"
    t.decimal "seconds_elapsed"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "metadata_sources", force: :cascade do |t|
    t.string "metadata_cloud_name"
    t.string "display_name"
    t.string "file_prefix"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
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
    t.bigint "authoritative_metadata_source_id", default: 1, null: false
    t.jsonb "ladybird_json"
    t.jsonb "voyager_json"
    t.jsonb "aspace_json"
    t.string "reading_direction", default: "ltr"
    t.string "pagination", default: "individuals"
    t.index ["authoritative_metadata_source_id"], name: "index_parent_objects_on_authoritative_metadata_source_id"
    t.index ["oid"], name: "index_parent_objects_on_oid", unique: true
  end

  create_table "sample_fields", force: :cascade do |t|
    t.string "field_name"
    t.integer "field_count"
    t.decimal "field_percent_of_total"
    t.bigint "metadata_sample_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["metadata_sample_id"], name: "index_sample_fields_on_metadata_sample_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "sample_fields", "metadata_samples", on_delete: :cascade
end
