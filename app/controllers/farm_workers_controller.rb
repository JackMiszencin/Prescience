class FarmWorkersController < ApplicationController
	def create
		begin
			cell = params[:From]
			postal_code = params[:Body].to_s.strip
			fw = FarmWorker.create_weather_farmer(cell, postal_code)
			if fw && fw.class_name == "FarmWorker"
				fw.send_confirmation
			else
				FarmWorker.send_error(cell, fw)
			end
		rescue Exception => e
			message = "EXCEPTION: #{e.class.name}: #{e.message}"
			ErrorMailer.send_error(message).deliver
		end
	end
end