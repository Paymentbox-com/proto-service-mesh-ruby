# frozen_string_literal: true

RSpec.describe ProtoServiceMesh::Registry do
  let(:registry) { ProtoServiceMesh.registry }

  let(:billing_target) do
    ServiceMesh::Target.new(segments: %w[billing InvoiceService Create], kind: :route, metadata: {"transport" => "http"})
  end

  let(:billing_service) do
    target = billing_target
    Class.new(ProtoServiceMesh::RPCService) do
      rpc :create, target: target, input: Shop::Order, output: Shop::Order, kind: :route
      def create(request) = request
    end
  end

  let(:orders) do
    Class.new(Shop::OrderService) do
      def place(request) = request

      def placed(request)
      end
    end
  end

  def consumer_group(served) = served.metadata[ServiceMesh::CONSUMER_GROUP_KEY]

  it "hands back every endpoint and subscriber registered" do
    ProtoServiceMesh.register(orders.new)
    ProtoServiceMesh.register(billing_service.new)

    expect(registry.endpoints.map(&:target)).to eq([Shop::OrderTargets::PLACE, billing_target])
    expect(registry.subscribers.map(&:target)).to eq([Shop::OrderTargets::PLACED])
  end

  it "keeps the consumer group the generated code carries" do
    ProtoServiceMesh.register(orders.new)

    expect(consumer_group(registry.subscribers.first)).to eq("audit")
    expect(consumer_group(registry.endpoints.first)).to be_nil
  end

  it "replaces a subscriber's consumer group with the one given" do
    ProtoServiceMesh.register(orders.new, consumer_groups: {Shop::OrderTargets::PLACED => "billing-ledger"})

    expect(consumer_group(registry.subscribers.first)).to eq("billing-ledger")
  end

  it "sets an endpoint's consumer group" do
    ProtoServiceMesh.register(orders.new, consumer_groups: {Shop::OrderTargets::PLACE => "orders"})

    expect(consumer_group(registry.endpoints.first)).to eq("orders")
  end

  it "removes the generated consumer group for an empty one" do
    ProtoServiceMesh.register(orders.new, consumer_groups: {Shop::OrderTargets::PLACED => ""})

    expect(registry.subscribers.first.metadata).not_to have_key(ServiceMesh::CONSUMER_GROUP_KEY)
  end

  it "raises ArgumentError naming a target that is not the service's, and registers nothing" do
    expect { ProtoServiceMesh.register(orders.new, consumer_groups: {billing_target => "x"}) }
      .to raise_error(ArgumentError, /\["billing", "InvoiceService", "Create"\]/)
    expect(registry.endpoints).to eq([])
    expect(registry.subscribers).to eq([])
  end
end
