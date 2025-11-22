namespace :swimming_results do
  desc "Recalculate all time conversions using the British Swimming algorithm"
  task recalculate_conversions: :environment do
    puts "Recalculating time conversions for all performances..."
    puts "=" * 80
    puts ""

    performances = Performance.all
    total_count = performances.count

    if total_count.zero?
      puts "No performances found in the database."
      exit
    end

    puts "Found #{total_count} performances to recalculate"
    puts ""

    updated_count = 0
    skipped_count = 0
    error_count = 0

    performances.each_with_index do |performance, index|
      begin
        # Store original values for comparison
        original_lc = performance.lc_time_seconds
        original_sc = performance.sc_time_seconds

        # Determine which time is the source (actual recorded time)
        if performance.course_type == "LC"
          # LC is the actual time, recalculate SC
          performance.lc_time_seconds = performance.time_seconds
          performance.sc_time_seconds = TimeConverter.lc_to_sc(
            performance.time_seconds,
            performance.distance_m,
            performance.stroke
          )
        elsif performance.course_type == "SC"
          # SC is the actual time, recalculate LC
          performance.sc_time_seconds = performance.time_seconds
          performance.lc_time_seconds = TimeConverter.sc_to_lc(
            performance.time_seconds,
            performance.distance_m,
            performance.stroke
          )
        else
          puts "  [#{index + 1}/#{total_count}] Performance ##{performance.id}: Unknown course type '#{performance.course_type}'"
          skipped_count += 1
          next
        end

        # Check if values actually changed
        lc_changed = original_lc && (original_lc - performance.lc_time_seconds).abs > 0.01
        sc_changed = original_sc && (original_sc - performance.sc_time_seconds).abs > 0.01

        if lc_changed || sc_changed
          if performance.save
            updated_count += 1

            # Show details for first 10 updates
            if updated_count <= 10
              puts "  [#{index + 1}/#{total_count}] Updated Performance ##{performance.id}"
              puts "    Event: #{performance.distance_m}m #{performance.stroke} (#{performance.course_type})"
              if lc_changed
                diff = performance.lc_time_seconds - original_lc
                puts "    LC: #{format_time(original_lc)} → #{format_time(performance.lc_time_seconds)} (#{sprintf('%+.2f', diff)}s)"
              end
              if sc_changed
                diff = performance.sc_time_seconds - original_sc
                puts "    SC: #{format_time(original_sc)} → #{format_time(performance.sc_time_seconds)} (#{sprintf('%+.2f', diff)}s)"
              end
              puts ""
            end
          else
            error_count += 1
            puts "  [#{index + 1}/#{total_count}] ERROR: Failed to save Performance ##{performance.id}: #{performance.errors.full_messages.join(', ')}"
          end
        else
          skipped_count += 1
        end

        # Progress indicator every 50 records
        if (index + 1) % 50 == 0
          puts "  Progress: #{index + 1}/#{total_count} (#{updated_count} updated, #{skipped_count} unchanged, #{error_count} errors)"
        end

      rescue => e
        error_count += 1
        puts "  [#{index + 1}/#{total_count}] ERROR: Exception for Performance ##{performance.id}: #{e.message}"
      end
    end

    puts ""
    puts "=" * 80
    puts "Recalculation Summary:"
    puts "  Total performances: #{total_count}"
    puts "  Updated: #{updated_count}"
    puts "  Unchanged: #{skipped_count}"
    puts "  Errors: #{error_count}"
    puts "=" * 80
    puts ""
    puts "✓ Recalculation complete!"
  end

  private

  def format_time(seconds)
    return "N/A" if seconds.nil?

    minutes = (seconds / 60).floor
    secs = seconds % 60

    if minutes > 0
      sprintf("%d:%05.2f", minutes, secs)
    else
      sprintf("%.2f", secs)
    end
  end
end
