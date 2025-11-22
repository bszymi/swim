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

ActiveRecord::Schema[8.1].define(version: 2025_11_22_121617) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "counties", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "region_id", null: false
    t.datetime "updated_at", null: false
    t.index ["region_id", "name"], name: "index_counties_on_region_id_and_name", unique: true
    t.index ["region_id"], name: "index_counties_on_region_id"
  end

  create_table "live_meetings", force: :cascade do |t|
    t.string "city"
    t.bigint "county_id"
    t.string "course_type", null: false
    t.datetime "created_at", null: false
    t.date "end_date"
    t.string "external_url"
    t.integer "license_level"
    t.string "meet_number"
    t.string "name", null: false
    t.text "notes"
    t.bigint "region_id"
    t.date "start_date", null: false
    t.datetime "updated_at", null: false
    t.string "venue"
    t.index ["county_id"], name: "index_live_meetings_on_county_id"
    t.index ["meet_number"], name: "index_live_meetings_on_meet_number"
    t.index ["region_id"], name: "index_live_meetings_on_region_id"
    t.index ["start_date", "region_id"], name: "index_live_meetings_on_start_date_and_region_id"
    t.index ["start_date"], name: "index_live_meetings_on_start_date"
  end

  create_table "meet_rules", force: :cascade do |t|
    t.boolean "allow_lc_to_sc", default: false
    t.boolean "allow_sc_to_lc", default: false
    t.datetime "created_at", null: false
    t.text "include_levels_text"
    t.bigint "meet_standard_set_id", null: false
    t.integer "min_license_level"
    t.datetime "updated_at", null: false
    t.index ["meet_standard_set_id"], name: "index_meet_rules_on_meet_standard_set_id"
  end

  create_table "meet_standard_rows", force: :cascade do |t|
    t.integer "age_max"
    t.integer "age_min"
    t.datetime "created_at", null: false
    t.integer "distance_m", null: false
    t.string "gender"
    t.bigint "meet_standard_set_id", null: false
    t.string "pool_of_standard"
    t.string "standard_type", null: false
    t.string "stroke", null: false
    t.decimal "time_seconds", precision: 8, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["meet_standard_set_id"], name: "index_meet_standard_rows_on_meet_standard_set_id"
  end

  create_table "meet_standard_sets", force: :cascade do |t|
    t.date "age_rule_date"
    t.string "age_rule_type"
    t.datetime "created_at", null: false
    t.string "license_number"
    t.bigint "live_meeting_id"
    t.string "name", null: false
    t.text "notes"
    t.string "pool_required"
    t.string "promoter"
    t.string "region"
    t.string "season"
    t.string "source_pdf_url"
    t.datetime "updated_at", null: false
    t.date "window_end"
    t.date "window_start"
    t.index ["license_number"], name: "index_meet_standard_sets_on_license_number"
    t.index ["live_meeting_id"], name: "index_meet_standard_sets_on_live_meeting_id"
  end

  create_table "meeting_error_reports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.bigint "meet_standard_set_id", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["meet_standard_set_id"], name: "index_meeting_error_reports_on_meet_standard_set_id"
    t.index ["status"], name: "index_meeting_error_reports_on_status"
    t.index ["user_id"], name: "index_meeting_error_reports_on_user_id"
  end

  create_table "parsed_meet_data", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "data"
    t.text "error_message"
    t.string "pdf_content_type"
    t.binary "pdf_data"
    t.string "pdf_filename"
    t.text "raw_response"
    t.string "status"
    t.datetime "updated_at", null: false
  end

  create_table "pdf_ingest_jobs", force: :cascade do |t|
    t.decimal "confidence", precision: 4, scale: 3
    t.datetime "created_at", null: false
    t.string "file_hash"
    t.jsonb "parsed_json"
    t.string "status"
    t.datetime "updated_at", null: false
    t.string "url"
  end

  create_table "performances", force: :cascade do |t|
    t.string "course_type", null: false
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.integer "distance_m", null: false
    t.float "lc_time_seconds"
    t.integer "license_level"
    t.string "license_no"
    t.string "meet_name"
    t.string "original_time_str"
    t.float "sc_time_seconds"
    t.string "source_url"
    t.string "stroke", null: false
    t.bigint "swimmer_id", null: false
    t.decimal "time_seconds", precision: 8, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.string "venue"
    t.integer "wa_points"
    t.index ["swimmer_id", "stroke", "distance_m"], name: "index_performances_on_swimmer_id_and_stroke_and_distance_m"
    t.index ["swimmer_id"], name: "index_performances_on_swimmer_id"
  end

  create_table "regions", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_regions_on_code", unique: true
    t.index ["name"], name: "index_regions_on_name", unique: true
  end

  create_table "swimmers", force: :cascade do |t|
    t.string "club"
    t.datetime "created_at", null: false
    t.date "dob", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "se_membership_id"
    t.string "sex", limit: 1, null: false
    t.datetime "updated_at", null: false
    t.index ["se_membership_id"], name: "index_swimmers_on_se_membership_id", unique: true
  end

  create_table "user_swimmers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "display_order"
    t.string "nickname"
    t.bigint "swimmer_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["swimmer_id"], name: "index_user_swimmers_on_swimmer_id"
    t.index ["user_id", "swimmer_id"], name: "index_user_swimmers_on_user_id_and_swimmer_id", unique: true
    t.index ["user_id"], name: "index_user_swimmers_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "provider"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role", default: "user", null: false
    t.string "uid"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "counties", "regions"
  add_foreign_key "live_meetings", "counties"
  add_foreign_key "live_meetings", "regions"
  add_foreign_key "meet_rules", "meet_standard_sets"
  add_foreign_key "meet_standard_rows", "meet_standard_sets"
  add_foreign_key "meet_standard_sets", "live_meetings"
  add_foreign_key "meeting_error_reports", "meet_standard_sets"
  add_foreign_key "meeting_error_reports", "users"
  add_foreign_key "performances", "swimmers"
  add_foreign_key "user_swimmers", "swimmers"
  add_foreign_key "user_swimmers", "users"
end
