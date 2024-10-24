# Copyright 2024 Block, Inc.
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# frozen_string_literal: true

require "elastic_graph/graphql/filtering/filter_value_set_extractor"

module ElasticGraph
  class GraphQL
    class DatastoreQuery
      # Responsible for picking routing values for a specific query based on the filters.
      class RoutingPicker
        def initialize(schema_names:)
          # @type var all_values_set: _RoutingValueSet
          all_values_set = RoutingValueSet::ALL

          @filter_value_set_extractor = Filtering::FilterValueSetExtractor.new(schema_names, all_values_set) do |operator, filter_value|
            if operator == :equal_to_any_of
              # This calls `.compact` to remove `nil` filter_value values
              RoutingValueSet.of(filter_value.compact)
            else # gt, lt, gte, lte, matches
              # With one of these inexact/inequality operators, we don't have a way to precisely represent
              # the set of values. Instead, we represent it with the special UnboundedWithExclusions
              # implementation since when these operators are used the set is unbounded (there's an infinite
              # number of values in the set) but it doesn't contain all values (it has some exclusions).
              RoutingValueSet::UnboundedWithExclusions
            end
          end
        end

        # Given a list of `filter_hashes` and a list of `routing_field_paths`, returns a list of
        # routing values that can safely be used to limit what index shards we search
        # without risking missing any matching documents that could exist on other shards.
        #
        # If an eligible list of routing values cannot be determined, returns `nil`.
        #
        # Importantly, we have to be careful to not return routing values unless we are 100% sure
        # that the set of values will route to the full set of shards on which documents matching
        # the filters could live. If a document matching the filters lived on a shard that our
        # search does not route to, it will not be included in the search response.
        #
        # Essentially, this method guarantees that the following pseudo code is always satisfied:
        #
        # ``` ruby
        # if (routing_values = extract_eligible_routing_values(filter_hashes, routing_field_paths))
        #   Datastore.all_documents_matching(filter_hashes).each do |document|
        #     routing_field_paths.each do |field_path|
        #       expect(routing_values).to include(document.value_at(field_path))
        #     end
        #   end
        # end
        # ```
        def extract_eligible_routing_values(filter_hashes, routing_field_paths)
          @filter_value_set_extractor.extract_filter_value_set(filter_hashes, routing_field_paths).to_return_value
        end
      end

      class RoutingValueSet < Data.define(:type, :routing_values)
        # @dynamic ==

        def self.of(routing_values)
          new(:inclusive, routing_values.to_set)
        end

        def self.of_all_except(routing_values)
          new(:exclusive, routing_values.to_set)
        end

        ALL = of_all_except([])

        def intersection(other_set)
          # Here we return `self` to preserve the commutative property of `intersection`. Returning `self`
          # here matches the behavior of `UnboundedWithExclusions.intersection`. See the comment there for
          # rationale.
          return self if other_set == UnboundedWithExclusions

          # @type var other: RoutingValueSet
          other = _ = other_set

          if inclusive? && other.inclusive?
            # Since both sets are inclusive, we can just delegate to `Set#intersection` here.
            RoutingValueSet.of(routing_values.intersection(other.routing_values))
          elsif exclusive? && other.exclusive?
            # Since both sets are exclusive, we need to return an exclusive set of the union of the
            # excluded values. For example, when dealing with positive integers:
            #
            #   s1 = RoutingValueSet.of_all_except([1, 2, 3]) # > 3
            #   s2 = RoutingValueSet.of_all_except([3, 4, 5]) # 1, 2, > 5
            #
            #   s3 = s1.intersection(s2)
            #
            # Here s3 would be all values > 5 (the same as `RoutingValueSet.of_all_except([1, 2, 3, 4, 5])`)
            RoutingValueSet.of_all_except(routing_values.union(other.routing_values))
          else
            # Since one set is inclusive and one set is exclusive, we need to return an inclusive set of
            # `included_values - excluded_values`. For example, when dealing with positive integers:
            #
            #   s1 = RoutingValueSet.of([1, 2, 3]) # 1, 2, 3
            #   s2 = RoutingValueSet.of_all_except([3, 4, 5]) # 1, 2, > 5
            #
            #   s3 = s1.intersection(s2)
            #
            # Here s3 would be just `1, 2`.
            included_values, excluded_values = get_included_and_excluded_values(other)
            RoutingValueSet.of(included_values - excluded_values)
          end
        end

        def union(other_set)
          # Here we return `other` to preserve the commutative property of `union`. Returning `other`
          # here matches the behavior of `UnboundedWithExclusions.union`. See the comment there for
          # rationale.
          return other_set if other_set == UnboundedWithExclusions

          # @type var other: RoutingValueSet
          other = _ = other_set

          if inclusive? && other.inclusive?
            # Since both sets are inclusive, we can just delegate to `Set#union` here.
            RoutingValueSet.of(routing_values.union(other.routing_values))
          elsif exclusive? && other.exclusive?
            # Since both sets are exclusive, we need to return an exclusive set of the intersection of the
            # excluded values. For example, when dealing with positive integers:
            #
            #   s1 = RoutingValueSet.of_all_except([1, 2, 3]) # > 3
            #   s2 = RoutingValueSet.of_all_except([3, 4, 5]) # 1, 2, > 5
            #
            #   s3 = s1.union(s2)
            #
            # Here s3 would be all 1, 2, > 3 (the same as `RoutingValueSet.of_all_except([3])`)
            RoutingValueSet.of_all_except(routing_values.intersection(other.routing_values))
          else
            # Since one set is inclusive and one set is exclusive, we need to return an exclusive set of
            # `excluded_values - included_values`. For example, when dealing with positive integers:
            #
            #   s1 = RoutingValueSet.of([1, 2, 3]) # 1, 2, 3
            #   s2 = RoutingValueSet.of_all_except([3, 4, 5]) # 1, 2, > 5
            #
            #   s3 = s1.union(s2)
            #
            # Here s3 would be 1, 2, 3, > 5 (the same as `RoutingValueSet.of_all_except([4, 5])`)
            included_values, excluded_values = get_included_and_excluded_values(other)
            RoutingValueSet.of_all_except(excluded_values - included_values)
          end
        end

        def negate
          with(type: INVERTED_TYPES.fetch(type))
        end

        INVERTED_TYPES = {inclusive: :exclusive, exclusive: :inclusive}

        def to_return_value
          # Elasticsearch/OpenSearch have no routing value syntax to tell it to avoid searching a specific shard
          # (and the fact that we are excluding a routing value doesn't mean that other documents that
          # live on the same shard with different routing values can't match!) so we return `nil` to
          # force the datastore to search all shards.
          return nil if exclusive?

          routing_values.to_a
        end

        protected

        def inclusive?
          type == :inclusive
        end

        def exclusive?
          type == :exclusive
        end

        private

        def get_included_and_excluded_values(other)
          inclusive? ? [routing_values, other.routing_values] : [other.routing_values, routing_values]
        end

        # This `RoutingValueSet` implementation is used for otherwise unrepresentable cases. We use it when
        # a filter on one of the `routing_field_paths` uses an inequality like:
        #
        #     {routing_field: {gt: "abc"}}
        #
        # In a case like that, the set is unbounded (there's an infinite number of values that are greater
        # than `"abc"`...), but it's not `RoutingValueSet::ALL`--since it's based on an inequality, there are
        # _some_ values that are excluded from the set. But we can't use `RoutingValueSet.of_all_except(...)`
        # because the set of exclusions is also unbounded!
        #
        # When our filter value extraction results in this set, we must search all shards of the index and
        # cannot pass any `routing` value to the datastore at all.
        module UnboundedWithExclusions
          # @dynamic self.==

          def self.intersection(other)
            # Technically, the "true" intersection would be `other - values_of(self)` but as we don't have
            # any known values from this unbounded set, we just return `other`. It's OK to include extra values
            # in the set (we'll search additional shards) but not OK to fail to include necessary values in
            # the set (we'd avoid searching a shard that may have matching documents) so we err on the side of
            # including more values.
            other
          end

          def self.union(other)
            # Since our set here is unbounded, the resulting union is also unbounded. This errs on the side
            # of safety since this set's `to_return_value` returns `nil` to cause the datastore to search
            # all shards.
            self
          end

          def self.negate
            # This here is the only difference in behavior of this set implementation vs `RoutingValueSet::ALL`.
            # Where as `ALL.negate` returns an empty set, we treat `negate` as a no-op. We do that because the
            # negation of an inexact unbounded set is still an inexact unbounded set. While it flips which values
            # are in or out of the set, this object is still the representation in our datamodel for that case.
            self
          end

          def self.to_return_value
            # Here we return `nil` to make sure that the datastore searches all shards, since we don't have
            # any information we can use to safely limit what shards it searches.
            nil
          end
        end
      end

      # `Query::RoutingPicker` exists only for use by `Query` and is effectively private.
      private_constant :RoutingPicker
      # `RoutingValueSet` exists only for use here and is effectively private.
      private_constant :RoutingValueSet

      # Steep is complaining that it can't find some `Query` but they are not in this file...
      # @dynamic aggregations, shard_routing_values, search_index_definitions, merge_with, search_index_expression
      # @dynamic with, to_datastore_msearch_header_and_body, document_paginator
    end
  end
end
