require 'open-uri'
require 'json'

class WeatherReport
	attr_accessor :weather_hash, :high_rain, :med_range, :low_range

	def self.get_report(lat, lng, opts={})
		report = WeatherReport.new
		config = YAML.load_file("#{Rails.root}/config/forecast_io.yml")
		key = config['api_key']
		base_url = "https://api.forecast.io/forecast/"
		return nil unless key.present? && lat.present? && lng.present?
		begin
			report.weather_hash = JSON.parse(open( base_url + key.to_s +  "/" + lat.to_s + "," + lng.to_s).read)
		rescue Exception => e
			message = "EXCEPTION: #{e.class.name}: #{e.message}"
			ErrorMailer.send_error(message).deliver
			return false
		end
		return false unless report.weather_hash == nil
		return report
	end

	def get_sms(opts={})
		if opts["type"].present?
			return self.send(opts["type"].to_s + "_report")
		else
			return general_report
		end
	end

	def general_report
		return ("Now: " + self.weather_hash["currently"]["summary"].to_s + " Today: " + self.weather_hash["hourly"]["summary"] + " Coming up: " + self.weather_hash["daily"]["summary"])
	end

	def rain_report
	end

	def wind_report
	end


end