class Line
	include Mongoid::Document
	embedded_in :shape, :inverse_of => :line
	field :start_lat, :type => Float
	field :start_lng, :type => Float
	field :end_lat, :type => Float
	field :end_lng, :type => Float
	def intersect(other_line)

	end
	def include_point(other_lat, other_lng)
		
	end
end