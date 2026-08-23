# Multi-Vendor CAN Registry Boundary

## Ownership

helianthus-canbusreg receives generic CAN observations and owns vendor
identification, bounded raw evidence, capability profiles, and projections. It
is not a transport implementation and does not configure SocketCAN.

## Fail-Closed Identification

A profile identifies only when all declared discriminators match. A missing
discriminator, malformed observation, overlap with another profile, or
unsupported version leaves the observation unknown and opaque. Unknown
observations have no vendor projection.

## Evidence and Projection

Evidence is bounded in size and carries caller-supplied capture context. A
projection is emitted only where a profile defines the exact source field,
representation, and capability gate. Unspecified fields remain raw.

Profiles are isolated. Adding a vendor such as Gree VRF or a future vendor must
not alter the generic registry contract or another profile's classification.
