class User < ApplicationRecord
  has_secure_password

  has_many :stores, dependent: :destroy

  before_validation :normalize_email
  before_create :set_jti

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, allow_nil: true

  def regenerate_jti!
    update!(jti: SecureRandom.uuid)
  end

  private

  def normalize_email
    self.email = email.to_s.downcase.strip
  end

  def set_jti
    self.jti ||= SecureRandom.uuid
  end
end
