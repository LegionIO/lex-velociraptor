# frozen_string_literal: true

module Legion
  module Extensions
    module Velociraptor
      module Runners
        module Hunts
          include Helpers::Cli
          include Collections
          include Legion::Extensions::Helpers::Lex if defined?(Legion::Extensions::Helpers::Lex)

          def launch_hunt(artifacts:, description: nil, env: {}, **)
            artifact_expr = artifacts_expr(artifacts)
            description_arg = description ? ", description=#{vql_string(description)}" : ''
            vql = "SELECT hunt(artifacts=#{artifact_expr}, env=#{dict_from_env_keys(env)}#{description_arg}) AS hunt FROM scope()"
            query(vql: vql, env: env, **)
          end

          def hunt_results(hunt_id:, artifact:, **)
            hunt = validate_id!(hunt_id, 'hunt_id')
            source_artifact = validate_artifact!(artifact)
            vql = "SELECT * FROM source(hunt_id=#{vql_string(hunt)}, artifact=#{vql_string(source_artifact)})"
            query(vql: vql, **)
          end

          def list_hunts(**)
            query(vql: 'SELECT * FROM hunts()', **)
          end
        end
      end
    end
  end
end
