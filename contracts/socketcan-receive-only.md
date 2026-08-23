# SocketCAN Receive-Only Contract

## Admission

The caller supplies an already-open SocketCAN descriptor and owns network
namespace selection, interface creation, bit-rate configuration, and controller
mode.

## Receive Semantics

The transport accepts classic CAN observations with an 11-bit standard or
29-bit extended identifier. Payload length is zero through eight bytes.
Cancellation and deadline expiry terminate reception without a stateful retry
or a write.

## Denials

The transport must not transmit, acknowledge, probe, configure, bring up, or
otherwise mutate a CAN interface. It must not derive a physical-layer type from
an interface name or received frame.
