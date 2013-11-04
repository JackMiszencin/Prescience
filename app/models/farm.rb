class Farm
  include Mongoid::Document
  include Mongoid::Timestamps
  belongs_to :farmer
  embeds_one :polygon
  field :name, :type => String
end