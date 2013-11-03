# -*- encoding: utf-8 -*-

require File.expand_path("../lib/rtgrep/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "rtgrep"
  s.version     = Rtgrep::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Brenton "B-Train" Fletcher']
  s.email       = ["i@bloople.net"]
  s.homepage    = "http://github.com/bloopletech/rtgrep"
  s.summary     = "Rtgrep lists vim tags and browses and selects them."
  s.description     = "Rtgrep lists vim tags and browses and selects them."

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "rtgrep"

  s.add_development_dependency "bundler", ">= 1.0.0"
  s.add_dependency "rbcurse-core", "= 0.0.3"

  s.files        = `git ls-files`.split("\n")
  s.executables  = `git ls-files`.split("\n").map{|f| f =~ /^bin\/(.*)/ ? $1 : nil}.compact
  s.require_path = 'lib'
end
