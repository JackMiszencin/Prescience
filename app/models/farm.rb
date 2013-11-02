class Farm < ActiveRecord::Base
  include Mongoid::Document
  include Mongoid::Timestamps
  belongs_to :farmer
end