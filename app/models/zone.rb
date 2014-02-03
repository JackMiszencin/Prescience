require 'open-uri'
require 'json'
class Zone
  include Mongoid::Document
  include Mongoid::Timestamps
  belongs_to :province
  belongs_to :region
  has_many :farm_worker
  field :postal_code, :type => String, :index => true
  field :name, :type => String
  field :latitude, :type => Float
  field :longitude, :type => Float
  field :has_google_result, :type => Boolean
  field :lng_lat_source, :type => String
  field :problem, :type => Boolean

  validates :postal_code, :presence => true, :uniqueness => true
  validates :name, :presence => true

  # METHODS FOR GATHERING GEOCOORDINATE DATA

  def formatted_address(opts={})
	    return (self.name.downcase + "+" + self.region.name.downcase + "+pakistan").gsub(" ", "+") if opts[:region]
	    return (self.region.name.downcase + "+pakistan").gsub(" ", "+") if opts[:region_only]
	    return (self.region.name.downcase.gsub("gpo", "").gsub("hpo", "").gsub("G.P.O.", "").gsub("H.P.O.","").strip + "+" + self.province.name + "+pakistan").gsub(" ", "+") if opts[:region_no_gpo]
	    return (self.region.name.downcase.gsub("gpo", "").gsub("hpo", "").strip + "+pakistan").gsub(" ", "+") if opts[:region_only_no_gpo]
	    return (self.name.downcase.gsub("gpo", "").gsub("hpo", "").strip + "+" + self.province.name + "+pakistan").gsub(" ", "+") if opts[:no_gpo]
	    return (self.name.downcase + "+" + self.province.name.downcase + "+pakistan").gsub(" ", "+") if opts[:with_province]  	
	    return (self.name.downcase + "+pakistan").gsub(" ", "+")
  end

  def get_lat_lng(opts={})
  	begin
	    hash = JSON.parse(open("http://maps.googleapis.com/maps/api/geocode/json?address=#{self.formatted_address(opts)}&sensor=true").read)
	    if hash["results"].present?
		    results = hash["results"]
		    town = nil
		    results.each do |x|
		    	town = x if (x["types"].to_a.include?("locality") || x["types"].to_a.include?("neighborhood"))
		    end
		    if town
		    	self.problem = false
		    	result = town
		    else
		    	self.problem = true
		    	return false
		    end
		    latlng = result["geometry"]["location"]
		    self.latlng = latlng.to_s
		    self.latitude = latlng["lat"]
		    self.longitude = latlng["lng"]
		    self.lng_lat_source = "region" if opts[:region_only]
		    self.lng_lat_source = "with_province" if opts[:with_province]
		    self.lng_lat_source = "region_no_gpo" if opts[:region_no_gpo]
		    self.lng_lat_source = "region_only_no_gpo" if opts[:region_only_no_gpo]
		    self.lng_lat_source = "no_gpo" if opts[:no_gpo]
		    self.has_google_result = true
			else
				self.has_google_result = false
			end
		rescue
			puts "Error on Zone #{self.id.to_s}"
		end
  end

  def lat_lng
  	[self.latitude, self.longitude]
  end

  def self.by_postal_code(code)
  	Zone.where(:postal_code => code.to_s.strip).first
  end

  # Method below exists solely for manual data-gathering purposes
	def self.process_first_problem
		x = Zone.where(:problem => true).first
    puts
    puts x.id.to_s
    puts x.name
    puts x.region.name
    puts x.province.name
    puts x.name + ", " + x.province.name
    puts x.latitude.to_s + ", " + x.longitude.to_s
    puts "Latitude, Longitude: "
    str = gets.chomp
    arry = str.split(",").map{|x| x.strip.to_f}
   	x.latitude = arry[0]
    x.longitude = arry[1]
    x.problem = false
    puts "Name Change? [y/n]"
    change = gets.chomp
    if change == "y"
    	puts "Name: "
    	x.name = gets.chomp
    end
    puts "Region only no GPO? [y/n]"
    change = gets.chomp
    if change == "y"
    	x.lng_lat_source = "region_only_no_gpo"
    end
    x.save
    puts [x.latitude.to_s, x.longitude.to_s, x.problem.to_s].join(" ")
	end

	# METHODS FOR SENDING SMS

	def send_weather(opts={})

	end

end