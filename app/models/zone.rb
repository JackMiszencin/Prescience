class Zone
  include Mongoid::Document
  include Mongoid::Timestamps
  belongs_to :province
  belongs_to :region
  field :postal_code, :type => String
  field :name, :type => String

end