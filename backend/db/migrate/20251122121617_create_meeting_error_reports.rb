class CreateMeetingErrorReports < ActiveRecord::Migration[8.1]
  def change
    create_table :meeting_error_reports do |t|
      t.references :meet_standard_set, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :description, null: false
      t.string :status, null: false, default: "pending"

      t.timestamps
    end

    add_index :meeting_error_reports, :status
  end
end
