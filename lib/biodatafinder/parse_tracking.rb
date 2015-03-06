def parse_tracking (filepath)
	File.open(filepath, "r") do |file|

		header = file.readline
		# raise "tracking file format error" if header.split != [
		# 	"tracking_id",
		# 	"class_code",
		# 	"nearest_ref_id",
		# 	"gene_id",
		# 	"gene_short_name",
		# 	"tss_id",
		# 	"locus",
		# 	"length",
		# 	"coverage",
		# 	"FPKM",
		# 	"FPKM_conf_lo",
		# 	"FPKM_conf_hi",
		# 	"FPKM_status"
		# ]
		lbs = file.pos # Start line byte
		docpool = []
		file.each_with_index do |line,i|

			ldata = line.chomp.split
			tracking_id = ldata[0]
			nearest_ref_id = ldata[3]
			gene_id = ldata[4]
			gene_short_name = ldata[5]
			sequence, start, stop = ldata[6].tr(":-",' ').split
			f_ext = File.extname(filepath)
			f_name = File.basename(filepath, f_ext)
			f_dir = File.dirname(filepath)
			position = {"dir" => f_dir, "name" => f_name, "extension" => f_ext, "line_start_byte" => lbs}
			lbs = file.pos # Refresh data for the new line.

			document = {
				"tracking_id" => tracking_id,
				"nearest_ref_id" => nearest_ref_id,
				"gene_id" => gene_id,
				"gene_short_name" => gene_short_name,
				"type" => "Tracking",
				"position" => position,
				"sequence" => sequence,
				"start" => start.to_i,
				"stop" => stop.to_i
			}

			#document.each_key { |key| document[key] = document[key].gsub('_','-') if document[key].instance_of? String } #substitute underscore with hypens to create an only ES string.

			docpool << document

			if i % poolsize == 0 # When the pool fills the specificated amount, it is loaded and emptied
				load_pool docpool, "tracking"
				docpool = []
			end

		end
		(load_pool docpool, "tracking") unless docpool == [] # When file was been enterely processed, docpool have to to be load if it isn't empty.
	end
end #parse_tracking

def tabix_tracking?
	true
end #tabix_tracking?

def tabix_tracking(filepath)
	# TO BE IMPLEMENTED
	  # File.open(filepath,'r') do |file|
		# 	File.open(filepath + "tabix_header", 'w') do |w|
		# 		#read first line and keep it aside
		# 		w.write file.readline
		# 	end
		# 	file.each_line
		# end
		# bgzip_file = "#{filepath}.gz"
		# unless File.exists?(bgzip_file)
		# 	`bgzip -c #{filepath} > #{bgzip_file}`
		# end
end #tabix_tracking
