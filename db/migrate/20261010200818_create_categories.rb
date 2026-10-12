class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.references :store, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.text :description

      t.timestamps
    end

    add_index :categories, [ :store_id, :name ], unique: true
  end
end
