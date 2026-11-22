# Gree VRF UART-to-CAN Command Map

This document defines the numeric command table used to translate selected
UART `R` property entries into candidate CAN command payloads.

Every encodable row is sent through the
[command contract](gree-vrf-can-command-contract.md) when it is called. A UART
reply does not prove CAN delivery, device acceptance, or a physical effect.

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
low byte is the register coordinate:

| High byte | Value kind | Low byte | CAN data bytes | DLC |
| --- | --- | --- | --- | ---: |
| `0x6f` | Boolean | bit coordinate | `index 01 bool(value)` | 3 |
| `0x71` | Unsigned 8-bit | byte coordinate | `index 01 value` | 3 |
| `0x73` | Unsigned 16-bit, little-endian | byte coordinate of the low byte | `index 03 value_lo value_hi` | 4 |

`index` in the data bytes is the low byte of the register. The second data
byte is a mask of the value bytes present, not a count: `01` marks one value
byte and `03` the two bytes of one 16-bit value. For `0x6f` the value byte
carries one boolean for the bit at that coordinate only; data-family reports
pack eight bits into one byte, but these command bytes do not. No form beyond
these three is defined. The
[register model](gree-vrf-can-register-model.md#addressed-write-frames)
describes the same layouts.

A command value that reappears in the data family is not a confirmation of a
physical effect. No confirmation, repetition or arbitration protocol is
defined.

Profile-qualified property labels in the table are noncanonical diagnostics.
Numeric ID equality across Profile A and Profile B does not imply equal
meaning.

## Label Conflicts

Two groups of candidate labels disagree with the
[parameter dictionary](gree-vrf-can-dictionary.md#conflicts). This page
chooses no side:

| Rows | Registers | Candidate labels | Dictionary definition |
| --- | --- | --- | --- |
| `0x14`, `0x18`, `0x1a` | `0x7304`, `0x7308`, `0x730a` | upper energy-saving limits | lower energy-saving limits |
| `0x2b` | `0x71b5` | automatic cleaning | commissioning key with its own enumeration |

No value is defined for an automatic-cleaning function, and the comparison
that a unit applies to the limits is not established. Sixteen encodable rows
address coordinates that the dictionary does not define; they resolve to
label-only entries.

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

The [register model](gree-vrf-can-register-model.md#clock-frame) describes a
clock frame with identifier `0x04820084` and the same data layout. Its low 14
identifier bits and its receivers are not established, and neither identifier
establishes the other.

## Profile Boundary

The 88-row table is the only documented primary command map. There is no
Profile-B write mapping and no active `M152` command path. Static encodability
is not by itself a send. A send uses the
[command contract](gree-vrf-can-command-contract.md).
