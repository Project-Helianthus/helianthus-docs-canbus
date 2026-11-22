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

The transport accepts observations from a SocketCAN file descriptor. The transport sends the frames a driver submits through its send API and offers periodic publication. The driver decides what is sent and how often. The caller configures listen-only for an interface that only receives and normal mode for one on which a driver sends. The transport does not probe, configure or bring up an interface on its own. Listen-only for an interface that only receives is the caller's configuration, not a mode the library sets or verifies.

## Vendor Independence

Bit rate, identifier conventions, electrical assumptions, and payload semantics
belong to vendor profiles or deployment configuration. A vendor must be
addable without a change to helianthus-canbus.
