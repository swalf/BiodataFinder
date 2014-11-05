require "json"
require "elasticsearch"
require_relative "reconstructorcodes.rb"

class Finder

    attr_accessor :client, :index
    
    def initialize (client, index)
        @client, @index = client, index.downcase
    end

    def query (query_text, output_format)
        results =  (@client.search index: @index, q: query_text)
        answers = results["hits"]["hits"].inject([]) {|stor, el| [el["_source"]]}
        puts "#{answers.length} result(s) found:"
        objs = []
        answers.each_with_index do |answer,i|
            filepath = answer["position"]["dir"] + '/' + answer["position"]["name"] + answer["position"]["extension"]
            objs = []
            File.open(filepath, "r") do |file|
                file.seek answer["position"]["line_start_byte"].to_i
                line = file.gets
                return line if output_format == 'rawline' or output_format == nil
                return "Sorry, not yet implemented!" if output_format == 'pretty_output' #Issue: pretty output not yet implemented!
                obj = self.reconstruct(line, answer["position"]["extension"])
                objs << obj
            end 
        end
        objs
    end
    
    def reconstruct (line, type)
        mn = type[1..-1].capitalize + "_code"
        ReconstructorCodes.const_get(mn).call line, type #Call the appropriate code for recostructoring the json from line data
    end

end




