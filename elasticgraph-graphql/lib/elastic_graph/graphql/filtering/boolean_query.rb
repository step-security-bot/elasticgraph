# Copyright 2024 Block, Inc.
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# frozen_string_literal: true

module ElasticGraph
  class GraphQL
    module Filtering
      # BooleanQuery is an internal class for composing a datastore query:
      # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-bool-query.html
      #
      # It is composed of:
      #   1) The occurrence type (:must, :filter, :should, or :must_not)
      #   2) A list of query clauses evaluated by the given occurrence type
      #   3) An optional flag indicating whether the occurrence should be negated
      class BooleanQuery < ::Data.define(:occurrence, :clauses)
        def self.must(*clauses)
          new(:must, clauses)
        end

        def self.filter(*clauses)
          new(:filter, clauses)
        end

        def self.should(*clauses)
          new(:should, clauses)
        end

        def merge_into(bool_node)
          bool_node[occurrence].concat(clauses)
        end

        # For `any_of: []` we need a way to force the datastore to match no documents, but
        # I haven't found any sort of literal `false` we can pass in the compound expression
        # or even a literal `1 = 0` as is sometimes used in SQL. Instead, we use this for that
        # case.
        empty_array = [] # : ::Array[untyped]
        ALWAYS_FALSE_FILTER = filter({ids: {values: empty_array}})
      end
    end
  end
end
