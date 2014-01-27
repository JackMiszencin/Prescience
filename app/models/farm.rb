# require 'rubygems'
# require 'twilio-ruby'
# require 'open-uri'
# require 'json'

class Farm
  include Mongoid::Document
  include Mongoid::Timestamps
  has_many :farm_workers
  belongs_to :zone
  embeds_one :polygon
  field :state, :type => String
  @@states = ['active', 'inactive', 'weather_only']
  validates :state, :inclusion => {:in => @@states, :message => "%{value} is not a valid state value." }



  field :name, :type => String
  field :postal_code, :type => String
  field :send_ready, :type => Boolean
  scope :send_ready, where(:send_ready => true)

  # def self.send_texts(message_text, opts={})
  # 	config = YAML.load_file("#{Rails.root}/config/twilio.yml")
  # 	begin
	 #  	client = Twilio::REST::Client.new(config['account_sid'], config['auth_token'])
  # 	rescue Twilio::REST::RequestError => e
  # 		puts e.to_s
  # 	end
  # 	Farm.send_ready.each do |f|
  # 		begin
	 #  		message = client.account.sms.messages.create(:body => message_text,
	 #  			:to => f.farmer.formatted_cell,
	 #  			:from => (opts[:from] || config['source_phone']))
	 #  		puts message.sid
  # 		rescue Twilio::REST::RequestError => e
  # 			puts e.to_s
  # 		end
  # 	end
  # end

  def lat_lng
    return self.polygon.first_point if self.polygon && self.polygon.first_point
    return self.zone.lat_lng
  end

  def get_forecast
    return false unless self.polygon.first_point
  end

end