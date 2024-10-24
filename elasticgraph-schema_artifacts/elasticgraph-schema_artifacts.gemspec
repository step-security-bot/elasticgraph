# Copyright 2024 Block, Inc.
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# frozen_string_literal: true

require_relative "../gemspec_helper"

ElasticGraphGemspecHelper.define_elasticgraph_gem(gemspec_file: __FILE__, category: :core) do |spec, eg_version|
  spec.summary = "ElasticGraph gem containing code related to generated schema artifacts."

  spec.add_dependency "elasticgraph-support", eg_version

  # Necessary since `ScalarType` references coercion adapters defined in the `elasticgraph-graphql` gem.
  spec.add_development_dependency "elasticgraph-graphql", eg_version

  # Necessary since `ScalarType` references indexing preparer defined in the `elasticgraph-indexer` gem.
  spec.add_development_dependency "elasticgraph-indexer", eg_version
end
