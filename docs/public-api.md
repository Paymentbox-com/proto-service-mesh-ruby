# Public API

Every public constant and method in `ProtoServiceMesh`.

| Name | Role |
|---|---|
| `ProtoServiceMesh.transport_router` | The process `TransportRouter`, created on first use. |
| `ProtoServiceMesh.add_transport(name, client)` | A shortcut for `transport_router.add`. |
| `ProtoServiceMesh.registry` | The process `Registry`, created on first use. |
| `ProtoServiceMesh.register(service, consumer_groups: {})` | A shortcut for `registry.register`. |
| `ProtoServiceMesh::TransportRouter` | Holds one client per transport name. `TransportRouter.new` builds an empty one. Its methods are `#add(name, client)`, `#client(name)`, `#names`, and `#close`. |
| `ProtoServiceMesh::Registry` | Holds the registered endpoints and subscribers. `Registry.new` builds an empty one. Its methods are `#register(service, consumer_groups: {})`, which raises `ArgumentError` for a target that is not the service's, `#endpoints`, and `#subscribers`. |
| `ProtoServiceMesh::RPCService` | The base class of generated services, which the application subclasses to implement its handlers, as described under [Handlers](handlers.md). `#endpoints` and `#subscribers` return what the subclass serves. |
| `ProtoServiceMesh::RPCClient` | The base class of generated clients. A generated client has one class method per rpc method, as described under [Calling](calling.md). |
| `ProtoServiceMesh::RPCRuntime.new(transport:, deployment_group:, runtime:, config: {})` | Builds an `RPCRuntime`, which serves one transport and one deployment group. Its methods are `#start`, `#stop(drain)`, `#running?`, `#client`, `#t_runtime`, `#transport`, and `#deployment_group`. |
| `ProtoServiceMesh::MeshError` | Described under [MeshError](mesherror.md). `MeshError.new`, `MeshError.from_proto`, and one subclass per code, such as `NotFoundError`, build one. Its methods are `#code`, `#message`, `#details`, `#proto`, and `#mesh_metadata`. |
| `ProtoServiceMesh::OPTION_PREFIX` | `"Mesh-Option-"`, the prefix that marks a metadata key as a transport option. |
| `ProtoServiceMesh::Wire` | Holds the constants `MESH_CONTENT_TYPE_KEY`, `CONTENT_TYPE`, and `MESH_STATUS_KEY`, and the deprecated `CONTENT_TYPE_KEY` and `GRPC_STATUS_KEY` described under [Older Versions](calling.md#older-versions). |
| `ProtoServiceMesh::Error`, `ProtoServiceMesh::UnknownTransport`, `ProtoServiceMesh::CloseFailed` | Listed under [Library Errors](mesherror.md#library-errors). |

## Used by Generated Code

Generated code calls these. They are an implementation detail between the generator and this library, and applications do not call them.
[What Generated Code Relies On](generated-code.md#what-generated-code-relies-on) describes them.

| Name | Role |
|---|---|
| `RPCService.rpc(...)`, `RPCClient.rpc(...)`, `.rpcs` | The class-level declaration generated classes make for each rpc method, and the list of what a class declared. |
| `ProtoServiceMesh::Rpc` | A `Data` value describing one rpc method, with `name`, `target`, `input`, `output`, `kind`, `owner`, and `#route?`. |
| `ProtoServiceMesh::Metadata` | A module that adds `#mesh_metadata` and `#mesh_metadata=` to a message class. |
