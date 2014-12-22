Gem::Specification.new do |s|
  s.name        = 'biodatafinder'
  s.version     = '0.1.16.pre'
  s.date        = '2014-12-22'
  s.add_runtime_dependency "json", ["~> 1.8"]
  s.add_runtime_dependency "elasticsearch", ["~> 1.0"]
  s.add_runtime_dependency "thor", ["~> 0.18"]
  s.add_runtime_dependency "sassy", ["~> 1.0"]
  s.add_runtime_dependency "sass", ["~> 3.4.9"]
  s.add_runtime_dependency "progressbar", ["~> 0.9"]
  s.add_runtime_dependency "sinatra", ["~> 1.4.5"]
  s.add_runtime_dependency "sinatra-contrib", ["~> 1.4.2"]
  s.summary     = "Gem for indexing and searching biodata files"
  s.description = "
  # BiodataFinder
  
  This gem allow you to index some biodata files (currently only gtf and tracking files) in an ElasticSearch index and then 
  make some full text search over it. 
  
  BiodataFinder currently has two interfaces, a command-line interface (bdf-cli) and a web Sinatra interface (bdf-si). 
  Both interfaces need to work a running instance of ElasticSearch running on port 9200.
  
  Currently BDF support only GTF and Tracking filetypes.
  
  *Warning* Keep in mind that this project is in a very alpha state and it's not ready for production systems.
  "
  s.authors     = ["Alessandro Bonfanti"]
  s.email       = 'swalf@users.noreply.github.com'
  s.files       = [
	"lib/bdf-finder.rb",
	"lib/bdf-indexer.rb",
	"bin/bdf-cli",
	"bin/bdf-si",
	"lib/biodatafinder/parse_gtf.rb",
	"lib/biodatafinder/parse_tracking.rb",
	"lib/biodatafinder/reconstruct_gtf.rb",
	"lib/biodatafinder/reconstruct_tracking.rb",
	"app/public/favicon.ico",
	"app/public/images/logo.png",
	"app/views/nav.erb", 
	"app/views/es_error.erb",
	"app/views/not_found.erb", 
	"app/views/search.erb",
	"app/views/search_inline.erb",
	"app/views/layout.erb",
	"app/views/styles.scss", 
	"app/views/restable.erb", 
	"app/views/about.erb"
  ]

  s.executables << 'bdf-cli'
  s.executables << 'bdf-si'
  s.homepage    =
    'https://github.com/swalf/BiodataFinder'
  s.license       = 'GPLv3'
end
