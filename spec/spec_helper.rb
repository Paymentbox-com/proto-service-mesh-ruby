# frozen_string_literal: true

require "proto_service_mesh"
require_relative "support/memory_transport"
require_relative "support/testproto/service_maps"

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :expect }
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed

  # Every example starts from an empty process router and registry.
  config.before do
    ProtoServiceMesh.instance_variable_set(:@transport_router, ProtoServiceMesh::TransportRouter.new)
    ProtoServiceMesh.instance_variable_set(:@registry, ProtoServiceMesh::Registry.new)
    ProtoServiceMesh::Wire.instance_variable_set(:@warned, {})
  end
end
