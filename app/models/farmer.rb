class Farmer
  include Mongoid::Document
  include Mongoid::Timestamps
  has_many :farm_workers
  field :cell, :type => String
  embeds_one :contact

  validates :cell, :presence => true



  # Weather forecast SMS fields
  field :rain_percent, :type => Boolean, :default => true
  field :forecast_days, :type => Integer, :default => 1
  field :hi_temp, :type => Boolean, :default => true
  field :lo_temp, :type => Boolean, :default => true
  field :rain_details, :type => Boolean, :default => true
  field :sms_hour, :type => Integer, :default => 17

  validates :cell, :presence => true, :uniqueness => true

  def formatted_cell # No need to format just yet, but eventually, we'll need to.
  	self.cell.to_s
  end

  
  
end