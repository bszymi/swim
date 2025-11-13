# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# UK Swimming Regions and Counties
puts "Seeding UK Swimming Regions and Counties..."

regions_data = {
  "East Region" => {
    code: "EAST",
    description: "Swim England East Region",
    counties: ["Bedfordshire", "Cambridgeshire", "Essex", "Hertfordshire", "Norfolk", "Suffolk"]
  },
  "East Midlands Region" => {
    code: "EMID",
    description: "Swim England East Midlands Region",
    counties: ["Derbyshire", "Leicestershire", "Lincolnshire", "Northamptonshire", "Nottinghamshire", "Rutland"]
  },
  "London Region" => {
    code: "LOND",
    description: "Swim England London Region",
    counties: ["Greater London"]
  },
  "North East Region" => {
    code: "NE",
    description: "Swim England North East Region",
    counties: ["County Durham", "Northumberland", "Tees Valley", "Tyne and Wear"]
  },
  "North West Region" => {
    code: "NW",
    description: "Swim England North West Region",
    counties: ["Cheshire", "Cumbria", "Greater Manchester", "Lancashire", "Merseyside"]
  },
  "South East Region" => {
    code: "SE",
    description: "Swim England South East Region",
    counties: ["Berkshire", "Buckinghamshire", "East Sussex", "Hampshire", "Isle of Wight", "Kent", "Oxfordshire", "Surrey", "West Sussex"]
  },
  "South West Region" => {
    code: "SW",
    description: "Swim England South West Region",
    counties: ["Bristol", "Cornwall", "Devon", "Dorset", "Gloucestershire", "Somerset", "Wiltshire"]
  },
  "West Midlands Region" => {
    code: "WMID",
    description: "Swim England West Midlands Region",
    counties: ["Herefordshire", "Shropshire", "Staffordshire", "Warwickshire", "West Midlands", "Worcestershire"]
  },
  "Yorkshire Region" => {
    code: "YORK",
    description: "Swim England Yorkshire Region",
    counties: ["East Riding of Yorkshire", "North Yorkshire", "South Yorkshire", "West Yorkshire"]
  }
}

regions_data.each do |region_name, data|
  region = Region.find_or_create_by!(name: region_name) do |r|
    r.code = data[:code]
    r.description = data[:description]
  end

  puts "  Created/found region: #{region_name}"

  data[:counties].each do |county_name|
    County.find_or_create_by!(name: county_name, region: region)
    puts "    - #{county_name}"
  end
end

puts "Seeding complete!"
