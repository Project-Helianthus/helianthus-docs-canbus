# Generic CAN Transport Architecture

## Ownership

helianthus-canbus is a generic classic-CAN transport. It owns SocketCAN socket
lifecycle, frame reception, standard and extended identifier framing, bounded
queues, cancellation, and deadlines. It does not identify vendors, name
fields, select bit rates, or interpret frame payloads.

## Frame Contract

The transport emits identifier kind and value, payload bytes, effective data
length, and receive metadata. A classical CAN payload is limited to eight
bytes. A valid raw wire DLC extension remains metadata, not payload length.

Unknown frames are transport-valid observations. The transport retains raw data
and must not infer a vendor, unit, capability, or property.

## Receive-Only Boundary

The transport accepts observations from a SocketCAN file descriptor. It never
sends a CAN frame. There is no transmit API, automatic configuration, probing,
or interface mutation.

The caller MUST supply a descriptor backed by a controller already in physical
listen-only mode. This is an admission precondition, not a capability the
library can set or verify. Library receive-only behavior is not evidence of
electrical listen-only mode.

## Vendor Independence

Bit rate, identifier conventions, electrical assumptions, and payload semantics
belong to vendor profiles or deployment configuration. A vendor must be
addable without a change to helianthus-canbus.
