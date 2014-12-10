
module ReconstructorCodes
    
    Tracking_code = proc do |line,type|
        ldata = line.split "\t"
        document = {
            "tracking_id" => tracking_id = ldata[0],
            "class_code" => ldata[1], 
            "nearest_ref_id" => ldata[2],
            "gene_id" => ldata[3],
            "gene_short_name" => ldata[4],
            "tss_id" => ldata[5], 
            "locus" => ldata[6],
            "length" => ldata[7], 
            "coverage" => ldata[8],
            "FPKM" => ldata[9],
            "FPKM_conf_lo" => ldata[10],
            "FPKM_conf_hi" => ldata[11],
            "FPKM_status" => ldata[12]   
        }                                                 
    end
    
    Gtf_code = proc do |line, type|
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
    
    
end
