all:
	ruby ./setup.rb config
	ruby ./setup.rb setup

install:
	ruby ./setup.rb install

test:
	ruby -I. spec/optconfig_spec.rb

doc: lib/optconfig.rb
	rdoc -t OptConfig -c utf-8 lib/optconfig.rb
