# Gree VRF CAN Parameter Dictionary

## Status and Relationship

Declared from the vendor documentation. `gree-vrf-can` is qualified with
these pages as its specification evidence. The hardware test level is recorded
per class. The publication basis is stated in the
[protocol index](README.md#publication-basis).

The dictionary names the registers of the
[register model](gree-vrf-can-register-model.md). Each entry gives a type, a
coordinate, a native value type from
[gree-vrf-can-value-types.json](gree-vrf-can-value-types.json), and where
defined a native label, a unit, a presentation converter and an enumeration.
A label is native and noncanonical; it does not become a Helianthus name.

## Files

The dictionary is split into disjoint slices. Every type belongs to exactly
one slice.

| Slice | Types | Positions | Named values | Bit containers | Named bits | Label-only entries |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| [identity](dictionary/identity.json) | `0x10`, `0x11`, `0x12`, `0x13` | 64 | 63 | 1 | 6 | 0 |
| [temperatures-operating-state](dictionary/temperatures-operating-state.json) | `0x20`, `0x21`, `0x24` to `0x27` | 179 | 179 | 0 | 0 | 5 |
| [status-bits](dictionary/status-bits.json) | `0x1c` to `0x1f`, `0x22`, `0x23`, `0x29`, `0x33`, `0x36` | 93 | 0 | 93 | 538 | 2 |
| [electrical-system](dictionary/electrical-system.json) | `0x14`, `0x28`, `0x31`, `0x32` | 198 | 198 | 0 | 0 | 0 |
| [settings](dictionary/settings.json) | `0x6d`, `0x6e`, `0x6f`, `0x71`, `0x72`, `0x73`, `0x78`, `0x79`, `0x7b`, `0x7c`, `0x7d` | 110 | 93 | 17 | 89 | 25 |
| [remaining](dictionary/remaining.json) | `0x34`, `0x35`, `0x3d` to `0x41`, `0x4d`, `0x52` to `0x59` | 135 | 112 | 23 | 127 | 16 |
| Total | 50 types | 779 | 645 | 134 | 760 | 48 |

## Entry Schema

Every slice file has `schema` `gree.vrf.can.dictionary`, `schema_version` 1,
the slice name, its types, its counts and the list `entries`.

A value entry (`kind` `value`) has:

| Key | Meaning |
| --- | --- |
| `type` | register type |
| `coordinate` | byte coordinate of the first byte |
| `value_type` | native value type |
| `width` | number of bytes; a value of width 2 also occupies `coordinate + 1` |
| `label` | native label, when it is an identifier in Latin script |
| `label_en` | English rendering of a native label written in another script |
| `unit` | native unit as declared |
| `presentation_converter` | name of a [presentation converter](gree-vrf-can-presentation-converters.md) |
| `enumeration` | list of `value` and `label`; `label_translated` marks an English rendering |
| `notes` | statements that qualify the entry |
| `conflict` | a disagreement between definitions; it is kept, not resolved |
| `description` | English statement of a meaning the entry states; absent when no meaning is stated |

A bit container (`kind` `bits`) has `type`, `container` (byte index) and
`bits`. Each bit has `bit`, its bit `coordinate` (`8 * container + bit`), a
`label` or `label_en`, where defined `set_label` and `clear_label` for the
values 1 and 0, and `description` when a meaning is stated. A container without named bits exposes its raw byte only.

A label-only entry (`kind` `label_only_bit` or `label_only_value`) marks a
coordinate that the [CAN bus contract](vrf-canbus.md) maps or the
[command map](gree-vrf-command-map.md) addresses but that has no definition
here. It has the coordinate, the width or bit, `candidate_labels` per profile
label (`A`, `B`), and `referenced_by` (`M94`, `M115`, `commands`). It has no
unit, enumeration or effect. Of the published rows, 17 of 94 `M94` rows,
21 of 115 `M115` rows and 16 of 47 encodable command rows resolve to
label-only entries.

## Reading the Dictionary

- A position without a definition is not a zero, reserved or absent byte; it
  has no definition here.
- An enumeration value without a label is kept as a number.
- The unit, the value type and the presentation converter are three separate
  properties. A decoder applies the value type only.
- Width-2 values at odd coordinates are valid register positions; see the
  [register model](gree-vrf-can-register-model.md#register-coordinates-and-frame-rules).
- Entries of a value type without a decode rule expose their raw byte only.
- The same type and coordinate are read in the context of the device class;
  a label of one class does not carry over to another class.

## Unnamed Ranges

Types `0x00` to `0x0f` are declared as bit ranges without names:

| Type | First index | Last index |
| --- | --- | --- |
| `0x00` | `0x20` | `0x22` |
| `0x01` | `0x00` | `0x1f` |
| `0x02` to `0x0f` | `0x00` | `0xff` |

These ranges define no label, unit or meaning, and do not state whether an
index is a byte index or a bit coordinate.

## Notes Carried by Entries

Selected statements that the slice files carry:

- `10:04` is the family and profile identifier of every device class,
  outdoor units included, although its native label names indoor units. It
  does not identify a commercial model.
- `10:07` is six raw bytes kept in order. It is not a number, and its label
  does not establish it as the hardware address of a network adapter.
- Type `0x12` holds two bar codes of twelve fragments each. Fragment encoding
  and concatenation are not defined; a missing fragment is not replaced by
  zero.
- `11:00` keeps its native unit kW on a switch code; it is not a measured
  power. `71:0a` keeps its native unit sec on a selection; it is not a
  duration.
- `20:00` (indoor ambient), `20:05` (return air) and `31:0a` (high-precision
  ambient) are three parameters; their equality is not guaranteed. `21:05`
  names the sampling point of `20:00`.
- `20:09` and `20:18` are relative humidity with the offset of 100.
- `21:00` is the effective mode and `21:01` the effective fan step. They are
  not the setting registers `71:00` and `71:01`, and their enumerations
  differ.
- `1f:00` bit 0 is the power state; the on/off setting is `6f:00` bit 0.
  `1f:00` bit 4 is the most direct indicator of running capacity; it is not
  shown to equal thermostat-on or a measured heat delivery.
- `1e:00` bit 0 is the general indoor-unit fault flag and is not defined as
  the OR of every fault bit. `1e:0a` bits 1 and 2 and `1d:0e` bits 3 and 4 are
  four distinct system fault flags.
- `14:04`, `14:0c`, `14:10` and `14:14` are electrical quantities, not thermal
  capacities. Direction, measuring point, counter lifetime, reset and
  rollover are not established.
- `31:85` and `31:87` are the running and target capacity of the own module
  in per mille; their relation to the rated capacity `10:0e` is not
  documented. `31:91` and `31:93` are absolute pressures.
- `32:50`, `32:52`, `32:54`, `32:56` and `32:58` are stored fault codes. Raw
  `0x0000` and raw `0xffff` carry the same label and neither is declared as
  no fault. No register is defined as the currently displayed fault code.
- `41:04` and `7d:03`: values 5 and 6 are distinct pollution levels.

## Conflicts

Each conflict is kept in the entry and resolved by neither side:

| Entry | Conflict |
| --- | --- |
| `73:04`, `73:08`, `73:0a` | Defined as lower energy-saving limits; the command map labels the same coordinates as upper limits. The comparison the unit applies is not established. |
| `71:b5` | Defined as a commissioning key with its own enumeration; the command map labels the coordinate as automatic cleaning. No value is defined for automatic cleaning. |
| `20:5d`, `20:5e` | Label and description name different quantities. |
| `20:c8` to `20:cb` | Target-pressure labels on a temperature value type; `20:ca` names the high pressure in its label and the low pressure in its description. |
| `21:02`, `71:02` value 5; `21:50` value 4 | Label and description name different positions or steps. |
| `27:5e`, `27:5f` | The description names a different stored fault than the label. |

## Names

No Helianthus name is assigned by this dictionary. A point is addressed by
type and coordinate and carries its native label as noncanonical text. A
snake_case name under the naming contract is assigned only when a point is
promoted to another surface.

## Thermal placement

The typed-point read boundary in the driver's MCP namespace is outside this
page. A documented value has no SemReg element in this repository; that
element is assigned by the consuming rows.

| Point | Dictionary entry | Value type | Native unit |
| --- | --- | --- | --- |
| terminal-unit mode | `21:51` | `uint8` | none; the value is an enumeration |
| fault | `1e:0a` bit 1, `1e:0a` bit 2, `1d:0e` bit 3, `1d:0e` bit 4 | `bits` | none; each bit is a boolean |
| operation | `1f:0a` bit 1 | `bits` | none; the bit is a boolean |
| air temperature | `20:00` | `uint8Minus100` | `℃` |
| setpoint | `73:00` | `uint16Devide10` | `℃` |
