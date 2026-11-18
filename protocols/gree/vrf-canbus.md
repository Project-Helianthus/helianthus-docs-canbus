# Gree VRF CAN Bus Contract

## Scope and Safety

This contract defines the Gree-specific candidate CAN profile and its complete
deterministic offline state-projection maps. It does not define generic CAN,
SocketCAN configuration, connector wiring, voltage levels, transceiver
selection, installed-equipment compatibility, or a live bus operation.

A conforming implementation MUST retain unsupported, malformed, and
out-of-profile observations without a Gree projection. Offline decoding and
encoding do not authorize a transmit, acknowledgement, probe, configuration
change, or state-changing request.

## Candidate Link Profile

| Parameter | Candidate value | Boundary |
| --- | --- | --- |
| CAN generation | CAN 2.0B | Gree profile metadata |
| Identifier format | 29-bit extended | Not a universal default |
| Nominal bit rate | `20 kbit/s` | Not electrically confirmed |
| Payload | Classical CAN, `0..8` bytes | Runtime validation required |
| Electrical layer | Unconfirmed | CAN+ is only a hypothesis |

The profile must not be used to infer transceiver type, connector pinout,
voltage levels, termination, polarity, or CAN+ equivalence.

## Extended Identifier Layout

The 29-bit identifier is partitioned as follows:

| Bits | Neutral name | Extraction |
| --- | --- | --- |
| `28..21` | `class8` | `(id >> 21) & 0xff` |
| `20..14` | `opaque7` | `(id >> 14) & 0x7f` |
| `13..7` | `unit7` | `(id >> 7) & 0x7f` |
| `6..0` | `opcode7` | `id & 0x7f` |

`opaque7` remains opaque. The partitions do not establish source/destination
polarity or final unit semantics.

## Candidate Identifier Gate

A candidate frame uses a 29-bit extended identifier and requires every one of
these conditions:

~~~text
class8 = 0xf7
unit7  = 8
opcode7 in { 0x10, 0x11, 0x52, 0x58 }
~~~

The class and opcode comparison is:

~~~text
(id & 0x1fe0007f) in {
  0x1ee00010,
  0x1ee00011,
  0x1ee00052,
  0x1ee00058,
}
~~~

The unit7 comparison is independent:

~~~text
((id >> 7) & 0x7f) = 8
~~~

The masked comparison alone is insufficient because it does not include
unit7. `opaque7` is part of the source identity and MUST NOT be normalized,
discarded, or assigned a device or property meaning.

## Receive Layout

A table-driven state update uses:

```text
start_coordinate = data[0]
payload_bytes     = data[1:dlc]
source_key        = (opcode7 << 8) | coordinate
```

The packed map row contains a 16-bit source key, a destination bit for packed
bit sources, and a destination state-cell ID. Bit 19 is reserved and zero in
the active rows.

Strict implementations must apply these structural gates before table lookup:

1. require `1 <= dlc <= 8`;
2. for byte sources, require
   `start <= coordinate < start + (dlc - 1)`;
3. for packed-bit sources, require
   `start <= coordinate < start + 8 * (dlc - 1)`;
4. reject coordinate-span overflow above `0xff`;
5. for `u16_le_byte_stream`, reject a frame when `data[0]` bit 0 is set.

The complete deterministic rows are in
[gree-vrf-can-profile.json](gree-vrf-can-profile.json).

## Active Maps

Profile labels `A` and `B` are noncanonical convenience labels.

| Map | Profile label | Rows | Unique destination cells | Source kinds | Emits UART `p` |
| --- | --- | ---: | ---: | --- | --- |
| `M94` | `A` | 94 | 73 | 51 bit, 23 u8, 20 u16 LE stream | yes |
| `M115` | `B` | 115 | 83 | 46 bit, 37 u8, 32 u16 LE stream | no |

`M94` has 93 unique source keys because `0x220d` appears twice. Every row that
matches a source key is applied in ascending row-index order. The two `0x220d`
rows therefore update both destination bits 3 and 4. `M115` has 115 unique
source keys. The candidate Profile-B selector set is:

