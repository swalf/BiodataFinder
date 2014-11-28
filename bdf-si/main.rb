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

post '/searched' do
    @title = "You have search:"
    @searched = params[:search].to_s
    client = (Elasticsearch::Client.new)
    index = "blog"
    finder = Finder.new(client, index)
    query_text = @searched
    @results = (finder.query query_text, 'pretty_json')
    slim :searched
end

not_found do
    erb :not_found
end
=begin
  get '/search/:index/:text' do
    client = Elasticsearch::Client.new log: true
    index = params[:index]
    #index = @def_index if index.nil?
    #raise "If you don't specify an espicit index, you have to set default index key with setdef command." if index.nil?
    finder = Finder.new(client, index)
    query_text = params[:text].split('_').join(' ')
    res = (finder.query query_text, 'rawline')
    res
  end
=end  


__END__
@@layout
doctype html
html lang="en"
  head
    title== @title || "BiodataFinder"
    meta charset="utf-8"
    link rel="stylesheet" href="/styles.css"
  body
    header
      h1 BiodataFinder
      h2== @title || "Boh!"
      nav
        ul
          li <a href="/" title="Home">Home</a>
          li <a href="/search" title="Search">Search</a>
          li <a href="/about" title="About">About</a>
    section
      == yield

@@home
p Welcome in the alpha stage BDF web interface for searching.


@@searched
p Theese are the results of your search:
p== @results
p Enjoy your life!

@@about
p This software is written by Alessandro Bonfanti and licenced under GNU GPLv3

@@not_found
h2 404!
p The page you are looking for is missing. Why not go back to the <a href='/'>home page</a> and start over?



