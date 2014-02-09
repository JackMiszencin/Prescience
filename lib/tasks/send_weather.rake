task :send_weather => :environment do
	FarmWorker.send_all
end