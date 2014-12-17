def reconstruct_gtf (line, type)
	seqname, source, feature, c_start, c_end, score, strand, frame, attributes  = line.split "\t"
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