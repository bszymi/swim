class CreateLiveMeetings < ActiveRecord::Migration[8.1]
  def change
    create_table :live_meetings do |t|
      t.string :name, null: false
      t.string :meet_number
      t.references :region, null: true, foreign_key: true
      t.references :county, null: true, foreign_key: true
      t.string :city
      t.string :venue
      t.string :course_type, null: false # "25" or "50" (meters)
      t.integer :license_level
      t.date :start_date, null: false
      t.date :end_date
      t.string :external_url
      t.text :notes

      t.timestamps
    end

    add_index :live_meetings, :start_date
    add_index :live_meetings, :meet_number
    add_index :live_meetings, [ :start_date, :region_id ]
  end
end
