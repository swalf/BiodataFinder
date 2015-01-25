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
	
	def self.create_config (conf_file, chash = {})
		if File.exist? conf_file
			raise "'#{conf_file}' already exist, if you would create new setup, please delete it before"
		end

		storage = JSON.pretty_generate(
			{
		     index: (chash[:index] || 'idx'),
		     #indices: (chash[:indices] || []), 
		     host: (chash[:host] || "http://localhost:9200"),
		     max_results: (chash[:max_results] || 25),
		     files: (chash[:files] || [])
		    }
		)
		Dir.mkdir (File.dirname conf_file) unless Dir.exist? (File.dirname conf_file) 
		File.open(conf_file,"w") do |file|
			file.puts storage
		end
	end
	
	def self.check_config (conf_file)
		raise "'#{conf_file}' do not exist!" unless File.exist? conf_file
		# Do checking...
		true
	end
		
	
	
	attr_reader :poolsize, :conf_file, :host, :max_results, :index, :files
	
	def initialize (conf_file)
		#@conf_file = ENV['HOME'] + "/.biodatafinder/bdf.conf"
		if (File.exist? conf_file) && (BDFClient.check_config conf_file)
			@conf_file = conf_file
		else
			raise "Config file don't exist or it's wrong formatted!"
		end
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
		@ESClient = Elasticsearch::Client.new log: false, host: host
		unless @idx_initialized
			init_index @index
			store_setup
		end
	rescue Faraday::ConnectionFailed => e
		puts "It seems that there is no running istance of ElasticSearch running on '#{@host}', plese start it before use BioDataFinder"
		return :no_es_istance
	end
	
	def load_setup 
		File.open(@conf_file,"r") do |file|
			contents = file.inject("") {|text, line| text+=line}
			contents.gsub! "\n", " "
			chash = JSON.parse contents
			@host = chash['host']
			#@indices = chash['indices']
			@index = chash['index']
			@idx_initialized = chash['idx_initialized']
			@max_results = chash['max_results']
			@files = chash['files']
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
		     index: @index,
		     idx_initialized: @idx_initialized,
		     #indices: @indices,
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
		@ESClient = Elasticsearch::Client.new log: false, host: host
		@host = host
	rescue Faraday::ConnectionFailed => e
		puts "It seems that there is no running istance of ElasticSearch running on '#{host}', plese start it before use BioDataFinder"
	ensure
		store_setup
	end
	
	def index= (index)
		raise "Wrong index name, use only a-z,0-9,_" unless index =~ /^\w+$/
		#check if index already exist
		# Create new index and set default analyzer to keyword
		init_index index
		@index = index
	ensure
		store_setup
	end
		
		
	
	private
	
	def init_index (index)
		@ESClient.indices.create index: index, body: {	"index" => { "analysis" => { "analyzer" => { "default" => { "type" => "keyword" }}}}}
		@idx_initialized = true
		#@indices << index
		p "#{index} inizializzato!"
	end
	
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
		return :ok
	rescue Faraday::ConnectionFailed => e
		puts "It seems that there is no running istance of ElasticSearch running on '#{@host}', plese start it before use BioDataFinder"
		return :no_es_istance
	rescue Elasticsearch::Transport::Transport::Errors => e
		puts "Something in ElasticSearch has failed, parsing process aborted"
		puts e.message
		return :generic_es_error
	ensure 
		store_setup
	end
	
	def reparse (filepath, filetype = nil)
		log = delete filepath
		if log == :ok
			log = parse filepath, filetype
		end
		log
	rescue Faraday::ConnectionFailed
		puts "It seems that there is no running istance of ElasticSearch running on '#{@host}', plese start it before use BioDataFinder"
		return :no_es_istance
	ensure
		store_setup
	end
	
	def delete (filepath)
		raise "'#{filepath}' isn't a file indexed by BioDataFinder!" unless @files.include? filepath
		@ESClient.delete_by_query index: @index, body: {"query" => { "term" => { "path" => filepath}}}
		@files.delete filepath
		return :ok
	rescue Faraday::ConnectionFailed
		puts "It seems that there is no running istance of ElasticSearch running on '#{@host}', plese start it before use BioDataFinder"
		return :no_es_istance
	ensure
		store_setup
	end
	
	def remove_index (indexname)
		raise "'#{indexname}' is not a valid index!" unless @indices.include? indexname
		puts "Delete process on ES #{@host}, index '#{indexname}'"
		log = @ESClient.indices.delete index: indexname
		if log["acknowledged"] == "true"
			@indices.delete indexname
			return :ok
		else
			raise "Something has failed in deleting process"
			return :generic_es_error
		end
	rescue Faraday::ConnectionFailed
		puts "It seems that there is no running istance of ElasticSearch running on '#{@host}', plese start it before use bdf-cli."
		return :no_es_istance
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
	
	