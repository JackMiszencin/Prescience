class Convex
	include Mongoid::Document
	embedded_in :polygon, :inverse_of => :convex
	embeds_many :lines
	embeds_many :triangles
	# add in validation to make sure all cross products are in same direction
	def triangulate
		self.triangles = []
		primary = self.lines.first.start
		self.lines.each_with_index do |l, idx|
			next if idx == 0 || idx == (self.lines.count - 1)
			self.triangles << Triangle.new(:first_point => primary, :second_point => l.start, :third_point => l.finish)
		end
		self.triangles.each do |x|
			x.make_lines
		end
		return self.triangles
	end

	def reset_first
		lines.first.destroy
	end

	def reset_last
		lines.last.destroy
	end
end