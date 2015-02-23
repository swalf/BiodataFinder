def reconstruct_gtf (line, type, header)
	seqname, source, feature, c_start, c_end, score, strand, frame, attr_string  = line.chomp.split "\t"
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
	document = {
		"seqname" => seqname,
		"source" => source,
		"feature" => feature,
		"start" => c_start,
		"end" => c_end,
		"score" => score,
		"strand" => strand,
		"frame" => frame,
		"attributes" => attributes    
	} 
end