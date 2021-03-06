$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$:.unshift File.dirname(__FILE__)

require "bundler/setup"
require 'rubygems'
require 'rspec'
require 'yaml'
require 'open-uri/cached'
require 'rdf/isomorphic'
require 'rdf/spec'
require 'rdf/spec/matchers'
require 'matchers'
require 'rdf/turtle'
require 'rdf/vocab'
begin
  require 'nokogiri'
rescue LoadError
end
begin
  require 'simplecov'
  require 'coveralls'
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ])
  SimpleCov.start do
    add_filter "/spec/"
    add_filter "/lib/rdf/rdfa/reader/rexml.rb"
    add_filter "/lib/rdf/rdfa/context.rb"
  end
rescue LoadError
end
require 'rdf/rdfa'

# Create and maintain a cache of downloaded URIs
URI_CACHE = File.expand_path(File.join(File.dirname(__FILE__), "uri-cache"))
Dir.mkdir(URI_CACHE) unless File.directory?(URI_CACHE)
OpenURI::Cache.class_eval { @cache_path = URI_CACHE }

::RSpec.configure do |c|
  c.filter_run focus: true
  c.run_all_when_everything_filtered = true
  c.exclusion_filter = {
    ruby:     lambda { |version| !(RUBY_VERSION.to_s =~ /^#{version}/) },
  }
  c.include(RDF::Spec::Matchers)
end

# For testing, modify RDF::Util::File.open_file to use Kernel.open, so we can just use open-uri-cached
module RDF::Util::File
  def self.open_file(filename_or_url, options = {}, &block)
    options = options[:headers] || {} if filename_or_url.start_with?('http')
    Kernel.open(filename_or_url, options, &block)
  end
end

TMP_DIR = File.join(File.expand_path(File.dirname(__FILE__)), "tmp")

# Heuristically detect the input stream
def detect_format(stream)
  # Got to look into the file to see
  if stream.is_a?(IO) || stream.is_a?(StringIO)
    stream.rewind
    string = stream.read(1000)
    stream.rewind
  else
    string = stream.to_s
  end
  case string
  when /<html/i   then RDF::RDFa::Reader
  when /@prefix/i then RDF::Turtle::Reader
  else                 RDF::NTriples::Reader
  end
end
