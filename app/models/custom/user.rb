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

  def finalize_guest_identity(params)
    return unless guest?

    # 1. Standardize Date of Birth (Consul Census style)
    year = params[:guest_year_of_birth].to_i
    # Ensure year is a sane number (e.g., 1992)
    if year > 1900 && year < Date.today.year
      self.date_of_birth = Date.new(year, 6, 30)
    else
      return false # Or set a default
    end

    # 2. Build a Composite Document Number (Signature Sheet style)
    # This acts as our unique 'Signature'
    initials = params[:guest_initials].to_s.gsub(/\s+/, "").upcase.truncate(3)
    postcode = params[:guest_postal_code].to_s.gsub(/\s+/, "").upcase
    if initials.blank? || postcode.blank?
      errors.add(:base, "Initials and Postcode are required")
      return false
    end
    timestamp = Time.current.strftime("%H%M%S")

    # Format: INITIALS,POSTCODE,TIMESTAMP
    self.document_number = "#{initials},#{postcode},#{timestamp}"
    self.document_type = "guest_id"

    # 3. Optional: Map Gender if provided
    self.gender = params[:gender] if params[:gender].present?

    save
  end

  def send_devise_notification(notification, *args)
    return if guest?

    super
  end

end
