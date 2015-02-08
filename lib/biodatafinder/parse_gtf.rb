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
			
			seqname, source, feature, c_start, c_end, score, strand, frame, attr_string  = line.split "\t"
			attrs_array = attr_string.split ";"
			attributes = Hash.new
			attrs_array.each do |attr_pair|
				key, value = attr_pair.split " "
				case key 
				when 'gene_id'
					attributes[:gene_id] = value.tr '"', ''
				when 'gene_underscore_name'
					attributes[:gene_underscore_name] = value.tr '"', ''
				when 'gene_source'
					attributes[:gene_source] = value.tr '"', ''
				when 'gene_biotype'
					attributes[:gene_biotype] = value.tr '"', ''
				when 'transcript_id'
					attributes[:transcript_id] = value.tr '"', ''
				when 'gene_new_name'
					attributes[:gene_new_name] = value.tr '"', ''
				end
			end
			
			unless attributes.length == 0
				f_ext = File.extname(filepath)
				f_name = File.basename(filepath, f_ext) 
				f_dir = File.dirname(filepath)
				position = {"dir" => f_dir, "name" => f_name, "extension" => f_ext, "line_start_byte" => lbs}
				lbs = file.pos # Refresh data for the new line.
				
				document = {
					"attributes" => attributes,				
					# Metadata
					"type" => "Gtf",
					"position" => position
				} 
				
				docpool << document
				
				if i % poolsize == 0 # When the pool fills the specificated amount, it is loaded and emptied
					load_pool docpool, "gtf"
					docpool = []
				end
			end
		
			
			
			
			
		end
		(load_pool docpool, "gtf") unless docpool == [] # When file was been enterely processed, docpool have to to be load if it isn't empty.
	end
	
end