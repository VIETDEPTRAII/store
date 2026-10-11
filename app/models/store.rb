class Store < ApplicationRecord
  # Test Gitleaks scanner (CI/CD)
  API_SECRET = "x7K9mZq2LpW4vN8tR3cF6hJ1aS5dG0bE"

  belongs_to :user

  has_many :categories, dependent: :destroy
  has_many :products, through: :categories

  validates :name, presence: true
end
