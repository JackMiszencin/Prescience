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
			puts "NEW LINE"
			puts points[idx-1].to_s
			puts p.to_s
			l.finish = p
		end
		self.save
	end

	def cumulative_cross_product
		total_product = 0.0
		self.lines.each_with_index do |l, idx|
			frontier = ((idx == line_count - 1) ? 0 : idx + 1)
			total_product += cross_product(l.vector, self.lines[frontier].vector)
		end
		return total_product
	end

	def same_direction(vector_1, vector_2)
		direction = self.cumulative_cross_product
		return (cross_product(vector_1, vector_2) * direction) >= 0
	end

	def triangulate
		idx = 0
		genesis = self.lines[0]
		c = self.convexes.build
		c.lines << genesis
		while idx <= line_count - 2
			idx2 = idx + 1
			current = lines[idx]
			frontier = lines[idx2]
			# Translation of below line: If this and next line are not in same direction as polygon spin
			if same_direction(current.vector, (frontier || genesis).vector ) && no_intersection(idx2, nil) # Not really sure what this line was for: < && self.same_direction(self.lines[idx + 1].vector, self.lines.first.vector) >
				c.lines << frontier
				idx += 1
				next 
			else # Go into build_convex, which will give you an index value back to feed idx as the next line to process
				idx3 = build_convex(idx2)
				new_line = Line.new(:start => current.finish, :finish => (self.lines[idx3] || genesis).start)
				reset_lines(idx2, idx3, new_line)
				puts "IDX: #{idx.to_s}"
				puts self.lines.count
				# c.lines << new_line
				# idx = idx2
				next
			end
		end
		self.save
	end

	def no_intersection(idx, to_line)
		genesis = (to_line || self.lines.first)
		l1 = self.lines[idx]
		puts "L1: "
		puts l1.start.to_s
		puts l1.finish.to_s
		l2 = Line.new(:start => l1.finish, :finish => genesis.start)
		puts "L2: "
		puts l2.start.to_s
		puts l2.finish.to_s
		for i in ((idx+1)..(line_count-1))
			l3 = self.lines[i]
			puts "Intersection check on #{i}: " + l2.intersection(l3).to_s
			if i == idx+1
				if l2.intersection(l3) == l3.start
					next
				else # There should probably be some elsifs in here for other conditions. I think for right now, we just need to assume that validations will prevent these possibilities.
					puts "TRIGGERS FIRST FALSE ON #{i}"
					return false
				end
			elsif i == line_count - 1 && to_line == nil
				if l2.intersection(l3) == l3.finish
					next
				else
					puts "TRIGGERS SECOND FALSE ON #{i}"
					return false
				end
			else
				if l2.intersection(l3) == false
					next
				else
					puts "TRIGGERS THIRD FALSE ON #{i}"
					return false
				end
			end
		end
		return true
	end


	# NEED TO REWRITE THIS
	def no_insert_intersection(idx, line) # Checks for intersections between line and every line at idx through the end. Might want to also check the others. I don't really see the fucking point.
		# Line at idx will be that whose start gives "line" its finish.
		for i in (idx..(line_count-1))
			line2 = self.lines[i]
			if i == idx
				if line.intersection(line2) == line.finish
					next
				else
					return false
				end
			else
				if line.intersection(line2) != false
					return false
				else
					next
				end
			end
		end
		return true
	end

	def reset_lines(sub_idx,con_idx,new_line) # index of the line to be substituted, index of the next valid line, new line to replace substituted line
		puts "calling reset_lines, sub_idx: #{sub_idx.to_s}, con_idx: #{con_idx.to_s}"
		remnants = []
		items = self.lines.map{|x| x }
		idx = 0
		while idx < self.lines.count
			if idx < sub_idx
				remnants << items[idx]
			elsif idx == sub_idx
				remnants << new_line
			elsif idx >= con_idx
				remnants << items[idx]
			else
				remnants = remnants
			end
			idx += 1
		end
		self.lines = remnants
		self.save
	end


	def line_count
		self.lines.count
	end

	def last_line(idx)
		idx >= (self.lines.count - 1)
	end

	# Make this a recursive funciton that calls itself every time there's a new line encountered which presents an alternate direction from the turn of the polygon.
	def build_convex(idx) # returns an index
		puts
		puts "BUILD_CONVEX TRIGGERED ON #{idx.to_s}"
		fin = line_count - 1
		genesis = self.lines[idx]
		reference = self.lines[idx-1]
		c = self.convexes.build
		c.lines << genesis
		while idx <= fin
			idx2 = idx + 1
			idx3 = idx + 2
			current = lines[idx]
			frontier = lines[idx2]
			# Translation of below line: If this and next line are not in same direction as polygon spin
			puts "Checking no intersection on #{idx2.to_s}: " + no_intersection(idx2, genesis).to_s
			puts "Checking same_direction on #{idx2.to_s}: " + same_direction(current.vector, (frontier || genesis).vector ).to_s
			if same_direction(current.vector, (frontier || genesis).vector ) && no_intersection(idx2, genesis) # Not really sure what this line was for: < && self.same_direction(self.lines[idx + 1].vector, self.lines.first.vector) >
				c.lines << frontier
				test_line = Line.new(:start => genesis.start, :finish => frontier.finish)
				puts "SAME DIRECTION TEST: " + same_direction(reference.vector, test_line.vector).to_s
				puts "NO INSERT TEST: " + no_intersection(idx2, genesis).to_s
				if same_direction(reference.vector, test_line.vector ) && no_intersection(idx2, genesis ) # Can probably get rid of this last part of the conditional
					c.lines.build(:start => frontier.finish, :finish => genesis.start)
					puts "BUILD_CONVEX RETURNING #{idx3.to_s}"
					return idx3
				else # If it works for this convex, but doesn't complete previous convex
					idx += 1
					next
				end 
			else # Go into build_convex, which will give you an index value back to feed idx as the next line to process
				idx3 = build_convex(idx2)
				new_line = Line.new(:start => current.finish, :finish => (self.lines[idx3] || self.lines.first).start)
				reset_lines(idx2, idx3, new_line)
				puts self.lines.count.to_s
				# c.lines << new_line
				# idx = idx2
				next
			end
		end

		# ////////////////       OLD CODE! DON'T WANT TO THROW OUT YET, THOUGH.      ///////////////////////

		# # WE TAKE THE LINE THAT WAS GIVEN TO US, AND WE MAKE IT THE FIRST OF THE CONVEX

		# c.lines.build(:start => initial.start, :finish => initial.finish)
		# continue = true
		# skipped_cursor = nil
		# while idx < line_count # WE'RE GOING TO KEEP ON GOING I SUPPOSE UNTIL WE REACH A POINT THAT GETS THE POLYGON AND THE REFERENCE LINE GOING IN THE
		# 	# SAME DIRECTION

		# 	# TO BE CLEAR, THE LINE AT [CURSOR] IS THE ONE THAT IS BEING CHECKED, NOT THE ONE THAT HAS ALREADY BEEN ADDED.

		# 	# WE CHECK TO SEE IF THE NEXT LINE IS IN THE RIGHT DIRECTION. IF NOT, WE CREATE A NEW CONVEX, FEEDING CURSOR + 1 IN AS THE NEW INDEX
		# 	# WHEN THE RECURSION HAS DONE ITS WORK, WE ARE GIVEN BACK THE INDEX OF THE NEXT LINE TO ADD IN, AKA, THE INDEX OF THE LINE THAT THE FUNCTION
		# 	# DETERMINED WOULD FIT THE REFERENCE LINE

		# 	prev = self.lines[cursor - 1]
		# 	prev = skipped_cursor if skipped_cursor
		# 	skipped_cursor = nil
		# 	l = self.lines[cursor]
		# 	if same_direction(reference.vector, [ (l.start_lng - reference.end_lng), (l.start_lat - reference.end_lat) ]) # SAYS THAT THE REFERENCE AND THE CURRENT LINE FIT
		# 		c.lines.build(:start => prev.finish, :finish => initial.start)
		# 		return cursor
		# 	else
		# 		if same_direction(l.vector, prev.vector) && self.same_direction([ (l.end_lat - initial.start_lat), (l.end_lng - initial.start_lng) ], initial.vector)
		# 			c.lines.build(:start => l.start, :finish => l.finish)
		# 		else
		# 			skipped_cursor = cursor
		# 			cursor = create_convex(cursor)
		# 			x = self.lines[cursor]
		# 			c.lines.build(:start => prev.finish, :finish => x.start)

		# 			# MAKE SURE THAT A LINE BETWEEN THE END OF X AND THE START OF INITIAL IS IN THE SAME DIRECTION
		# 			c.lines.build(:start => x.start, :finish => x.finish)
		# 		end
		# 		cursor += 1
		# 	end
		# end # END WHILE LOOP

		# return nil



	end

end