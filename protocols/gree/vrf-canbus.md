# Gree VRF CAN Bus Contract

## Scope and Safety

This contract defines the Gree VRF candidate CAN profile named
gree.vrf.canbus.candidate.v1. It defines passive parsing and profile
qualification only. It does not define generic CAN, SocketCAN configuration,
connector wiring, voltage levels, transceiver selection, or a send operation.

A conforming implementation MUST remain receive-only. A syntactically
recognized frame MUST NOT cause a transmit, acknowledgement, probe,
configuration change, or state-changing request.

## Candidate Link Profile

| Parameter | Candidate value | Constraint |
| --- | --- | --- |
| CAN generation | CAN 2.0B | Gree profile metadata only |
| Identifier format | 29-bit extended | Not a universal SocketCAN default |
| Nominal bit rate | 20 kbit/s | Electrical applicability is unconfirmed |
| Payload | Classical CAN, 0 through 8 bytes | Runtime qualification required |
| CAN+ | Electrical hypothesis | Not equivalent to CAN |

The candidate link profile MUST be explicit configuration. It MUST NOT be
selected from an interface name, connector, or single received frame.

## Extended Identifier Layout

| Bits | Name | Extraction |
| --- | --- | --- |
| 28..21 | class8 | (id >> 21) & 0xff |
| 20..14 | opaque7 | (id >> 14) & 0x7f |
| 13..7 | unit7 | (id >> 7) & 0x7f |
| 6..0 | opcode7 | id & 0x7f |

opaque7 MUST be retained without a semantic assignment. The layout does not
establish sender/receiver direction or a final unit identity.

## Receive Layout

For table-driven data frames, data[0] is start_coordinate and the remaining
payload is a coordinate stream. The source key is:

~~~text
source_key = (opcode7 << 8) | coordinate
~~~

Before a table lookup, a receiver MUST require 1 <= dlc <= 8. For a byte
source, the coordinate MUST satisfy start_coordinate <= coordinate <
start_coordinate + dlc - 1. For a packed bit source, it MUST satisfy
start_coordinate <= coordinate < start_coordinate + 8 * (dlc - 1). A span
above 0xff is invalid. An invalid frame has no profile projection.

## Candidate Decode Families

| Family label | Revision status | Projection boundary |
| --- | --- | --- |
| M94 | Decoder details are not specified by this revision | Raw data only |
| M115 | Decoder details are not specified by this revision | Raw data only |

M94 and M115 are profile-qualified decoder labels. This revision defines no
complete row map, target-cell map, transform set, or automatic family
classifier for either label. A conforming registry MUST retain the payload raw
until a later revision supplies the complete deterministic contract.

The candidate M115 selector set is:

~~~text
605d 6079 6084 608d 608e 6091 6098 6099 60a0 60a4 60a9
~~~

An M115 selector match is not a Gree identifier and does not admit a Gree
projection. Every selector outside this set remains opaque. M94 has no positive
admission discriminator in this revision and therefore also remains opaque. A
registry MUST expose a capability only after a later revision defines and the
installation satisfies a complete positive profile gate.

## State and Unknown Data

Numeric source key and raw payload are authoritative. Labels, units, ranges,
writability, target cells, transforms, and operational meaning are not
established by this revision. A later revision MAY define them only with a
complete deterministic map and an exact capability gate. All frames, fields,
and selectors remain opaque in this revision.

## Registry Admission

A registry MUST require explicit Gree candidate profile selection and every
required structural gate before exposing a Gree projection. Partial match,
malformed DLC, standard identifier, unsupported profile revision, or profile
overlap MUST produce an opaque observation with no vendor projection.

## Conformance Examples

| Input condition | Required outcome |
| --- | --- |
| Standard identifier | Opaque observation; no Gree projection |
| Extended identifier with dlc = 0 | Opaque observation; no Gree projection |
| Coordinate span above 0xff | Opaque observation; no Gree projection |
| M115 selector match | Opaque observation; no Gree projection |
| Any M94 candidate frame | Opaque observation; no Gree projection |

## Compatibility

This is a candidate profile. It does not establish electrical compatibility,
installed-unit support, timing behavior, arbitration behavior, or delivery to
a physical bus. A later revision MUST add new facts without broadening a
previously unknown observation into a Gree projection by default.
