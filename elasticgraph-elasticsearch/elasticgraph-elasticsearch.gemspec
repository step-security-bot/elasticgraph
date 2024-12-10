# Copyright 2024 Block, Inc.
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# frozen_string_literal: true

require_relative "../gemspec_helper"

ElasticGraphGemspecHelper.define_elasticgraph_gem(gemspec_file: __FILE__, category: :datastore_adapter) do |spec, eg_version|
  spec.summary = "Wraps the Elasticsearch client for use by ElasticGraph."

  spec.add_dependency "elasticgraph-support", eg_version
  spec.add_dependency "elasticsearch", "~> 8.16"
  spec.add_dependency "faraday", "~> 2.12"
  spec.add_dependency "faraday-retry", "~> 2.2"

  spec.add_development_dependency "httpx", "~> 1.3"
end
