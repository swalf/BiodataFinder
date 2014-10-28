require "json"
require "elasticsearch"

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
            puts "#{i}:"
            answer.each_pair {|key, value| (puts key + ': ' + value.to_s) unless key == "position"}
            puts "Document:"
            filepath = answer["position"]["dir"] + '/' + answer["position"]["name"] + answer["position"]["extension"]
            File.open(filepath, "r") do |file|
                file.seek answer["position"]["line_start_byte"].to_i
                line = file.gets
                line.length.times {print '#'}
                puts
                puts line
                line.length.times {print '#'}
                puts
            end
        end
    end

end




