# Copyright 2024 Block, Inc.
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# frozen_string_literal: true

require_relative "../gemspec_helper"

ElasticGraphGemspecHelper.define_elasticgraph_gem(gemspec_file: __FILE__, category: :core) do |spec, eg_version|
  spec.summary = "ElasticGraph gem providing support utilities to the other ElasticGraph gems."

  # Ruby 3.4 warns about using `logger` being moved out of the standard library, and in Ruby 3.5
  # it'll no longer be available without declaring a dependency.
  #
  # Note: Logger 1.6.0 has an issue that impacts our ElasticGraph lambdas, but 1.6.1 avoids the issue:
  # https://github.com/aws/aws-lambda-ruby-runtime-interface-client/issues/33
  spec.add_dependency "logger", "~> 1.6", ">= 1.6.2"

  spec.add_development_dependency "faraday", "~> 2.12"
  spec.add_development_dependency "rake", "~> 13.2"
end
