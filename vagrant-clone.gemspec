# coding: utf-8
require File.expand_path('../lib/vagrant-clone/version', __FILE__)

Gem::Specification.new do |spec|
  spec.name          = 'vagrant-clone'
  spec.version       = VagrantClone::VERSION
  spec.authors       = ['Alexander Kaluzny']
  spec.email         = ['galiaf1995@gmail.com']

  spec.summary       = 'Plugin for creating and managing clones of VM(s)'
  spec.description   = 'Plugin for creating and managing clones of VM(s)'
  spec.homepage      = 'https://bitbucket.org/galiaf95/vagrant-clone'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.13'
  spec.add_development_dependency 'rake', '~> 10.0'
end
