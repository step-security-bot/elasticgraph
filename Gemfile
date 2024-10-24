# Copyright 2024 Block, Inc.
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# frozen_string_literal: true

source "https://rubygems.org"

# Since this file gets symlinked both at the repo root and into each Gem directory, we have
# to dynamically detect the repo root, by looking for the `.git` directory.
repo_root = ::Pathname.new(::Dir.pwd).ascend.find { |dir| ::Dir.exist?("#{dir}/.git") }.to_s

# `tmp` and `log` are git-ignored but many of our build tasks and scripts expect them to exist.
# We create them here since `Gemfile` evaluation happens before anything else.
::FileUtils.mkdir_p("#{repo_root}/log")
::FileUtils.mkdir_p("#{repo_root}/tmp")

# Identify the gems that live in the ElasticGraph repository.
require "#{repo_root}/script/list_eg_gems"
gems_in_this_repo = ::ElasticGraphGems.list.to_set

# Here we override the `gem` method to automatically add the ElasticGraph version
# to all ElasticGraph gems. If we don't do this, we can get confusing bundler warnings
# like:
#
# A gemspec development dependency (elasticgraph-schema_definition, = 0.17.1.0) is being overridden by a Gemfile dependency (elasticgraph-schema_definition, >= 0).
# This behaviour may change in the future. Please remove either of them, or make sure they both have the same requirement
#
# This is necessary because our `gemspec` call below registers a `gem` for the gem defined by the gemspec, but it does not include
# a version requirement, and bundler gets confused when other gems have dependencies on the same gem with a version requirement.
# This ensures that we always have the same version requirements for all ElasticGraph gems.
define_singleton_method :gem do |name, *args|
  if gems_in_this_repo.include?(name)
    args.unshift ::ElasticGraph::VERSION unless args.first.include?(::ElasticGraph::VERSION)
  end

  super(name, *args)
end

# This file is symlinked from the repo root into each gem directory. To detect which case we're in,
# we can compare the the current directory to the repo root.
if repo_root == __dir__
  # When we are at the root, we want to load the gemspecs for each ElasticGraph gem in the repository.
  gems_in_this_repo.sort.each do |gem_name|
    gemspec path: gem_name
  end
else
  # Otherwise, we just load the local `.gemspec` file in the current directory.
  gemspec

  # After loading the gemspec, we want to explicitly tell bundler where to find each of the ElasticGraph
  # gems that live in this repository. Otherwise, it will try to look in system gems or on a remote
  # gemserver for them.
  #
  # Bundler stores all loaded gemspecs in `@gemspecs` so here we get the gemspec that was just loaded
  if (loaded_gemspec = @gemspecs.last)

    # This set will keep track of which gems have been registered so far, so we never register an
    # ElasticGraph gem more than once.
    registered_gems = ::Set.new

    register_gemspec_gems_with_path = lambda do |deps|
      deps.each do |dep|
        next unless gems_in_this_repo.include?(dep.name) && !registered_gems.include?(dep.name)

        dep_path = "#{repo_root}/#{dep.name}"
        gem dep.name, path: dep_path

        # record the fact that this gem has been registered so that we don't try calling `gem` for it again.
        registered_gems << dep.name

        # Finally, load the gemspec and recursively apply this process to its runtime dependencies.
        # Notably, we avoid using `.dependencies` because we do not want development dependencies to
        # be registered as part of this.
        runtime_dependencies = ::Bundler.load_gemspec("#{dep_path}/#{dep.name}.gemspec").runtime_dependencies
        register_gemspec_gems_with_path.call(runtime_dependencies)
      end
    end

    # Ensure that the recursive lambda above doesn't try to re-register the loaded gemspec's gem.
    registered_gems << loaded_gemspec.name

    # Here we begin the process of registering the ElasticGraph gems we need to include in the current
    # bundle. We use `loaded_gemspec.dependencies` to include development and runtime dependencies.
    # For the "outer" gem identified by our loaded gemspec, we need the bundle to include both its
    # runtime and development dependencies. In contrast, when we recurse, we only look at runtime
    # dependencies. We are ok with transitive runtime dependencies being pulled in but we don't want
    # transitive development dependencies.
    register_gemspec_gems_with_path.call(loaded_gemspec.dependencies)
  end
end

# Documentation generation gems
group :site do
  gem "filewatcher", "~> 2.1"
  gem "jekyll", "~> 4.3"
  gem "yard", "~> 0.9", ">= 0.9.36"
  gem "yard-doctest", "~> 0.1", ">= 0.1.17"
end

custom_gem_file = ::File.join(repo_root, "Gemfile-custom")
eval_gemfile(custom_gem_file) if ::File.exist?(custom_gem_file)
