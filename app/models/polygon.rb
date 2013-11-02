class Polygon
	include Mongoid::Document
	belongs_to :land, :inverse_of => :polygon
	field :area, :type => Float
	embeds_many :lines
	embeds_many :triangles
end