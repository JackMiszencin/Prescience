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

  def lat_lng
    return self.polygon.first_point if self.polygon && self.polygon.first_point
    return self.zone.lat_lng
  end

  def latitude
    return self.polygon.first_point[1] if self.polygon.first_point
    return nil
  end

  def longitude
    return self.polygon.first_point[0] if self.polygon.first_point
    return nil
  end

  def get_forecast
    return false unless self.polygon.first_point
  end

end