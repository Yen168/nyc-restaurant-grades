class DataSet
  ORDER = :id.freeze
  LIMIT = 1000.freeze

  attr_accessor :page

  def initialize
    @page = 0
  end

  def endpoint
    "https://data.cityofnewyork.us/resource/xx67-kt59.json?#{parameters}"
  end

  def parameters
    return unless ORDER && LIMIT && offset
    "$order=:#{ORDER}&$limit=#{LIMIT}&$offset=#{offset}"
  end

  private

  def offset
    page * LIMIT
  end
end

not_broken = true
dataset = DataSet.new

while not_broken
  begin
    response        = RestClient.get(dataset.endpoint)
    parsed_response = JSON.parse(response)

    parsed_response.each do |restaurant_data|
      ActiveRecord::Base.transaction do
        next unless restaurant_data['dba']

        restaurant = Restaurant.find_or_create_by(camis: restaurant_data['camis']) do |r|
          r.name             = restaurant_data['dba'].titleize
          r.building_number  = restaurant_data['building']
          r.street           = restaurant_data['street'].titleize
          r.zipcode          = restaurant_data['zipcode']
          r.borough          = Restaurant.boroughs[restaurant_data['boro']]
          r.phone_number     = restaurant_data['phone']
        end

        Inspection.create(
          restaurant:             restaurant,
          type:                   restaurant_data['inspection_type'],
          inspected_at:           restaurant_data['inspection_date'].to_datetime,
          graded_at:              restaurant_data['grade_date'],
          score:                  restaurant_data['score'],
          violation_description:  restaurant_data['violation_description'],
          violation_code:         restaurant_data['violation_code'],
          grade:                  restaurant_data['grade']
        )
      end
    end

    puts "Completed page #{dataset.page}"
    dataset.page += 1
  rescue Exception => exception
    puts exception
    puts "Failed at page #{dataset.page}"
    not_broken = false
  end
end
