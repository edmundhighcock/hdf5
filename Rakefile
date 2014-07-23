# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://guides.rubygems.org/specification-reference/ for more options
  gem.name = "hdf5"
  gem.homepage = "http://github.com/edmundhighcock/hdf5"
  gem.license = "GPLv3"
  gem.summary = %Q{A ruby wrapper to the HDF5 data library. Currently can only read existing HDF5 files.}
  gem.description = %Q{A ruby wrapper to the HDF5 data library. Currently can only read HDF5 files.}
  gem.email = "edmundhighcock@users.sourceforge.net"
  gem.authors = ["Edmund Highcock"]
	gem.files.exclude 'test/**/*'
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

desc "Code coverage detail"
task :simplecov do
  ENV['COVERAGE'] = "true"
  Rake::Task['test'].execute
end

require "rake/extensiontask"

NAME = 'hdf5'

Rake::ExtensionTask.new "hdf5" do |ext|
	  ext.lib_dir = "lib/hdf5"
end

task :default => :test

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "hdf5 #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
