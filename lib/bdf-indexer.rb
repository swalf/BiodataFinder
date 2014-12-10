# indexer

require 'json'
require 'elasticsearch'
require_relative 'biodatafinder/indexercodes.rb'


class Indexer
    #extend FileExt
    attr_accessor :client, :index
    
    def initialize (client, index)
        @client, @index = client, index
    end

    def parse (filepath, filetype = nil)
        if filetype == nil
            mn = "#{File.extname(filepath)[1..-1].capitalize}_code"
        else
            mn = "#{filetype.capitalize}_code"
        end
        
        IndexerCodes.const_get(mn).call self, filepath  #costruisce il nome dell'oggetto dalla stringa
    rescue NameError => e #name error è troppo generica, bisognerebbe catturare un eccezione più specifica
        $stderr.puts e.message 
        $stderr.puts "#{filepath}: Parsing for this filetype (#{filetype}) isn't yet implemented."
    end

    

    def load_document (document, type)
        @client.index  index: @index.to_s.downcase, type: type, body: document
    end
    
    def load_pool (docpool, type)
        body = []
        docpool.each do |doc|
            body << { index:  { _index: @index.to_s.downcase, _type: type, data: doc } }
        end
        @client.bulk body: body
    end
       
end

