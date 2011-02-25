# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
 
require 'loadbalancers'
 
Gem::Specification.new do |s|
  s.name        = "cloud-loadbalancers"
  s.version     = LoadBalancers::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["H. Wade Minter"]
  s.email       = ["minter@lunenburg.org"]
  s.homepage    = "http://github.com/rackspace/ruby-loadbalancers"
  s.summary     = "Ruby API into the Rackspace Cloud Load Balancers product"
  s.description = "A Ruby API to manage the Rackspace Cloud Load Balancers product"
 
  s.required_rubygems_version = ">= 1.3.6"
 
  s.add_runtime_dependency "typhoeus"
  s.add_runtime_dependency "json"
 
  s.files = [
    "VERSION",
    "COPYING",
    ".gitignore",
    "README.rdoc",
    "loadbalancers.gemspec",
    "lib/loadbalancers.rb",
    "lib/loadbalancers/authentication.rb",
    "lib/loadbalancers/balancer.rb",
    "lib/loadbalancers/connection.rb",
    "lib/loadbalancers/exception.rb",
    "lib/loadbalancers/node.rb",
    "lib/loadbalancers/health_monitor.rb",
    "lib/loadbalancers/connection_throttle.rb"
  ]
  s.require_path = 'lib'
end