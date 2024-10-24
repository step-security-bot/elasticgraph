# Copyright 2024 Block, Inc.
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# frozen_string_literal: true

require_relative "../gemspec_helper"

ElasticGraphGemspecHelper.define_elasticgraph_gem(gemspec_file: __FILE__, category: :local) do |spec, eg_version|
  spec.summary = "ElasticGraph gem for serving an ElasticGraph GraphQL endpoint using rack."

  spec.add_dependency "elasticgraph-graphql", eg_version
  spec.add_dependency "rack", "~> 3.1"

  spec.add_development_dependency "elasticgraph-admin", eg_version
  spec.add_development_dependency "elasticgraph-elasticsearch", eg_version
  spec.add_development_dependency "elasticgraph-opensearch", eg_version
  spec.add_development_dependency "elasticgraph-indexer", eg_version
  spec.add_development_dependency "rack-test", "~> 2.1"
end
