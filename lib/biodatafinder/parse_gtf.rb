def parse_gtf (filepath)
	
	
	File.open(filepath, "r") do |file|
		comments = 0
		lbs = file.pos # Start line byte
		docpool = []
		file.each_with_index do |line,i|
			if line[0] == '#'
				comments += 1
				lbs = file.pos # Refresh data for the new line.
				next
			end
			
			seqname, source, feature, c_start, c_end, score, strand, frame, attributes  = line.split "\t"
			f_ext = File.extname(filepath)
			f_name = File.basename(filepath, f_ext) 
			f_dir = File.dirname(filepath)
			position = {"dir" => f_dir, "name" => f_name, "extension" => f_ext, "line_start_byte" => lbs}
			lbs = file.pos # Refresh data for the new line.
			
			document = {
				"seqname" => seqname,
				"source" => source,
				"feature" => feature,
				"start" => c_start,
				"end" => c_end,
				"score" => score,
				"strand" => strand,
				"frame" => frame,
				"type" => "Gtf",
				"position" => position    
			} 
			document.each_pair { |key, value| key = value.gsub('_','-') } #substitute underscore with hypens to create an only ES string.
			
			docpool << document
			
			if i % poolsize == 0 # When the pool fills the specificated amount, it is loaded and emptied
				load_pool docpool, "gtf"
				docpool = []
			end
			
		end
		(load_pool docpool, "gtf") unless docpool == [] # When file was been enterely processed, docpool have to to be load if it isn't empty.
	end
	
end