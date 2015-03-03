#
# This is Biodatafinder Core Module
#
# Author::    Alessandro Bonfanti  (mailto:swalf@users.noreply.github.com)
# Copyright:: Copyright (c) 2014, Alessandro Bonfanti
# License::   GNU GPLv3

require 'json'
require 'elasticsearch'
require 'progressbar'
require 'fileutils'

module Biodatafinder

	# Error classes

	class BDFError < RuntimeError
	end

	class NoSetupFile < BDFError
	end

	class WrongDBVersion < BDFError
	end

	class NoESInstance < BDFError
	end

	class IndexedFileNotFound < BDFError
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

		@@Version = "0.3.9.pre"
		@@DBVersion = 1.1

		def self.version
			@@Version
		end

		def self.db_version
			@@DBVersion
		end



		attr_reader :poolsize, :host, :index, :files, :supported_types

		def initialize (es_host, bdf_index, idx_exists)

			@ESClient = Elasticsearch::Client.new log: false, host: es_host.to_s
			@host = es_host.to_s
			@index = bdf_index.to_s
			@poolsize = 10000 # This setting say how much frequently bdf launch bulk call by ES APIs
			if idx_exists
				raise BDFIndexNotFound.new "#{bdf_index} don't exist or it's not a valid BioDataFinder index!" unless (@ESClient.indices.exists index: bdf_index)
				load_setup
			else
				raise IndexAlreadyOccupied.new "#{bdf_index} already exists!" if (@ESClient.indices.exists index: bdf_index)
				# New index initialization
				@ESClient.indices.create index: bdf_index
				# sleep 2
        # @ESClient.indices.close index: bdf_index
        # sleep 2
				# # Setting Index for autocomplete
				# @ESClient.indices.put_settings index: bdf_index, body:    {
		  #     index: {
		  #       analysis: {
		  #         filter: {
		  #           autocomplete_filter: {
		  #             type: 'edge_ngram',
		  #             min_gram: 1,
		  #             max_gram: 20
		  #           }
		  #         },
		  #         analyzer: {
		  #           autocomplete: {
		  #             type: 'custom',
		  #             tokenizer: 'standard',
		  #             filter: [
		  #               'lowercase',
		  #               'autocomplete_filter'
		  #             ]
		  #           }
		  #         }
		  #       }
		  #     }
		  #   }
		  #   sleep 2
        # @ESClient.indices.open index: bdf_index
        # sleep 2
				# Mappings for fields that have to be threated literally
				@ESClient.indices.put_mapping index: bdf_index, type: '_default_', body: {
					_default_: {
						properties: {
							position: {
								properties: {
									dir: {
										type: "string",
										analyzer: "keyword"
									},
									name: {
										type: "string",
										analyzer: "keyword"
									},
									extension: {
										type: "string",
										analyzer: "keyword"
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

			@supported_types = []
			# Load parsing code
			Dir.entries(File.dirname(__FILE__) + '/biodatafinder/').each do |entry|
				if entry =~ /^parse_\w+.rb$/
					require_relative 'biodatafinder/'.concat(entry)
					@supported_types << entry[6..-4] # Add name of supported filetype.
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
		rescue Elasticsearch::Transport::Transport::Errors::ServiceUnavailable
			raise NoESInstance.new "It seems that the instance of ElasticSearch running on '#{@host}' is unavailable. Try to wait few seconds and retry."
		rescue Elasticsearch::Transport::Transport::Errors => e
			raise GenericESError.new "Something in ElasticSearch has failed, BDFClient init process aborted:\n#{e.message}"
		end

		def files
			@files = @ESClient.get_source(index: 'ingm', type: 'bdf_db', id: "ingm_db")["files"]
		end

		def db_version
			@db_version = @ESClient.get_source(index: 'ingm', type: 'bdf_db', id: "ingm_db")["db_version"]
		end

		def parse (filepath, opts = {:filetype => nil})
			filetype = opts[:filetype]
			group    = opts[:group]

			if files.any?{|file| file["name"] == File.expand_path(filepath)}
				raise BDFError.new "'#{filepath}' has been already parsed, if you would update it, please use 'reparse'"
			end

			# Warning: this way of calling functions is discouraged.
			#          it would be better to have a module/class structure and based
			#          on the kind of data that class will call "standard" methods/have hooks

			mn = function_name_by_filetype("parse", filetype, filepath)

			if self.respond_to? mn.to_sym, true # 'true' was added for check private methods
				@pbar = ProgressBar.new("Parsing", (count_prog_step filepath))
				@pbar.set 0
				self.send mn, (File.expand_path(filepath)) # Calls the specific code for the indexing of current filetype
				tabix_fname = function_name_by_filetype("tabix", filetype, filepath)
				# @self.send tabix_fname, filepath  #if (self.respond_to?("#{tabix_fname}?".to_sym, true) && @self.send("#{tabix_fname}?"))
				@files << {name: File.expand_path(filepath), group: group}
				@pbar.finish
			else
				raise "#{File.expand_path(filepath)}: Sorry, parsing for this filetype (#{(filetype || File.extname(filepath)[1..-1])}) isn't yet implemented."
			end
		rescue Faraday::ConnectionFailed => e
			raise NoESInstance.new "It seems that there is no running instance of ElasticSearch running on '#{@host}', plese start it before use BioDataFinder"
		rescue Elasticsearch::Transport::Transport::Errors::ServiceUnavailable
			raise NoESInstance.new "It seems that the instance of ElasticSearch running on '#{@host}' is unavailable. Try to wait few seconds and retry."
		rescue Elasticsearch::Transport::Transport::Errors => e
			raise GenericESError.new "Something in ElasticSearch has failed, parsing process aborted:\n#{e.message}"
		ensure
			store_setup(group: group)
		end

		def reparse (filepath, filetype = nil)
			delete filepath
			parse filepath, filetype
		ensure
			store_setup
		end

		def delete (filepath)
			raise WrongArgument.new "'#{filepath}' isn't a file indexed by BioDataFinder!" unless files.any?{|file| file["name"]==filepath}
			f_dir = File.dirname filepath
			f_ext = File.extname filepath
			f_name = File.basename filepath, f_ext

			@ESClient.delete_by_query index: @index, body: (
				{ query:
					{ constant_score:
						{ filter:
							{ bool:
								{ must:
									[
										{ term:
											{ dir: f_dir}
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
						}
					}
				}
			)

			@files.delete filepath
		rescue Faraday::ConnectionFailed => e
			raise NoESInstance.new "It seems that there is no running instance of ElasticSearch running on '#{@host}', plese start it before use BioDataFinder"
		rescue Elasticsearch::Transport::Transport::Errors::ServiceUnavailable
			raise NoESInstance.new "It seems that the instance of ElasticSearch running on '#{@host}' is unavailable. Try to wait few seconds and retry."
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
		rescue Elasticsearch::Transport::Transport::Errors::ServiceUnavailable
			raise NoESInstance.new "It seems that the instance of ElasticSearch running on '#{@host}' is unavailable. Try to wait few seconds and retry."
		rescue Elasticsearch::Transport::Transport::Errors => e
			raise GenericESError.new "Something in ElasticSearch has failed, remove process aborted:\n#{e.message}"
		end

		def search (input_text, options = {})
			options = {files_list: :all, dir_list: :all, filetype: :all, max_results: 100, rawdata: false}.update options

			# Preprocessing query

			query_text = parse_query_input input_text

			filter = filer_on_files_or_directories options

			es_results = @ESClient.search(
				index: @index,
				type: (options[:filetype] == :all ? nil : options[:filetype]),
				body: {
			           size: options[:max_results],
			           query: {
			                   query_string: {query: (query_text)}
			                  },
			           filter: filter
			          }
			)

			answers = es_results["hits"]["hits"].inject([]) {|stor, el| stor << el["_source"]}
			scores = es_results["hits"]["hits"].inject([]) {|stor, el| stor << el["_score"]}
			gen_infos = {:nres => answers.length, :max_scores => scores.max}
			objs = []
			answers.each_with_index do |answer,i|
				# puts answer.inspect
				#data should be clustered by filepath to avoid reopening of the file multiple times.
				infos = {:scores => scores[i]}
				filepath = answer["position"]["dir"] + '/' + answer["position"]["name"] + answer["position"]["extension"]

				infos[:filepath] = filepath
				filetype = answer["type"]
				infos[:filetype] = filetype
				begin
					File.open(filepath, "r") do |file|
						header = file.readline #header can be read in a smarter way (extracted from the file ahead of processing)
						file.seek(0)
						file.seek answer["position"]["line_start_byte"].to_i
						infos[:header] = header.strip.split
						line = file.gets
						if options[:rawdata] == true
							objs << {:infos => infos, :data => {:rawdata => line}}
						else
							hashline = reconstruct(line, filetype, header)
							objs << {:infos => infos, :data => hashline}
						end
					end
				rescue Errno::ENOENT
					raise IndexedFileNotFound.new "There were some results in '#{filepath}' but the file has been deleted or moved from disk. Please remove it from BDF database."
				end

			end
			{:gen_infos => gen_infos, :objs => objs}
		rescue Faraday::ConnectionFailed => e
			raise NoESInstance.new "It seems that there is no running instance of ElasticSearch running on '#{@host}', plese start it before use BioDataFinder"
		rescue Elasticsearch::Transport::Transport::Errors::ServiceUnavailable
			raise NoESInstance.new "It seems that the instance of ElasticSearch running on '#{@host}' is unavailable. Try to wait few seconds and retry."
		rescue Elasticsearch::Transport::Transport::Errors => e
			raise GenericESError.new "Something in ElasticSearch has failed, searching process aborted:\n#{e.message}"
		end



		private


		def load_setup
			if db_version != @@DBVersion
				raise WrongDBVersion.new "'#{@index}_db' version is #{db_version} but BioDataFinder #{@@Version} require #{@@DBVersion}."
			end

			files
		rescue Elasticsearch::Transport::Transport::Errors::NotFound => e
			raise NoSetupFile.new "#{@index}_db not found"
		end #load_setup


		def store_setup(opts={})
			@ESClient.update  index: @index, type: 'bdf_db', id: "#{@index}_db", body: {
				doc: {
					files: @files,
					db_version: @@DBVersion
					}
			}
		end #store_setup

		def count_prog_step (filepath)
			lines = 0
			File.foreach(filepath) { lines += 1} # It seems that foreach is faster than alternatives
			@prog_steps = (lines / @poolsize).to_i
		end #count_prog_step

		def load_document (document, type)
			@ESClient.index  index: @index.to_s.downcase, type: type, body: document
		end #load_document

		def load_pool (docpool, type)
			body = []
			docpool.each do |doc|
				body << { index:  { _index: @index.to_s.downcase, _type: type, data: doc } }
			end
			@ESClient.bulk body: body
			@pbar.inc
		end #load_pool

		def reconstruct (line, type, header)
			# Warning: this way of calling functions is discouraged.
			#          it would be better to have a module/class structure and based
			#          on the kind of data that class will call "standard" methods/haveooks
			mn = "reconstruct_" + type.downcase
			if self.respond_to? mn, true # 'true' was added for check private methods
				self.send mn.to_sym, line, type, header # Call the appropriate code for recostructoring the json from line data
			else
				raise BDFError.new "Sorry, I can't reconstruct data from this filetype (#{type}) because lack of specific code. Please check if code is installed."
			end
		end #reconstruct

	  def parse_query_input(iquery)
	  	iquery.split.map do |text_token|
				if text_token =~/-/
				  "(" + text_token.split('-').join(' AND ') + ")"
				else
					text_token
				end
			end.join(' OR ')
		end #parse_query_input

		def filer_on_files_or_directories(options)
			if options[:files_list] != :all
				raise WrongArgument.new ":filelist must be :all or an array filled by some indexed files" unless options[:files_list].is_a? Array
				part_filters = []
				options[:files_list].each do |filepath|
					raise WrongArgument.new "'#{filepath}' isn't a file indexed by BioDataFinder!" unless @files.any?{|file| file[:name]==filepath }
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
						filename = file["name"]
						file_tokens = filename.split '/'
						same_flag = true
						input_tokens.length.times do |i|
							if input_tokens[i] != file_tokens[i]
								same_flag = false
								break
							end
						end
						dir_array << (File.dirname filename) if same_flag
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
		end #filer_on_files_or_directories

		def function_name_by_filetype(basename, filetype, filepath)
			if filetype == nil
				"#{basename}_#{File.extname(filepath)[1..-1]}"
			else
				"#{basename}_#{filetype}"
			end
		end #function_name_by_filetype

	end #Client




end #BioDatafinder
