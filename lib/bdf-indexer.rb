#!/usr/bin/env ruby
#
# This is indexer library for BiodataFinder
#
# Author::    Alessandro Bonfanti  (mailto:swalf@users.noreply.github.com)
# Copyright:: Copyright (c) 2014, Alessandro Bonfanti
# License::   GNU GPLv3

require 'json'
require 'elasticsearch'
require 'progressbar'



class Indexer

    private
	
	@@poolsize = 10000
	
	
	def poolsize 
		@@poolsize
	end
	
	def count_prog_step (filepath)
		lines = 0
		File.foreach(filepath) { lines += 1} # It seems that foreach is faster than alternatives
		puts "Total Lines: #{lines}"
		@prog_steps = (lines / @@poolsize).to_i
	end

    def load_document (document, type)
        @client.index  index: @index.to_s.downcase, type: type, body: document
    end
    
    def load_pool (docpool, type)
        body = []
        docpool.each do |doc|
            body << { index:  { _index: @index.to_s.downcase, _type: type, data: doc } }
        end
        @client.bulk body: body
		@bar.inc
    end
	
		
	Dir.entries(File.dirname(__FILE__) + '/biodatafinder/').each do |entry|
		if entry =~ /^parse_\w+.rb$/
			require_relative 'biodatafinder/'.concat(entry)
		end
	end
	
	public
	
	
	
	#extend FileExt
	attr_accessor :client, :index
	
	
	def initialize (client, index)
		@client, @index = client, index
	end
	
	def parse (filepath, filetype = nil)
		
		if filetype == nil
			mn = "parse_#{File.extname(filepath)[1..-1]}"
		else
			mn = "parse_#{filetype}"
		end
		
		if self.respond_to? mn.to_sym, true # 'true' was added for check private methods
			@bar = ProgressBar.new("Parsing", (count_prog_step filepath))
			@bar.set 0
			self.send mn, filepath # Calls the specific code for the indexing of current filetype
			@bar.finish
		else
			raise "#{filepath}: Sorry, parsing for this filetype (#{(filetype || File.extname(filepath)[1..-1])}) isn't yet implemented."
		end
	end
	
	def delete_file(filepath)
	end
		
       
end

