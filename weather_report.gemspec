# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{weather_report}
  s.version = "0.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Charles Cordingley"]
  s.date = %q{2009-07-17}
  s.description = %q{Connect to the BBC Backstage (http://backstage.bbc.co.uk) weather API and get weather observations and forecasts for thousands of cities worldwide. No login is required to the BBC for use.}
  s.email = ["inquiries at cordinc dot com"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.rdoc", "PostInstall.txt"]
  s.files = ["History.txt", "Manifest.txt", "README.rdoc", "PostInstall.txt", "Rakefile", "lib/weather_report.rb", "script/console", "script/console.cmd", "script/destroy", "script/destroy.cmd", "script/generate", "script/generate.cmd", "test/test_helper.rb", "test/test_weather_report.rb"]
  s.has_rdoc = true
  s.homepage = %q{Homepage::  http://www.cordinc.com/projects/weather_report}
  s.post_install_message = %q{PostInstall.txt}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{weather-report}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Connect to the BBC Backstage (http://backstage.bbc.co.uk) weather API and get weather observations and forecasts for thousands of cities worldwide}
  s.test_files = ["test/test_helper.rb", "test/test_weather_report.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<newgem>, [">= 1.3.0"])
      s.add_development_dependency(%q<hoe>, [">= 1.8.0"])
    else
      s.add_dependency(%q<newgem>, [">= 1.3.0"])
      s.add_dependency(%q<hoe>, [">= 1.8.0"])
    end
  else
    s.add_dependency(%q<newgem>, [">= 1.3.0"])
    s.add_dependency(%q<hoe>, [">= 1.8.0"])
  end
end
