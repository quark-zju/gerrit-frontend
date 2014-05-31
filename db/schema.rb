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

ActiveRecord::Schema.define(version: 20140530172427) do

  create_table "change_comments", force: true do |t|
    t.integer  "author_id",       null: false
    t.integer  "change_id",       null: false
    t.string   "local_id",        null: false
    t.integer  "revision_number"
    t.text     "message"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "change_comments", ["author_id"], name: "index_change_comments_on_author_id"
  add_index "change_comments", ["change_id"], name: "index_change_comments_on_change_id"

  create_table "changes", force: true do |t|
    t.integer  "host_id"
    t.string   "change_id",              null: false
    t.string   "subject",                null: false
    t.integer  "number",                 null: false
    t.integer  "project_id"
    t.string   "branch"
    t.integer  "owner_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",     default: 0, null: false
  end

  add_index "changes", ["host_id", "number"], name: "index_changes_on_host_id_and_number", unique: true
  add_index "changes", ["host_id"], name: "index_changes_on_host_id"
  add_index "changes", ["project_id"], name: "index_changes_on_project_id"

  create_table "contents", force: true do |t|
    t.string "digest",             null: false
    t.binary "compressed_content", null: false
  end

  add_index "contents", ["digest"], name: "index_contents_on_digest", unique: true

  create_table "delayed_jobs", force: true do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority"

  create_table "hosts", force: true do |t|
    t.string  "base_url",                        null: false
    t.boolean "allow_anonymous", default: false, null: false
    t.boolean "is_local_net",    default: false, null: false
  end

  create_table "projects", force: true do |t|
    t.integer "host_id"
    t.string  "name",    null: false
  end

  add_index "projects", ["host_id"], name: "index_projects_on_host_id"

  create_table "revision_file_comments", force: true do |t|
    t.integer  "revision_file_id"
    t.integer  "line"
    t.text     "message"
    t.integer  "author_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "local_id"
  end

  add_index "revision_file_comments", ["author_id"], name: "index_revision_file_comments_on_author_id"
  add_index "revision_file_comments", ["revision_file_id"], name: "index_revision_file_comments_on_revision_file_id"

  create_table "revision_files", force: true do |t|
    t.integer "revision_id",  null: false
    t.string  "pathname",     null: false
    t.integer "a_content_id"
    t.integer "b_content_id"
  end

  add_index "revision_files", ["revision_id"], name: "index_revision_files_on_revision_id"

  create_table "revisions", force: true do |t|
    t.integer "change_id",     null: false
    t.integer "local_id",      null: false
    t.string  "parent_commit"
    t.string  "author"
    t.string  "committer"
    t.string  "subject"
    t.text    "message"
  end

  add_index "revisions", ["change_id"], name: "index_revisions_on_change_id"

  create_table "users", force: true do |t|
    t.integer "host_id",    null: false
    t.string  "name",       null: false
    t.string  "username",   null: false
    t.string  "email",      null: false
    t.integer "account_id", null: false
  end

  add_index "users", ["host_id"], name: "index_users_on_host_id"

end
