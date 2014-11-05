require 'slim'
require 'sinatra'
require 'stretcher'

configure do
  ES = Stretcher::Server.new('http://localhost:9200')
end

class Biodata
  def self.match(text: 'elasticsearch', size: 1000)
    ES.index(:a3).search size: size, query: {
      match: { text: text }
    }
  end
end

get "/" do
  redirect "/elasticsearch"
end

get "/:word" do
  slim :index, locals: {
    biodata: Biodata.match(text: params[:word])
  }
end

