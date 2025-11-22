namespace :admin do
  desc "Promote a user to admin by email"
  task :promote, [ :email ] => :environment do |t, args|
    unless args[:email]
      puts "ERROR: Please provide an email"
      puts "Usage: rake admin:promote[user@example.com]"
      exit 1
    end

    user = User.find_by(email: args[:email])

    unless user
      puts "ERROR: User with email #{args[:email]} not found"
      exit 1
    end

    if user.admin?
      puts "User #{user.email} is already an admin"
      exit 0
    end

    if user.update(role: "admin")
      puts "✓ Successfully promoted #{user.email} to admin"
    else
      puts "✗ Failed to promote user: #{user.errors.full_messages.join(', ')}"
      exit 1
    end
  end

  desc "Demote an admin user to regular user by email"
  task :demote, [ :email ] => :environment do |t, args|
    unless args[:email]
      puts "ERROR: Please provide an email"
      puts "Usage: rake admin:demote[user@example.com]"
      exit 1
    end

    user = User.find_by(email: args[:email])

    unless user
      puts "ERROR: User with email #{args[:email]} not found"
      exit 1
    end

    unless user.admin?
      puts "User #{user.email} is not an admin"
      exit 0
    end

    if user.update(role: "user")
      puts "✓ Successfully demoted #{user.email} to regular user"
    else
      puts "✗ Failed to demote user: #{user.errors.full_messages.join(', ')}"
      exit 1
    end
  end

  desc "List all admin users"
  task list: :environment do
    admins = User.where(role: "admin")

    if admins.empty?
      puts "No admin users found"
      exit 0
    end

    puts "Admin Users:"
    puts "=" * 80
    admins.each do |admin|
      swimmers_count = admin.swimmers.count
      puts "  #{admin.email} (ID: #{admin.id}, Swimmers: #{swimmers_count}, Created: #{admin.created_at.to_date})"
    end
    puts "=" * 80
    puts "Total admins: #{admins.count}"
  end
end
