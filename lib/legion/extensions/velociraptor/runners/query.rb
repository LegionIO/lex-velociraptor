# frozen_string_literal: true

module Legion
  module Extensions
    module Velociraptor
      module Runners
        module Query
          include Helpers::Cli
          include Legion::Extensions::Helpers::Lex if defined?(Legion::Extensions::Helpers::Lex)

          def query(vql:, env: {}, format: :jsonl, **)
            result = run_vql(vql: vql, env: env, format: format, **)
            { rows: result[:rows], stderr: result[:stderr] }
          end

          def server_info(**)
            query(vql: 'SELECT * FROM info()', **)
          end

          def search_clients(query: nil, **)
            env = {}
            vql = 'SELECT * FROM clients()'
            if query
              env[:ClientQuery] = query
              vql = 'SELECT * FROM clients(search=ClientQuery)'
            end

            query(vql: vql, env: env, **)
          end
        end
      end
    end
  end
end
