# Copyright 2024 Block, Inc.
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# frozen_string_literal: true

require_relative "../gemspec_helper"

ElasticGraphGemspecHelper.define_elasticgraph_gem(gemspec_file: __FILE__, category: :lambda) do |spec, eg_version|
  spec.summary = "ElasticGraph gem that supports running ElasticGraph using AWS Lambda."

  spec.add_dependency "elasticgraph-opensearch", eg_version
  spec.add_dependency "faraday_middleware-aws-sigv4", "~> 1.0"

  spec.add_development_dependency "elasticgraph-admin", eg_version
  spec.add_development_dependency "elasticgraph-graphql", eg_version
  spec.add_development_dependency "elasticgraph-indexer", eg_version
  spec.add_development_dependency "elasticgraph-indexer_autoscaler_lambda", eg_version
  spec.add_development_dependency "httpx", "~> 1.3"
end
