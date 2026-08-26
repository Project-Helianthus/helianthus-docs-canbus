# Gree VRF Profile-Qualified Property Catalog

Numeric IDs and raw values are the wire authority. Labels in this catalog are
candidate diagnostics qualified by Profile A or Profile B. They are
noncanonical, may collide across profiles, and must not be exposed as final
property names without runtime validation.

The complete deterministic label sets and width markers are in
[gree-vrf-uart.json](gree-vrf-uart.json). The
[command map](gree-vrf-command-map.json) repeats labels only where a
UART ID is part of the 88-row command table.

## Width Markers

| Marker | Profile-qualified storage width |
| --- | --- |
| `0xff` | one byte |
| `0xffff` | two bytes |

The markers describe storage width only. They do not establish signedness,
scale, unit, range, writability, or final meaning.

## Profile Selection

Profile A is the default candidate label set. Profile B is selected for this
candidate product-ID set:

```text
605d 6079 6084 608d 608e 6091 6098 6099 60a0 60a4 60a9
```

The selector and both labels remain profile-qualified.

## Ambiguous Examples

| Numeric ID | Profile A candidate | Profile B candidate |
| --- | --- | --- |
| `0x05` | `GetEr`, `AllErr` | `Pow` |
| `0x06` | `Pow` | `Tur` |
| `0x0b` | `Mod` | `IDUAirQu` |
| `0x10` | `SetTem`, `SetDeciTem` | `InVitiGrCg` |
| `0x1d` | `GoOut`, `OutHome` | `InEffClRes` |
| `0x42` | `WUTHSetTem` | `PctCle` |
| `0x4b` | `FSetTem` | `PM2P5Sta` |
| `0xff` | `host` | `GasQ` |

Equal numeric IDs do not imply equal semantics. Multiple labels for one ID do
not imply aliases unless runtime validation establishes that relationship.

## Profile-A Q And R Typed Shapes

Handler shape is structural metadata, not a semantic name.

| IDs | Family | Structural behavior |
| --- | --- | --- |
| Q `0x10,12,14,16,18,1a` | two-byte value | Consume current and following vector bytes as big-endian after Profile-A selection. |
| R `0x10,12,14,16,18,1a,42,4b` | two-byte value | Require at least two entry data bytes after Profile-A selection. |
| R `0x3a/0x3b` | paired update | Treat the adjacent pair as the stricter signal. |
| R `0x45/0x46` | paired update | Treat the adjacent pair as the stricter signal. |
| R even `0x2a..0x4c` | table-shaped update | Use numeric handling except for explicitly specialized IDs. |
| R `0x59` | dedicated mapping | Distinct from frame type `Y/0x59`. |
| R `0xff` | global status | Keep numeric and opaque until runtime validation. |

Unknown Q/R IDs must be preserved as raw numeric items. Missing labels are not
a structural parse error.

## Profile-B Q And R Boundary

Profile-B catalog markers describe storage only. They do not establish Q or R
parser widths, including Q `0x10` and `0x11`, or R `0x10`, `0x12`, `0x18`,
`0x42`, and `0x4b`. Profile-B Q bytes and R entry data remain opaque and have
no semantic projection. In particular, a Profile-B Q value must not consume a
following byte because a Profile-A typed rule exists.

The Profile-B `U` state-bank request remains separate: its `0x5b` count is a
byte count for the opaque state-bank payload, not a Q/R width rule.
