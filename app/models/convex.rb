class Convex
	include Mongoid::Document
	embeds_many :lines
	embeds_many :triangles
	# add in validation to make sure all cross products are in same direction
	def triangulate
		primary = self.lines.first.start
		self.lines.each_with_index do |l, idx|
			next if idx == 1 || idx == (self.lines.count - 1)
			t = self.triangles.build(:first_point => primary, :second_point => l.start, :third_point => l.finish)
		end
		self.save
		return self.triangles
	end

	def reset_first
		lines.first.destroy
	end

	def reset_last
		lines.last.destroy
	end
end