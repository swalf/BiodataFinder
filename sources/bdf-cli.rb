require "thor"
require_relative "indexer.rb"
require_relative "finder.rb"
require 'elasticsearch'

class BDFcli < Thor
    @def_index
    
    private
    
    def load_setup
        unless File.exist? "./.bdf-cli.conf"
            File.open("./.bdf-cli.conf", "w").puts "# bdf-cli config file:", "# sintax 'key':'value'"
        end
        File.open("./.bdf-cli.conf","r") do |file|
            file.each do |line|
                next if line[0] == '#'
                key, value = line.split(':') 
                case key
                when "def_index"
                    @def_index = value.downcase.chomp
                else 
                    raise "Config file entain wrong fields!"
                end
            end
        end
    rescue RuntimeError => exc
        if exc.message == "Config file entain wrong fields!"
            $stderr.puts "Error: #{exc.message}",
              "Config file will be not loaded."
        else
            $stderr.puts "Error: #{exc.message}"
        end
    end
    
    public
        
    desc "index FILEPATH", "Index a specificated file"
    method_option :index, :aliases => "-i", :desc => "Specify the index where the input file will be indexed, elsewere were used default"
    method_option :filetype, :aliases => "-t", :desc => "Specify the filetype, elsewere indexer will try to deduce filetype from extension"
    def index (filepath)
        load_setup
        if options[:index] != nil
            index = options[:index]
        else
            if @def_index != nil
                index = options[:index]
            else
                raise "If you don't specify an espicit index, you have to set default index key with setdef command."
            end
        end
        client = Elasticsearch::Client.new log: false
        indexer = Indexer.new client, index
        indexer.parse filepath, options[:filetype]    
    rescue RuntimeError => exc
        $stderr.puts "ERROR: " + exc.to_s
    end
    
    desc "setdef --FIELD_NAME=VALUE", "Set the default fields to a value"
    method_option :index, :aliases => "-i", :desc => "Set the default index name"
    def setdef
        load_setup
        options.each_pair do |field,value|  
            case field
            when "index"
                @def_index = value
                File.open("./.bdf-cli.conf", "a").puts "def_index:#{value}"  
                puts "Default index = #{@def_index}"
            else
                raise "Wrong field!"
            end
        end
    rescue RuntimeError => exc
        $stderr.puts "ERROR: " + exc.to_s        
    end
    
    desc "search TEXT TO SEARCH", "Search a string of text in an index"
    method_option :index, :aliases => "-i", :desc => "Specifify in which index search will be implemented, '*' for all indeces, elsewere default will be used."
    method_option :output_format, :aliases => "-f", :desc => "Specify the format of output, allovable values are 'json', 'rawline', 'pretty_output'."
    def search (*text)
        load_setup
        client = Elasticsearch::Client.new log: true
        index = options[:index]
        index = @def_index if index.nil?
        raise "If you don't specify an espicit index, you have to set default index key with setdef command." if index.nil?
        finder = Finder.new(client, index)
        query_text = text.join(' ')
        puts (finder.query query_text, options[:output_format])
    end
    
end

BDFcli.start ARGV