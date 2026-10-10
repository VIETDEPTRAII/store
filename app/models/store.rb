class Store < ApplicationRecord
  belongs_to :user

  has_many :categories, dependent: :destroy
  has_many :products, through: :categories

  validates :name, presence: true
end
