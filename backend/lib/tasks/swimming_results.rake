namespace :swimming_results do
  desc "Import performances for all swimmers with SE membership IDs"
  task import_all: :environment do
    swimmers = Swimmer.where.not(se_membership_id: nil)

    puts "Found #{swimmers.count} swimmers with SE membership IDs"

    if swimmers.empty?
      puts "No swimmers found with SE membership IDs"
      exit
    end

    historic = ENV["HISTORIC"] == "true"
    mode = historic ? "historic" : "personal bests"

    puts "Starting #{mode} import for all swimmers..."
    puts "This may take a while..."

    swimmers.each_with_index do |swimmer, index|
      puts "\n[#{index + 1}/#{swimmers.count}] Processing #{swimmer.full_name} (SE ID: #{swimmer.se_membership_id})"

      begin
        ImportPerformancesJob.perform_async(swimmer.id, historic)
        puts "  ✓ Job queued successfully"
      rescue => e
        puts "  ✗ Error queuing job: #{e.message}"
      end
    end

    puts "\n✓ All jobs queued. Check Sidekiq dashboard to monitor progress."
  end

  desc "Import performances for all swimmers synchronously (not recommended for large datasets)"
  task import_all_sync: :environment do
    swimmers = Swimmer.where.not(se_membership_id: nil)

    puts "Found #{swimmers.count} swimmers with SE membership IDs"

    if swimmers.empty?
      puts "No swimmers found with SE membership IDs"
      exit
    end

    historic = ENV["HISTORIC"] == "true"
    mode = historic ? "historic" : "personal bests"

    puts "Starting synchronous #{mode} import for all swimmers..."
    puts "This may take a while..."

    success_count = 0
    error_count = 0

    swimmers.each_with_index do |swimmer, index|
      puts "\n[#{index + 1}/#{swimmers.count}] Processing #{swimmer.full_name} (SE ID: #{swimmer.se_membership_id})"

      begin
        ImportPerformancesJob.new.perform(swimmer.id, historic)
        puts "  ✓ Import completed"
        success_count += 1
      rescue => e
        puts "  ✗ Error: #{e.message}"
        error_count += 1
      end

      # Add delay between swimmers to avoid rate limiting
      if historic && index < swimmers.count - 1
        sleep 3
      end
    end

    puts "\n" + "=" * 50
    puts "Import Summary:"
    puts "  Total swimmers: #{swimmers.count}"
    puts "  Successful: #{success_count}"
    puts "  Errors: #{error_count}"
    puts "=" * 50
  end

  desc "Import performances for a specific swimmer by ID"
  task :import_swimmer, [:swimmer_id] => :environment do |t, args|
    unless args[:swimmer_id]
      puts "ERROR: Please provide a swimmer ID"
      puts "Usage: rake swimming_results:import_swimmer[123]"
      puts "       rake swimming_results:import_swimmer[123] HISTORIC=true"
      exit 1
    end

    swimmer = Swimmer.find_by(id: args[:swimmer_id])

    unless swimmer
      puts "ERROR: Swimmer with ID #{args[:swimmer_id]} not found"
      exit 1
    end

    unless swimmer.se_membership_id.present?
      puts "ERROR: Swimmer #{swimmer.full_name} has no SE membership ID"
      exit 1
    end

    historic = ENV["HISTORIC"] == "true"
    mode = historic ? "historic" : "personal bests"

    puts "Importing #{mode} for #{swimmer.full_name} (SE ID: #{swimmer.se_membership_id})..."

    begin
      ImportPerformancesJob.new.perform(swimmer.id, historic)
      puts "✓ Import completed successfully"
    rescue => e
      puts "✗ Error: #{e.message}"
      exit 1
    end
  end

  desc "Show stats about swimmers and their SE membership IDs"
  task stats: :environment do
    total_swimmers = Swimmer.count
    swimmers_with_se_id = Swimmer.where.not(se_membership_id: nil).count
    swimmers_without_se_id = total_swimmers - swimmers_with_se_id

    puts "Swimmer Statistics:"
    puts "  Total swimmers: #{total_swimmers}"
    puts "  With SE membership ID: #{swimmers_with_se_id}"
    puts "  Without SE membership ID: #{swimmers_without_se_id}"

    if swimmers_with_se_id > 0
      puts "\nSwimmers with SE membership IDs:"
      Swimmer.where.not(se_membership_id: nil).each do |swimmer|
        perf_count = swimmer.performances.count
        puts "  - #{swimmer.full_name} (SE ID: #{swimmer.se_membership_id}) - #{perf_count} performances"
      end
    end
  end
end
