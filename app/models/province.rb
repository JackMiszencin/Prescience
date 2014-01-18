class Province
  include Mongoid::Document
  include Mongoid::Timestamps
  has_many :regions
  has_many :zones
  field :name
end