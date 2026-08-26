# Gree VRF CAN Bridge-Record V1

This document defines a bounded structural record passed after candidate CAN
state reassembly. It does not define generic CAN, a UART frame, an equipment
identity, or HVAC property meaning.

## Record Boundary

A complete bridge record is exactly `0x23 bytes` long. The handoff receives a
pointer to the first byte together with length `0x23`.

| Byte index | Fixed value or source | Boundary |
| --- | --- | --- |
| `0..1` | `0x7e 0x7e` | Fixed prefix. |
| `2..8` | Opaque | Not specified by this contract. |
| `9..15` | State slot cells `0..6`, in ascending cell order | Copy exactly seven bytes. |
| `16` | `0x00` | Fixed. |
| `17` | `0x10` | Fixed. |
| `18` | `0x73` | Fixed marker. |
| `19..20` | Opaque | Not specified by this contract. |
| `21` | State slot cell `3` | Copy one byte. |
| `22..33` | State slot cells `0x10..0x1b`, in ascending cell order | Copy exactly twelve bytes. |
| `34` | Opaque | Not specified by this contract. |

The structural slot index is `0`. This contract does not define a second slot
or a multi-slot record. A bridge-record reader must reject a buffer whose
length is not exactly `0x23`.

## Synthetic Fixture

The fixture below names the complete set of fixed positions and bounded copy
ranges. `opaque` means that the byte must be retained as an uninterpreted
position; it is not a value wildcard for a serializer.

```text
length: 0x23
slot:   0

0:0x7e  1:0x7e  2..8:opaque
9..15:cell[0..6]
16:0x00  17:0x10  18:0x73  19..20:opaque
21:cell[3]  22..33:cell[0x10..0x1b]  34:opaque
```

This fixture is a boundary check, not a complete frame encoder or parser.
Implementations must not assign meaning to opaque positions, calculate a
trailer value, or construct a full record from this fixture alone.

## Callback Handoff Boundary

The handoff accepts the bounded buffer and its fixed length only. This
document does not identify the recipient, transport, direction, timing, or
delivery result. It must remain separate from UART: the bridge-record prefix,
marker, and cell positions do not establish UART framing or command behavior.

## Safety Boundary

Writes are disabled and unsafe. Bridge records must not be transmitted to
equipment. The structural boundary does not establish electrical
compatibility, delivery, acceptance, or a safe operating effect.
