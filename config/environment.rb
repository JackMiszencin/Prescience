# Load the rails application
require File.expand_path('../application', __FILE__)

ActiveSupport::Inflector.inflections do |inflect|
  inflect.irregular 'convex', 'convexes'
end

# Initialize the rails application
Prescience::Application.initialize!
