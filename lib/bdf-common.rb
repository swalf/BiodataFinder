module BDFCommon
	
	$Version = "0.2.1.pre"
	$conf_file = ENV['HOME'] + "/.biodatafinder/bdf.conf"
	
	
	def load_setup
		unless File.exist? $conf_file
			Dir.mkdir (File.dirname $conf_file) 
			File.open($conf_file, "w") do |f|
				f.puts(
					"# bdf-cli config file:",
					"# sintax KEY:=\"VALUE\"",
					"def_index:=\"idx\"",
					"indexes:=\"idx\"",
					"host:=\"http://localhost:9220\""
				)
			end
		end
		File.open($conf_file,"r") do |file|
			file.each do |line|
				next if line[0] == '#'
				key, value = line.split(/:="/)
				value = (value.chomp).chomp "\""
				case key
				when "def_index"
					@def_index = value.downcase
				when "indexes"
					@indexes = value.split(',')
				when "host"
					@host = value
				else 
					raise "Config file entain wrong fields!"
				end
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
		File.open($conf_file,"w") do |file|
			file.puts( 
				"# bdf-cli config file:",
				"# sintax 'key':'value'",
				"def_index:=\"#{@def_index}\"",
				"indexes:=\"#{@indexes.join(',')}\"",
				"host:=\"#{@host}\""
			)		
		end
	rescue RuntimeError => e
		$stderr.puts "ERROR: " + e.message      
	end
	
end