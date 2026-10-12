class Category < ApplicationRecord
  belongs_to :store
  has_many :products, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :store_id }
end
