class Rack::Attack
  # Use existing Memcached store (from your production.rb)
  Rack::Attack.cache.store = Rails.cache

  # Always allow requests from localhost
  safelist('allow from localhost') do |req|
    '127.0.0.1' == req.ip || '::1' == req.ip
  end

  # If any single IP makes 300 requests in 5 minutes, they are likely a bad scraper.
  throttle('req/ip', limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?('/assets')
  end

  # Throttling login attempts by IP (6 reqs/minute)
  throttle('logins/ip', limit: 6, period: 60.seconds) do |req|
    if req.path == '/users/sign_in' && req.post?
      req.ip
    end
  end

  # HARDENING: Shadow Guest Rate Limit (Shared-IP Friendly)
  # Limit: 5 votes per 24 hours per unique Device+IP combination
  Rack::Attack.throttle('req/ip/guest_votes', limit: 5, period: 1.day) do |req|
    if req.post? && req.path.match?(%r{^/polls/[^/]+/answer$})
      # We combine the IP with the User Agent string to differentiate devices
      # and then hash it to keep the Memcached key a consistent length.
      Digest::SHA256.hexdigest("#{req.ip}-#{req.user_agent}")
    end
  end

  # This allows you to see blocks in your Rails logs
  ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |name, start, finish, request_id, payload|
    req = payload[:request]
    Rails.logger.warn "[Rack::Attack] Throttled: #{req.ip} path: #{req.path} (Rule: #{req.env['rack.attack.matched']})"
  end
end
