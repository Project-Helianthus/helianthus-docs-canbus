# SocketCAN Receive-Only Contract

## Admission

The caller supplies an already-open SocketCAN descriptor and owns network
namespace selection, interface creation, bit-rate configuration, and controller
mode. Caller MUST configure the physical controller in listen-only mode before
opening the descriptor. A descriptor backed by a normal controller MUST NOT be
admitted.

The library cannot verify or set physical controller mode through this contract.
The integrator records the controller's listen-only configuration as the
admission precondition; the library's no-transmit API does not replace it.

## Receive Semantics

The transport accepts classic CAN observations with an 11-bit standard or
29-bit extended identifier. Payload length is zero through eight bytes.
Cancellation and deadline expiry terminate reception without a stateful retry
or a write.

## Denials

The transport must not transmit, acknowledge, probe, configure, bring up, or
otherwise mutate a CAN interface. It must not derive a physical-layer type from
an interface name or received frame.
