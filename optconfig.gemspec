Gem::Specification.new do |s|
  s.name = 'optconfig'
  s.version = '0.4.5'
  s.summary = 'OptConfig is a parser of command line option'
  s.authors = ['Tomita Masahiro']
  s.date = '2011-12-07'
  s.description = 'OptConfig is a parser of command line option'
  s.email = 'tommy@tmtm.org'
  s.homepage = 'http://github.com/tmtm/optconfig'
  s.files = ['lib/optconfig.rb']
  s.test_files = ['spec/optconfig_spec.rb']
  s.add_dependency 'stringvalidator'
  s.has_rdoc = true
  s.license = 'Ruby\'s'
end
