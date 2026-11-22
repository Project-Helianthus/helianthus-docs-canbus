# Gree VRF CAN Register Model

## Status and Relationship

Declared from the vendor documentation. `gree-vrf-can` is qualified with
these pages as its specification evidence. The hardware test level is recorded
per class. The publication basis is stated in the
[protocol index](README.md#publication-basis).

This page defines the register traffic of a Gree VRF CAN interface: the
identifier families, how a frame addresses a register, how values are packed,
and the layout of addressed write frames. The
[CAN bus contract](vrf-canbus.md) defines a separate, specialised state
projection and its maps; nothing on this page changes it. The
[parameter dictionary](gree-vrf-can-dictionary.md) names the registers, the
[value types](gree-vrf-can-value-types.json) decode them, the
[device classes](gree-vrf-can-device-classes.md) tell which unit sends which
set, and the [presentation converters](gree-vrf-can-presentation-converters.md)
describe display conversions.

This page describes frame layouts only. It makes no electrical, delivery,
acceptance or operating-effect claim. Addressed writes and the two clock
identifiers are specified by the
[command contract](gree-vrf-can-command-contract.md). The three addressed-write
forms are in its [Frame forms](gree-vrf-can-command-contract.md#frame-forms)
table, and the two separately invoked fixed-ID forms are in its
[Clock frame](gree-vrf-can-command-contract.md#clock-frame) section.

## Notation

Identifiers, types, coordinates, masks and enumeration values are
hexadecimal. Lengths and counts are decimal. `T:C` names type `T` and
coordinate `C`; it is not a complete CAN identifier. For a bit type, `C` is a
bit coordinate.

## Identifier Families and Addressing

Register traffic uses 29-bit extended identifiers with the partitions of the
[CAN bus contract](vrf-canbus.md#extended-identifier-layout). On this page the
low seven bits are called the type.

| Bits | Field | Extraction |
| --- | --- | --- |
| `28..21` | `class8` | `(id >> 21) & 0xff` |
| `20..14` | `opaque7` | `(id >> 14) & 0x7f` |
| `13..7` | unit | `(id >> 7) & 0x7f` |
| `6..0` | type | `id & 0x7f` |

Three families carry registers. They share this layout, and all three use
`opaque7 = 0x7f`:

| `class8` | Base with `opaque7 = 0x7f` | Family | Payload |
| --- | --- | --- | --- |
| `0xf7` | `0x1effc000` | data | start coordinate, then values |
| `0xe7` | `0x1cffc000` | addressed data | start coordinate, then values |
| `0xe5` | `0x1cbfc000` | addressed write | start coordinate, value mask, then values |

A register identifier is `base | (unit << 7) | type`, where the base is
`(class8 << 21) | (0x7f << 14)`. For example, type `0x20` of unit `0x20` in
the data family is `0x1effd020`, type `0x20` of unit `0x08` is `0x1effc420`,
and type `0x73` of unit `0x20` in the addressed write family is
`0x1cbfd073`.

Addressing rules:

- In the addressed data and addressed write families the unit field names the
  destination. No field of these identifiers names the sender.
- In the data family the unit field is the unit address under which the
  register is kept. Whether that unit is also the sender is not established.
- No own address of a gateway, controller or other node is defined.
- `0x7f` is the only `opaque7` value described for the three families. Its
  meaning is not established, and this page does not call it a broadcast
  marker.
- Addressed data payloads are register data in the same layout as the data
  family, packed bits and multi-byte values included. They are not request
  codes. Which node emits them is not established.
- No read-request transaction is defined on CAN.
- `class8` value `0x24` is used by the [clock frame](#clock-frame). No other
  `class8` value is assigned by this page.

Unit ranges:

| Units | Device classes |
| --- | --- |
| `0x08..0x0b` | outdoor modules; system values are kept under unit `0x08` |
| `0x20..0x6f` | indoor units, hot-water units and water tanks |

No separate unit range is defined for mode converters, fresh-air units, wired
controllers or central controllers. A display number is presentation only:
it is the unit minus 7 for outdoor modules and the unit minus 31 for the
indoor side, so unit `0x08` and unit `0x20` both display as 1. Unit values in
examples are examples, not a numbering rule.

## Register Coordinates and Frame Rules

A frame of the data or addressed data family carries:

```text
data[0]          start coordinate S
data[1..dlc-1]   values
```

A frame with `dlc = 1` defines no value. A value needs `dlc` from 2 to 8.

Byte types use byte coordinates. Value byte `data[j+1]` is coordinate `S+j`
of the register. Multi-byte integers are little-endian: the byte at the lower
coordinate is the less significant one.

Bit types use bit coordinates. Value byte `j` covers bit coordinates
`S+8j .. S+8j+7`, least significant bit first. `S` need not be a multiple of
8, so a frame can start inside a dictionary container. Bit `k` of dictionary
container `i` is bit coordinate `8i+k`. For example, coordinate `0x13` of a
bit type is container `0x02`, bit 3.

Register identity and updates:

- A register is identified by interface, family, unit and type. Values of
  different units or different types are never combined.
- An update is partial. A coordinate outside the frame keeps its previous
  state. A value that never arrived is absent, never zero.
- `dlc < 8` does not mark the end of a register. A partial update does not
  invalidate the other values of the register.
- A multi-byte value is taken only when all of its bytes arrive in one frame.
  Bytes of different frames are never joined. Reassembly across frames, cycle
  identification and freshness are not defined.
- An enumeration value without a label is kept as a number.
- No raw value is a universal marker for an absent sensor. A temperature byte
  of `0x46` is not such a marker.

Multi-byte values also start at odd coordinates: 16-bit values of type `0x31`
from `0x5f` to `0x97`, the 32-bit value `27:65`, and the 16-bit values `10:1b`,
`10:1d` and `11:05`. The even-start gate of the
[CAN bus contract](vrf-canbus.md#receive-layout) belongs to its
`u16_le_byte_stream` map rows; it is not a property of registers.

Conventions that are not rules:

- Coordinates below `0x50` usually hold indoor-side values and coordinates from
  `0x50` usually hold outdoor-module and system values. Bit container `0x0a`
  is bit coordinate `0x50`.
- Pages that start at `0x80` and at `0xc8` exist; no protocol role is assigned
  to them.

System and module values: outdoor reference sets take system values from unit
`0x08` and module values from units `0x08..0x0b`. Whether other modules also
send system values is not established.

Type `0x13` holds start-of-transmission flags. Some registers are sent only
after such a flag is set; the set of those registers is not established. A
receive-only listener treats a register it never received as absent, not as
unsupported.

## Value Types

Each dictionary entry names a native value type. The rules are in
[gree-vrf-can-value-types.json](gree-vrf-can-value-types.json). With `b0` the
first value byte, `u = b0 + 256*b1` and `v` the 32-bit little-endian value:

| Name | Bytes | Result |
| --- | ---: | --- |
| `uint8` | 1 | `b0` |
| `uint8M2` | 1 | `2*b0` |
| `uint8Devide2` | 1 | `b0/2` |
| `uint8Minus100` | 1 | `b0-100` |
| `cfloat8base10` | 1 | `b0/10` |
| `uint16`, `uint16multi256` | 2 | `u` |
| `uint16Devide10` | 2 | `u/10` |
| `uint16Devide100`, `uint16Multi10` | 2 | `u/100` |
| `uint16Devide3600`, `uint16Multi1000` | 2 | `u/3600` |
| `uint16Minus1000Devide10` | 2 | `(u-1000)/10` |
| `uint16Minus32768Multi10` | 2 | `(u-32768)/100` |
| `uint16Minus32768Multi1000` | 2 | `(u-32768)/3600` |
| `uint16DecimalsDevide256` | 2 | `b1 + b0/256` |
| `cfloat16base10` | 2 | `b1 + b0/10` |
| `cfloat16base256` | 2 | `b1 + b0/256`, rounded to two decimals, half to even |
| `uint16Int` | 2 | `b1 + f(b0)`; `f` is `b0/10000` for 0..9, `b0/100` for 10..99, `b0/1000` for 100..255 |
| `uint32` | 4 | `v` |
| `ubytes6` | 6 | six raw bytes in the order `b0` to `b5`; never a number |
| `bits` | 1 | one boolean per defined bit; bit 0 is the least significant |

Rules for every type:

- Divisions are real divisions.
- The names are native and kept as spelled. A name does not describe its
  rule: `uint16Multi10` divides by 100 and `uint16Multi1000` by 3600.
- `uint8Minus100` also applies to relative humidity: raw `0x91` is 45 %.
- No rule reserves `0xff`, `0xffff` or `0xffffffff`. Raw bytes stay available
  beside the decoded value.
- Input shorter than the rule needs gives no value.

Three names have no decode rule: `uint8Multi2`, `uint8Devide10` and
`uint8Minus100Devide10`. An entry of such a type exposes its raw byte only.
`uint8Multi2` is not an alias of `uint8M2`.

## Addressed Write Frames

A frame of the addressed write family carries:

```text
data[0]          start coordinate S
data[1]          value mask M
data[2..dlc-1]   values
```

`M` is a mask of the value bytes present, not a count:

| Register kind | `S` | Data bytes | DLC |
| --- | --- | --- | ---: |
| bit type | bit coordinate | `S 01 b`, `b` is `00` or `01` | 3 |
| byte value | byte coordinate | `S 01 v` | 3 |
| 16-bit value | byte coordinate of the low byte | `S 03 lo hi` | 4 |

For a bit type the value byte carries one boolean for the bit at coordinate
`S` and for no other bit. Data-family reports pack eight bits into each value
byte; an addressed write frame carries one bit per value byte. Other masks,
several bits in one frame and longer value runs are not defined.

Example: setting the set temperature `73:00` of unit `0x20` to 23.0 °C is
identifier `0x1cbfd073` with data `00 03 e6 00`. Setting the on/off bit
`6f:00` bit 0 of the same unit is identifier `0x1cbfd06f` with data
`00 01 01`. A one-byte write to `6f:00` may also change the functions of bits 1..7 of that byte, and the actual effect of the write on those bits is not established. A start command does not imply that those bits are
preserved.

Boundaries:

- When a value reappears in the data family after an addressed write frame,
  the report is not a confirmation of a physical effect. The effective mode
  can differ from the set mode, for example when the requested mode conflicts
  with the mode of the outdoor unit.
- No confirmation, repetition, timeout or arbitration protocol between
  several controllers is defined.
- Which registers a device accepts, and which it refuses, is not
  established. No rule derives acceptance from the type number. Setting types
  `0x6d` to `0x7d` correspond only in part to status types (`0x71` with
  `0x21`, `0x6f` with `0x1f`, `0x78` with `0x28`); they are not mirrors.
- The [command map](gree-vrf-command-map.md) is a separate, profile-qualified
  table of candidate commands and keeps its own boundary.

## Clock Frame

A clock frame has its own identifier outside the three register families:

| Field | Value |
| --- | --- |
| Identifier | `0x04820084` (`class8 = 0x24`, `opaque7 = 0x08`, unit `0x01`, type `0x04`) |
| DLC | 8 |
| Data | `YY MM DD hh mm ss W 02` |

`YY MM DD hh mm ss` are packed decimal (two decimal digits per byte). `W` is
the weekday from 0 to 6. The last byte is `0x02`. In one system the frame
repeats about every 200 ms; that interval is not a requirement.

The meaning of the low 14 identifier bits, the sender and the set of
receivers are not established. The time payload of the
[command map](gree-vrf-command-map.md#time-payload) uses the same data layout
under its own candidate identifier.

## Timing

The following intervals were seen in one system. They are orientation, not
requirements, and they do not define freshness:

| Item | Interval |
| --- | --- |
| Clock frame | about 200 ms |
| Addressed data frames | about 625 ms per indoor unit |
| Complete cycle of some registers | on the order of 20 s |
| First data-family fragment from coordinate 0 after an addressed write frame | about 0.1 to 0.9 s |
| Type `0x21` after an addressed write frame | about 1 to 4 s |

## Not Established

- The meaning of `opaque7 = 0x7f`, and whether other values occur.
- The sender of addressed data and addressed write frames, and whether any
  node has an own address.
- Whether the bits in which `0xf7`, `0xe7` and `0xe5` differ have individual
  meanings.
- Which node emits addressed data frames, and their purpose.
- The low 14 bits, the sender and the receivers of the clock frame.
- The set of registers sent only after a start-of-transmission flag.
- Reassembly of a value split across frames, cycle identification and
  freshness.
- The set of registers a device accepts in an addressed write frame, and
  masks other than `01` and `03`.
- A confirmation, repetition or arbitration protocol.
- Whether outdoor modules other than unit `0x08` send system values.
- Unit ranges for mode converters, fresh-air units, wired controllers and
  central controllers.
- Decode rules for `uint8Multi2`, `uint8Devide10` and `uint8Minus100Devide10`.
