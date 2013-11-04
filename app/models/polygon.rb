class Polygon
	include Mongoid::Document
	embedded_in :land, :inverse_of => :polygon
	field :area, :type => Float
	embeds_many :lines
	embeds_many :triangles
end