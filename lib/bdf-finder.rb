#!/usr/bin/env ruby
#
# This is finder library for BiodataFinder
#
# Author::    Alessandro Bonfanti  (mailto:swalf@users.noreply.github.com)
# Copyright:: Copyright (c) 2014, Alessandro Bonfanti
# License::   GNU GPLv3

require "json"
require "elasticsearch"


class Finder
	
	private
	
	Dir.entries(File.dirname(__FILE__) + '/biodatafinder/').each do |entry|
		if entry =~ /^reconstruct_\w+.rb$/
			require_relative 'biodatafinder/'.concat(entry)
		end
	end

	public
	
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
		mn = "reconstruct_" + type.downcase
		if self.respond_to? mn, true # 'true' was added for check private methods
			self.send mn.to_sym, line, type # Call the appropriate code for recostructoring the json from line data
		else
			raise "#Sorry, I can't reconstruct data from this filetype (#{type}) because lack of specific code. Please check if code is installed."
		end
    end
	
	

end




