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

	def check_points # NEED TO ADD VALIDATION THAT ENSURES LINE HAS LENGTH GREATER THAN ZERO
		puts "Running Validation"
		[:start, :finish].each do |x|
			return errors.add(x, "Must have both longitude and latitude") unless self.send(x).class.to_s == "Array" && self.send(x).length == 2
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

	# METRICS FOR LINE'S EQUATION ARE IN THE FORM OF THE EQUATION { C = AX + BY } WHERE C IS THE METHOD "CONSTANT", A IS "X_COEFFICIENT" AND B IS "Y_COEFFICIENT"

	def slope # SLOPE CAN BE SEEN AS -A/B
		return (vector[1].to_f/vector[0].to_f) unless vector[0].to_f == 0.0
		return nil
	end

	def x_coefficient
		(-1.0 * vector[1].to_f)
	end

	def y_coefficient
		vector[0].to_f
	end

	def constant
		(x_coefficient*start[0] + y_coefficient*start[1])
	end



	def intersection(other) # Returns true for overlap, a point array for an intersection, and false for no intersection
		a1 = x_coefficient
		b1 = y_coefficient
		c1 = constant
		a2 = other.x_coefficient
		b2 = other.y_coefficient
		c2 = other.constant
		if a1 == 0.0 # this line is horizontal
			if b1 == 0.0 # this line is actually just a point, or a vector with zero magnitude
				# return false
				# Comment out below lines and uncomment above line if you want to make endpoints not count as an intersection.
				if start_lng * a2 + start_lat * b2 == c2 && other.in_range(start_lng, start_lat)
					return [start_lng, start_lat]
				else
					return false
				end
			end
			y1 = (c1/b1).round(6)
			if a2 == 0.0 # other line is horizontal
				if b2 == 0.0 # other line is just a point
					if other.start_lat == y1 && in_range(other.start_lng, other.start_lat)
						return [other.start_lng, other.start_lat]
					else
						return false
					end
				else
					y2 = (c2/b2).round(6)
					if y1 == y2 # if the two horizontal lines lie at the same y-coordinate
						if (max_x > other.min_x) && (min_x < other.max_x)
							return true
						elsif max_x == other.min_x
							return [max_x, y1]
						elsif min_x == other.max_x
							return [min_x, y1]
						else
							return false
						end
					else
						return false
					end
				end
			elsif b2 == 0.0 # other line is vertical
				x2 = (c2/a2).round(6)
				if y1 <= other.max_y && y1 >= other.min_y && max_x >= x2 && min_x <= x2
					return [x2, y1]
				else
					return false
				end
			else
				x2 = (c2/a2 - b2*y1).round(6)
				if in_range(x2,y1) && other.in_range(x2,y1)
					return [x2,y1]
				else
					return false
				end
			end
		elsif b1 == 0.0 # this line is vertical
			x1 = (c1/a1).round(6)
			if b2 == 0.0 # other line is vertical
				if a2 == 0.0 # other line is just a point
					if other.start_lng == x1 && in_range(other.start_lng, other.start_lat)
						return [x1, other.start_lat]
					else
						return false
					end
				else
					x2 = (c2/a2).round(6)
					if x2 == x1
						if (max_y > other.min_y) && (min_y < other.max_y)
							return true
						elsif max_y == other.min_y
							return [x1, max_y]
						elsif min_y == other.max_y
							return [x1, min_y]
						else
							return false
						end
					else
						return false
					end
				end
			elsif a2 == 0.0 # other line is horizontal
				y2 = (c2/b2).round(6)
				if in_range(x1,y2) && other.in_range(x1,y2)
					return [x1,y2]
				else
					return false
				end
			else
				y2 = ((c2/b2) - (x1 * a2/b2)).round(6)
				if in_range(x1,y2) && other.in_range(x1,y2)
					return [x1, y2]
				else
					return false
				end
			end
		elsif a2 == 0.0 # other line is horizontal
			if b2 == 0.0 # other line is actually just a point
				if (a1*other.start_lng + b1*other.start_lat).round(8) == c1 && in_range(other.start_lng, other.start_lat)
					return [other.start_lng, other.start_lat]
				else
					return false
				end
			else
				y2 = other.start_lat
				x1 = ((c1 - b1*y2)/a1).round(6)
				if in_range(x1, y2) && other.in_range(x1, y2)
					return [x1, y2]
				else
					return false
				end
			end
		elsif b2 == 0.0 # other line is vertical
			x2 = other.start_lng
			y1 = ((c1 - a1*x2)/b1).round(6)
			if in_range(x2, y1) && other.in_range(x2, y1)
				return [x2, y1]
			else
				return false
			end
		elsif a1/b1 == a2/b2 # two lines have same slope
			if (c1/a1).round(8) == c2/a2.round(8)
				if (max_x > other.min_x) && (min_x < other.max_x) && (max_y > other.min_y) && (min_y < other.max_y)
					return true
				elsif max_x == other.min_x # If at the same slope and y intercept, having equal minimun and maximum x'es will be the same as having the same minimum and maximum y'es
					return [max_x, other.min_y]
				elsif min_x == other.max_x
					return [min_x, other.max_y]
				else
					return false
				end
			else
				return false
			end
		else # Standard line intersection
			puts "getting into the branch we expected"
			x = ((c1/b1 - c2/b2)/(a1/b1 - a2/b2)).round(6)
			puts x.to_s
			y = ((-1.0*a1/b1) * x + (c1/b1)).round(6)
			puts y.to_s
			puts in_range(x,y).to_s
			puts other.in_range(x,y)
			if in_range(x,y) && other.in_range(x,y)
				return [x,y]
			else
				return false
			end
		end			
	end

	def in_range(x,y) # check to see if horizontal or vertical segments whose lines intersect can actually intersect themsleves
		(x >= min_x && x <= max_x && y >= min_y && y <= max_y)
	end

	def max_y
		[start_lat, end_lat].max
	end

	def max_x
		[start_lng, end_lng].max
	end

	def min_y
		[start_lat, end_lat].min
	end

	def min_x
		[start_lng, end_lng].min
	end


	def intersect(other)

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
		return [(end_lng - start_lng), (end_lat - start_lat)]
	end

	def dot_product(other_vector)
		return ((self.vector[0]*other_vector[0]) + (self.vector[1]*other_vector[1]))
	end

	def inverse_vector
		return [(start_lng - end_lng), (start_lat - end_lat)]
	end

	def -(other)
		[(self.start[0] - other.finish[0]), (self.start[1] - other.finish[1])]
	end
end