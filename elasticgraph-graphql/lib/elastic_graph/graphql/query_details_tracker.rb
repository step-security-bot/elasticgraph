# Copyright 2024 Block, Inc.
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# frozen_string_literal: true

require "elastic_graph/graphql/client"
require "elastic_graph/support/hash_util"
require "graphql"

module ElasticGraph
  class GraphQL
    # Class used to track details of what happens during a single GraphQL query for the purposes of logging.
    # Here we use `Struct` instead of `Data` specifically because it is designed to be mutable.
    class QueryDetailsTracker < Struct.new(
      :hidden_types,
      :shard_routing_values,
      :search_index_expressions,
      :query_counts_per_datastore_request,
      :datastore_query_server_duration_ms,
      :datastore_query_client_duration_ms,
      :mutex
    )
      def self.empty
        new(
          hidden_types: ::Set.new,
          shard_routing_values: ::Set.new,
          search_index_expressions: ::Set.new,
          query_counts_per_datastore_request: [],
          datastore_query_server_duration_ms: 0,
          datastore_query_client_duration_ms: 0,
          mutex: ::Thread::Mutex.new
        )
      end

      def record_datastore_queries_for_single_request(queries)
        mutex.synchronize do
          shard_routing_values.merge(queries.flat_map { |q| q.shard_routing_values || [] })
          search_index_expressions.merge(queries.map(&:search_index_expression))
          query_counts_per_datastore_request << queries.size
        end
      end

      def record_hidden_type(type)
        mutex.synchronize do
          hidden_types << type
        end
      end

      def record_datastore_query_duration_ms(client:, server:)
        mutex.synchronize do
          self.datastore_query_client_duration_ms += client
          self.datastore_query_server_duration_ms += server if server
        end
      end
    end
  end
end
