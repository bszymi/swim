class TimeConverter
  # British Swimming Equivalent Time Algorithm
  # Written by Graham Sykes
  # Source: https://leman.net/wp/2024/11/08/converting-swim-times-between-short-and-long-course-in-excel-using-the-british-swimming-equivalent-time-algorithm/
  #
  # Turn factors for converting between 25m (short course) and 50m (long course)
  # These factors account for the advantage gained from turns and push-offs in shorter pools

  TURN_FACTORS = {
    50 => {
      "FREE" => 42.245,
      "BACK" => 40.5,
      "BREAST" => 63.616,
      "FLY" => 38.269
    },
    100 => {
      "FREE" => 42.245,
      "BACK" => 40.5,
      "BREAST" => 63.616,
      "FLY" => 38.269
    },
    200 => {
      "FREE" => 43.786,
      "BACK" => 41.98,
      "BREAST" => 66.598,
      "FLY" => 39.76,
      "IM" => 49.7
    },
    400 => {
      "FREE" => 44.233,
      "IM" => 55.366
    },
    800 => {
      "FREE" => 45.525
    },
    1500 => {
      "FREE" => 46.221
    }
  }.freeze

  # Convert LC time to SC time (50m -> 25m)
  # Formula: SC = LC - (TurnFactor / LC) × (Distance/100)² × 2
  # @param lc_time_seconds [Float] Time in long course (50m pool)
  # @param distance_m [Integer] Distance in meters
  # @param stroke [String] Stroke type (FREE, BACK, BREAST, FLY, IM)
  # @return [Float] Estimated SC time in seconds
  def self.lc_to_sc(lc_time_seconds, distance_m, stroke)
    return lc_time_seconds if lc_time_seconds.nil?
    return lc_time_seconds if lc_time_seconds <= 0

    turn_factor = get_turn_factor(distance_m, stroke)
    return lc_time_seconds if turn_factor.nil? # No conversion available

    num_turn_factor = ((distance_m / 100.0) ** 2) * 2

    sc_time = lc_time_seconds - ((turn_factor / lc_time_seconds) * num_turn_factor)

    # Ensure result is positive
    sc_time > 0 ? sc_time : lc_time_seconds
  end

  # Convert SC time to LC time (25m -> 50m)
  # Formula: LC = (SC + √(SC² + 4 × TurnFactor × NumTurnFactor)) / 2
  # @param sc_time_seconds [Float] Time in short course (25m pool)
  # @param distance_m [Integer] Distance in meters
  # @param stroke [String] Stroke type (FREE, BACK, BREAST, FLY, IM)
  # @return [Float] Estimated LC time in seconds
  def self.sc_to_lc(sc_time_seconds, distance_m, stroke)
    return sc_time_seconds if sc_time_seconds.nil?
    return sc_time_seconds if sc_time_seconds <= 0

    turn_factor = get_turn_factor(distance_m, stroke)
    return sc_time_seconds if turn_factor.nil? # No conversion available

    num_turn_factor = ((distance_m / 100.0) ** 2) * 2

    # Calculate using quadratic formula solution
    discriminant = (sc_time_seconds ** 2) + (4 * turn_factor * num_turn_factor)

    # Ensure discriminant is positive
    return sc_time_seconds if discriminant < 0

    lc_time = (sc_time_seconds + Math.sqrt(discriminant)) / 2.0

    # Ensure result is positive and greater than SC time (LC should always be slower)
    (lc_time > 0 && lc_time >= sc_time_seconds) ? lc_time : sc_time_seconds
  end

  # Get the appropriate time for a given course type
  # @param lc_time [Float] LC time in seconds
  # @param sc_time [Float] SC time in seconds
  # @param desired_course [String] 'LC' or 'SC'
  # @return [Float] Time in the desired course
  def self.get_time_for_course(lc_time, sc_time, desired_course)
    case desired_course
    when "LC"
      lc_time
    when "SC"
      sc_time
    else
      # Default to whichever is available
      lc_time || sc_time
    end
  end

  private

  # Get the turn factor for a specific distance and stroke
  # @param distance_m [Integer] Distance in meters
  # @param stroke [String] Stroke type
  # @return [Float, nil] Turn factor or nil if not available
  def self.get_turn_factor(distance_m, stroke)
    distance_factors = TURN_FACTORS[distance_m]
    return nil unless distance_factors

    distance_factors[stroke]
  end
end
