Gem::Specification.new do |s|
  s.name        = 'biodatafinder'
  s.version     = '0.0.6.pre'
  s.date        = '2014-12-01'
  s.add_runtime_dependency "json", ["~> 1.8"]
  s.add_runtime_dependency "elasticsearch", ["~> 1.0"]
  s.add_runtime_dependency "thor", ["~> 0.18"]
  s.add_runtime_dependency "slim", ["~> 2.0"]
  s.add_runtime_dependency "sassy", ["~> 1.0"]
  s.summary     = "Gem for indexing and searching biodata files"
  s.description = "
  # BiodataFinder
  
  This gem allow you to index some biodata files (currently only gtf and tracking files) in an ElasticSearch index and then 
  make some full text search over it. 
  
  *Warning* Keep in mind that this project is in a very alpha state and it's not ready for production systems.
  "
  s.authors     = ["Alessandro Bonfanti"]
  s.email       = 'swalf@users.noreply.github.com'
  s.files       = [
    "lib/bdf-finder.rb",
    "lib/bdf-indexer.rb",
    "bin/bdf-cli",
    "bin/bdf-si",
    "lib/biodatafinder/indexercodes.rb",
    "lib/biodatafinder/reconstructorcodes.rb",
	"public/favicon.ico",
	"public/images/logo.png",
	"views/nav.slim",
	"views/home.slim", 
	"views/es_error.slim",
	"views/not_found.slim", 
	"views/search.slim",
	"views/layout.slim",
	"views/styles.scss", 
	"views/results.slim", 
	"views/about.slim"
  ]

  s.executables << 'bdf-cli'
  s.executables << 'bdf-si'
  s.homepage    =
    'https://github.com/swalf/BiodataFinder'
  s.license       = 'GPLv3'
end