namespace :test do
  desc "Compare old vs new time conversion algorithms"
  task compare_conversions: :environment do
    puts "Comparison of Time Conversion Methods"
    puts "=" * 80
    puts "British Swimming Equivalent Time Algorithm vs Simple Percentage Method"
    puts "=" * 80
    puts ""

    test_cases = [
      { distance: 50, stroke: "FREE", sc_time: 30.0 },
      { distance: 100, stroke: "FREE", sc_time: 60.0 },
      { distance: 100, stroke: "BREAST", sc_time: 75.0 },
      { distance: 200, stroke: "FREE", sc_time: 120.0 },
      { distance: 200, stroke: "FLY", sc_time: 140.0 },
      { distance: 400, stroke: "IM", sc_time: 300.0 },
      { distance: 800, stroke: "FREE", sc_time: 540.0 },
      { distance: 1500, stroke: "FREE", sc_time: 1000.0 }
    ]

    test_cases.each do |test|
      sc_time = test[:sc_time]
      distance = test[:distance]
      stroke = test[:stroke]

      lc_time = TimeConverter.sc_to_lc(sc_time, distance, stroke)
      back_to_sc = TimeConverter.lc_to_sc(lc_time, distance, stroke)

      difference = lc_time - sc_time
      roundtrip_error = (back_to_sc - sc_time).abs

      puts "#{distance}m #{stroke}"
      puts "  SC Time: #{format_time(sc_time)}"
      puts "  LC Time: #{format_time(lc_time)}"
      puts "  Difference: #{sprintf('%.2f', difference)}s (#{sprintf('%.2f', (difference / sc_time * 100))}%)"
      puts "  Roundtrip error: #{sprintf('%.4f', roundtrip_error)}s"
      puts ""
    end
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
