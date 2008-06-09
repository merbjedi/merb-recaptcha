require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'rake/packagetask'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/contrib/rubyforgepublisher'
require 'fileutils'
require 'hoe'
include FileUtils
require File.join(File.dirname(__FILE__), 'lib', 'recaptcha', 'version')

AUTHOR = 'Felix McCoey'  # can also be an array of Authors
EMAIL = "felix.mccoey@gmail.com"
DESCRIPTION = "ReCaptcha gem for Merb"
GEM_NAME = 'merb_recaptcha' # what ppl will type to install your gem
#RUBYFORGE_PROJECT = 'recaptcha' # The unix name for your project
#HOMEPATH = "http://#{RUBYFORGE_PROJECT}.rubyforge.org"


NAME = "merb_recaptcha"
REV = nil
VERS = ENV['VERSION'] || (MerbRecaptcha::VERSION::STRING + (REV ? ".#{REV}" : ""))
CLEAN.include ['**/.*.sw?', '*.gem', '.config', '**/.DS_Store']
RDOC_OPTS = ['--quiet', '--title', 'merb_recaptcha documentation',
    "--opname", "index.html",
    "--line-numbers", 
    "--main", "README",
    "--inline-source"]

class Hoe
  def extra_deps 
    @extra_deps.reject { |x| Array(x).first == 'hoe' } 
  end 
end

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
hoe = Hoe.new(GEM_NAME, VERS) do |p|
  p.author = AUTHOR 
  p.description = DESCRIPTION
  p.email = EMAIL
  p.summary = DESCRIPTION
  p.url = HOMEPATH
  p.rubyforge_name = RUBYFORGE_PROJECT if RUBYFORGE_PROJECT
  p.test_globs = ["test/**/test_*.rb"]
  p.clean_globs = CLEAN  #An array of file patterns to delete on clean.
  
  # == Optional
#  `hg history lib/recaptcha.rb>History.txt` 
#  p.changes = p.paragraphs_of("History.txt", 0..1).join("\n\n")
  #p.extra_deps = []     # An array of rubygem dependencies [name, version], e.g. [ ['active_support', '>= 1.3.1'] ]
  p.spec_extras = {:platform=>'ruby'}    # A hash of extra values to set in the gemspec.
end
