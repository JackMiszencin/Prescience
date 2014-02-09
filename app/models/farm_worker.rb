class FarmWorker # A join model for connecting the Farm, Farmer, and Zone classes for optimal queries.
  include Mongoid::Document
  include Mongoid::Timestamps
  belongs_to :farmer
  belongs_to :farm
  belongs_to :zone
  validates :farmer, :presence => true
  validates :farm, :presence => true
  validates :zone, :presence => true
  validates :cell, :presence => true, :uniqueness => true
  validates :postal_code, :presence => true

  field :cell, :index => true
  field :postal_code, :index => true
  field :weather, :type => Boolean, :index => true
  field :weather_type, :type => String, :index => true
  field :has_location, :type => Boolean, :default => false # We activate this if the farmer has specified a specific set of lng/lat coordinates for their farm.

  def latitude
    self.farm.latitude
  end

  def longitude
    self.farm.longitude
  end

  def formatted_cell # No need to format just yet, but eventually, we'll need to.
  	self.cell.to_s
  end

  def self.create_weather_farmer(cell, postal_code, opts={})
  	fw = FarmWorker.new(:cell => cell, :postal_code => postal_code, :weather => true)
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
    config = FarmWorker.get_config
    client = FarmWorker.get_client(config)
    return false unless config && client
		begin
  		message = client.account.sms.messages.create(:body => message_text,
  			:to => self.formatted_cell,
  			:from => (opts[:from] || config['source_phone']))
  		puts message.sid
		rescue Twilio::REST::RequestError => e
      message = "EXCEPTION: #{e.class.name}: #{e.message}"
      ErrorMailer.send_error(message)
		end
  end

  def self.get_config
    YAML.load_file("#{Rails.root}/config/twilio.yml")
  end

  def self.get_client(config=nil)
    config ||= self.get_config
    begin
      client = Twilio::REST::Client.new(config['account_sid'], config['auth_token'])
    rescue Twilio::REST::RequestError => e
      message = "EXCEPTION: #{e.class.name}: #{e.message}"
      ErrorMailer.send_error(message)
      return nil
    end
    return client
  end

  def self.send_error(cell, message=nil)
  	config = FarmWorker.get_config
    client = FarmWorker.get_client(config)
    return false unless config && client
  	message ||= "We're sorry, but something went wrong. Please try again."
		begin
  		message = client.account.sms.messages.create(:body => message,
  			:to => cell,
  			:from => (config['source_phone']))
  		puts message.sid
		rescue Twilio::REST::RequestError => e
			puts e.to_s
		end
  end

  def send_message(message_text, opts={})
    config = opts[:config]
    config ||= FarmWorker.get_config
    client = opts[:client]
    client ||= FarmWorker.get_client(config)
    return false unless config && client
    begin
      message = client.account.sms.messages.create(:body => message_text,
        :to => self.formatted_cell,
        :from => (config['source_phone']))
      puts message.sid
    rescue Twilio::REST::RequestError => e
      puts e.to_s
    end
  end

  def self.send_all(opts={})
    config = FarmWorker.get_config
    client = FarmWorker.get_client(client)
    Zone.all.each do |z|
      begin
        puts "Hit zone ##{z.id.to_s}"
        next unless z.weather_farm_workers.count > 0
        report = WeatherReport.get_report(z.latitude, z.longitude)
        z.weather_farm_workers.each do |fw|
          begin
            if fw.has_location && fw.latitude && fw.longitude
              begin
                new_report = WeatherReport.get_report(fw.latitude, fw.longitude)
                fw.send_message(new_report.get_sms(:type => fw.weather_type), :config => config, :client => client)
              rescue Exception => e
                message = "EXCEPTION: #{e.class.name}: #{e.message}"
                ErrorMailer.send_error(message)
                fw.send_message(report.get_sms(:type => fw.weather_type), :config => config, :client => client)
              end
            else
              fw.send_message(report.get_sms(:type => fw.weather_type), :config => config, :client => client)
            end
          rescue Exception => e
            message = "Error on FarmWorker ##{fw.id.to_s} // EXCEPTION: #{e.class.name}: #{e.message}"
            ErrorMailer.send_error(message)
          end
        end
      rescue Exception => e
        message = "Error on zone ##{z.id.to_s} // EXCEPTION: #{e.class.name}: #{e.message}"
        ErrorMailer.send_error(message)
      end
    end
  end

end