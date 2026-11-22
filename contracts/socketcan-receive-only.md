# SocketCAN Receive-Only Contract

## Admission

The caller supplies an already-open SocketCAN descriptor and owns network
namespace selection, interface creation, bit-rate configuration, and controller
mode. The caller configures listen-only for an interface that only receives
and normal mode for one on which a driver sends, before opening the descriptor.

The library cannot verify or set physical controller mode through this contract.
The integrator records that caller configuration; the library does not replace it.

## Receive Semantics

The transport accepts classic CAN observations with an 11-bit standard or
29-bit extended identifier. Payload length is zero through eight bytes.
Cancellation and deadline expiry terminate reception without a stateful retry
or a write.

## Denials

The transport sends the frames a driver submits through its send API and
offers periodic publication. The driver decides what is sent and how often.
The transport does not probe, configure or bring up an interface on its own.
It must not derive a physical-layer type from an interface name or received
frame.
