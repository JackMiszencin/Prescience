class Triangle
	include Mongoid::Document
	include Mongoid::Timestamps
	embedded_in :polygon
	embeds_many :lines
end