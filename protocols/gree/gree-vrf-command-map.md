# Gree VRF UART-to-CAN Command Map

This document defines the numeric command table used to translate selected
UART `R` property entries into candidate CAN command payloads.

Writes are disabled and unsafe. These encodings are documentation only. A UART
reply does not prove CAN delivery, device acceptance, or a safe operating
effect.

## Table Boundary

The table has exactly 88 little-endian 16-bit entries indexed by UART property
ID `0x00..0x57`.

| Classification | Count |
| --- | ---: |
| Encodable | 47 |
| Reserved `0xffff` | 40 |
| Unsupported width | 1 |
| Total | 88 |

IDs `0x58` and above are outside the table. `0x57` is in range but stores
`0x0000`, whose high byte has no supported encoding. No generic CAN command may
be formed for an out-of-table, reserved, or unsupported entry.

The complete table, including every reserved row, is in
[gree-vrf-command-map.json](gree-vrf-command-map.json).

## Register Families

For an encodable 16-bit value, the high byte selects the value family and the
low byte is the register index:

| High byte | Value kind | CAN data bytes | DLC |
| --- | --- | --- | ---: |
| `0x6f` | Boolean | `index 01 bool(value)` | 3 |
| `0x71` | Unsigned 8-bit | `index 01 value` | 3 |
| `0x73` | Unsigned 16-bit, little-endian | `index 03 value_lo value_hi` | 4 |

Profile-qualified property labels in the table are noncanonical diagnostics.
Numeric ID equality across Profile A and Profile B does not imply equal
meaning.

## Candidate Command Identifier

The candidate command construction preserves opaque seed bits, inserts the unit
field and the register-family opcode, then limits the result to 29 bits:

```text
word = (seed & 0xffffc000)
     | 0x001fc000
     | (unit7 << 7)
     | ((register >> 8) & 0x7f)

extended_id = word & 0x1fffffff
```

The opaque seed is part of the input. A fixed identifier prefix must not be
inferred from this formula.

## Time Payload

UART `w/0x77` has a separate documented command encoding:

- candidate extended identifier `0x04820000`;
- DLC `8`;
- bytes `year month day hour minute second weekday 02`;
- the first seven values use packed decimal.

The corresponding UART reply is handler-local and is not a delivery receipt.

## Profile Boundary

The 88-row table is the only documented primary command map. There is no
Profile-B write mapping and no active `M152` command path. Static encodability
must never enable a write.
