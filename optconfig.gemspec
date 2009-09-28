Gem::Specification.new do |s|
  s.name = 'optconfig'
  s.version = '0.4.4'
  s.summary = 'OptConfig is a parser of command line option'
  s.authors = ['Tomita Masahiro']
  s.date = '2009-09-28'
  s.description = 'OptConfig is a parser of command line option'
  s.email = 'tommy@tmtm.org'
  s.homepage = 'http://github.com/tmtm/optconfig'
  s.files = [
    "lib/optconfig.rb",
  ]
  s.add_dependency 'stringvalidator'
  s.rubyforge_project = 'optconfig'
  s.has_rdoc = true
  s.rdoc_options = [
    "--charset=utf-8",
  ]
  s.rubygems_version = '1.3.0'
end
