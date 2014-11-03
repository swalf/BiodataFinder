require "json"
require "elasticsearch"
require_relative "indexercodes.rb"

class CLIFinder

    attr_accessor :client, :index
    
    def initialize (client, index)
        @client, @index = client, index.downcase
    end

    def query (query_text)
        results =  (@client.search index: @index, q: query_text)
        answers = results["hits"]["hits"].inject([]) {|stor, el| [el["_source"]]}
        puts "#{answers.length} result(s) found:"
        answers.each_with_index do |answer,i|
            puts "#{i+1}:"
            answer.each_pair {|key, value| (puts key + ': ' + value.to_s) unless key == "position"}
            puts "Document:"
            filepath = answer["position"]["dir"] + '/' + answer["position"]["name"] + answer["position"]["extension"]
            File.open(filepath, "r") do |file|
                file.seek answer["position"]["line_start_byte"].to_i
                line = file.gets
                puts
                puts line
                puts
                obj = self.reconstruct(line, answer["position"]["extension"])
                puts obj
            end
        end
    end
    
    def reconstruct (line, type)
        mn = tipe[1..-1].capitalize + "_code"
        ReconstructorCodes.const_get(mn).call line, type
    end

end




