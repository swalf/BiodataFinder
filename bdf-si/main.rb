#!/usr/bin/env ruby
#Sinatra sample test

require 'sinatra'
require 'slim'
require 'sinatra/reloader' if development?
#require 'finder'

configure do
    set :port, 1234
    enable :session
end

get '/' do
    erb :home
end

get '/about' do
    erb :about
end
get '/search' do
    @search
    slim :search
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
<% title="BiodataFinder" %>
<!doctype html>
<html lang="en">
    <head>
        <title><%= title %></title>
        <meta charset="utf-8">
        <link rel="stylesheet" href="styles.css">
    </head>
    <body>
        <header>
            <h1><%= title %></h1>
            <nav>
                <ul>
                    <li><a href="/" title="Home">Home</a></li>
                    <li><a href="/about" title="About">About</a></li>
                    <li><a href="/search" title="Search">Search</a></li>
                </ul>
            </nav>
        </header>
        <section>
            <%= yield %>
        </section>
    </body>
</html>

@@home
<p>Welcome in the alpha stage BDF web interface for searching.</p>
<img src="/images/13671.gif" alt="BDF-img">

@@about
<p>This software is written by Alessandro Bonfanti and licenced under GNU GPLv3</p>

@@not_found
<h2>4 Oh 4!</h2>
<p> The page you are looking for is missing. Why not go back to the
<a href='/'>home page</a> and start over?</p>



