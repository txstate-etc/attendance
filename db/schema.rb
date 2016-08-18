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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20160818021319) do

  create_table "attendancetypes", :force => true do |t|
    t.string  "name"
    t.text    "description"
    t.integer "display_column",   :limit => 1, :default => 0,     :null => false
    t.string  "color"
    t.boolean "absent",                        :default => false, :null => false
    t.boolean "default_type",                  :default => false, :null => false
    t.integer "display_order",    :limit => 1, :default => 0,     :null => false
    t.boolean "default_inactive",              :default => false, :null => false
    t.boolean "default_created",               :default => false, :null => false
    t.integer "grade_type",                    :default => 0,     :null => false
  end

  add_index "attendancetypes", ["absent"], :name => "index_attendancetypes_on_absent"
  add_index "attendancetypes", ["default_created"], :name => "index_attendancetypes_on_default_created"
  add_index "attendancetypes", ["default_inactive"], :name => "index_attendancetypes_on_default_inactive"
  add_index "attendancetypes", ["default_type"], :name => "index_attendancetypes_on_default_type"
  add_index "attendancetypes", ["display_order"], :name => "index_attendancetypes_on_display_order"

  create_table "binaries", :force => true do |t|
    t.string "sha1"
    t.binary "data", :limit => 16777215, :null => false
  end

  add_index "binaries", ["sha1"], :name => "index_binaries_on_sha1"

  create_table "checkins", :force => true do |t|
    t.integer  "userattendance_id"
    t.datetime "time"
    t.string   "source"
  end

  add_index "checkins", ["userattendance_id"], :name => "index_checkins_on_userattendance_id"

  create_table "checkinsettings", :force => true do |t|
    t.integer  "site_id"
    t.boolean  "auto_enabled", :default => false, :null => false
    t.integer  "tardy_after",  :default => 15,    :null => false
    t.integer  "absent_after", :default => 30,    :null => false
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
  end

  add_index "checkinsettings", ["site_id"], :name => "index_checkinsettings_on_site_id"

  create_table "gradesettings", :force => true do |t|
    t.integer "site_id"
    t.decimal "tardy_value",       :precision => 3, :scale => 2, :default => 1.0,   :null => false
    t.integer "forgiven_absences",                               :default => 0,     :null => false
    t.decimal "deduction",         :precision => 3, :scale => 2, :default => 0.0,   :null => false
    t.integer "tardy_per_absence",                               :default => 0,     :null => false
    t.integer "max_points",                                      :default => 100,   :null => false
    t.boolean "auto_max_points",                                 :default => false, :null => false
  end

  add_index "gradesettings", ["site_id"], :name => "index_gradesettings_on_site_id"

  create_table "gradeupdates", :force => true do |t|
    t.integer  "membership_id",                :null => false
    t.integer  "tries",         :default => 0, :null => false
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
    t.string   "last_error"
  end

  add_index "gradeupdates", ["membership_id"], :name => "index_gradeupdates_on_membership_id"

  create_table "meetings", :force => true do |t|
    t.datetime "starttime",                         :null => false
    t.boolean  "cancelled",      :default => false, :null => false
    t.boolean  "deleted",        :default => false, :null => false
    t.datetime "updated_at",                        :null => false
    t.integer  "section_id",                        :null => false
    t.boolean  "future_meeting", :default => false, :null => false
    t.string   "checkin_code"
  end

  add_index "meetings", ["deleted", "cancelled"], :name => "index_meetings_on_site_id_and_deleted_and_cancelled"
  add_index "meetings", ["section_id"], :name => "index_meetings_on_section_id"
  add_index "meetings", ["starttime"], :name => "index_meetings_on_starttime"
  add_index "meetings", ["updated_at"], :name => "index_meetings_on_updated_at"

  create_table "memberships", :force => true do |t|
    t.integer "site_id",   :default => 0,     :null => false
    t.integer "user_id",   :default => 0,     :null => false
    t.boolean "active",    :default => false, :null => false
    t.string  "sourcedid"
  end

  add_index "memberships", ["active"], :name => "index_sites_users_on_dropped"
  add_index "memberships", ["site_id"], :name => "index_sites_users_on_site_id"
  add_index "memberships", ["user_id"], :name => "index_sites_users_on_user_id"

  create_table "memberships_sections", :id => false, :force => true do |t|
    t.integer "section_id",    :null => false
    t.integer "membership_id", :null => false
  end

  add_index "memberships_sections", ["membership_id"], :name => "index_memberships_sections_on_membership_id"
  add_index "memberships_sections", ["section_id"], :name => "index_memberships_sections_on_section_id"

  create_table "memberships_siteroles", :id => false, :force => true do |t|
    t.integer "siterole_id",   :default => 0, :null => false
    t.integer "membership_id", :default => 0, :null => false
  end

  add_index "memberships_siteroles", ["membership_id"], :name => "index_roles_users_on_user_id"
  add_index "memberships_siteroles", ["siterole_id"], :name => "index_roles_users_on_role_id"

  create_table "nonces", :force => true do |t|
    t.string  "nonce"
    t.integer "request_time", :default => 0, :null => false
  end

  add_index "nonces", ["nonce"], :name => "index_nonces_on_nonce"
  add_index "nonces", ["request_time"], :name => "index_nonces_on_request_time"

  create_table "roles", :force => true do |t|
    t.string  "roletype"
    t.string  "subroletype"
    t.string  "roleurn"
    t.string  "displayname"
    t.integer "displayorder",       :limit => 1, :default => 0,     :null => false
    t.boolean "sets_permissions",                :default => false, :null => false
    t.boolean "take_attendance",                 :default => false, :null => false
    t.boolean "record_attendance",               :default => false, :null => false
    t.boolean "edit_gradesettings",              :default => false, :null => false
  end

  create_table "rosterupdates", :force => true do |t|
    t.integer  "site_id",    :null => false
    t.integer  "binary_id",  :null => false
    t.datetime "fetched_at", :null => false
  end

  add_index "rosterupdates", ["binary_id"], :name => "index_rosterupdates_on_binary_id"
  add_index "rosterupdates", ["site_id", "fetched_at"], :name => "index_rosterupdates_on_site_id_and_fetched_at"

  create_table "sections", :force => true do |t|
    t.integer "site_id",                       :null => false
    t.string  "name"
    t.boolean "is_default", :default => false, :null => false
    t.string  "users_hash"
  end

  add_index "sections", ["name"], :name => "index_sections_on_name"
  add_index "sections", ["site_id"], :name => "index_sections_on_site_id"

  create_table "sessions", :force => true do |t|
    t.string   "session_id"
    t.text     "data"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "siteroles", :force => true do |t|
    t.integer "site_id",            :default => 0,     :null => false
    t.integer "role_id",            :default => 0,     :null => false
    t.boolean "take_attendance",    :default => false, :null => false
    t.boolean "record_attendance",  :default => false, :null => false
    t.boolean "edit_gradesettings", :default => false, :null => false
  end

  add_index "siteroles", ["role_id"], :name => "index_roles_sites_on_role_id"
  add_index "siteroles", ["site_id"], :name => "index_roles_sites_on_site_id"

  create_table "sites", :force => true do |t|
    t.string   "context_id"
    t.string   "context_label"
    t.string   "context_name"
    t.datetime "roster_fetched_at",  :null => false
    t.string   "roster_hash"
    t.datetime "update_in_progress"
    t.string   "outcomes_url"
    t.string   "points_url"
  end

  add_index "sites", ["context_id"], :name => "index_sites_on_context_id"

  create_table "userattendances", :force => true do |t|
    t.integer  "meeting_id",        :default => 0, :null => false
    t.integer  "membership_id",                    :null => false
    t.integer  "attendancetype_id", :default => 0, :null => false
    t.datetime "updated_at",                       :null => false
  end

  add_index "userattendances", ["attendancetype_id"], :name => "index_meetings_users_on_attendancetype_id"
  add_index "userattendances", ["meeting_id", "membership_id"], :name => "index_userattendances_on_meeting_id_and_membership_id", :unique => true
  add_index "userattendances", ["meeting_id"], :name => "index_meetings_users_on_meeting_id"
  add_index "userattendances", ["membership_id"], :name => "index_userattendances_on_membership_id"

  create_table "users", :force => true do |t|
    t.string  "netid"
    t.string  "lastname"
    t.string  "firstname"
    t.string  "fullname"
    t.boolean "admin",      :default => false, :null => false
    t.string  "tc_user_id"
  end

  add_index "users", ["lastname"], :name => "index_users_on_lastname"
  add_index "users", ["netid"], :name => "index_users_on_netid"
  add_index "users", ["tc_user_id"], :name => "index_users_on_tc_user_id"

end
