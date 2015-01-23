#
# Author::    Alessandro Bonfanti  (mailto:swalf@users.noreply.github.com)
# Copyright:: Copyright (c) 2014, Alessandro Bonfanti
# License::   GNU GPLv3

require 'json'
require 'elasticsearch'
require 'progressbar'

class BDFClient 
	
	@@Version = "0.3.1.pre"
	
	def self.version
		@@Version
	end
	
	
	attr_reader :poolsize, :conf_file, :host, :max_results, :def_index, :indices, :files
	
	def initialize
		@conf_file = ENV['HOME'] + "/.biodatafinder/bdf.conf"
		@poolsize = 10000
		# Load parsing code
		Dir.entries(File.dirname(__FILE__) + '/biodatafinder/').each do |entry|
			if entry =~ /^parse_\w+.rb$/
				require_relative 'biodatafinder/'.concat(entry)
			end
		end
		# Load reconstruct code
		Dir.entries(File.dirname(__FILE__) + '/biodatafinder/').each do |entry|
			if entry =~ /^reconstruct_\w+.rb$/
				require_relative 'biodatafinder/'.concat(entry)
			end
		end
		# Loading setup in config file.
		load_setup
		# Create ESClient
		@ESClient = Elasticsearch::Client.new log: false, host: @host
	end
	
	def load_setup 
		unless File.exist? @conf_file
			Dir.mkdir (File.dirname @conf_file) unless Dir.exist? (File.dirname @conf_file) 
			@def_index = 'idx'
			@indices = [@def_index]
			@host = "http://localhost:9200"
			@max_results = 25
			@files = []
			store_setup
		else
			File.open(@conf_file,"r") do |file|
				contents = file.inject("") {|text, line| text+=line}
				contents.gsub! "\n", " "
				chash = JSON.parse contents
				@def_index = chash['def_index']
				@indices = chash['indices']
				@host = chash['host']
				@max_results = chash['max_results']
				@files = chash['files']
				puts chash
			end
		end
	rescue RuntimeError => e
		if e.message == "Config file entain wrong fields!"
			$stderr.puts "Error: #{exc.message}", "Config file will be not loaded."
		else
			$stderr.puts "Error: #{exc.message}"
		end
	end
	
	def store_setup   
		storage = JSON.pretty_generate(
			{
		     def_index: @def_index,
		     indices: @indices,
		     host: @host,
		     max_results: @max_results,
		     files: @files
		    }
		)
		File.open(@conf_file,"w") do |file|
			file.puts storage
		end
	rescue RuntimeError => e
		$stderr.puts "ERROR: " + e.message      
	end
	
	def max_results= (num)
		raise "Arg must be a positive number!" unless (num.is_a? Integer) && (num > 0)
		@max_results = num
	ensure
		store_setup
	end
	
	def host= (host)
		#security control lacks
		@host = host
	ensure
		store_setup
	end
	
	def def_index= (index)
		raise "Wrong index name, use only a-z,0-9,_" unless index =~ /^\w+$/
		unless @indices.include? index
			# Create new index and set default analyzer to keyword
			@ESClient.indices.create index: index, body: {	"index" => { "analysis" => { "analyzer" => { "default" => { "type" => "keyword" }}}}}
			@indices << index
		end
		@def_index = index
	ensure
		store_setup
	end
		
		
	
	private
	
	
	
	
	def count_prog_step (filepath)
		lines = 0
		File.foreach(filepath) { lines += 1} # It seems that foreach is faster than alternatives
		puts "Total Lines: #{lines}"
		@prog_steps = (lines / @poolsize).to_i
	end
	
	def load_document (document, type)
		@ESClient.index  index: @index.to_s.downcase, type: type, body: document
	end
	
	def load_pool (docpool, type)
		body = []
		docpool.each do |doc|
			body << { index:  { _index: @index.to_s.downcase, _type: type, data: doc } }
		end
		@ESClient.bulk body: body
		@pbar.inc
	end
	
	def reconstruct (line, type)
		mn = "reconstruct_" + type.downcase
		if self.respond_to? mn, true # 'true' was added for check private methods
			self.send mn.to_sym, line, type # Call the appropriate code for recostructoring the json from line data
		else
			raise "#Sorry, I can't reconstruct data from this filetype (#{type}) because lack of specific code. Please check if code is installed."
		end
	end
	
	
	public
	
	def parse (filepath, filetype = nil)
		
		if @files.include? filepath
			raise "'#{filepath}' has been already parsed, if you would update it, please use 'reparse'"
		end
		
		if filetype == nil
			mn = "parse_#{File.extname(filepath)[1..-1]}"
		else
			mn = "parse_#{filetype}"
		end
		
		if self.respond_to? mn.to_sym, true # 'true' was added for check private methods
			@pbar = ProgressBar.new("Parsing", (count_prog_step filepath))
			@pbar.set 0
			self.send mn, filepath # Calls the specific code for the indexing of current filetype
			@files << filepath
			@pbar.finish
		else
			raise "#{filepath}: Sorry, parsing for this filetype (#{(filetype || File.extname(filepath)[1..-1])}) isn't yet implemented."
		end
		
	rescue Faraday::ConnectionFailed => e
		puts "It seems that there is no running istance of ElasticSearch running on '#{@host}', plese start it before use BioDataFinder"
	rescue Elasticsearch::Transport::Transport::Errors => e
		puts "Something in ElasticSearch has failed, parsing process aborted"
		puts e.message
	rescue RuntimeError => e
		$stderr.puts "ERROR: " + e.message	
	ensure 
		store_setup
	end
	
	def reparse (filepath, filetype = nil)
		#blabla
		puts "Fake reparsing!"
		
	rescue Faraday::ConnectionFailed
		puts "It seems that there is no running istance of ElasticSearch running on '#{@host}', plese start it before use BioDataFinder"
	ensure
		store_setup
	end
	
	def delete (filepath)
		#blabla
		puts "Fake deleting of #{filepath}"
	rescue Faraday::ConnectionFailed
		puts "It seems that there is no running istance of ElasticSearch running on '#{@host}', plese start it before use BioDataFinder"
	ensure
		store_setup
	end
	
	def remove_index (indexname)
		raise "'#{indexname}' is not a valid index!" unless @indices.include? indexname
		@ESClient.indices.delete index: indexname
		puts "Delete process on ES #{@host}, index '#{indexname}'"
		@indices.delete indexname
	rescue Faraday::ConnectionFailed
		puts "It seems that there is no running istance of ElasticSearch running on '#{@host}', plese start it before use bdf-cli."
	end
		
	def search (query_text, files_list = :all)
		
		es_results =  @ESClient.search index: @index, body: {size: @max_results, query: {query_string: {query: query_text}}} #Tried to set nres to 25
		answers = es_results["hits"]["hits"].inject([]) {|stor, el| stor << el["_source"]}
		scores = es_results["hits"]["hits"].inject([]) {|stor, el| stor << el["_score"]}
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
				hashline = reconstruct(line, filetype)
				objs << {:infos => infos, :data => hashline}
			end 
		end
		{:gen_infos => gen_infos, :objs => objs}
		#Missing index ES exeption have to be catched	
	rescue Faraday::ConnectionFailed
		puts "It seems that there is no running istance of ElasticSearch running on '#{@host}', plese start it before use bdf-cli."
	rescue Elasticsearch::Transport::Transport::Errors => e
		puts "Something in ElasticSearch has failed, searching process aborted"
		puts e.message
	rescue RuntimeError => e
		$stderr.puts "ERROR: " + e.message    
	end
	
end
	
	