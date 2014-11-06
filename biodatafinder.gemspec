Gem::Specification.new do |s|
  s.name        = 'biodatafinder'
  s.version     = '0.0.2.pre'
  s.date        = '2014-11-05'
  s.add_runtime_dependency "json", ["~> 1.8"]
  s.add_runtime_dependency "elasticsearch", ["~> 1.0"]
  s.add_runtime_dependency "thor", ["~> 0.18"]
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
    "lib/finder.rb",
    "lib/indexer.rb",
    "bin/bdf-cli",
    "bin/bdf-si",
    "lib/biodatafinder/indexercodes.rb",
    "lib/biodatafinder/reconstructorcodes.rb"
  ]
  s.executables << 'bdf-cli'
  s.executables << 'bdf-si'
  s.homepage    =
    'https://github.com/swalf/BiodataFinder'
  s.license       = 'GPLv3'
end