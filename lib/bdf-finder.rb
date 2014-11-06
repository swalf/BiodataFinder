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
        results =  (@client.search index: @index, q: query_text)
        answers = results["hits"]["hits"].inject([]) {|stor, el| stor << el["_source"]}
        scores = results["hits"]["hits"].inject([]) {|stor, el| stor << el["_score"]}
        gen_infos = {:nres => answers.length, :max_scores => scores.max}
        objs = []
        answers.each_with_index do |answer,i|
            infos = {:scores => scores[i]}
            filepath = answer["position"]["dir"] + '/' + answer["position"]["name"] + answer["position"]["extension"]
            
            File.open(filepath, "r") do |file|
                file.seek answer["position"]["line_start_byte"].to_i
                line = file.gets
                case output_format
                when 'json'
                    json = self.reconstruct(line, answer["position"]["extension"])
                    objs << {:infos => infos, :data => json}
                when 'rawline'
                    objs << {:infos => infos, :data => line}
                when 'pretty_output'
                    return "Sorry, not yet implemented!"
                    #Issue: pretty output not yet implemented!
                else
                    json = self.reconstruct(line, answer["position"]["extension"])
                    objs << {:infos => infos, :data => json}
                end
            end 
        end
        {:gen_infos => gen_infos, :objs => objs}
    end
    
    def reconstruct (line, type)
        mn = type[1..-1].capitalize + "_code"
        ReconstructorCodes.const_get(mn).call line, type #Call the appropriate code for recostructoring the json from line data
    end

end




