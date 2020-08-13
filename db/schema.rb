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

ActiveRecord::Schema.define(version: 2020_08_13_193045) do

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

  create_table "child_objects", id: false, force: :cascade do |t|
    t.integer "child_oid"
    t.string "caption"
    t.integer "width"
    t.integer "height"
    t.integer "order"
    t.bigint "parent_object_oid", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["child_oid"], name: "index_child_objects_on_child_oid", unique: true
    t.index ["parent_object_oid"], name: "index_child_objects_on_parent_object_oid"
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

  create_table "mets_xml_imports", force: :cascade do |t|
    t.xml "mets_xml"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "oid"
    t.index ["oid"], name: "index_mets_xml_imports_on_oid"
  end

  create_table "oid_imports", force: :cascade do |t|
    t.text "csv"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "parent_objects", id: false, force: :cascade do |t|
    t.bigint "oid", null: false
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
    t.string "visibility", default: "Private"
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

  add_foreign_key "child_objects", "parent_objects", column: "parent_object_oid", primary_key: "oid", on_delete: :cascade
  add_foreign_key "sample_fields", "metadata_samples", on_delete: :cascade
end
