# finder

require "json"
require "elasticsearch"
require_relative "biodatafinder/reconstructorcodes.rb"

class Finder

    attr_accessor :client, :index
    
    def initialize (client, index)
        @client, @index = client, index.downcase
    end

    def query (query_text)
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
			infos[:filepath] = filepath
            filetype = answer["type"]
			infos[:filetype] = filetype
            File.open(filepath, "r") do |file|
                file.seek answer["position"]["line_start_byte"].to_i
                line = file.gets
                hashline = self.reconstruct(line, filetype)
                objs << {:infos => infos, :data => hashline}
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




