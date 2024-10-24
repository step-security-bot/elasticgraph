# Copyright 2024 Block, Inc.
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# frozen_string_literal: true

module ElasticGraph
  module Apollo
    module SchemaDefinition
      # Module designed to be extended onto an `ElasticGraph::SchemaDefinition::GraphQLSDLEnumerator`
      # instance to customize the schema artifacts to support Apollo.
      #
      # @private
      module GraphQLSDLEnumeratorExtension
        def root_query_type
          super.tap do |type_or_nil|
            # @type var type: ElasticGraph::SchemaDefinition::SchemaElements::ObjectType
            type = _ = type_or_nil

            if schema_def_state.object_types_by_name.values.any?(&:indexed?)
              type.field "_entities", "[_Entity]!" do |f|
                f.documentation <<~EOS
                  A field required by the [Apollo Federation subgraph
                  spec](https://www.apollographql.com/docs/federation/subgraph-spec/#query_entities):

                  > The graph router uses this root-level `Query` field to directly fetch fields of entities defined by a subgraph.
                  >
                  > This field must take a `representations` argument of type `[_Any!]!` (a non-nullable list of non-nullable
                  > [`_Any` scalars](https://www.apollographql.com/docs/federation/subgraph-spec/#scalar-_any)). Its return type must be `[_Entity]!` (a non-nullable list of _nullable_
                  > objects that belong to the [`_Entity` union](https://www.apollographql.com/docs/federation/subgraph-spec/#union-_entity)).
                  >
                  > Each entry in the `representations` list  must be validated with the following rules:
                  >
                  > - A representation must include a `__typename` string field.
                  > - A representation must contain all fields included in the fieldset of a `@key` directive applied to the corresponding entity definition.
                  >
                  > For details, see [Resolving entity fields with `Query._entities`](https://www.apollographql.com/docs/federation/subgraph-spec/#resolving-entity-fields-with-query_entities).

                  Not intended for use by clients other than Apollo.
                EOS

                f.argument "representations", "[_Any!]!" do |a|
                  a.documentation <<~EOS
                    A list of entity data blobs from other apollo subgraphs. For more information (and
                    to see an example of what form this argument takes), see the [Apollo Federation subgraph
                    spec](https://www.apollographql.com/docs/federation/subgraph-spec/#resolve-requests-for-entities).
                  EOS
                end
              end
            end

            type.field "_service", "_Service!" do |f|
              f.documentation <<~EOS
                A field required by the [Apollo Federation subgraph
                spec](https://www.apollographql.com/docs/federation/subgraph-spec/#query_service):

                > This field of the root `Query` type must return a non-nullable [`_Service` type](https://www.apollographql.com/docs/federation/subgraph-spec/#type-_service).

                > For details, see [Enhanced introspection with `Query._service`](https://www.apollographql.com/docs/federation/subgraph-spec/#enhanced-introspection-with-query_service).

                Not intended for use by clients other than Apollo.
              EOS
            end
          end
        end
      end
    end
  end
end
