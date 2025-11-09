# Service to check qualification for a swimmer without requiring a persisted Swimmer record
# Used for the public qualification checker on the homepage
class PublicQualificationChecker
  attr_reader :dob, :sex, :stroke, :distance_m, :time_seconds, :course_type

  def initialize(dob:, sex:, stroke:, distance_m:, time_seconds:, course_type:)
    @dob = dob
    @sex = sex
    @stroke = stroke
    @distance_m = distance_m
    @time_seconds = time_seconds
    @course_type = course_type
  end

  def check_all_meets
    results = []

    # Get all meetings
    meetings = Meeting.all

    meetings.each do |meeting|
      result = check_against_meet(meeting)
      results << result if result
    end

    # Sort by qualification status (qualified first, then consideration, then not qualified)
    # Then by delta (closer to qualifying time first)
    results.sort_by do |r|
      status_priority = if r[:qualified]
                          0
      elsif r[:consideration]
                          1
      else
                          2
      end
      [ status_priority, r[:delta] || Float::INFINITY ]
    end
  end

  private

  def check_against_meet(meeting)
    # Calculate swimmer's age on the meet's age reference date
    age_reference_date = meeting.age_reference_date
    age = calculate_age_on(age_reference_date)

    # Find the standard for this swimmer
    standards = meeting.meeting_standards
                       .for_event(@stroke, @distance_m)
                       .for_age(age)
                       .where(gender: @sex)

    qualifying_standard = standards.qualifying.first
    consideration_standard = standards.consideration.first

    # If no standards found, skip this meet
    return nil if qualifying_standard.nil? && consideration_standard.nil?

    # Get the swimmer's time in the required pool format
    meet_rule = meeting.meet_rule
    required_pool = meeting.pool_required

    swimmer_time = get_time_for_pool(required_pool, meet_rule)
    return nil if swimmer_time.nil?

    # Determine qualification status
    required_time = qualifying_standard&.time_seconds
    consideration_time = consideration_standard&.time_seconds

    qualified = required_time && swimmer_time <= required_time
    consideration = if consideration_time && required_time
                      swimmer_time > required_time && swimmer_time <= consideration_time
    elsif consideration_time && !required_time
                      swimmer_time <= consideration_time
    else
                      false
    end

    delta = required_time ? (swimmer_time - required_time).round(2) : nil

    # Format age group display
    age_group = if qualifying_standard
                  format_age_group(qualifying_standard.age_min, qualifying_standard.age_max)
    elsif consideration_standard
                  format_age_group(consideration_standard.age_min, consideration_standard.age_max)
    end

    # Generate conversion note if applicable
    conversion_note = if @course_type != required_pool && %w[LC SC].include?(required_pool)
                        "Time converted from #{@course_type} to #{required_pool} (#{TimeParser.to_formatted(@time_seconds)} → #{TimeParser.to_formatted(swimmer_time)})"
    end

    {
      meet_name: meeting.name,
      qualified: qualified,
      consideration: consideration,
      swimmer_time: TimeParser.to_formatted(swimmer_time),
      required_time: required_time ? TimeParser.to_formatted(required_time) : nil,
      delta: delta,
      age_group: age_group,
      conversion_note: conversion_note
    }
  end

  def get_time_for_pool(required_pool, meet_rule)
    # If the meet doesn't specify a required pool, use the swimmer's time as-is
    return @time_seconds unless %w[LC SC].include?(required_pool)

    # If the swimmer's time is already in the required pool, use it directly
    return @time_seconds if @course_type == required_pool

    # Check if conversion is allowed
    return nil unless meet_rule&.conversion_allowed?(@course_type, required_pool)

    # Convert the time
    converted_time = EquivalentTime.convert(
      stroke: @stroke,
      distance_m: @distance_m,
      from_course: @course_type,
      to_course: required_pool,
      time_seconds: @time_seconds
    )

    converted_time
  end

  def calculate_age_on(date)
    age = date.year - @dob.year
    age -= 1 if date.yday < @dob.yday
    age
  end

  def format_age_group(age_min, age_max)
    if age_min && age_max
      if age_min == age_max
        "#{age_min} years"
      else
        "#{age_min}-#{age_max} years"
      end
    elsif age_min
      "#{age_min}+ years"
    elsif age_max
      "Up to #{age_max} years"
    else
      "All ages"
    end
  end
end
