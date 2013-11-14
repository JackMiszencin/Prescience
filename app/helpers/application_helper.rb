module ApplicationHelper
	module MathHelper
		def dot_product(vector_1, vector_2)
			return (vector_1[0]*vector_2[0] + vector_1[1]*vector_2[1])
		end
		def cross_product(vector_!, vector_2)
			return (vector_1[0]*vector_2[1] - vector_2[0]*vector_1[1])
		end
		def cross_product_direction(vector_1, vector_2)
			right_hand = [(-1.0 * vector_1[1]), vector_1[0]]
			left_hand = [vector_1[1], (-1.0 * vector_1[0])]
			if (distance(vector_2, right_hand) < distance(vector_2, left_hand))
				return 1.0
			elsif (distance(vector_2, right_hand) > distance(vector_2, left_hand))
				return -1.0
			else
				return 0.0
			end
		end

		def distance(point_1, point_2)
			return Math.sqrt((point_2[0] - point_1[0])**2 + (point_2[1] - point_1[1])**2)
		end
	end
end