```text
605d 6079 6084 608d 608e 6091 6098 6099 60a0 60a4 60a9
```

All other selector values use Profile A under this candidate classification.
Selector interpretation and profile labels remain profile-qualified and
require runtime validation.

No active `M152` map is part of this profile.

## State-Cell Update Rules

For ordinary rows, byte sources replace one destination byte and packed-bit
sources replace only the selected destination bit. A matching row may then
apply one named transform:

The machine contract represents every transform as ordered operations with
explicit conditions, relative cell offsets, global latch names, and collection
effects. Cell offsets are signed and relative to the current row destination.

| Transform | Normative effect |
| --- | --- |
| `boolean_to_magic_aa_55` | Raw `1` becomes `0xaa`; every other value becomes `0x55`. |
| `swing_value_remap` | Raw `1` becomes `0`; raw `2` becomes `1`; other values retain the ordinary write. |
| `mode_range_to_boolean` | Raw `1` becomes `0`; raw `2..4` becomes `1`; other values retain the ordinary write. |
| `nonzero_boolean_with_one_cleared` | Raw `0` and `1` become `0`; values above `1` become `1`. |
| `aggregate_error_latch_part` | After the ordinary bit write, raw `1` sets the aggregate latch; raw `0` leaves it unchanged. |
| `aggregate_error_latch_finalize` | Nonzero raw data keeps the ordinary bit and clears the latch; raw zero restores bit 0 when the latch is set. |
| `run_mode_coupled_remap` | A set coupled cell forces value `5`; raw `5` or `6` sets the coupled cell. |
| `global_mode_latch_update` | Raw `1` writes `7` and sets the mode latch; other values retain the ordinary write and clear the latch. |
| `mode_updates_all_100_slot_flags` | Apply the ordinary write. If cell `dest+0x13` is nonzero, write `2` to cell `dest+0x11`. Otherwise, when cell `dest-4` is nonzero, raw `1`, `2`, or `5` clears every slot flag and raw `4` or `6` sets every slot flag to `1`. |
| `global_mode_latch_projection` | A set mode latch writes `7`; otherwise the ordinary write is retained. |
| `coupled_state_remap` | If the completed destination byte equals `1`, the coupled cell three positions later becomes `6`. |
| `mode_value_remap` | A set guard cell forces `6`; otherwise `1` becomes `7`, `2..6` become `raw-1`, and other values are retained. |

The `all_slot_flags` collection has exactly 100 ordered members. Member
`slot_index` is state cell `0x1c` in unit slot `slot_index`, for indices `0`
through `99`.

Receive processing first validates the frame gates, then applies frame rules,
then applies every matching row in ascending row-index order, and finally
applies eligible Profile-B post-decode cleanup. Before matching rows, a frame
whose start key is `0x3d00` clears the aggregate error latch. A zero-valued
aggregate finalize restores bit 0 when that latch is set and leaves the latch
set; a later nonzero finalize clears it.

The [machine-readable profile](gree-vrf-can-profile.json) includes normative
initial-state, input, and expected-state vectors covering every transform,
duplicate-row application, collection-wide changes, frame-rule ordering, and
Profile-B cleanup.

For Profile-B selector values `0x6098` and `0x60a4`, post-decode cleanup sets
state cells `0x06`, `0x11`, and `0x44` to zero and clears bit 1 of state cell
`0x42`. This cleanup runs after all matching M115 rows and also runs when an
otherwise valid decode attempt has no matching row.

These transforms describe state projection only. They do not establish final
property names or units.

## Bounded Opaque Cell Projection

After the candidate identifier gate, frame gates, selected map, and applicable
post-decode cleanup succeed, an implementation may expose each updated state
cell as the bounded pair `cell` and `value`. `cell` is the numeric state-cell
identifier and `value` is its final unsigned byte after all ordered updates.

The pair remains opaque. It has no unit, range, direction, writability,
equipment identity, or HVAC property meaning. A rejected or unqualified frame
has no cell/value projection.

