# Copyright 2024 Block, Inc.
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# frozen_string_literal: true

require_relative "../gemspec_helper"

ElasticGraphGemspecHelper.define_elasticgraph_gem(gemspec_file: __FILE__, category: :local) do |spec, eg_version|
  spec.summary = "Provides support for developing and running ElasticGraph applications locally."

  spec.add_dependency "elasticgraph-admin", eg_version
  spec.add_dependency "elasticgraph-graphql", eg_version
  spec.add_dependency "elasticgraph-indexer", eg_version
  spec.add_dependency "elasticgraph-rack", eg_version
  spec.add_dependency "elasticgraph-schema_definition", eg_version
  spec.add_dependency "rackup", "~> 2.1"
  spec.add_dependency "rake", "~> 13.2"

  spec.add_development_dependency "elasticgraph-elasticsearch", eg_version
  spec.add_development_dependency "elasticgraph-opensearch", eg_version
  spec.add_development_dependency "httpx", "~> 1.3"
end
