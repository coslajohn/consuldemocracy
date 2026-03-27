namespace :guests do
  desc "Remove guest users and anonymize their poll participation"
  task cleanup: :environment do
    puts "--- Starting Guest Cleanup ---"

    # 1. Find all guest users
    guests = User.where(guest: true)
    count = guests.count

    puts "Found #{count} guest users to remove."

    guests.find_each do |guest|
      # 2. Anonymize Poll::Voter records so stats stay intact
      # This prevents foreign key errors when the User is deleted
      Poll::Voter.where(user_id: guest.id).update_all(user_id: nil)

      # 3. Destroy the user (this also handles dependent records like sessions)
      guest.destroy
      print "."
    end

    puts "\n--- Cleanup Complete. #{count} guests removed. ---"
  end
end
