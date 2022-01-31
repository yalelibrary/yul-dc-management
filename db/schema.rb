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

ActiveRecord::Schema.define(version: 2022_01_31_212240) do

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

  create_table "admin_sets", force: :cascade do |t|
    t.string "key"
    t.string "label"
    t.string "homepage"
    t.string "summary"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "batch_connections", force: :cascade do |t|
    t.bigint "batch_process_id", null: false
    t.string "connectable_type", null: false
    t.bigint "connectable_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "status"
    t.index ["batch_process_id"], name: "index_batch_connections_on_batch_process_id"
    t.index ["connectable_type", "connectable_id"], name: "index_batch_connections_on_connectable_type_and_connectable_id"
  end

  create_table "batch_processes", force: :cascade do |t|
    t.text "csv"
    t.xml "mets_xml"
    t.bigint "oid"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "user_id", null: false
    t.string "file_name"
    t.string "batch_status"
    t.string "batch_action", default: "create parent objects"
    t.string "output_csv"
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
    t.datetime "created_at", precision: 6, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", precision: 6, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "label"
    t.string "checksum"
    t.string "viewing_hint"
    t.datetime "ptiff_conversion_at"
    t.string "mets_access_master_path"
    t.boolean "full_text", default: false
    t.integer "original_oid"
    t.text "preservica_content_object_uri"
    t.text "preservica_generation_uri"
    t.text "preservica_bitstream_uri"
    t.index ["caption"], name: "index_child_objects_on_caption"
    t.index ["label"], name: "index_child_objects_on_label"
    t.index ["oid"], name: "index_child_objects_on_oid", unique: true
    t.index ["order"], name: "index_child_objects_on_order"
    t.index ["original_oid"], name: "index_child_objects_on_original_oid"
    t.index ["parent_object_oid"], name: "index_child_objects_on_parent_object_oid"
    t.index ["preservica_bitstream_uri"], name: "index_child_objects_on_preservica_bitstream_uri"
    t.index ["preservica_content_object_uri"], name: "index_child_objects_on_preservica_content_object_uri"
    t.index ["preservica_generation_uri"], name: "index_child_objects_on_preservica_generation_uri"
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
    t.index ["failed_at"], name: "index_delayed_jobs_on_failed_at"
    t.index ["locked_at", "failed_at"], name: "index_delayed_jobs_on_locked_at_and_failed_at"
    t.index ["locked_at"], name: "index_delayed_jobs_on_locked_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
    t.index ["priority"], name: "index_delayed_jobs_on_priority"
    t.index ["queue"], name: "index_delayed_jobs_on_queue"
  end

  create_table "dependent_objects", force: :cascade do |t|
    t.string "dependent_uri"
    t.string "parent_object_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "metadata_source"
    t.index ["parent_object_id"], name: "index_dependent_objects_on_parent_object_id"
  end

  create_table "digital_object_jsons", force: :cascade do |t|
    t.text "json"
    t.bigint "parent_object_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["parent_object_id"], name: "index_digital_object_jsons_on_parent_object_id"
  end

  create_table "ingest_events", force: :cascade do |t|
    t.string "reason"
    t.string "status"
    t.bigint "batch_connection_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["batch_connection_id"], name: "index_ingest_events_on_batch_connection_id"
  end

  create_table "metadata_sources", force: :cascade do |t|
    t.string "metadata_cloud_name"
    t.string "display_name"
    t.string "file_prefix"
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
    t.string "viewing_direction"
    t.string "display_layout"
    t.integer "child_object_count"
    t.boolean "generate_manifest", default: false
    t.boolean "use_ladybird", default: false
    t.bigint "representative_child_oid"
    t.string "rights_statement"
    t.boolean "from_mets", default: false
    t.string "extent_of_digitization"
    t.datetime "last_mets_update"
    t.bigint "admin_set_id"
    t.string "digitization_note"
    t.string "call_number"
    t.string "container_grouping"
    t.string "project_identifier"
    t.string "parent_model"
    t.text "redirect_to"
    t.string "preservica_uri"
    t.string "digital_object_source", default: "None"
    t.index ["admin_set_id"], name: "index_parent_objects_on_admin_set_id"
    t.index ["aspace_uri"], name: "index_parent_objects_on_aspace_uri"
    t.index ["authoritative_metadata_source_id"], name: "index_parent_objects_on_authoritative_metadata_source_id"
    t.index ["barcode"], name: "index_parent_objects_on_barcode"
    t.index ["bib"], name: "index_parent_objects_on_bib"
    t.index ["call_number"], name: "index_parent_objects_on_call_number"
    t.index ["holding"], name: "index_parent_objects_on_holding"
    t.index ["item"], name: "index_parent_objects_on_item"
    t.index ["oid"], name: "index_parent_objects_on_oid", unique: true
    t.index ["project_identifier"], name: "index_parent_objects_on_project_identifier"
    t.index ["redirect_to"], name: "index_parent_objects_on_redirect_to"
  end

  create_table "preservica_ingests", force: :cascade do |t|
    t.datetime "ingest_time"
    t.bigint "parent_oid"
    t.bigint "child_oid"
    t.string "preservica_id"
    t.string "preservica_child_id"
    t.bigint "batch_process_id"
    t.datetime "created_at", precision: 6, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", precision: 6, default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "roles", force: :cascade do |t|
    t.string "name"
    t.string "resource_type"
    t.bigint "resource_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id"
    t.index ["resource_type", "resource_id"], name: "index_roles_on_resource_type_and_resource_id"
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
    t.boolean "deactivated", default: false
    t.string "first_name"
    t.string "last_name"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "users_roles", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "role_id"
    t.index ["role_id"], name: "index_users_roles_on_role_id"
    t.index ["user_id"], name: "index_users_roles_on_user_id"
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "batch_connections", "batch_processes"
  add_foreign_key "batch_processes", "users"
  add_foreign_key "child_objects", "parent_objects", column: "parent_object_oid", primary_key: "oid"
  add_foreign_key "ingest_events", "batch_connections"
end
