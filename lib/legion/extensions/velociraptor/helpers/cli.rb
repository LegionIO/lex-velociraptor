# frozen_string_literal: true

require 'json'
require 'open3'
require 'timeout'

module Legion
  module Extensions
    module Velociraptor
      module Helpers
        module Cli
          ENV_KEY_PATTERN = /\A[A-Za-z_][A-Za-z0-9_]*\z/
          ID_PATTERN = /\A[A-Za-z]\.[A-Za-z0-9_-]+\z/
          ARTIFACT_PATTERN = %r{\A[A-Za-z][A-Za-z0-9_.-]*(/[A-Za-z][A-Za-z0-9_.-]*)?\z}

          class CommandError < StandardError
            attr_reader :exit_status, :stderr, :stdout

            def initialize(message, exit_status: nil, stderr: nil, stdout: nil)
              @exit_status = exit_status
              @stderr = stderr
              @stdout = stdout
              super(message)
            end
          end

          def run_vql(vql:, env: {}, format: :jsonl, api_config: nil, binary: nil, timeout: nil, **)
            normalized_env = normalize_env(env)
            command = velociraptor_query_command(
              vql:        vql,
              env:        normalized_env,
              format:     format,
              api_config: api_config,
              binary:     binary
            )
            result = run_command(command, timeout: timeout || option(:timeout))
            result.merge(rows: parse_output(result[:stdout], format))
          end

          def velociraptor_query_command(vql:, env: {}, format: :jsonl, api_config: nil, binary: nil)
            command = [binary || option(:binary) || 'velociraptor']
            config = api_config || option(:api_config)
            command += ['--api_config', config] if present?(config)
            command += ['query', vql.to_s, '--format', format.to_s]
            normalize_env(env).each { |key, value| command += ['--env', "#{key}=#{value}"] }
            command
          end

          def run_command(command, timeout: nil)
            stdout, stderr, status = capture(command, timeout: timeout)
            unless status.success?
              raise CommandError.new(
                "velociraptor command failed with exit #{status.exitstatus}",
                exit_status: status.exitstatus,
                stderr:      stderr,
                stdout:      stdout
              )
            end

            { success: true, stdout: stdout, stderr: stderr }
          rescue Errno::ENOENT => e
            raise CommandError, e.message
          rescue Timeout::Error => e
            raise CommandError, "velociraptor command timed out: #{e.message}"
          end

          def parse_output(stdout, format)
            case format.to_sym
            when :jsonl
              stdout.to_s.each_line.filter_map do |line|
                next if line.strip.empty?

                stringify_keys(::JSON.parse(line))
              end
            when :json
              parsed = stringify_keys(::JSON.parse(stdout.to_s))
              parsed.is_a?(Array) ? parsed : [parsed]
            else
              stdout.to_s
            end
          end

          def vql_string(value)
            ::JSON.generate(value.to_s)
          end

          def vql_list(values)
            Array(values).map { |value| vql_string(value) }.join(', ').then { |items| "[#{items}]" }
          end

          def validate_id!(value, label)
            return value.to_s if value.to_s.match?(ID_PATTERN)

            raise ArgumentError, "#{label} must look like a Velociraptor id"
          end

          def validate_artifact!(value)
            return value.to_s if value.to_s.match?(ARTIFACT_PATTERN)

            raise ArgumentError, 'artifact must be a Velociraptor artifact name'
          end

          def normalize_env(env)
            env.to_h.each_with_object({}) do |(key, value), normalized|
              name = key.to_s
              raise ArgumentError, "invalid VQL env key: #{name}" unless name.match?(ENV_KEY_PATTERN)

              normalized[name] = value.to_s
            end
          end

          def dict_from_env_keys(env)
            normalize_env(env).keys.map { |key| "#{key}=#{key}" }.join(', ').then { |items| "dict(#{items})" }
          end

          private

          def capture(command, timeout: nil)
            return Open3.capture3(*command) unless timeout

            Timeout.timeout(timeout) { Open3.capture3(*command) }
          end

          def option(key)
            respond_to?(:opts) ? opts[key] : nil
          end

          def present?(value)
            !value.nil? && value.to_s != ''
          end

          def stringify_keys(value)
            case value
            when Array
              value.map { |item| stringify_keys(item) }
            when Hash
              value.each_with_object({}) do |(key, val), normalized|
                normalized[key.to_s] = stringify_keys(val)
              end
            else
              value
            end
          end
        end
      end
    end
  end
end
