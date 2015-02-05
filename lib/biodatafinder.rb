#
# This is BiodataFinder Core Module
#
# Author::    Alessandro Bonfanti  (mailto:swalf@users.noreply.github.com)
# Copyright:: Copyright (c) 2014, Alessandro Bonfanti
# License::   GNU GPLv3

require 'json'
require 'elasticsearch'
require 'progressbar'

module BiodataFinder

	class BDFError < RuntimeError
	end

	class NoSetupFile < BDFError
	end

	class WrongDBVersion < BDFError
	end

	class NoESInstance < BDFError
	end

	class BDFIndexNotFound < BDFError
	end

	class IndexAlreadyOccupied < BDFError
	end

	class GenericESError < BDFError
	end
	
	class WrongArgument < BDFError
	end


		

	class Client 
		
		@@Version = "0.3.4.pre"
		@@DBVersion = 1 
		
		def self.version
			@@Version
		end
		
		def self.db_version
			@@DBVersion
		end
		
		
		
		attr_reader :poolsize, :host, :index, :files
		
		def initialize (es_host, bdf_index, idx_exists)
			
			@ESClient = Elasticsearch::Client.new log: false, host: es_host.to_s
			@host = es_host.to_s
			@index = bdf_index.to_s
			@poolsize = 10000
			if idx_exists
				raise BDFIndexNotFound.new "#{bdf_index} don't exist or it's not a valid BioDataFinder index!" unless (@ESClient.indices.exists index: bdf_index)
				load_setup
			else
				raise IndexAlreadyOccupied.new "#{bdf_index} already exists!" if (@ESClient.indices.exists index: bdf_index)
				# New index initialization
				@ESClient.indices.create index: bdf_index, body: {
					"index" => { 

							}
				}
				@ESClient.indices.put_mapping index: bdf_index, type: '_default_', body: {
					_default_: {
								properties: {
											position: {
														properties: {
																	"dir" => {
																			"type" => "string",
																			"analyzer" => "keyword"
																			},
																	"name" => {
																				"type" => "string",
																				"analyzer" => "keyword"
																			},
																	"extension" => {
																					"type" => "string",
																					"analyzer" => "keyword"
																					}
																	}
													}
											}                             
							}
				}	
				
				# Create config file
				@ESClient.index  index: bdf_index, type: 'bdf_db', id: "#{bdf_index}_db", body: {
					files: [],
					db_version: @@DBVersion
				}
				load_setup

			end		

			
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
			
		rescue Faraday::ConnectionFailed => e
			raise NoESInstance.new "It seems that there is no running instance of ElasticSearch running on '#{@host}', plese start it before use BioDataFinder"
		rescue Elasticsearch::Transport::Transport::Errors => e
			raise GenericESError.new "Something in ElasticSearch has failed, BDFClient init process aborted:\n#{e.message}"
		end
		
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
			raise NoESInstance.new "It seems that there is no running instance of ElasticSearch running on '#{@host}', plese start it before use BioDataFinder"
		rescue Elasticsearch::Transport::Transport::Errors => e
			raise GenericESError.new "Something in ElasticSearch has failed, parsing process aborted:\n#{e.message}"
		ensure 
			store_setup
		end
		
		def reparse (filepath, filetype = nil)
			delete filepath
			parse filepath, filetype
		ensure
			store_setup
		end
		
		def delete (filepath)
			raise WrongArgument.new "'#{filepath}' isn't a file indexed by BioDataFinder!" unless @files.include? filepath
			f_dir = File.dirname filepath
			f_ext = File.extname filepath
			f_name = File.basename filepath, f_ext
			
			@ESClient.delete_by_query index: @index, body: (
				{
				"query" => {
							"constant_score" => {
												"filter" => {
															"bool" => {
																		"must" => [
																					{
																					"term" => { "dir" => f_dir}
																					},
																					{
																					"term" => { "name" => f_name}
																					},
																					{
																					"term" => { "extension" => f_ext}
																					}
																					]
																		}
															}                            
												}
							}
				}
			)
			
			@files.delete filepath
		rescue Faraday::ConnectionFailed => e
			raise NoESInstance.new "It seems that there is no running instance of ElasticSearch running on '#{@host}', plese start it before use BioDataFinder"
		rescue Elasticsearch::Transport::Transport::Errors => e
			raise GenericESError.new "Something in ElasticSearch has failed, parsing process aborted:\n#{e.message}"
		ensure
			store_setup
		end
		
		def erase_bdf_db (indexname)
			unless (@ESClient.indices.exists index: indexname) && (@ESClient.exists index: indexname, type: 'bdf_db', id: "#{indexname}_db")
				raise BDFIndexNotFound.new "'#{indexname}' is not a valid index!" 
			end
			log = @ESClient.indices.delete index: indexname
			if log["acknowledged"] == true
				true
			else
				raise BDFError.new "Something has failed in deleting process of index '#{indexname}'"
			end
		rescue Faraday::ConnectionFailed => e
			raise NoESInstance.new "It seems that there is no running instance of ElasticSearch running on '#{@host}', plese start it before use BioDataFinder"
		rescue Elasticsearch::Transport::Transport::Errors => e
			raise GenericESError.new "Something in ElasticSearch has failed, remove process aborted:\n#{e.message}"
		end
		
		def search (query_text, options = {})
			options = {files_list: :all, dir_list: :all, filetype: :all, max_results: 25}.update options
			
			if options[:files_list] != :all
				raise WrongArgument.new ":filelist must be :all or an array filled by some indexed files" unless options[:files_list].is_a? Array 
				part_filters = []
				options[:files_list].each do |filepath|
					raise WrongArgument.new "'#{filepath}' isn't a file indexed by BioDataFinder!" unless @files.include? filepath
					f_ext = File.extname filepath
				    f_name = File.basename filepath, f_ext
				    f_dir = File.dirname filepath   
					part_filters << (
						{ bool: 
					      { must: 
					        [
					         { term: 
					           { dir: f_dir }
					         },
					         { term: 
					           { name: f_name}
					         },
					         { term: 
					           { extension: f_ext}
					         }
					        ]
					      }
					    }
					)
					
				end
				
				filter = {or: part_filters}
				                 
			elsif options[:dir_list] != :all
				raise WrongArgument.new ":dir_list must be :all or an array filled by some indexed files" unless options[:dir_list].is_a? Array 
				# This code select full dirpaths of the bdf files that match with one element of the list  
				dir_array = []
				options[:dir_list].each do |dirpath|
					input_tokens = dirpath.split '/'
					@files.each do |file|
						file_tokens = file.split '/'
						same_flag = true
						input_tokens.length.times do |i|
							if input_tokens[i] != file_tokens[i]
								same_flag = false
								break
							end
						end
						dir_array << (File.dirname file) if same_flag
					end
				end
				dir_array.uniq!
				# This code build partial filter for every selected directory 
				part_filters = []		
				dir_array.each do |dirpath|
					part_filters << (
						{ bool: 
					      { must: 
					        [
					         { term: 
					           { dir: (dirpath.chomp '/') }
					         }
					        ]
					      }
					    }
					)
				end
				
				filter = {or: part_filters}
				 
			else
				filter = {}
			end
			
			es_results = @ESClient.search(
				index: @index,
				type: (options[:filetype] == :all ? nil : options[:filetype]),				    
				body: {
			           size: options[:max_results],
			           query: {
			                   query_string: {query: query_text}
			                  },
			           filter: filter
			          }
			)
			
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
		rescue Faraday::ConnectionFailed => e
			raise NoESInstance.new "It seems that there is no running instance of ElasticSearch running on '#{@host}', plese start it before use BioDataFinder"
		rescue Elasticsearch::Transport::Transport::Errors => e
			raise GenericESError.new "Something in ElasticSearch has failed, searching process aborted:\n#{e.message}"
		end
			
			
		
		private
		
		
		def load_setup
			settings = (@ESClient.get index: @index, type: 'bdf_db', id: "#{@index}_db")["_source"]
			if settings["db_version"] != @@DBVersion 
				raise WrongDBVersion.new "'#{@index}_db' version is #{settings["db_version"]} but BioDataFinder #{@@Version} require #{@@DBVersion}."
			end
			
			@files = settings['files']	
		rescue Elasticsearch::Transport::Transport::Errors::NotFound => e
			raise NoSetupFile.new "#{@index}_db not found"
		end
		
		
		def store_setup 
			@ESClient.update  index: @index, type: 'bdf_db', id: "#{@index}_db", body: {
				doc: {
					files: @files,
					db_version: @@DBVersion
					}
			}
		end
		
		def count_prog_step (filepath)
			lines = 0
			File.foreach(filepath) { lines += 1} # It seems that foreach is faster than alternatives
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
				raise BDFError.new "Sorry, I can't reconstruct data from this filetype (#{type}) because lack of specific code. Please check if code is installed."
			end
		end
		
	end
		
		
		
		
end
	
	