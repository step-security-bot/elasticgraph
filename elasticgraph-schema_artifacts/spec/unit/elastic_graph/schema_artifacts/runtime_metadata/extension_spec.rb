# Copyright 2024 Block, Inc.
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# frozen_string_literal: true

require "elastic_graph/schema_artifacts/runtime_metadata/extension"
require "elastic_graph/schema_artifacts/runtime_metadata/extension_loader"

module ElasticGraph
  module SchemaArtifacts
    module RuntimeMetadata
      RSpec.describe Extension do
        let(:loader) { ExtensionLoader.new(Class.new) }

        it "can roundtrip through a primitive ruby hash for easy serialization and deserialization" do
          extension = loader.load("ElasticGraph::Extensions::Valid", from: "support/example_extensions/valid", config: {foo: "bar"})
          hash = extension.to_dumpable_hash

          expect(hash).to eq({
            "extension_config" => {"foo" => "bar"},
            "extension_name" => "ElasticGraph::Extensions::Valid",
            "require_path" => "support/example_extensions/valid"
          })

          reloaded_extension = Extension.load_from_hash(hash, via: loader)

          expect(reloaded_extension).to eq(extension)
        end
      end
    end
  end
end
