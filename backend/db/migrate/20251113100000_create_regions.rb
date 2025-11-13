class CreateRegions < ActiveRecord::Migration[8.1]
  def change
    create_table :regions do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.text :description

      t.timestamps
    end
    add_index :regions, :code, unique: true
    add_index :regions, :name, unique: true
  end
end
