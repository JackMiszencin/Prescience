class FarmWorkersController < ApplicationController
	def create
		cell = params[:From]
		postal_code = params[:Body].to_s.strip
		fw = FarmWorker.create_weather_farmer(cell, postal_code)
		if fw && fw.class_name == "FarmWorker"
			fw.send_confirmation
		else
			FarmWorker.send_error(cell, fw)
		end
	end
end