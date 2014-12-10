# finder

require "json"
require "elasticsearch"
require_relative "biodatafinder/reconstructorcodes.rb"

class Finder

    attr_accessor :client, :index
    
    def initialize (client, index)
        @client, @index = client, index.downcase
    end

    def query (query_text, output_format)
        # ES generates errors when only '-' is passed as a query 
        query_text.gsub!('-') {|c| c = ' '}
        results =  @client.search index: @index, body: {query: {query_string: {query: query_text}}}
        answers = results["hits"]["hits"].inject([]) {|stor, el| stor << el["_source"]}
        scores = results["hits"]["hits"].inject([]) {|stor, el| stor << el["_score"]}
        gen_infos = {:nres => answers.length, :max_scores => scores.max}
        objs = []
        answers.each_with_index do |answer,i|
            infos = {:scores => scores[i]}
            filepath = answer["position"]["dir"] + '/' + answer["position"]["name"] + answer["position"]["extension"]
            filetype = answer["type"]
            File.open(filepath, "r") do |file|
                file.seek answer["position"]["line_start_byte"].to_i
                line = file.gets
                case output_format
                when 'json'
                    json = JSON.generate( self.reconstruct(line, filetype) )
                    objs << {:infos => infos, :data => json}
                when 'pretty_json'
                    json = JSON.pretty_generate( self.reconstruct(line, filetype) )
                    objs << {:infos => infos, :data => json}
                when 'rawline'
                    objs << {:infos => infos, :data => line}
                when 'hash'
                    hash = self.reconstruct(line, filetype)
                    objs << {:infos => infos, :data => hash}
                else
                    raise "Invalid output format"
                end
            end 
        end
        {:gen_infos => gen_infos, :objs => objs}
    rescue Elasticsearch::Transport::Transport::Errors => e
    	$stderr.puts "ES error: " + e.message
    	raise
    end
    
    def reconstruct (line, type)
        mn = type + "_code"
        ReconstructorCodes.const_get(mn).call line, type #Call the appropriate code for recostructoring the json from line data
    end

end




