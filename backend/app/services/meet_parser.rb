require "anthropic"
require "base64"

class MeetParser
  class ParserError < StandardError; end

  def initialize(pdf_path_or_data)
    @pdf_data = if pdf_path_or_data.is_a?(String) && pdf_path_or_data.start_with?("/")
                  # It's a file path
                  File.read(pdf_path_or_data)
    else
                  # It's binary data
                  pdf_path_or_data
    end

    # Explicitly load .env file if ENV variable isn't set
    api_key = ENV["ANTHROPIC_API_KEY"]
    if api_key.nil? || api_key.empty?
      require "dotenv"
      Dotenv.load
      api_key = ENV["ANTHROPIC_API_KEY"]
    end

    @client = Anthropic::Client.new(api_key: api_key)
  end

  # Parse the PDF and extract meet qualification standards
  def parse
    base64_pdf = Base64.strict_encode64(@pdf_data)

    prompt = build_parsing_prompt

    response = @client.beta.messages.create(
      model: "claude-sonnet-4-5-20250929",
      max_tokens: 16000,
      betas: [ "pdfs-2024-09-25" ],
      messages: [
        {
          role: "user",
          content: [
            {
              type: "document",
              source: {
                type: "base64",
                media_type: "application/pdf",
                data: base64_pdf
              }
            },
            {
              type: "text",
              text: prompt
            }
          ]
        }
      ]
    )

    # Extract JSON from response
    # Response is a BetaMessage object, not a hash
    content = response.content&.first&.text
    raise ParserError, "No response from Claude" unless content

    # Strip markdown code fences if present (```json ... ```)
    json_content = content.strip
    if json_content.start_with?("```")
      # Remove opening fence (```json or ```)
      json_content = json_content.sub(/\A```(?:json)?\n?/, "")
      # Remove closing fence
      json_content = json_content.sub(/\n?```\z/, "")
    end

    # Parse the JSON response
    parsed_data = JSON.parse(json_content)

    validate_parsed_data(parsed_data)

    parsed_data

  rescue JSON::ParserError => e
    raise ParserError, "Failed to parse JSON response: #{e.message}"
  rescue => e
    raise ParserError, "Parsing error: #{e.message}"
  end

  private

  def build_parsing_prompt
    <<~PROMPT
      You are a swimming meet qualification document parser. Extract all qualification standards from this PDF.

      IMPORTANT: Return ONLY valid JSON, no markdown formatting, no code blocks, no explanation.

      Extract the following information:

      1. **Meet Information:**
         - Meet name
         - Season/year
         - Pool type required (LC/SC)
         - Qualifying window dates (start and end)
         - Age calculation method (either "age_on_date" with specific date, or "calendar_year")

      2. **Qualification Standards:**
         For each event, extract all qualifying times organized by:
         - Event (distance + stroke, e.g., "50 FREE", "100 BACK")
         - Course type (LC or SC)
         - Age groups (e.g., "10", "11", "12-13", "14-15")
         - Gender (M/F)
         - Qualifying time in seconds

      Return data in this EXACT JSON structure:

      {
        "meet_name": "string",
        "license_number": "string or null (e.g., '4NE252206', '3SE251839')",
        "season": "string",
        "pool_required": "LC" or "SC",
        "window_start": "YYYY-MM-DD" or null,
        "window_end": "YYYY-MM-DD" or null,
        "age_calculation": {
          "method": "age_on_date" or "calendar_year",
          "date": "YYYY-MM-DD" or null
        },
        "standards": [
          {
            "distance_m": integer,
            "stroke": "FREE" or "BACK" or "BREAST" or "FLY" or "IM",
            "course_type": "LC" or "SC",
            "age_group": "string",
            "sex": "M" or "F",
            "qualifying_time_seconds": float
          }
        ]
      }

      IMPORTANT NOTES:
      - Convert all times to seconds (e.g., "1:30.45" becomes 90.45)
      - Stroke codes: FREE, BACK, BREAST, FLY, IM
      - Age groups: keep as strings (e.g., "10", "11-12", "13-14", "Open")
      - If age is calculated on a specific date, use "age_on_date" method
      - If age is based on calendar year (e.g., "age as of 31 Dec 2025"), use "calendar_year" method
      - Extract ALL standards from ALL tables in the document
      - Be careful with merged cells and complex table layouts
      - **IMPORTANT**: Extract the Swim England license number if present (usually in format like "4NE252206" where 4=level, NE=region code, 252206=year+sequence)

      Return ONLY the JSON object, nothing else.
    PROMPT
  end

  def validate_parsed_data(data)
    required_keys = [ "meet_name", "standards" ]
    missing_keys = required_keys - data.keys

    raise ParserError, "Missing required keys: #{missing_keys.join(', ')}" if missing_keys.any?
    raise ParserError, "No standards found" if data["standards"].empty?

    # Validate each standard
    data["standards"].each_with_index do |standard, idx|
      required_standard_keys = [ "distance_m", "stroke", "course_type", "sex", "qualifying_time_seconds" ]
      missing = required_standard_keys - standard.keys

      if missing.any?
        raise ParserError, "Standard ##{idx + 1} missing keys: #{missing.join(', ')}"
      end
    end
  end
end
