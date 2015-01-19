module BDFCommon
	
	$Version = "0.2.4.pre"
	$conf_file = ENV['HOME'] + "/.biodatafinder/bdf.conf"
	
	
	def load_setup
		unless File.exist? $conf_file
			Dir.mkdir (File.dirname $conf_file) unless Dir.exist? (File.dirname $conf_file) 
			@def_index = 'idx'
			@indexes = [@def_index]
			@host = "http://localhost:9200"
			@max_results = 25
			store_setup
		else
			File.open($conf_file,"r") do |file|
				contents = file.inject("") {|text, line| text+=line}
				contents.gsub! "\n", " "
				chash = JSON.parse contents
				@def_index = chash['def_index']
				@indexes = chash['indexes']
				@host = chash['host']
				@max_results = chash['max_result']
				puts chash
			end
		end
	rescue RuntimeError => e
		if e.message == "Config file entain wrong fields!"
			$stderr.puts "Error: #{exc.message}", "Config file will be not loaded."
		else
			$stderr.puts "Error: #{exc.message}"
		end
	end
	
	def store_setup   
		storage = JSON.pretty_generate(
			{
				def_index: @def_index,
				indexes: @indexes,
				host: @host,
				max_results: @max_results
			}
		)
		File.open($conf_file,"w") do |file|
			file.puts storage
		end
	rescue RuntimeError => e
		$stderr.puts "ERROR: " + e.message      
	end
	
end