class Region
  include Mongoid::Document
  include Mongoid::Timestamps
  belongs_to :province
  has_many :zones
  field :name
end