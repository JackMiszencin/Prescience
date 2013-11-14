class Convex
	include Mongoid::Document
	embeds_many :lines
	embeds_many :triangles
	def triangulate
		primary = self.lines.first.start
		self.lines.each_with_index do |l, idx|
			next if idx == 1 || idx == (self.lines.count - 1)
			t = self.triangles.build(:first_point => primary, :second_point => l.start, :third_point => l.finish)
		end
		self.save
		return self.triangles
	end
end