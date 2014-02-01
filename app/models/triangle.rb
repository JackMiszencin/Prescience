class Triangle
	include Mongoid::Document
	include Mongoid::Timestamps
	include ApplicationHelper::MathHelper
	embedded_in :polygon
	embeds_many :sides, :class_name => "Line"

	field :first_point, :type => Array
	field :second_point, :type => Array
	field :third_point, :type => Array

	# validates :first_point, :presence => true, :length => {:is => 2}
	# validates :second_point, :presence => true, :length => {:is => 2}
	# validates :second_point, :presence => true, :length => {:is => 2}
	validate :check_points
	after_update :make_lines

	def check_points
		[:first_point, :second_point, :third_point].each do |x|
			errors.add(x, "Must have both longitude and latitude") unless self.send(x).length == 2
		end
		[:first_point, :second_point, :third_point].each do |x|
			self.send(x).each do |y|
				unless y.class == Float
					errors.add(x, "Each element must be a Float")
					break
				end
			end
		end
	end

	# after_create :make_lines

	def make_lines
		self.sides = []
		l1 = Line.new(:start => self.first_point, :finish => self.second_point)
		l2 = Line.new(:start => self.second_point, :finish => self.third_point)
		l3 = Line.new(:start => self.third_point, :finish => self.first_point)
		self.sides << l1
		self.sides << l2
		self.sides << l3
	end

	# def new_line(point)

	# 	case self.sides.count
	# 	when 0

	# 	when 1
	# 		l = self.sides.build
	# 		l.start = self.sides.first.finish
	# 		l.save
	# 	when 2
	# 		l = self.sides.build
	# 		l.start = self.sides.last.finish
	# 		l.end = self.sides.first.start
	# 		l.save
	# 	when 3
	# 		return false
	# 	else
	# 	end
	# end


	def other_vector(arry)
		return [(arry[0] - first_point[0]), (arry[1] - first_point[1])]
	end
	def includes_point(point)
		v0 = other_vector(point)
		v1 = self.sides.first.vector
		v2 = self.sides.last.inverse_vector
		denominator = ( (dot_product(v1,v2) * dot_product(v2,v1) ) - ( dot_product(v1,v1) * dot_product(v2,v2) )   )
		a = ((dot_product(v2,v1) * dot_product(v0,v2)) - (dot_product(v2,v2) * dot_product(v0,v1))) / denominator
		b = ((dot_product(v0,v1) * dot_product(v1,v2)) - (dot_product(v0,v2) * dot_product(v1,v1))) / denominator

		puts a
		puts b

		return (a + b <= 1.0) && (a >= 0.0) && (b >= 0.0)

	end
end