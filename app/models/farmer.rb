class Farmer
  include Mongoid::Document
  include Mongoid::Timestamps
  has_many :farms
  field :cell, :type => String
  embeds_one :contact
end