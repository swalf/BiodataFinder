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

configure do
    set :port, 1234
    enable :session
end

get '/' do
    @title = "A tool for searching in biodata files."
    slim :home
end

get '/about' do
    slim :about
end
get '/search' do
    @title = "Enter a new search!"
    @search
    slim :search
end

post '/results' do
    begin
        @title = "You have search:"
        @searched = params[:search].to_s
        client = (Elasticsearch::Client.new)
        index = "a3"
        finder = Finder.new(client, index)
        query_text = @searched
        results = (finder.query query_text, 'rawline')
        @str_res = ""
        @str_res << "#{results[:gen_infos][:nres]} result(s) found (max score #{results[:gen_infos][:max_scores]}):\n"
        results[:objs].each_with_index do |obj,i|
            @str_res << "<p>Result #{i+1} (score #{obj[:infos][:scores]}):\n</p>"
            @str_res << obj[:data]
        end
        slim :results
    rescue Faraday::ConnectionFailed => exc
        slim :es_error
    end
end

not_found do
    slim :not_found
end

