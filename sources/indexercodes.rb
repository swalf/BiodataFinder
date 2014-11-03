
module IndexerCodes

#Tracking start

    Track_code = proc do |idx, filepath|
        File.open(filepath, "r") do |file|
            header = file.readline
            raise "tracking file format error" if header.split != ["tracking_id", 
                                                               "class_code", 
                                                               "nearest_ref_id",
                                                               "gene_id",
                                                               "gene_short_name",
                                                               "tss_id", 
                                                               "locus",
                                                               "length", 
                                                               "coverage",
                                                               "FPKM",
                                                               "FPKM_conf_lo",
                                                               "FPKM_conf_hi",
                                                               "FPKM_status"] 
            lbs = file.pos #Byte di inizio riga
            file.each do |line|

                ldata = line.split
                tracking_id = ldata[0]
                nearest_ref_id = ldata[3]
                gene_id = ldata[4]
                gene_short_name = ldata[5]
                f_ext = File.extname(filepath)
                f_name = File.basename(filepath, f_ext) 
                f_dir = File.dirname(filepath)
                position = {"dir" => f_dir, "name" => f_name, "extension" => f_ext, "line_start_byte" => lbs}
                lbs = file.pos #Aggiorna il dato per la nova riga.

                document = JSON.generate( {"tracking_id" => tracking_id,
                                         "nearest_ref_id" => nearest_ref_id,
                                         "gene_id" => gene_id,
                                         "gene_short_name" => gene_short_name,
                                         "position" => position} )

                idx.load_document document, "tracking"
           end
        end
    end

#Tracking end
#GTF start

    Gtf_code = proc do |idx, filepath|
        File.open(filepath, "r") do |file|
            comments = 0
            lbs = file.pos #Byte di inizio riga
            file.each_with_index do |line,i|
                if line[0] == '#'
                    comments += 1
                    lbs = file.pos #Aggiorna il dato per la nova riga.
                    next
                end
      
                seqname, source, feature, c_start, c_end, score, strand, frame, attributes  = line.split "\t"
                f_ext = File.extname(filepath)
                f_name = File.basename(filepath, f_ext) 
                f_dir = File.dirname(filepath)
                position = {"dir" => f_dir, "name" => f_name, "extension" => f_ext, "line_start_byte" => lbs}
                lbs = file.pos #Aggiorna il dato per la nova riga.

                document = JSON.generate( {"seqname" => seqname,
                                       "source" => source,
                                       "feature" => feature,
                                       "start" => c_start,
                                       "end" => c_end,
                                       "score" => score,
                                       "strand" => strand,
                                       "frame" => frame,
                                       "position" => position} )
                   
                idx.load_document document, "gtf"      
            end
        end
    end

#GTF end

end