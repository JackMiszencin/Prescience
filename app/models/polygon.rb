class Polygon
	include ApplicationHelper::MathHelper
	include Mongoid::Document
	embedded_in :land, :inverse_of => :polygon
	field :area, :type => Float
	embeds_many :segments, :class_name => "Line"
	embeds_many :triangles
	embeds_many :convexes

	# The test line I've been running for the following function is below:
	# p.make_lines([[10.0,0.0],[0.0,0.0],[0.0,8.0],[9.0,10.0],[7.0,2.0],[3.0,5.0],[4.5,6.0],[6.0,4.0],[7.0,8.0],[1.0,7.0],[1.0,1.0],[9.0,1.0],[9.0,3.0],[10.0,3.0],[10.0,0.0]])
	def make_lines(points)
		points.each_with_index do |p, idx|
			next if idx == 0
			l = self.segments.build
			l.start = points[idx-1]
			puts "NEW LINE"
			puts points[idx-1].to_s
			puts p.to_s
			l.finish = p
		end
		self.save
	end

	def first_point
		return false unless self.triangles.first
		self.triangles.first.first_point
	end

	def cumulative_cross_product
		total_product = 0.0
		(@lines || self.segments).each_with_index do |l, idx|
			frontier = ((idx == line_count - 1) ? 0 : idx + 1)
			total_product += cross_product(l.vector, (@lines || self.segments)[frontier].vector)
		end
		return total_product
	end

	def same_direction(vector_1, vector_2)
		direction = self.cumulative_cross_product
		return (cross_product(vector_1, vector_2) * direction) >= 0
	end

	def triangulate
		idx = 0
		@lines = self.segments
		genesis = @lines[0]
		c = self.convexes.build
		c.lines << genesis.clone
		while idx <= line_count - 2
			idx2 = idx + 1
			current = @lines[idx]
			frontier = @lines[idx2]
			# Translation of below line: If this and next line are not in same direction as polygon spin
			if same_direction(current.vector, (frontier || genesis).vector ) && no_intersection(idx2, nil) # Not really sure what this line was for: < && self.same_direction(@lines[idx + 1].vector, @lines.first.vector) >
				c.lines << frontier.clone
				idx += 1
				next 
			else # Go into build_convex, which will give you an index value back to feed idx as the next line to process
				idx3 = build_convex(idx2)
				new_line = Line.new(:start => current.finish, :finish => (@lines[idx3] || genesis).start)
				reset_lines(idx2, idx3, new_line)
				puts "IDX: #{idx.to_s}"
				puts @lines.count
				# c.lines << new_line
				# idx = idx2
				next
			end
		end
		self.save
		self.triangles = []
		self.convexes.each do |x|
			x.triangulate.each do |y|
				self.triangles << y.clone
			end
		end
		self.save
		self.segments.each do |x|
			x.destroy
		end
		self.save
	end

	def includes_point(arry)
		self.triangles.collect{|x| x.includes_point(arry)}.include? true
	end

	def no_intersection(idx, to_line)
		genesis = (to_line || @lines.first)
		l1 = @lines[idx]
		puts "L1: "
		puts l1.start.to_s
		puts l1.finish.to_s
		l2 = Line.new(:start => l1.finish, :finish => genesis.start)
		puts "L2: "
		puts l2.start.to_s
		puts l2.finish.to_s
		for i in ((idx+1)..(line_count-1))
			l3 = @lines[i]
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


	def no_insert_intersection(idx, line) # Checks for intersections between line and every line at idx through the end. Might want to also check the others. I don't really see the fucking point.
		# Line at idx will be that whose start gives "line" its finish.
		for i in (idx..(line_count-1))
			line2 = @lines[i]
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
		idx = 0
		while idx < @lines.count
			if idx < sub_idx
				remnants << @lines[idx]
			elsif idx == sub_idx
				remnants << new_line
			elsif idx >= con_idx
				remnants << @lines[idx]
			else
				remnants = remnants
			end
			idx += 1
		end
		@lines = remnants
	end


	def line_count
		(@lines || self.segments).count
	end

	def last_line(idx)
		idx >= ((@lines || self.segments).count - 1)
	end

	# Make this a recursive funciton that calls itself every time there's a new line encountered which presents an alternate direction from the turn of the polygon.
	def build_convex(idx) # returns an index
		puts
		puts "BUILD_CONVEX TRIGGERED ON #{idx.to_s}"
		fin = line_count - 1
		genesis = @lines[idx]
		reference = @lines[idx-1]
		c = self.convexes.build
		c.lines << genesis.clone
		while idx <= fin
			idx2 = idx + 1
			idx3 = idx + 2
			current = @lines[idx]
			frontier = @lines[idx2]
			# Translation of below line: If this and next line are not in same direction as polygon spin
			puts "Checking no intersection on #{idx2.to_s}: " + no_intersection(idx2, genesis).to_s
			puts "Checking same_direction on #{idx2.to_s}: " + same_direction(current.vector, (frontier || genesis).vector ).to_s
			if same_direction(current.vector, (frontier || genesis).vector ) && no_intersection(idx2, genesis) # Not really sure what this line was for: < && self.same_direction(@lines[idx + 1].vector, @lines.first.vector) >
				c.lines << frontier.clone
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
				new_line = Line.new(:start => current.finish, :finish => (@lines[idx3] || @lines.first).start)
				reset_lines(idx2, idx3, new_line)
				puts @lines.count.to_s
				# c.lines << new_line
				# idx = idx2
				next
			end
		end
	end

end