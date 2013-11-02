class Contact
	include Mongoid::Document
	field :cell_1, :type => String
	field :cell_2, :type => String
	field :cell_3, :type => String
	embedded_in :target, :inverse_of => :contact
end