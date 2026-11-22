# Gree VRF CAN Device Classes

## Status and Relationship

Declared from the vendor documentation. `gree-vrf-can` is qualified with
these pages as its specification evidence. The hardware test level is recorded
per class. The publication basis is stated in the
[protocol index](README.md#publication-basis).

A device class tells which unit addresses a register set belongs to and which
display offset applies. The class is keyed by the family and profile
identifier in register `10:04` of the
[register model](gree-vrf-can-register-model.md). The machine-readable table
is [gree-vrf-can-device-classes.json](gree-vrf-can-device-classes.json).

## Classes

| Class | Identifiers | Unit range | Display offset |
| --- | ---: | --- | ---: |
| Outdoor unit | 36 | system values at `0x08`; module values at `0x08..0x0b` | 7 |
| Indoor unit | 57 | `0x20..0x6f` | 31 |
| Hot-water unit | 2 | `0x20..0x6f` | 31 |
| Water tank | 1 | `0x20..0x6f` | 31 |

The display number of a unit is its address minus the display offset. It is
presentation only and never an identity.

Identifiers per class:

| Class | Identifiers at `10:04` |
| --- | --- |
| Outdoor unit | `0x0603`, `0x6030` to `0x6034`, `0x6037` to `0x6039`, `0x6062` to `0x6064`, `0x6066` to `0x606a`, `0x606e`, `0x6070`, `0x607a`, `0x607b`, `0x607d`, `0x6082`, `0x6083`, `0x6089`, `0x608a`, `0x608c`, `0x6090`, `0x6094` to `0x6097`, `0x609a` to `0x609c`, `0x609f` |
| Indoor unit | `0x4021`, `0x6040` to `0x605e`, `0x6071` to `0x6076`, `0x6079`, `0x607f`, `0x6080`, `0x6084` to `0x6088`, `0x608b`, `0x608d` to `0x608f`, `0x6091`, `0x6092`, `0x6098`, `0x6099`, `0x609d`, `0x60a1`, `0x60ff` |
| Hot-water unit | `0x6036`, `0x6065` |
| Water tank | `0x6035` |

The enumeration of `10:04` also lists `0x6093`, which belongs to no class.
The native labels of the identifiers are in the
[identity slice](dictionary/identity.json) of the dictionary.

## Profile Identity and Selection

- A profile is identified by `10:04` together with the device protocol
  version `10:02`. The general protocol version `10:00` is kept beside them.
- Two similar commercial names do not make one profile, and an identifier
  does not name a commercial model.
- Every class profile is defined for device protocol version 1 and general
  protocol version 1. Devices in one system report `0x000a` for both
  registers. A rule that relates the two values is not established.
- A device that reports a protocol version other than the class profile is
  decoded with that profile and the mismatch is marked.
- A reference lookup takes `10:04` and `10:02`, tries the exact version
  first, then higher versions up to 255, then lower versions down to 0. This
  order does not establish compatibility between versions, and a consumer
  reports the versions as read.

## Reference Sets

Each class profile lists a set of register coordinates for display. A set is
a display selection: it is not a capability list and not a write permission.
A register absent from a set can still be present on the bus. The sets are
not published here; only their system and module split is used above.

## State Projection Selectors

The [CAN bus contract](vrf-canbus.md#active-maps) selects map `M115` for
eleven identifiers. Eight of them are indoor-unit identifiers: `0x605d`,
`0x6079`, `0x6084`, `0x608d`, `0x608e`, `0x6091`, `0x6098` and `0x6099`. The
identifiers `0x60a0`, `0x60a4` and `0x60a9` belong to no class and to no
enumeration value of `10:04`. That `M115` corresponds to one device class is
not established.

## Not Established

- Unit ranges for mode converters, fresh-air units, wired controllers and
  central controllers.
- The commercial model behind an identifier.
- The meaning of `0x60a0`, `0x60a4` and `0x60a9`, and the class of `0x6093`.
- The relation between the reported version `0x000a` and the profile
  version 1.
