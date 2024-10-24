# Copyright 2024 Block, Inc.
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.
#
# frozen_string_literal: true

require "aws-sdk-lambda"
require "aws-sdk-sqs"
require "elastic_graph/indexer_autoscaler_lambda/concurrency_scaler"
require "support/builds_indexer_autoscaler"

module ElasticGraph
  class IndexerAutoscalerLambda
    RSpec.describe ConcurrencyScaler, :capture_logs do
      include BuildsIndexerAutoscalerLambda

      describe "#tune_indexer_concurrency" do
        let(:event_source_mapping_uuid) { "uuid123" }
        let(:min_cpu_target) { 70 }
        let(:max_cpu_target) { 80 }
        let(:cpu_midpoint) { 75 }

        it "1.5x the concurrency when the CPU usage is significantly below the minimum target" do
          lambda_client = lambda_client_with_concurrency(200)
          concurrency_scaler = build_concurrency_scaler(
            datastore_client: datastore_client_with_cpu_usage(10.0),
            sqs_client: sqs_client_with_number_of_messages(1),
            lambda_client: lambda_client
          )

          tune_indexer_concurrency(concurrency_scaler)

          expect(updated_concurrencies_requested_from(lambda_client)).to eq [300] # 200 * 1.5
        end

        it "increases concurrency by a factor CPU usage when CPU is slightly below the minimum target" do
          # CPU is at 50% and our target range is 70-80. 75 / 50 = 1.5, so increase it by 50%.
          lambda_client = lambda_client_with_concurrency(200)
          concurrency_scaler = build_concurrency_scaler(
            datastore_client: datastore_client_with_cpu_usage(50.0),
            sqs_client: sqs_client_with_number_of_messages(1),
            lambda_client: lambda_client
          )

          tune_indexer_concurrency(concurrency_scaler)

          expect(updated_concurrencies_requested_from(lambda_client)).to eq [300] # 200 + 50%
        end

        it "sets concurrency to the max when it cannot be increased anymore when CPU usage is under the limit" do
          current_concurrency = ConcurrencyScaler::MAXIMUM_CONCURRENCY - 1
          lambda_client = lambda_client_with_concurrency(current_concurrency)
          concurrency_scaler = build_concurrency_scaler(
            datastore_client: datastore_client_with_cpu_usage(10),
            sqs_client: sqs_client_with_number_of_messages(1),
            lambda_client: lambda_client
          )

          tune_indexer_concurrency(concurrency_scaler)

          expect(updated_concurrencies_requested_from(lambda_client)).to eq [ConcurrencyScaler::MAXIMUM_CONCURRENCY]
        end

        it "decreases concurrency by a factor of the CPU when the CPU usage is over the limit" do
          # CPU is at 90% and our target range is 70-80. 90 / 75 = 1.2, so decrease it by 20%.
          lambda_client = lambda_client_with_concurrency(500)
          concurrency_scaler = build_concurrency_scaler(
            datastore_client: datastore_client_with_cpu_usage(90.0),
            sqs_client: sqs_client_with_number_of_messages(1),
            lambda_client: lambda_client
          )

          tune_indexer_concurrency(concurrency_scaler)

          expect(updated_concurrencies_requested_from(lambda_client)).to eq [400] # 500 - 20%
        end

        it "sets concurrency to the min when it cannot be decreased anymore when CPU utilization is over the limit" do
          current_concurrency = ConcurrencyScaler::MINIMUM_CONCURRENCY + 1
          lambda_client = lambda_client_with_concurrency(current_concurrency)
          concurrency_scaler = build_concurrency_scaler(
            datastore_client: datastore_client_with_cpu_usage(100),
            sqs_client: sqs_client_with_number_of_messages(1),
            lambda_client: lambda_client
          )

          tune_indexer_concurrency(concurrency_scaler)

          expect(updated_concurrencies_requested_from(lambda_client)).to eq [ConcurrencyScaler::MINIMUM_CONCURRENCY]
        end

        it "does not adjust concurrency when the CPU is within the target range" do
          lambda_client = lambda_client_with_concurrency(500)
          [min_cpu_target, cpu_midpoint, max_cpu_target].each do |cpu_usage|
            concurrency_scaler = build_concurrency_scaler(
              datastore_client: datastore_client_with_cpu_usage(cpu_usage),
              sqs_client: sqs_client_with_number_of_messages(1),
              lambda_client: lambda_client
            )

            tune_indexer_concurrency(concurrency_scaler)
          end

          expect(updated_concurrencies_requested_from(lambda_client)).to eq []
        end

        it "decreases the concurrency when at least one of the node's CPU is over the limit" do
          current_concurrency = 500
          high_cpu_usage = 81
          expect(high_cpu_usage).to be > max_cpu_target

          lambda_client = lambda_client_with_concurrency(current_concurrency)
          concurrency_scaler = build_concurrency_scaler(
            datastore_client: datastore_client_with_cpu_usage(min_cpu_target, high_cpu_usage),
            sqs_client: sqs_client_with_number_of_messages(1),
            lambda_client: lambda_client
          )

          tune_indexer_concurrency(concurrency_scaler)

          expect(high_cpu_usage).to be > max_cpu_target
          expect(updated_concurrencies_requested_from(lambda_client)).to eq [460] # 500 - 8% since 81/75 = 1.08
        end

        it "sets concurrency to the min when there are no messages in the queue" do
          current_concurrency = 500
          lambda_client = lambda_client_with_concurrency(current_concurrency)
          concurrency_scaler = build_concurrency_scaler(
            datastore_client: datastore_client_with_cpu_usage(min_cpu_target - 1),
            sqs_client: sqs_client_with_number_of_messages(0),
            lambda_client: lambda_client
          )

          tune_indexer_concurrency(concurrency_scaler)

          expect(updated_concurrencies_requested_from(lambda_client)).to eq [ConcurrencyScaler::MINIMUM_CONCURRENCY]
        end

        it "leaves concurrency unset if it is currently unset" do
          lambda_client = lambda_client_without_concurrency

          # CPU is at 50% and our target range is 70-80.
          concurrency_scaler = build_concurrency_scaler(
            datastore_client: datastore_client_with_cpu_usage(50),
            sqs_client: sqs_client_with_number_of_messages(1),
            lambda_client: lambda_client
          )

          tune_indexer_concurrency(concurrency_scaler)

          expect(updated_concurrencies_requested_from(lambda_client)).to eq []
        end

        it "supports setting the concurrency on multiple sqs queues" do
          current_concurrency = 500
          cpu_usage = 60.0
          lambda_client = lambda_client_with_concurrency(current_concurrency)

          queue_urls = [
            "https://sqs.us-west-2.amazonaws.com/000000000/some-eg-app-queue-name1",
            "https://sqs.us-west-2.amazonaws.com/000000000/some-eg-app-queue-name2"
          ]

          event_source_mapping_uuids = [
            "event_source_mapping_uuid1",
            "event_source_mapping_uuid2"
          ]

          concurrency_scaler = build_concurrency_scaler(
            datastore_client: datastore_client_with_cpu_usage(cpu_usage),
            sqs_client: sqs_client_with_number_of_messages(1),
            lambda_client: lambda_client
          )

          tune_indexer_concurrency(
            concurrency_scaler,
            queue_urls: queue_urls,
            event_source_mapping_uuids: event_source_mapping_uuids
          )

          # Each event source mapping started with a concurrency of 500 (for a total of 1000).
          # Adding 25% (since the midpoint of our target range is 25% higher than our usage of 60)
          # gives us 1250 total concurrency. Dividing evenly across queues gives us 625 each.
          expect(updated_concurrencies_requested_from(
            lambda_client,
            event_source_mapping_uuids: event_source_mapping_uuids
          )).to eq [625, 625]
        end
      end

      def updated_concurrencies_requested_from(lambda_client, event_source_mapping_uuids: [event_source_mapping_uuid])
        lambda_client.api_requests.filter_map do |req|
          if req.fetch(:operation_name) == :update_event_source_mapping
            expect(event_source_mapping_uuids).to include(req.dig(:params, :uuid))
            req.dig(:params, :scaling_config, :maximum_concurrency)
          end
        end
      end

      def datastore_client_with_cpu_usage(percent, percent2 = percent)
        stubbed_datastore_client(get_node_os_stats: {
          "nodes" => {
            "node1" => {
              "os" => {
                "cpu" => {
                  "percent" => percent
                }
              }
            },
            "node2" => {
              "os" => {
                "cpu" => {
                  "percent" => percent2
                }
              }
            }
          }
        })
      end

      def sqs_client_with_number_of_messages(num_messages)
        ::Aws::SQS::Client.new(stub_responses: true).tap do |sqs_client|
          sqs_client.stub_responses(:get_queue_attributes, {
            attributes: {
              "ApproximateNumberOfMessages" => num_messages.to_s,
              "QueueArn" => "arn:aws:sqs:us-west-2:000000000:some-eg-app-queue-name"
            }
          })
        end
      end

      def lambda_client_with_concurrency(concurrency)
        ::Aws::Lambda::Client.new(stub_responses: true).tap do |lambda_client|
          lambda_client.stub_responses(:get_event_source_mapping, {
            uuid: event_source_mapping_uuid,
            scaling_config: {
              maximum_concurrency: concurrency
            }
          })
        end
      end

      # If the concurrency on the event source mapping is not set, the scaling_config on the Lambda client will be nil.
      def lambda_client_without_concurrency
        ::Aws::Lambda::Client.new(stub_responses: true).tap do |lambda_client|
          lambda_client.stub_responses(:get_event_source_mapping, {
            uuid: event_source_mapping_uuid,
            scaling_config: nil
          })
        end
      end

      def build_concurrency_scaler(datastore_client:, sqs_client:, lambda_client:)
        build_indexer_autoscaler(
          clients_by_name: {"main" => datastore_client},
          sqs_client: sqs_client,
          lambda_client: lambda_client
        ).concurrency_scaler
      end

      def tune_indexer_concurrency(
        concurrency_scaler,
        queue_urls: ["https://sqs.us-west-2.amazonaws.com/000000000/some-eg-app-queue-name"],
        event_source_mapping_uuids: [event_source_mapping_uuid]
      )
        concurrency_scaler.tune_indexer_concurrency(
          queue_urls: queue_urls,
          min_cpu_target: min_cpu_target,
          max_cpu_target: max_cpu_target,
          event_source_mapping_uuids: event_source_mapping_uuids
        )
      end
    end
  end
end
