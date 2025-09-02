# frozen_string_literal: true

require "bundler/gem_tasks"

# Add custom tasks if needed
namespace :gem do
  desc "Build the gem"
  task :build do
    require "rubygems/package"
    require "rubygems/specification"
    
    # Load the gemspec
    spec = Gem::Specification.load("multiplayer_otlp.gemspec")
    
    # Build the gem
    Gem::Package.build(spec)
    
    puts "Built gem: #{spec.full_name}.gem"
  end
  
  desc "Install the gem locally"
  task :install do
    require "rubygems/installer"
    
    # Find the built gem
    gem_file = Dir["*.gem"].first
    raise "No .gem file found. Run 'rake gem:build' first." unless gem_file
    
    # Install the gem
    Gem::Installer.new(gem_file).install
    puts "Installed gem: #{gem_file}"
  end
end

# Default task
task default: :build
