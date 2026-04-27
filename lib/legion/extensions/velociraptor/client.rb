# frozen_string_literal: true

require_relative 'helpers/cli'
require_relative 'runners/query'
require_relative 'runners/collections'
require_relative 'runners/hunts'

module Legion
  module Extensions
    module Velociraptor
      class Client
        include Helpers::Cli
        include Runners::Query
        include Runners::Collections
        include Runners::Hunts

        attr_reader :opts

        def initialize(api_config: nil, binary: nil, timeout: nil, **extra)
          @opts = {
            api_config: api_config || ENV.fetch('VELOCIRAPTOR_API_CONFIG', nil),
            binary:     binary || ENV.fetch('VELOCIRAPTOR_BIN', 'velociraptor'),
            timeout:    timeout,
            **extra
          }
        end

        def settings
          { options: @opts }
        end
      end
    end
  end
end
