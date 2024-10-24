ARG RUBY_VERSION
FROM ruby:${RUBY_VERSION}

ARG TARGET_APOLLO_FEDERATION_VERSION

WORKDIR /web

# Each of the elasticgraph gems this implementation depends on must be
# copied into the container so it's available for inclusion in the bundle.
# Note: we've observed that hidden files (like .rspec) are not copied by COPY.
# gemspec_helper enforces the presence of `.rspec`/`.yardopts`, so we have to copy them.
COPY elasticgraph-admin /web/elasticgraph-admin
COPY elasticgraph-admin/.rspec /web/elasticgraph-admin/.rspec
COPY elasticgraph-admin/.yardopts /web/elasticgraph-admin/.yardopts

COPY elasticgraph-apollo /web/elasticgraph-apollo
COPY elasticgraph-apollo/.rspec /web/elasticgraph-apollo/.rspec
COPY elasticgraph-apollo/.yardopts /web/elasticgraph-apollo/.yardopts

COPY elasticgraph-datastore_core /web/elasticgraph-datastore_core
COPY elasticgraph-datastore_core/.rspec /web/elasticgraph-datastore_core/.rspec
COPY elasticgraph-datastore_core/.yardopts /web/elasticgraph-datastore_core/.yardopts

COPY elasticgraph-elasticsearch /web/elasticgraph-elasticsearch
COPY elasticgraph-elasticsearch/.rspec /web/elasticgraph-elasticsearch/.rspec
COPY elasticgraph-elasticsearch/.yardopts /web/elasticgraph-elasticsearch/.yardopts

COPY elasticgraph-graphql /web/elasticgraph-graphql
COPY elasticgraph-graphql/.rspec /web/elasticgraph-graphql/.rspec
COPY elasticgraph-graphql/.yardopts /web/elasticgraph-graphql/.yardopts

COPY elasticgraph-indexer /web/elasticgraph-indexer
COPY elasticgraph-indexer/.rspec /web/elasticgraph-indexer/.rspec
COPY elasticgraph-indexer/.yardopts /web/elasticgraph-indexer/.yardopts

COPY elasticgraph-json_schema /web/elasticgraph-json_schema
COPY elasticgraph-json_schema/.rspec /web/elasticgraph-json_schema/.rspec
COPY elasticgraph-json_schema/.yardopts /web/elasticgraph-json_schema/.yardopts

COPY elasticgraph-rack /web/elasticgraph-rack
COPY elasticgraph-rack/.rspec /web/elasticgraph-rack/.rspec
COPY elasticgraph-rack/.yardopts /web/elasticgraph-rack/.yardopts

COPY elasticgraph-schema_artifacts /web/elasticgraph-schema_artifacts
COPY elasticgraph-schema_artifacts/.rspec /web/elasticgraph-schema_artifacts/.rspec
COPY elasticgraph-schema_artifacts/.yardopts /web/elasticgraph-schema_artifacts/.yardopts

COPY elasticgraph-schema_definition /web/elasticgraph-schema_definition
COPY elasticgraph-schema_definition/.rspec /web/elasticgraph-schema_definition/.rspec
COPY elasticgraph-schema_definition/.yardopts /web/elasticgraph-schema_definition/.yardopts

COPY elasticgraph-support /web/elasticgraph-support
COPY elasticgraph-support/.rspec /web/elasticgraph-support/.rspec
COPY elasticgraph-support/.yardopts /web/elasticgraph-support/.yardopts

# We also have to copy the implementation files (config, schema, etc) as well.
COPY elasticgraph-apollo/apollo_tests_implementation /web/

COPY gemspec_helper.rb /web/gemspec_helper.rb

# We need to install the bundle and generate our schema artifacts.
RUN bundle install
RUN bundle exec rake schema_artifacts:dump TARGET_APOLLO_FEDERATION_VERSION=${TARGET_APOLLO_FEDERATION_VERSION}

# Finally we can boot the app!
CMD ["bundle", "exec", "rackup", "--host", "0.0.0.0", "--port", "4001"]
