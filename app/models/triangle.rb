class Triangle
	include Mongoid::Document
	include Mongoid::Timestamps
	include ApplicationHelper::MathHelper
	embedded_in :polygon
	embeds_many :lines

	field :first_point, :type => Array
	field :second_point, :type => Array
	field :third_point, :type => Array

	# validates :first_point, :presence => true, :length => {:is => 2}
	# validates :second_point, :presence => true, :length => {:is => 2}
	# validates :second_point, :presence => true, :length => {:is => 2}
	validate :check_points

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
		self.lines.each do |x|
			x.destroy
		end
		l1 = self.lines.build
		l1.start = self.first_point
		l1.finish = self.second_point
		l2 = self.lines.build
		l2.start = self.second_point
		l2.finish = self.third_point
		l3 = self.lines.build
		l3.start = self.third_point
		l3.finish = self.first_point
		self.save
	end

	# def new_line(point)

	# 	case self.lines.count
	# 	when 0

	# 	when 1
	# 		l = self.lines.build
	# 		l.start = self.lines.first.finish
	# 		l.save
	# 	when 2
	# 		l = self.lines.build
	# 		l.start = self.lines.last.finish
	# 		l.end = self.lines.first.start
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
		v1 = self.lines.first.vector
		v2 = self.lines.last.inverse_vector
		denominator = ( (dot_product(v1,v2) * dot_product(v2,v1) ) - ( dot_product(v1,v1) * dot_product(v2,v2) )   )
		a = ((dot_product(v2,v1) * dot_product(v0,v2)) - (dot_product(v2,v2) * dot_product(v0,v1))) / denominator
		b = ((dot_product(v0,v1) * dot_product(v1,v2)) - (dot_product(v0,v2) * dot_product(v1,v1))) / denominator

		puts a
		puts b

		return (a + b <= 1.0) && (a >= 0.0) && (b >= 0.0)

	end
end