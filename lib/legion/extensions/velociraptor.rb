# frozen_string_literal: true

require 'legion/extensions/velociraptor/version'
require 'legion/extensions/velociraptor/helpers/cli'
require 'legion/extensions/velociraptor/runners/query'
require 'legion/extensions/velociraptor/runners/collections'
require 'legion/extensions/velociraptor/runners/hunts'
require 'legion/extensions/velociraptor/client'

module Legion
  module Extensions
    module Velociraptor
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core, false
    end
  end
end
