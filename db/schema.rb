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

ActiveRecord::Schema.define(version: 2020_10_08_202306) do

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

  create_table "batch_process_events", force: :cascade do |t|
    t.bigint "batch_process_id", null: false
    t.bigint "parent_object_oid", null: false
    t.datetime "queued", precision: 6
    t.datetime "metadata_fetched", precision: 6
    t.datetime "child_records_created", precision: 6
    t.datetime "ptiff_jobs_created", precision: 6
    t.datetime "iiif_manifest_saved", precision: 6
    t.datetime "indexed_to_solr", precision: 6
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["batch_process_id"], name: "index_batch_process_events_on_batch_process_id"
    t.index ["parent_object_oid"], name: "index_batch_process_events_on_parent_object_oid"
  end

  create_table "batch_processes", force: :cascade do |t|
    t.text "csv"
    t.xml "mets_xml"
    t.bigint "oid"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "user_id", null: false
    t.string "file_name"
    t.index ["oid"], name: "index_batch_processes_on_oid"
    t.index ["user_id"], name: "index_batch_processes_on_user_id"
  end

  create_table "child_objects", id: false, force: :cascade do |t|
    t.integer "oid"
    t.string "caption"
    t.integer "width"
    t.integer "height"
    t.integer "order"
    t.bigint "parent_object_oid", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "label"
    t.string "checksum"
    t.string "viewing_hint"
    t.datetime "ptiff_conversion_at"
    t.index ["oid"], name: "index_child_objects_on_oid", unique: true
    t.index ["parent_object_oid"], name: "index_child_objects_on_parent_object_oid"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
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
    t.bigint "oid"
    t.index ["oid"], name: "index_mets_xml_imports_on_oid"
  end

  create_table "notifications", force: :cascade do |t|
    t.string "recipient_type", null: false
    t.bigint "recipient_id", null: false
    t.string "type", null: false
    t.jsonb "params"
    t.datetime "read_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["recipient_type", "recipient_id"], name: "index_notifications_on_recipient_type_and_recipient_id"
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
    t.string "reading_direction"
    t.string "pagination"
    t.integer "child_object_count"
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
    t.string "provider"
    t.string "uid"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "batch_process_events", "batch_processes"
  add_foreign_key "batch_process_events", "parent_objects", column: "parent_object_oid", primary_key: "oid"
  add_foreign_key "batch_processes", "users"
  add_foreign_key "child_objects", "parent_objects", column: "parent_object_oid", primary_key: "oid"
  add_foreign_key "sample_fields", "metadata_samples", on_delete: :cascade
end
