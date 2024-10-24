script_dir=$(dirname $0)

# Use the current max Elasticsearch version we test against.
export VERSION=$(ruby -ryaml -e "puts YAML.load_file('$script_dir/../../config/tested_datastore_versions.yaml').fetch('elasticsearch').max_by { |v| Gem::Version.new(v) }")

# Use the same Ruby version in the docker container as what we are currently using.
export RUBY_VERSION=$(ruby -e "puts RUBY_VERSION")

# Call the ENV "apollo" instead of "test" or "local" to avoid interference with
# the Elasticsearch container booted for those envs.
export ENV=apollo

# Apollo federation version used to generate the schema artifacts.
# TODO: Move to v2.6 once it is supported by the test suite.
export TARGET_APOLLO_FEDERATION_VERSION=2.3
