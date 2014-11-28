#!/usr/bin/env ruby
#Sinatra sample test

require 'sinatra'
require 'slim'
require 'sinatra/reloader' if development?
if development?
  require_relative '../lib/bdf-finder.rb'
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
    @title = "You have search:"
    @searched = params[:search].to_s
    client = (Elasticsearch::Client.new)
    index = "a3"
    finder = Finder.new(client, index)
    query_text = @searched
    results = (finder.query query_text, 'pretty_json')
    @str_res = ""
    @str_res << "#{results[:gen_infos][:nres]} result(s) found (max score #{results[:gen_infos][:max_scores]}):\n"
    results[:objs].each_with_index do |obj,i|
        @str_res << "Result #{i+1} (score #{obj[:infos][:scores]}):\n"
        @str_res << obj[:data]
    end
    slim :results
end

not_found do
    erb :not_found
end

