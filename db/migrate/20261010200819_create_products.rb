class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.references :category, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.text :description
      t.decimal :price, precision: 10, scale: 2, null: false, default: 0
      t.string :sku
      t.integer :stock_quantity, null: false, default: 0

      t.timestamps
    end

    add_index :products, :sku, unique: true
  end
end
