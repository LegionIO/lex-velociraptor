# frozen_string_literal: true

module Legion
  module Extensions
    module Velociraptor
      module Runners
        module Collections
          include Helpers::Cli
          include Query
          include Legion::Extensions::Helpers::Lex if defined?(Legion::Extensions::Helpers::Lex)

          def collect_artifact(client_id:, artifacts:, env: {}, **)
            client = validate_id!(client_id, 'client_id')
            artifact_expr = artifacts_expr(artifacts)
            vql = [
              'SELECT collect_client(',
              "client_id=#{vql_string(client)}, ",
              "artifacts=#{artifact_expr}, ",
              "env=#{dict_from_env_keys(env)}) AS collection FROM scope()"
            ].join
            query(vql: vql, env: env, **)
          end

          def collect_artifact_and_wait(client_id:, artifacts:, result_artifact:, env: {}, **)
            client = validate_id!(client_id, 'client_id')
            result_source = validate_artifact!(result_artifact)
            artifact_expr = artifacts_expr(artifacts)
            vql = [
              "LET collection <= collect_client(client_id=#{vql_string(client)}, artifacts=#{artifact_expr}, env=#{dict_from_env_keys(env)})",
              "LET _ <= SELECT * FROM watch_monitoring(artifact='System.Flow.Completion') WHERE FlowId = collection.flow_id LIMIT 1",
              "SELECT * FROM source(client_id=collection.request.client_id, flow_id=collection.flow_id, artifact=#{vql_string(result_source)})"
            ].join(' ')
            query(vql: vql, env: env, **)
          end

          def flow_results(client_id:, flow_id:, artifact:, **)
            client = validate_id!(client_id, 'client_id')
            flow = validate_id!(flow_id, 'flow_id')
            source_artifact = validate_artifact!(artifact)
            vql = "SELECT * FROM source(client_id=#{vql_string(client)}, flow_id=#{vql_string(flow)}, artifact=#{vql_string(source_artifact)})"
            query(vql: vql, **)
          end

          def cancel_flow(client_id:, flow_id:, **)
            client = validate_id!(client_id, 'client_id')
            flow = validate_id!(flow_id, 'flow_id')
            vql = "SELECT cancel_flow(client_id=#{vql_string(client)}, flow_id=#{vql_string(flow)}) AS canceled FROM scope()"
            query(vql: vql, **)
          end

          private

          def artifacts_expr(artifacts)
            values = Array(artifacts).map { |artifact| validate_artifact!(artifact) }
            values.one? ? vql_string(values.first) : vql_list(values)
          end
        end
      end
    end
  end
end
