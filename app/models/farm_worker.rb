class FarmWorker # A join model for connecting the Farm, Farmer, and Zone classes for optimal queries.
  include Mongoid::Document
  include Mongoid::Timestamps
  belongs_to :farmer
  belongs_to :farm
  belongs_to :zone
  validates :farmer, :presence => true
  validates :farm, :presence => true
  validates :zone, :presence => true
  validates :cell, :presence => true, :uniqeness => true
  validates :postal_code, :presence => true

  field :cell, :index => true
  field :postal_code, :index => true

  def formatted_cell # No need to format just yet, but eventually, we'll need to.
  	self.cell.to_s
  end

  def self.create_weather_farmer(cell, postal_code)
  	fw = FarmWorker.new(:cell => cell, :postal_code => postal_code)
  	z = Zone.by_postal_code(postal_code)
  	unless z
  		fw.errors.add(:postal_code, "Sorry, this is not a valid postal code")
  		return "Sorry, this is not a valid postal code"
  	end
  	fw.zone_id = z.id.to_s
  	farm = Farm.new(:state => "weather_only", :zone_id => z.id.to_s)
  	farmer = Farmer.new(:cell => cell)
  	ok = farm.save && farmer.save
  	if ok
  		fw.farm_id = farm.id.to_s
  		fw.farmer_id = farmer.id.to_s
  		return fw if fw.save
  		return false
  	else
  		return false
  	end
  end

  def send_confirmation(opts={})
  	message_text = "Thank you for signing up! You'll now receive a weather forecast every day at 5pm."
  	config = YAML.load_file("#{Rails.root}/config/twilio.yml")
  	begin
	  	client = Twilio::REST::Client.new(config['account_sid'], config['auth_token'])
  	rescue Twilio::REST::RequestError => e
  		puts e.to_s
  	end
		begin
  		message = client.account.sms.messages.create(:body => message_text,
  			:to => self.formatted_cell,
  			:from => (opts[:from] || config['source_phone']))
  		puts message.sid
		rescue Twilio::REST::RequestError => e
			puts e.to_s
		end
  end

  def self.send_error(cell, message=nil)
  	config = YAML.load_file("#{Rails.root}/config/twilio.yml")
  	message ||= "We're sorry, but something went wrong. Please try again."
  	begin
	  	client = Twilio::REST::Client.new(config['account_sid'], config['auth_token'])
  	rescue Twilio::REST::RequestError => e
  		puts e.to_s
  	end
		begin
  		message = client.account.sms.messages.create(:body => message,
  			:to => cell,
  			:from => (config['source_phone']))
  		puts message.sid
		rescue Twilio::REST::RequestError => e
			puts e.to_s
		end

  end

end