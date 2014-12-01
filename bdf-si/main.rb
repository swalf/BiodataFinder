#!/usr/bin/env ruby
#Sinatra sample test

require 'sinatra'
require 'slim'

if development?
    require_relative '../lib/bdf-finder.rb'
    require 'sinatra/reloader'
else
    require 'finder'
end

File.open("../.bdf-cli.conf","r") do |file|
	file.each do |line|
		next if line[0] == '#'
		key, value = line.split(':') 
		case key
		when "def_index"
			@def_index = value.downcase.chomp
		when "indexes"
			@indexes = values.split(',')
		else 
			raise "Config file entain wrong fields!"
		end
	end
end

configure do
    set :port, 1234
    enable :session
end

get '/' do
    @title = "BiodataFinder - Home"
    slim :home
end

get '/about' do
    slim :about
end
get '/search' do
    @title = "BDF search"
    @search
    slim :search
end

post '/results' do
    begin
        @title = "Results for '#{params[:search]}'"
        @searched = params[:search].to_s
        client = (Elasticsearch::Client.new)
        @sindex = params[:index] || @def_index #|| raise "Index lacks!"
        finder = Finder.new(client, @sindex)
        query_text = @searched
        results = (finder.query query_text, 'rawline')
        @str_res = ""
		unless results.any? 
			@res_preamble = "Sorry, I can't find anything for this search terms."
		else
        	@res_preamble = "#{results[:gen_infos][:nres]} result(s) found (max score #{results[:gen_infos][:max_scores]}):\n"
        	results[:objs].each_with_index do |obj,i|
				@str_res << "<p>Result #{i+1} (score #{obj[:infos][:scores]}):\n</p>"
				@str_res << obj[:data]
			end
		end
        slim :results
    rescue Faraday::ConnectionFailed => exc
        slim :es_error
    end
end

not_found do
    slim :not_found
end

