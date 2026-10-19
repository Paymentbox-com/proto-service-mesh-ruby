# frozen_string_literal: true

RSpec.describe ProtoServiceMesh::MeshError do
  it "is a StandardError built from a code name and a message" do
    error = described_class.new(:NOT_FOUND, "no such order")

    expect(error).to be_a(StandardError)
    expect(error.code).to eq(:NOT_FOUND)
    expect(error.message).to eq("no such order")
    expect(error.to_s).to eq("no such order")
    expect(error.details).to eq([])
    expect(error.proto).to eq(Google::Rpc::Status.new(code: 5, message: "no such order"))
    expect(error.mesh_metadata).to eq({})
  end

  it "carries the metadata given on construction through to the subclass" do
    error = described_class.new(:NOT_FOUND, "no such order", mesh_metadata: {"Retry-After" => "30"})

    expect(error).to be_an_instance_of(ProtoServiceMesh::NotFoundError)
    expect(error.mesh_metadata).to eq({"Retry-After" => "30"})
  end

  it "rejects a message with no code" do
    expect { described_class.new("store is down") }.to raise_error(ArgumentError, /takes a Google::Rpc::Code first/)
  end

  it "raises UNKNOWN from UnknownError and a message" do
    expect { raise ProtoServiceMesh::UnknownError, "store is down" }.to raise_error(ProtoServiceMesh::UnknownError, "store is down") do |error|
      expect(error.code).to eq(:UNKNOWN)
    end
  end

  it "raises a subclass from the class and a message" do
    expect { raise ProtoServiceMesh::NotFoundError, "no such order" }.to raise_error(ProtoServiceMesh::NotFoundError, "no such order") do |error|
      expect(error.code).to eq(:NOT_FOUND)
      expect(error.details).to eq([])
    end
  end

  it "builds the subclass for a named code" do
    error = described_class.new(:NOT_FOUND, "no such order")

    expect(error).to be_an_instance_of(ProtoServiceMesh::NotFoundError)
    expect(error.code).to eq(:NOT_FOUND)
  end

  it "builds the subclass from a proto" do
    error = described_class.from_proto(Google::Rpc::Status.new(code: 7, message: "nope"))

    expect(error).to be_an_instance_of(ProtoServiceMesh::PermissionDeniedError)
    expect(error.message).to eq("nope")
  end

  it "stays a MeshError for OK and for a number with no name" do
    expect(described_class.new(0, "fine")).to be_an_instance_of(described_class)
    expect(described_class.new(99, "vendor code")).to be_an_instance_of(described_class)
  end

  it "builds a subclass directly from a message and details" do
    info = Google::Rpc::ErrorInfo.new(reason: "ORDER_MISSING")

    error = ProtoServiceMesh::NotFoundError.new("no such order", info)

    expect(error).to be_a(described_class)
    expect(error.code).to eq(:NOT_FOUND)
    expect(error.message).to eq("no such order")
    expect(error.details[0].unpack(Google::Rpc::ErrorInfo)).to eq(info)
  end

  it "gives every subclass its own code" do
    expect(ProtoServiceMesh::CancelledError.new("").code).to eq(:CANCELLED)
    expect(ProtoServiceMesh::UnknownError.new("").code).to eq(:UNKNOWN)
    expect(ProtoServiceMesh::InvalidArgumentError.new("").code).to eq(:INVALID_ARGUMENT)
    expect(ProtoServiceMesh::DeadlineExceededError.new("").code).to eq(:DEADLINE_EXCEEDED)
    expect(ProtoServiceMesh::NotFoundError.new("").code).to eq(:NOT_FOUND)
    expect(ProtoServiceMesh::AlreadyExistsError.new("").code).to eq(:ALREADY_EXISTS)
    expect(ProtoServiceMesh::PermissionDeniedError.new("").code).to eq(:PERMISSION_DENIED)
    expect(ProtoServiceMesh::UnauthenticatedError.new("").code).to eq(:UNAUTHENTICATED)
    expect(ProtoServiceMesh::ResourceExhaustedError.new("").code).to eq(:RESOURCE_EXHAUSTED)
    expect(ProtoServiceMesh::FailedPreconditionError.new("").code).to eq(:FAILED_PRECONDITION)
    expect(ProtoServiceMesh::AbortedError.new("").code).to eq(:ABORTED)
    expect(ProtoServiceMesh::OutOfRangeError.new("").code).to eq(:OUT_OF_RANGE)
    expect(ProtoServiceMesh::UnimplementedError.new("").code).to eq(:UNIMPLEMENTED)
    expect(ProtoServiceMesh::InternalError.new("").code).to eq(:INTERNAL)
    expect(ProtoServiceMesh::UnavailableError.new("").code).to eq(:UNAVAILABLE)
    expect(ProtoServiceMesh::DataLossError.new("").code).to eq(:DATA_LOSS)
  end

  it "accepts the code as a number" do
    error = described_class.new(5, "no such order")

    expect(error.code).to eq(:NOT_FOUND)
    expect(error.proto.code).to eq(5)
  end

  it "keeps a number that names no Google::Rpc::Code" do
    error = described_class.new(99, "vendor code")

    expect(error.code).to eq(99)
    expect(error.proto.code).to eq(99)
  end

  it "rejects a name that is not a Google::Rpc::Code" do
    expect { described_class.new(:MISSING, "x") }.to raise_error(ArgumentError, /MISSING/)
  end

  it "rejects a detail that is not a protobuf message" do
    expect { described_class.new(:NOT_FOUND, "no such order", "o-1") }
      .to raise_error(TypeError, "a detail must be a protobuf message, got String")
  end

  it "packs detail messages and round-trips them through proto and from_proto" do
    info = Google::Rpc::ErrorInfo.new(reason: "ORDER_CANCELLED", domain: "shop", metadata: {"order" => "o-1"})
    packed = Google::Protobuf::Any.pack(Google::Rpc::RetryInfo.new)

    error = described_class.new(:FAILED_PRECONDITION, "revoked", info, packed)
    again = described_class.from_proto(Google::Rpc::Status.decode(error.proto.to_proto))

    expect(error.details.map(&:type_name)).to eq(%w[google.rpc.ErrorInfo google.rpc.RetryInfo])
    expect(error.details[1]).to equal(packed)
    expect(again.code).to eq(:FAILED_PRECONDITION)
    expect(again.message).to eq("revoked")
    expect(again.details[0].unpack(Google::Rpc::ErrorInfo)).to eq(info)
    expect(again.details[1].is(Google::Rpc::RetryInfo)).to be(true)
    expect(again.proto).to eq(error.proto)
  end
end
