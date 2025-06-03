# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.


ActiveRecord::Schema[7.0].define(version: 2025_05_28_222739) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "activity_stream_logs", force: :cascade do |t|
    t.datetime "run_time", precision: nil
    t.integer "activity_stream_items"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "retrieved_records"
  end

  create_table "admin_sets", force: :cascade do |t|
    t.string "key"
    t.string "label"
    t.string "homepage"
    t.string "summary"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "batch_connections", force: :cascade do |t|
    t.bigint "batch_process_id", null: false
    t.string "connectable_type", null: false
    t.bigint "connectable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status"
    t.index ["batch_process_id"], name: "index_batch_connections_on_batch_process_id"
    t.index ["connectable_type", "connectable_id"], name: "index_batch_connections_on_connectable_type_and_connectable_id"
  end

  create_table "batch_processes", force: :cascade do |t|
    t.text "csv"
    t.xml "mets_xml"
    t.bigint "oid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.string "file_name"
    t.string "batch_status"
    t.string "batch_action", default: "create parent objects"
    t.string "output_csv"
    t.string "admin_set"
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
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "label"
    t.string "checksum"
    t.string "viewing_hint"
    t.datetime "ptiff_conversion_at", precision: nil
    t.string "mets_access_primary_path"
    t.boolean "full_text", default: false
    t.integer "original_oid"
    t.text "preservica_content_object_uri"
    t.text "preservica_generation_uri"
    t.text "preservica_bitstream_uri"
    t.string "sha512_checksum"
    t.datetime "last_preservica_update", precision: nil
    t.text "extent_of_full_text"
    t.string "sha256_checksum"
    t.string "md5_checksum"
    t.bigint "file_size"
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

  create_table "dcs_activity_stream_updates", force: :cascade do |t|
    t.bigint "oid"
    t.string "md5_metadata_hash"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at", precision: nil
    t.datetime "locked_at", precision: nil
    t.datetime "failed_at", precision: nil
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "metadata_source"
    t.index ["dependent_uri"], name: "index_dependent_objects_on_dependent_uri"
    t.index ["parent_object_id"], name: "index_dependent_objects_on_parent_object_id"
  end

  create_table "digital_object_jsons", force: :cascade do |t|
    t.text "json"
    t.bigint "parent_object_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_object_id"], name: "index_digital_object_jsons_on_parent_object_id"
  end

  create_table "good_job_batches", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.jsonb "serialized_properties"
    t.text "on_finish"
    t.text "on_success"
    t.text "on_discard"
    t.text "callback_queue_name"
    t.integer "callback_priority"
    t.datetime "enqueued_at", precision: nil
    t.datetime "discarded_at", precision: nil
    t.datetime "finished_at", precision: nil
  end

  create_table "good_job_executions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id", null: false
    t.text "job_class"
    t.text "queue_name"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at", precision: nil
    t.datetime "finished_at", precision: nil
    t.text "error"
    t.integer "error_event", limit: 2
    t.index ["active_job_id", "created_at"], name: "index_good_job_executions_on_active_job_id_and_created_at"
  end

  create_table "good_job_processes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "state"
  end

  create_table "good_job_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "key"
    t.jsonb "value"
    t.index ["key"], name: "index_good_job_settings_on_key", unique: true
  end

  create_table "good_jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "queue_name"
    t.integer "priority"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at", precision: nil
    t.datetime "performed_at", precision: nil
    t.datetime "finished_at", precision: nil
    t.text "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id"
    t.text "concurrency_key"
    t.text "cron_key"
    t.uuid "retried_good_job_id"
    t.datetime "cron_at", precision: nil
    t.uuid "batch_id"
    t.uuid "batch_callback_id"
    t.boolean "is_discrete"
    t.integer "executions_count"
    t.text "job_class"
    t.integer "error_event", limit: 2
    t.text "labels", array: true
    t.index ["active_job_id", "created_at"], name: "index_good_jobs_on_active_job_id_and_created_at"
    t.index ["batch_callback_id"], name: "index_good_jobs_on_batch_callback_id", where: "(batch_callback_id IS NOT NULL)"
    t.index ["batch_id"], name: "index_good_jobs_on_batch_id", where: "(batch_id IS NOT NULL)"
    t.index ["concurrency_key"], name: "index_good_jobs_on_concurrency_key_when_unfinished", where: "(finished_at IS NULL)"
    t.index ["cron_key", "created_at"], name: "index_good_jobs_on_cron_key_and_created_at_cond", where: "(cron_key IS NOT NULL)"
    t.index ["cron_key", "cron_at"], name: "index_good_jobs_on_cron_key_and_cron_at_cond", unique: true, where: "(cron_key IS NOT NULL)"
    t.index ["finished_at"], name: "index_good_jobs_jobs_on_finished_at", where: "((retried_good_job_id IS NULL) AND (finished_at IS NOT NULL))"
    t.index ["labels"], name: "index_good_jobs_on_labels", where: "(labels IS NOT NULL)", using: :gin
    t.index ["priority", "created_at"], name: "index_good_jobs_jobs_on_priority_created_at_when_unfinished", order: { priority: "DESC NULLS LAST" }, where: "(finished_at IS NULL)"
    t.index ["queue_name", "scheduled_at"], name: "index_good_jobs_on_queue_name_and_scheduled_at", where: "(finished_at IS NULL)"
    t.index ["scheduled_at"], name: "index_good_jobs_on_scheduled_at", where: "(finished_at IS NULL)"
  end

  create_table "ingest_events", force: :cascade do |t|
    t.string "reason"
    t.string "status"
    t.bigint "batch_connection_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["batch_connection_id"], name: "index_ingest_events_on_batch_connection_id"
  end

  create_table "metadata_sources", force: :cascade do |t|
    t.string "metadata_cloud_name"
    t.string "display_name"
    t.string "file_prefix"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "parent_objects", id: false, force: :cascade do |t|
    t.bigint "oid", null: false
    t.string "bib"
    t.string "holding"
    t.string "item"
    t.string "barcode"
    t.string "aspace_uri"
    t.datetime "last_ladybird_update", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_id_update", precision: nil
    t.datetime "last_voyager_update", precision: nil
    t.datetime "last_aspace_update", precision: nil
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
    t.datetime "last_mets_update", precision: nil
    t.bigint "admin_set_id"
    t.string "digitization_note"
    t.string "call_number"
    t.string "container_grouping"
    t.string "project_identifier"
    t.string "parent_model"
    t.text "redirect_to"
    t.text "preservica_uri"
    t.string "digital_object_source", default: "None"
    t.string "preservica_representation_type"
    t.datetime "last_preservica_update", precision: nil
    t.string "digitization_funding_source"
    t.bigint "permission_set_id"
    t.text "extent_of_full_text", default: "None"
    t.jsonb "sierra_json"
    t.datetime "last_sierra_update", precision: nil
    t.string "sensitive_materials"
    t.index ["admin_set_id"], name: "index_parent_objects_on_admin_set_id"
    t.index ["aspace_uri"], name: "index_parent_objects_on_aspace_uri"
    t.index ["authoritative_metadata_source_id"], name: "index_parent_objects_on_authoritative_metadata_source_id"
    t.index ["barcode"], name: "index_parent_objects_on_barcode"
    t.index ["bib"], name: "index_parent_objects_on_bib"
    t.index ["call_number"], name: "index_parent_objects_on_call_number"
    t.index ["created_at"], name: "index_parent_objects_on_created_at"
    t.index ["holding"], name: "index_parent_objects_on_holding"
    t.index ["item"], name: "index_parent_objects_on_item"
    t.index ["oid"], name: "index_parent_objects_on_oid", unique: true
    t.index ["permission_set_id"], name: "index_parent_objects_on_permission_set_id"
    t.index ["project_identifier"], name: "index_parent_objects_on_project_identifier"
    t.index ["redirect_to"], name: "index_parent_objects_on_redirect_to"
  end

  create_table "permission_request_users", force: :cascade do |t|
    t.string "sub"
    t.string "name"
    t.string "email"
    t.boolean "email_verified"
    t.datetime "oidc_updated_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "netid"
  end

  create_table "permission_requests", force: :cascade do |t|
    t.text "approver_note"
    t.boolean "terms_approved"
    t.datetime "access_until", precision: nil
    t.bigint "permission_set_id"
    t.bigint "permission_request_user_id"
    t.bigint "parent_object_id"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "user_note"
    t.datetime "approved_or_denied_at"
    t.string "permission_request_user_name"
    t.string "change_access_type"
    t.string "new_visibility"
    t.string "approver"
    t.string "request_status", default: "Pending"
    t.index ["parent_object_id"], name: "index_permission_requests_on_parent_object_id"
    t.index ["permission_request_user_id"], name: "index_permission_requests_on_permission_request_user_id"
    t.index ["permission_set_id"], name: "index_permission_requests_on_permission_set_id"
    t.index ["user_id"], name: "index_permission_requests_on_user_id"
  end

  create_table "permission_set_terms", force: :cascade do |t|
    t.integer "permission_set_id"
    t.integer "activated_by_id"
    t.datetime "activated_at", precision: nil
    t.integer "inactivated_by_id"
    t.datetime "inactivated_at", precision: nil
    t.string "title"
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "permission_sets", force: :cascade do |t|
    t.text "label"
    t.text "key"
    t.integer "max_queue_length", default: 10
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "parent_object_id"
    t.index ["parent_object_id"], name: "index_permission_sets_on_parent_object_id"
  end

  create_table "preservica_ingests", force: :cascade do |t|
    t.datetime "ingest_time", precision: nil
    t.bigint "parent_oid"
    t.bigint "child_oid"
    t.string "preservica_id"
    t.string "preservica_child_id"
    t.bigint "batch_process_id"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "problem_reports", force: :cascade do |t|
    t.integer "child_count"
    t.integer "parent_count"
    t.integer "problem_parent_count"
    t.integer "problem_child_count"
    t.text "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_problem_reports_on_status"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name"
    t.string "resource_type"
    t.bigint "resource_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id"
    t.index ["resource_type", "resource_id"], name: "index_roles_on_resource_type_and_resource_id"
  end

  create_table "structures", force: :cascade do |t|
    t.boolean "top_level"
    t.text "label"
    t.string "description"
    t.string "type"
    t.string "resource_id"
    t.integer "position"
    t.integer "structure_id"
    t.integer "parent_object_oid"
    t.integer "child_object_oid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "terms_agreements", force: :cascade do |t|
    t.datetime "agreement_ts", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "permission_set_term_id"
    t.bigint "permission_request_user_id"
    t.index ["permission_request_user_id"], name: "index_terms_agreements_on_permission_request_user_id"
    t.index ["permission_set_term_id"], name: "index_terms_agreements_on_permission_set_term_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "provider"
    t.string "uid"
    t.boolean "deactivated", default: false
    t.string "first_name"
    t.string "last_name"
    t.bigint "permission_request_id"
    t.index ["permission_request_id"], name: "index_users_on_permission_request_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["uid"], name: "index_users_on_uid", unique: true
  end

  create_table "users_roles", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "role_id"
    t.index ["role_id"], name: "index_users_roles_on_role_id"
    t.index ["user_id"], name: "index_users_roles_on_user_id"
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type"
    t.string "{:null=>false}"
    t.bigint "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.datetime "created_at", precision: nil
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "batch_connections", "batch_processes"
  add_foreign_key "batch_processes", "users"
  add_foreign_key "child_objects", "parent_objects", column: "parent_object_oid", primary_key: "oid"
  add_foreign_key "ingest_events", "batch_connections"
  add_foreign_key "parent_objects", "permission_sets"
end
