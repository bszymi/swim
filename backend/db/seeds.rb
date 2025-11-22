# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Swim England Regions and Counties (2024-2025)
puts "Seeding Swim England Regions and Counties..."

regions_data = {
  "East" => {
    code: "EAST",
    description: "Swim England East Region",
    counties: [ "Bedfordshire", "Cambridgeshire", "Essex", "Hertfordshire", "Norfolk", "Suffolk" ]
  },
  "East Midlands" => {
    code: "EMID",
    description: "Swim England East Midlands Region",
    counties: [ "Derbyshire", "Leicestershire", "Lincolnshire", "Northamptonshire", "Nottinghamshire" ]
  },
  "London" => {
    code: "LOND",
    description: "Swim England London Region",
    counties: [ "Greater London" ]
  },
  "North East" => {
    code: "NE",
    description: "Swim England North East Region",
    counties: [ "County Durham", "North Yorkshire", "North & North East Lincolnshire", "Northumberland", "Teesside", "Yorkshire" ]
  },
  "North West" => {
    code: "NW",
    description: "Swim England North West Region",
    counties: [ "Cheshire", "Cumbria", "Lancashire" ]
  },
  "South East" => {
    code: "SE",
    description: "Swim England South East Region",
    counties: [ "Berkshire", "Buckinghamshire", "Channel Islands", "East Sussex", "Hampshire", "Isle of Wight", "Kent", "Oxfordshire", "Surrey", "West Sussex" ]
  },
  "South West" => {
    code: "SW",
    description: "Swim England South West Region",
    counties: [ "Cornwall", "Devon", "Dorset", "Gloucestershire", "Somerset", "Wiltshire" ]
  },
  "West Midlands" => {
    code: "WMID",
    description: "Swim England West Midlands Region",
    counties: [ "Shropshire", "Staffordshire", "Warwickshire", "Worcestershire" ]
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
