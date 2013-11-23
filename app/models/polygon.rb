class Polygon
	include ApplicationHelper::MathHelper
	include Mongoid::Document
	embedded_in :land, :inverse_of => :polygon
	field :area, :type => Float
	embeds_many :lines
	embeds_many :triangles
	embeds_many :convexes

	def make_lines(points)
		points.each_with_index do |p, idx|
			next if idx == 0
			l = self.lines.build
			l.start = points[idx-1]
			l.finish = p
		end
	end

	def cumulative_cross_product
		total_product = 0.0
		self.lines.each_with_index do |l, idx|
			total_product += cross_product(l.vector, self.lines[idx - 1].vector)
		end
		return total_product
	end

	def same_direction(vector_1, vector_2)
		direction = self.cumulative_cross_product
		return (cross_product(vector_1, vector_2) * direction) >= 0
	end

	def triangulate
		self.lines.each_with_index do |l, idx|
			if self.same_direction(l.vector, self.lines[((idx + 1 == self.lines.length) ? -1 : (idx + 1) )]) && self.same_direction(self.lines[idx + 1].vector, self.lines.first.vector)
				# Examine logic of above line for use in create_convex recursion
			else
			end
		end
	end

	def line_count
		self.lines.count
	end

	def last_line(idx)
		idx >= (self.lines.count - 1)
	end

	# Make this a recursive funciton that calls itself every time there's a new line encountered which presents an alternate direction from the turn of the polygon.
	def create_convex(index)
		cursor = index
		c = self.convexes.create
		reference = self.lines[cursor - 1]
		initial = self.lines[cursor]
		cursor += 1
		# WE TAKE THE LINE THAT WAS GIVEN TO US, AND WE MAKE IT THE FIRST OF THE CONVEX

		c.lines.create(:start => initial.start, :finish => initial.finish)
		continue = true
		skipped_cursor = nil
		while cursor < self.lines.count # WE'RE GOING TO KEEP ON GOING I SUPPOSE UNTIL WE REACH A POINT THAT GETS THE POLYGON AND THE REFERENCE LINE GOING IN THE
			# SAME DIRECTION

			# TO BE CLEAR, THE LINE AT [CURSOR] IS THE ONE THAT IS BEING CHECKED, NOT THE ONE THAT HAS ALREADY BEEN ADDED.

			# WE CHECK TO SEE IF THE NEXT LINE IS IN THE RIGHT DIRECTION. IF NOT, WE CREATE A NEW CONVEX, FEEDING CURSOR + 1 IN AS THE NEW INDEX
			# WHEN THE RECURSION HAS DONE ITS WORK, WE ARE GIVEN BACK THE INDEX OF THE NEXT LINE TO ADD IN, AKA, THE INDEX OF THE LINE THAT THE FUNCTION
			# DETERMINED WOULD FIT THE REFERENCE LINE

			prev = self.lines[cursor - 1]
			prev = skipped_cursor if skipped_cursor
			skipped_cursor = nil
			l = self.lines[cursor]
			if self.same_direction(reference.vector, [ (l.start_lat - reference.end_lat), (l.start_lng - reference.end_lng) ]) # SAYS THAT THE REFERENCE AND THE CURRENT LINE FIT
				c.lines.create(:start => prev.finish, :finish => initial.start)
				return cursor
			else
				if self.same_direction(l.vector, prev.vector) && self.same_direction([ (l.end_lat - initial.start_lat), (l.end_lng - initial.start_lng) ], initial.vector)
					c.lines.create(:start => l.start, :finish => l.finish)
				else
					skipped_cursor = cursor
					cursor = self.create_convex(cursor)
					x = self.lines[cursor]
					c.lines.create(:start => prev.finish, :finish => x.start)

					# MAKE SURE THAT A LINE BETWEEN THE END OF X AND THE START OF INITIAL IS IN THE SAME DIRECTION
					c.lines.create(:start => x.start, :finish => x.finish)
				end
				cursor += 1
			end
		end # END WHILE LOOP
		c.lines.create(:start => )
		return nil
	end

end