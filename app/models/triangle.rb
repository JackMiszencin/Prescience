class Triangle
	include Mongoid::Document
	include Mongoid::Timestamps
	embedded_in :polygon
	embeds_many :lines

	def first_point
		return [self.lines.first.start_lat, self.lines.first.end_lat]
	end
	def new_line
		case self.lines.count
		when 0

		when 1
			l = self.lines.build
			l.start = self.lines.first.finish
			l.save
			self.save
		when 2
			l = self.lines.build
			l.start = self.lines.last.finish
			l.end = self.lines.first.start
			l.save
			self.save
		when 3
			return false
		else
		end
	end
	def other_vector(arry)
		return [(arry[0] - first_point[0]), (arry[1] - first_point[1])]
	end
	def includes_point(point)
		v0 = other_vector(point)
		v1 = self.lines.first.vector
		v2 = self.lines.last.inverse_vector
		
	end
end