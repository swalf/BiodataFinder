Gem::Specification.new do |s|
  s.name        = 'biodatafinder'
  s.version     = '0.0.1.pre'
  s.date        = '2014-11-05'
  s.summary     = "Gem for indexing and searching biodata files"
  s.description = "
  ==============
  BiodataFinder
  ==============
  This gem allow you to index some biodata files (currently only gtf and tracking files) in an ElasticSearch index and then 
  make some full text search over it. 
  
  **Warning** Keep in mind that this project is in a very alpha state and it's not ready for production systems.
  "
  s.authors     = ["Alessandro Bonfanti"]
  s.email       = 'swalf@users.noreply.github.com'
  s.files       = [
    "lib/finder.rb",
    "lib/indexer.rb",
    "bin/bdf-cli",
    "lib/biodatafinder/indexercodes.rb",
    "lib/biodatafinder/reconstructorcodes.rb"
  ]
  s.executables << 'bdf-cli'
  s.homepage    =
    'https://github.com/swalf/BiodataFinder'
  s.license       = 'GPLv3'
end