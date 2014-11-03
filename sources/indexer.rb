#!/usr/bin/env ruby
# indexer

require "json"
require "elasticsearch"
require_relative "indexercodes.rb"


class Indexer
    #extend FileExt
    attr_accessor :client, :index
    
    def initialize (client, index)
        @client, @index = client, index
    end

    def parse (filepath)
         mn = "#{File.extname(filepath)[1..-1].capitalize}_code"
         puts mn
         IndexerCodes.const_get(mn).call self, filepath  #costruisce il nome dell'oggetto dalla stringa     
    end

    

    def load_document (document, type)
        @client.index  index: @index.to_s.downcase, type: type, body: document
        #puts "index: #{@index} type: #{type} body #{document}"
    end
       
end

