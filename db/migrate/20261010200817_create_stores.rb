class CreateStores < ActiveRecord::Migration[8.1]
  def change
    create_table :stores do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.text :description

      t.timestamps
    end
  end
end
