load Rails.root.join("app", "models", "user.rb")
class User < ApplicationRecord
  scope :real,   -> { where(guest: false) }
  scope :guests, -> { where(guest: true) }

  def password_required?
    return false if guest? || skip_password_validation
    super
  end

  def username_required?
    # Allow guests to have null or generated usernames
    !guest? && !organization? && !erased?
  end

  def email_required?
    # Guests use placeholder/temporary emails
    !guest? && !erased? && (unverified? || registering_from_web)
  end

  def guest?
    # Ensure it handles nil cases from database
    read_attribute(:guest) || false
  end

  # Allows the Polls logic to treat a guest as 'able to vote'
  # without a document number
  def verified?
    guest? ? true : super
  end

end
