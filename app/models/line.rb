class Line
	include Mongoid::Document
	embedded_in :shape, :inverse_of => :line
	# field :start_lat, :type => Float
	# field :start_lng, :type => Float
	# field :end_lat, :type => Float
	# field :end_lng, :type => Float
	field :start, :type => Array
	field :finish, :type => Array

	validate :check_points

	def check_points
		[:start, :finish].each do |x|
			errors.add(x, "Must have both longitude and latitude") unless self.send(x).length == 2
		end
		[:start, :finish].each do |x|
			self.send(x).each do |y|
				unless y.class == Float
					errors.add(x, "Each element must be a Float")
					break
				end
			end
		end
	end





	def intersect(other_line)

	end

	def magnitude
		Math.sqrt((start_lng - end_lng)**2 + (start_lat - end_lat)**2)
	end

	def include_point(other_lat, other_lng)

	end

	def start_lng
		self.start[0]
	end

	def start_lat
		self.start[1]
	end
	
	def end_lng
		self.finish[0]
	end
	
	def end_lat
		self.finish[1]
	end

	# def start
	# 	return [start_lat, start_lng]
	# end

	# def start=(arry=[nil,nil])
	# 	self.start_lat = arry[0] if arry[0]
	# 	self.start_lng = arry[1] if arry[1]
	# 	self.save
	# end

	# def finish
	# 	return [end_lat, end_lng]
	# end

	# def finish=(arry=[nil,nil])
	# 	self.end_lat = arry[0] if arry[0]
	# 	self.end_lng = arry[1] if arry[1]
	# 	self.save
	# end

	def vector
		return [(end_lat - start_lat), (end_lng - start_lng)]
	end

	def dot_product(other_vector)
		return ((self.vector[0]*other_vector[0]) + (self.vector[1]*other_vector[1]))
	end

	def inverse_vector
		return [(start_lat - end_lat), (start_lng - end_lng)]
	end

	def -(other)
		[(self.start[0] - other.finish[0]), (self.start[1] - other.finish[1])]
	end
end