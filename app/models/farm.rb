require 'rubygems'
require 'twilio-ruby'

class Farm
  include Mongoid::Document
  include Mongoid::Timestamps
  belongs_to :farmer
  belongs_to :zone
  embeds_one :polygon
  field :name, :type => String
  field :postal_code, :type => String
  field :send_ready, :type => Boolean

  scope :send_ready, where(:send_ready => true)

  def self.send_texts(message_text, opts={})
  	config = YAML.load_file("#{Rails.root}/config/twilio.yml")
  	client = Twilio::REST::Client.new(config['account_sid'], config['auth_token'])
  	Farm.send_ready.each do |f|
  		message = client.account.sms.messages.create(:body => message_text,
  			:to => f.farmer.formatted_cell,
  			:from => (opts[:from] || config['source_phone']))
  		puts message.sid
  	end
  end
end