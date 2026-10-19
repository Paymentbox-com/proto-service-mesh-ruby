# frozen_string_literal: true

module ProtoServiceMesh
  # The start of an outgoing metadata key that is a transport option. A client
  # method passes each such key, with the prefix removed, to the transport's
  # request or publish options, and sends the other keys as message metadata.
  # Reply metadata never carries such keys. The match is exact and
  # case-sensitive.
  OPTION_PREFIX = "Mesh-Option-"

  # Metadata keys and values the specification fixes on every message.
  module Wire
    MESH_CONTENT_TYPE_KEY = "Mesh-Content-Type"
    CONTENT_TYPE = "application/x-protobuf"
    MESH_STATUS_KEY = "Mesh-Status"

    # Deprecated. The key older versions send in place of
    # MESH_CONTENT_TYPE_KEY.
    CONTENT_TYPE_KEY = "Content-Type"

    # Deprecated. The key older versions send in place of MESH_STATUS_KEY.
    GRPC_STATUS_KEY = "Grpc-Status"

    # The keys the library sets itself. Values for them in application
    # metadata are dropped.
    KEYS = [MESH_CONTENT_TYPE_KEY, MESH_STATUS_KEY, CONTENT_TYPE_KEY, GRPC_STATUS_KEY].freeze

    @warned = {}
    @warned_lock = Mutex.new

    # Metadata for a message carrying a payload of the method's type: +extra+
    # without KEYS, with MESH_CONTENT_TYPE_KEY, and with CONTENT_TYPE_KEY
    # too when +legacy+ is true.
    def self.metadata(extra = {}, legacy: false)
      out = extra.to_h.except(*KEYS).merge(MESH_CONTENT_TYPE_KEY => CONTENT_TYPE)
      out[CONTENT_TYPE_KEY] = CONTENT_TYPE if legacy
      out
    end

    # Whether +metadata+ comes from an older version: it carries
    # CONTENT_TYPE_KEY and no MESH_CONTENT_TYPE_KEY. The first such message on
    # +target+ writes a warning.
    def self.legacy_content_type?(target, metadata)
      deprecated?(target, metadata, CONTENT_TYPE_KEY, MESH_CONTENT_TYPE_KEY)
    end

    # Whether reply +metadata+ carries GRPC_STATUS_KEY and no
    # MESH_STATUS_KEY. The first such reply on +target+ writes a warning.
    def self.legacy_status?(target, metadata)
      deprecated?(target, metadata, GRPC_STATUS_KEY, MESH_STATUS_KEY)
    end

    def self.deprecated?(target, metadata, old, replacement)
      return false unless metadata.key?(old) && !metadata.key?(replacement)

      first = @warned_lock.synchronize { @warned.key?([old, target.segments]) ? false : @warned[[old, target.segments]] = true }
      if first
        warn "proto_service_mesh: a message on #{target.segments.inspect} carries the deprecated metadata key #{old} in place of #{replacement}; the sender runs an older version"
      end
      true
    end
    private_class_method :deprecated?

    # Splits +metadata+ into the message metadata and the transport options:
    # the keys that start with OPTION_PREFIX become options with the prefix
    # removed. Returns [metadata, options], both new Hashes.
    def self.split_options(metadata)
      options = {}
      rest = {}
      metadata.to_h.each do |key, value|
        if key.to_s.start_with?(OPTION_PREFIX)
          options[key.to_s.delete_prefix(OPTION_PREFIX)] = value
        else
          rest[key] = value
        end
      end
      [rest, options]
    end

    # A copy of +metadata+ without the keys that start with OPTION_PREFIX.
    def self.without_options(metadata)
      split_options(metadata).first
    end

    # Metadata for a reply whose payload is an encoded google.rpc.Status:
    # metadata(extra, legacy:) with MESH_STATUS_KEY, and with GRPC_STATUS_KEY
    # too when +legacy+ is true.
    def self.status_metadata(error, extra = {}, legacy: false)
      out = metadata(extra, legacy: legacy).merge(MESH_STATUS_KEY => error.proto.code.to_s)
      out[GRPC_STATUS_KEY] = out[MESH_STATUS_KEY] if legacy
      out
    end
  end
end