When an implementation receives native frame context, it must retain and
expose every available identifier field, identifier format, DLC, raw DLC, and
payload byte. Native data remains separate from a semantic projection. A
missing native field must not be fabricated, hashed, summarized, or replaced
with a redaction marker.

## Offline Command Encoding Boundary

The [command map](gree-vrf-command-map.md) defines deterministic in-memory
encoding for its explicitly supported rows. It makes no live, electrical,
delivery, acceptance, or safe operating-effect claim. The generic SocketCAN
transport contract remains receive-only.

## Compatibility

This is a candidate profile. It does not establish electrical compatibility,
installed-unit support, timing behavior, arbitration behavior, or delivery to
a physical bus. An unqualified observation remains opaque by default.

## What one interface establishes

One candidate CAN interface does not by itself establish system membership or
a unit role. No field on this surface is a canonical resource identity or a
zone. The unit field `unit7` is a destination coordinate and never an identity
anchor. The layout has no sender field. A display number is presentation; this
surface does not define one, and a display number is not an identity anchor.
An index in `all_slot_flags` is an ordered collection position. Slot order is
not membership and is not a relation.

Resource and relation rules are those of the common contract. The common
contract asks the native owner whether a relation is observable and for which
scope, and which token identifies a unit stably, in which canonical form.
Until those answers are stated for this family, the default is two resources,
no relation, and the relation unknown.

`unit7` equal to 8 is the candidate identifier gate. It admits frames. It
does not count systems, and it does not name a unit that holds system values.
`opaque7` stays part of the identifier and must not be assigned a device or
property meaning. That partition is not a stable unit token and not a
canonical resource identity. The projection latch `aggregate_error_latch` is
a state-cell rule. It is not a system aggregate, and it names no supplying
unit. The bounded pair `cell` and `value` has no equipment identity. The UART
seven-byte unit value is a field of the other protocol surface and is not a
token of this interface.

Each row has one grade: Proven, Hypothesis, or Unknown. The grade is Proven
or Hypothesis only when a protocol page of this repository, or a public
installation or service document, states the row. Otherwise the grade is
Unknown and the row names the missing fact. Slot order and display numbers
are not a basis. No row defers to a later site result.

| Question | What one interface establishes | Grade | Evidence |
| --- | --- | --- | --- |
| One system per bus, or not | Not established. | Unknown | Missing fact: whether one interface carries one system, more than one system, or no system. No protocol page under `protocols/gree/` states it, and this repository cites no public installation or service document that states it. |
| Which unit supplies the system aggregates | Not established. | Unknown | Missing fact: which unit, if any, supplies system aggregate values. [State-Cell Update Rules](#state-cell-update-rules) defines `aggregate_error_latch` only as a projection rule. No protocol page under `protocols/gree/` names a supplying unit, and this repository cites no public installation or service document that states it. |
| Whether outdoor-module values belong to that system | Not established. | Unknown | Missing fact: whether a value of an outdoor module belongs to a system on this interface, and how an outdoor module relates to a refrigerant circuit. No protocol page under `protocols/gree/` defines an outdoor module, and this repository cites no public installation or service document that states it. |
| How indoor, hot-water and tank units relate to the system and to the refrigerant circuit | Not established. | Unknown | Missing fact: how an indoor unit relates to a system, how an indoor unit relates to a refrigerant circuit, and the same two relations for a hot-water unit and for a tank unit. No protocol page under `protocols/gree/` defines those roles, and this repository cites no public installation or service document that states it. |
| Whether any field is a stable unit token | Not established. | Unknown | Missing fact: a token that identifies a unit stably, and the canonical form of that token. [Extended Identifier Layout](#extended-identifier-layout) states that the partitions do not establish final unit semantics. [Candidate Command Identifier](gree-vrf-command-map.md#candidate-command-identifier) places `unit7` in the identifier as the unit field. [Bounded Opaque Cell Projection](#bounded-opaque-cell-projection) assigns the cell pair no equipment identity. None of those pages names a stable unit token. |

None of these grades admits a relation. A relation stays unknown until native
documentation of this family states that the relation is observable for a
stated scope.
