class AddLicenseNumberToMeetStandardSets < ActiveRecord::Migration[8.1]
  def change
    add_column :meet_standard_sets, :license_number, :string
    add_reference :meet_standard_sets, :live_meeting, foreign_key: true
    add_index :meet_standard_sets, :license_number
  end
end
