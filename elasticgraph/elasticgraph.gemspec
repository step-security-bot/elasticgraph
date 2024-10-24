# Copyright 2024 Block, Inc.
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# frozen_string_literal: true

require_relative "../gemspec_helper"

ElasticGraphGemspecHelper.define_elasticgraph_gem(gemspec_file: __FILE__, category: :core) do |spec, eg_version|
  spec.summary = "ElasticGraph meta-gem that pulls in all the core ElasticGraph gems."

  spec.add_dependency "elasticgraph-admin", eg_version
  spec.add_dependency "elasticgraph-graphql", eg_version
  spec.add_dependency "elasticgraph-indexer", eg_version
  spec.add_dependency "elasticgraph-local", eg_version
end
