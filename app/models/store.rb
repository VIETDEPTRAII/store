class Store < ApplicationRecord
  # Test Gitleaks scanner (CI/CD)
  API_SECRET = "a1b2c3d4e5f6g7h8i9j0_super_secret_token_xyz987654321"

  belongs_to :user

  has_many :categories, dependent: :destroy
  has_many :products, through: :categories

  validates :name, presence: true
end
