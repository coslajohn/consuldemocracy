module GuestSessionHandler
  extend ActiveSupport::Concern

  included do
    helper_method :current_or_guest_user
  end

  # The "Master" method to use in views and controllers
  def current_or_guest_user
    if current_user
      # If a real user logs in, we could optionally merge guest data here
      current_user
    else
      guest_user
    end
  end

  # Passive: Only returns a guest if one ALREADY exists in this session
  def guest_user
    @guest_user ||= User.guests.find_by(id: session[:guest_user_id]) if session[:guest_user_id]
  end

  # Active: Creates the guest record only when an interaction occurs
  def ensure_guest_user!
    return current_or_guest_user if current_or_guest_user

    unless Setting.allow_guests?
      authenticate_user!
      return current_user
    end

    new_guest = User.new(
      guest: true,
      username: "guest_#{SecureRandom.hex(3)}",
      email: "guest_#{SecureRandom.uuid}@example.com",
      ip_address: request.remote_ip,
      fingerprint: generate_fingerprint,
      terms_of_service: "1"
    )

    new_guest.skip_confirmation!
    new_guest.save!(validate: false)

    session[:guest_user_id] = new_guest.id
    new_guest
  end

  private

    def generate_fingerprint
      Digest::SHA256.hexdigest("#{request.remote_ip}-#{request.user_agent}")
    end
end
