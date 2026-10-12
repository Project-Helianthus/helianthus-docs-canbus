# Growatt Low-Voltage BMS CAN Addressed Monitor Profile V1

This document describes a separate addressed profile that some monitor interfaces advertise: the extended-identifier families `04xx`, `08xx`, `10xx` and `14xx`, and the diagnostic record families `1881`/`18A1`, `1887`/`18A7`, `188B`/`18AB` and `188E`/`18AE`, with a per-signal field reference. It is not part of native LINK traffic.

[Profile](#addressed-monitor-profile) · [Field reference](#addressed-monitor-field-reference) · [Operating-state enums](#operating-state-enums) · [Structured fields](#structured-diagnostic-fields)

## Status and Relationship

This is an implementation-neutral protocol contract. It records candidate protocol claims and is published in the CC0 `protocols/` lane of this repository. CC0 does not grant rights in vendor specifications, trademarks, patents, software images or other third-party content.

**Helianthus status: candidate.** Nothing in this document is qualified by Helianthus against hardware, and no live trial has been run. A statement here is a documentation claim, not a support claim for any installed product. No public source is cited, and every statement is an unverified candidate claim. The words "qualified" and "qualification" below name a decoder's profile-matching state; they are not repository qualification claims.

**Receive-only boundary.** This repository authorizes no transmission, acknowledgement, probing, configuration, update or other live bus action. Where this document describes a message that a device accepts, it records the protocol's receiver behavior so that a decoder can interpret traffic correctly. It does not make that message available to Helianthus software. The capability and qualification conditions described here are necessary for a device to accept a message and are never sufficient: this repository defines no condition under which Helianthus software transmits.

**Relationship to the existing Growatt documents.** The [LINK protocol](growatt-low-voltage-bms-can-link-protocol-v1.md) and the [PCS protocol](growatt-low-voltage-bms-can-pcs-protocol-v1.md) describe the native module and stack interfaces; the [V1.04 contract](low-voltage-bms-can-v104.md) and its companions describe revision-labelled frames. This profile is independent of all of them:

- It is selected only by an independently qualified peer or protocol association together with compatible traffic. A project-code identity or a shared service PID never selects it, and it is never a fallback decoder for native `18xx` traffic.
- The same CAN identifier can carry a different layout in each set. An identifier match never selects a document.
- No correlation between this profile and project codes or published revision labels is established. A project-code selector MUST NOT select this profile, and this profile MUST NOT select a revision label.
- Signal names are descriptive labels. They are not stable identifiers, and a name alone does not establish the physical origin of a sensor or the safety meaning of a fault.
- Identifiers below are hexadecimal.

## Addressed monitor profile

Some monitor interfaces advertise an extended-ID format with `04xx`, `08xx`,
`10xx` and `14xx` families. Call this **Monitor-Addressed**. It must be selected by an
independently qualified peer/protocol association and compatible traffic. A QAAB
identity or a shared service PID does **not**
establish this profile. Do not use it as a fallback decoder for native `18xx`.

For system data, the addressed ID is `(base & FFFFFF00) + BCU`. For module data,
it is `(base & FF0FFF00) + (BMU << 20) + BCU`. BCU/BMU are protocol addresses,
not cell counts. Preserve them separately. The listed base IDs require
addressing before matching a particular peer.

This profile uses **LE16 for its 16-bit wire scalar fields**. Persisted records
and reassembled diagnostic records retain their own record-specific byte order;
the wire convention must not be applied to them globally. Byte order alone is not a discriminator between this profile
and native LINK. Identifiers, addressing, fragmentation, field positions, scales
and meanings retain their separate contracts. The convention does not establish
32-bit byte order or bit-to-channel ordering, and does not change fields explicitly
defined as BE16 in native LINK or PCS.

All rows are monitor telemetry, with RX class **U** (see the [receive-handler classes](growatt-low-voltage-bms-can-link-protocol-v1.md#receive-handler-classes)) for an automatically selected
peer until Monitor-Addressed support is independently qualified. No request/reply pair
or native LINK receive handler is implied by the advertised data item.

| Base PID | Detection / payload interpretation after Monitor-Addressed qualification |
|---|---|
| `04010000` | Four LE16 words: internal voltage ×0.1 V; current `(raw−30000)×0.1 A`; external voltage ×0.1 V; fuse-voltage field ×0.1 V. |
| `04020000` | Four LE16: maximum/minimum cell mV, maximum/minimum positions. |
| `04030000` | Four LE16: maximum/minimum temperature `raw/10−40 °C`, maximum/minimum positions. |
| `04040000` | Four LE16: USOC, SOH, ASOC (×0.1), cycle count. Preserve USOC and ASOC as separate quantities. |
| `04050000` | Four LE16: permitted charge/discharge current ×0.1 A; full/remaining capacity ×0.1 Ah. |
| `04060000` | Two four-byte cumulative charge-in/charge-out fields ×0.1 Ah. Byte order unqualified; retain raw bytes until the field contract is resolved. |
| `04070000` | Two four-byte cumulative energy-in/energy-out fields ×0.1 Wh. Byte order unqualified; retain raw bytes until the field contract is resolved. |
| `040A0000`–`040D0000` | Protection/alarm, system faults, other errors and hardware errors respectively; eight bytes each with profile-specific bit fields. Preserve raw until the exact bit dictionary is qualified; not native `185x` bitmaps. |
| `04100000` | B0–B3 hardware-state bytes; B4–B5 LE16 capacity ×0.1 Ah; B6–B7 LE16 resistance ×0.1 mΩ. |
| `04110000` | B0–B1 actuator state; B2 run mode; B3 work mode; B4–B5/B6–B7 LE16 charge/discharge current fields ×0.1. Charge is unsigned LE16; discharge is signed LE16. Mode enums and exact fields are defined in the complete field reference below. |
| `04120000` | B0/B1 main/sub software version; B2/B3 main/sub hardware version; B4–B7 four-byte numeric serial field, with byte order unqualified. This is not the native ASCII serial. |
| `04130000` | Four LE16: charge/discharge alarm thresholds ×0.1 A; two algorithm SOC estimates ×0.1%. |
| `04140000` | Four LE16 algorithm SOC estimates ×0.1%. |
| `04150000` | Three LE16 algorithm estimates ×0.1%; final LE16 SOC flags. |
| `04160000` | Four LE16: configured cell count; capacity field; breaker-voltage field ×0.1 V; total-voltage field ×0.1 V. Count is metadata, not measured coverage. |
| `04170000` | B0–B1 LE16 insulation-resistance field ×0.01 MΩ; remaining bytes unspecified. |
| `08000000`–`08030000` | Four LE16 cell slots per block, in mV; slots 1–4, 5–8, 9–12, 13–16. Do not assume those exhaust a product's configured cells. |
| `10000000` | Four LE16 sensor slots, `raw/10−40 °C`; advertised labels are cell T1–T3 and balance T1. |
| `10010000` | B0–B1 LE16 balance-temperature T2, `raw/10−40 °C`; remaining bytes unspecified. |
| `14000000` | Balance-flag word and per-cell bit fields. The complete field reference defines the addressed-profile bit positions; physical balancing semantics remain separately qualified. Do not reuse native `1801` ordering. |

Monitor-Addressed diagnostic families define `1881/18A1` product information,
`188B/18AB` controller information, `1887/18A7` history and `188E/18AE` module
information. These are separate advertised contracts, **not native LINK
queries**. Diagnostic fields may address a reassembled stream rather than one frame;
do not use stream offsets as CAN byte offsets. Handler support, framing and
side effects are separate conditions from decoding. Native `1881`, `1887`, `188B` and `188C`
are maintenance-only.

## Addressed monitor field reference

These tables apply only after the Monitor-Addressed profile and the endpoint's
scope have been qualified. They do not add receive handlers to native `18xx`
devices. Signal names that keep an unexpanded vendor-style abbreviation retain a label whose meaning is not established here. The signal names are descriptive labels, not stable identifiers; a name alone does not
establish the physical origin of a sensor or the safety meaning of a fault.

### Position, signedness and overlapping views

`B0…B7` are bytes in one classical CAN data frame. `B0.b7` is its most significant
bit and `B0.b0` its least significant bit. A range such as `bits3:2` names those
two physical bits. Full-word scalar byte order follows the selected field
contract; it must not be used to reverse the separately specified bit positions.

- Status fields tagged `INT8` use **LSB0** placement. An eight-bit value can also
  be rendered as signed two's-complement; retain its raw byte for bit operations.
  One- and two-bit subfields are nonnegative codes.
- The balancing `BOOL` fields use **MSB0** placement. Thus the declared first
  balance channel is B0.b7, the eighth B0.b0 and the ninth B1.b7. This is the
  addressed-profile bit contract; native `1801` has its own ordering and scope.
- Whole-byte status fields and their named subfields deliberately overlap.
  They are alternate views of the same payload, not additional bytes.
- The balance flag scalar and the individual balance labels also overlap.
  Apply the explicit bit positions to the labels; do not derive them using a
  generic native-LINK `bit n = cell n+1` rule.
- Numeric conversion is `(typed raw + offset) × factor`. Blank units remain
  unspecified. Preserve precision before applying application display rounding.

All live monitor frames below are publications, **not polling commands**.
The `042x`/`082x` companion IDs define no monitor request/reply transactions.

### `04010000` — Voltage and current

| Position | Signal | Encoding | Conversion / interpretation |
|---|---|---|---|
| B0–B1 | Internal pack voltage | LE16 unsigned | raw × 0.1 V |
| B2–B3 | Current | LE16 unsigned | (raw − 30000) × 0.1 A |
| B4–B5 | Output-port voltage | LE16 unsigned | raw × 0.1 V |
| B6–B7 | Fuse voltage | LE16 unsigned | raw × 0.1 V |

### `04020000` — Cell-voltage extrema

| Position | Signal | Encoding | Conversion / interpretation |
|---|---|---|---|
| B0–B1 | Maximum cell voltage | LE16 unsigned | raw × 0.001 V |
| B2–B3 | Minimum cell voltage | LE16 unsigned | raw × 0.001 V |
| B4–B5 | Position of maximum-voltage cell | LE16 unsigned | Reported channel position; index base is profile-specific |
| B6–B7 | Position of minimum-voltage cell | LE16 unsigned | Reported channel position; index base is profile-specific |

### `04030000` — Temperature extrema

| Position | Signal | Encoding | Conversion / interpretation |
|---|---|---|---|
| B0–B1 | Maximum cell temperature | LE16 unsigned | (raw − 400) × 0.1 °C |
| B2–B3 | Minimum cell temperature | LE16 unsigned | (raw − 400) × 0.1 °C |
| B4–B5 | Position of maximum-temperature sensor | LE16 unsigned | Reported channel position; index base is profile-specific |
| B6–B7 | Position of minimum-temperature sensor | LE16 unsigned | Reported channel position; index base is profile-specific |

### `04040000` — SOC, SOH and cycles

| Position | Signal | Encoding | Conversion / interpretation |
|---|---|---|---|
| B0–B1 | USOC | LE16 unsigned | raw × 0.1; unit unspecified |
| B2–B3 | SOH | LE16 unsigned | raw × 0.1; unit unspecified |
| B4–B5 | ASOC | LE16 unsigned | raw × 0.1; unit unspecified |
| B6–B7 | Cycle count | LE16 unsigned | Unscaled integer |

### `04050000` — Current limits and capacity

| Position | Signal | Encoding | Conversion / interpretation |
|---|---|---|---|
| B0–B1 | Permitted charge current | LE16 unsigned | raw × 0.1 A |
| B2–B3 | Permitted discharge current | LE16 unsigned | raw × 0.1 A |
| B4–B5 | Full-charge-capacity estimate | LE16 unsigned | raw × 0.1 Ah |
| B6–B7 | Remaining-capacity estimate | LE16 unsigned | raw × 0.1 Ah |

### `04060000` — Cumulative charge

| Position | Signal | Encoding | Conversion / interpretation |
|---|---|---|---|
| B0–B3 | Cumulative incoming charge | Four bytes; integer byte order unspecified | After byte-order qualification: raw × 0.1 Ah |
| B4–B7 | Cumulative outgoing charge | Four bytes; integer byte order unspecified | After byte-order qualification: raw × 0.1 Ah |

### `04070000` — Cumulative energy

| Position | Signal | Encoding | Conversion / interpretation |
|---|---|---|---|
| B0–B3 | Cumulative incoming energy | Four bytes; integer byte order unspecified | After byte-order qualification: raw × 0.1 Wh |
| B4–B7 | Cumulative outgoing energy | Four bytes; integer byte order unspecified | After byte-order qualification: raw × 0.1 Wh |

### `040A0000` — Protection and alarm state

| Position | Signal | Encoding | Conversion / interpretation |
|---|---|---|---|
| B0 | Protect alarm 0 | Raw byte / signed 8-bit rendering | Unscaled integer |
| B0.bits1:0 | Internal sum voltage high | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B0.bits3:2 | Internal sum voltage low | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B0.bits5:4 | Cell voltage high | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B0.bits7:6 | Cell voltage low | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B1 | Protect alarm 1 | Raw byte / signed 8-bit rendering | Unscaled integer |
| B1.bits1:0 | Delta voltage single | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B1.bits3:2 | Delta voltage all | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B1.bits5:4 | Delta temperature single | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B1.bits7:6 | Delta temperature all | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B2 | Protect alarm 2 | Raw byte / signed 8-bit rendering | Unscaled integer |
| B2.bits1:0 | Charge temperature high | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B2.bits3:2 | Charge temperature low | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B2.bits5:4 | Discharge temperature high | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B2.bits7:6 | Discharge temperature low | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B3 | Protect alarm 3 | Raw byte / signed 8-bit rendering | Unscaled integer |
| B3.bits1:0 | SOC high | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B3.bits3:2 | SOC low | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B3.bits7:6 | SOH low | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B4 | Protect alarm 4 | Raw byte / signed 8-bit rendering | Unscaled integer |
| B4.bits1:0 | Discharge power high | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B4.bits3:2 | Charge power high | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B4.bits5:4 | Delta current high | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B4.bits7:6 | Delta battery voltage high | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B5 | Protect alarm 5 | Raw byte / signed 8-bit rendering | Unscaled integer |
| B5.bits1:0 | Charge current high | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B5.bits3:2 | Discharge current high | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B6 | Protect alarm 6 | Raw byte / signed 8-bit rendering | Unscaled integer |
| B6.bits3:2 | Spcl sum voltage low | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B6.bits7:6 | Spcl cell voltage low | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B7 | Protect alarm 7 | Raw byte / signed 8-bit rendering | Unscaled integer |

### `040B0000` — System fault state

| Position | Signal | Encoding | Conversion / interpretation |
|---|---|---|---|
| B0 | System fault code 0 | Raw byte / signed 8-bit rendering | Unscaled integer |
| B0.bits1:0 | Current open positive | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B0.bits3:2 | Current open negative | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B0.bits5:4 | Positive not open | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B0.bits7:6 | Positive not close | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B1 | System fault code 1 | Raw byte / signed 8-bit rendering | Unscaled integer |
| B1.bits1:0 | Negative not open | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B1.bits3:2 | Negative not close | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B1.bits5:4 | Precharge not open | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B1.bits7:6 | Precharge not close | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B2 | System fault code 2 | Raw byte / signed 8-bit rendering | Unscaled integer |
| B2.bits1:0 | Precharge charge | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B2.bits3:2 | Parallel ID fail | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B2.bits5:4 | Parallel power fail | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B2.bits7:6 | Short circuit | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B3 | System fault code 3 | Raw byte / signed 8-bit rendering | Unscaled integer |
| B3.bits1:0 | Delta voltage invalid | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B3.bits3:2 | Cell voltage low invalid | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B3.bits5:4 | Supply voltage low | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B3.bits7:6 | Supply voltage high | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B4 | System fault code 4 | Raw byte / signed 8-bit rendering | Unscaled integer |
| B4.bits1:0 | Precharge temperature high | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B4.bits3:2 | MOSFET temperature high | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B4.bits5:4 | Balance temperature high | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B4.bits7:6 | Charger reverse | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B5 | System fault code 5 | Raw byte / signed 8-bit rendering | Unscaled integer |
| B5.bits1:0 | AFE temperature low | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B5.bits3:2 | AFE temperature high | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B5.bits5:4 | AFE voltage low | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B5.bits7:6 | AFE voltage high | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B6 | System fault code 6 | Raw byte / signed 8-bit rendering | Unscaled integer |
| B6.bits1:0 | AFE pin fault | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B6.bits3:2 | Shut down fail | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B6.bits5:4 | Cell temperature high invalid | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B6.bits7:6 | Cell voltage high invalid | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B7 | System fault code 7 | Raw byte / signed 8-bit rendering | Unscaled integer |
| B7.bits1:0 | Charge in OV | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B7.bits3:2 | Software version | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B7.bits5:4 | HVIL fault | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B7.bits7:6 | Sbmsuse fault | 2-bit code; LSB0 | Code 0–3; severity not assigned |

### `040C0000` — Other error state

| Position | Signal | Encoding | Conversion / interpretation |
|---|---|---|---|
| B0 | Other error code 0 | Raw byte / signed 8-bit rendering | Unscaled integer |
| B0.b0 | Negative not close | 1-bit code; LSB0 | Unscaled integer |
| B0.b1 | Negative offline | 1-bit code; LSB0 | Unscaled integer |
| B0.b2 | Precharge short VDD | 1-bit code; LSB0 | Unscaled integer |
| B0.b3 | Precharge short GND | 1-bit code; LSB0 | Unscaled integer |
| B0.b4 | Precharge over current | 1-bit code; LSB0 | Unscaled integer |
| B0.b5 | Precharge not open | 1-bit code; LSB0 | Unscaled integer |
| B0.b6 | Precharge not close | 1-bit code; LSB0 | Unscaled integer |
| B0.b7 | Precharge offline | 1-bit code; LSB0 | Unscaled integer |
| B1 | Other error code 1 | Raw byte / signed 8-bit rendering | Unscaled integer |
| B1.b0 | Positive over current | 1-bit code; LSB0 | Unscaled integer |
| B1.b1 | Positive not open | 1-bit code; LSB0 | Unscaled integer |
| B1.b2 | Positive not close | 1-bit code; LSB0 | Unscaled integer |
| B1.b3 | Positive offline | 1-bit code; LSB0 | Unscaled integer |
| B1.b4 | Negative short VDD | 1-bit code; LSB0 | Unscaled integer |
| B1.b5 | Negative short GND | 1-bit code; LSB0 | Unscaled integer |
| B1.b6 | Negative over current | 1-bit code; LSB0 | Unscaled integer |
| B1.b7 | Negative not open | 1-bit code; LSB0 | Unscaled integer |
| B2 | Other error code 2 | Raw byte / signed 8-bit rendering | Unscaled integer |
| B2.b4 | Actor not close | 1-bit code; LSB0 | Unscaled integer |
| B2.b5 | Actor not open | 1-bit code; LSB0 | Unscaled integer |
| B2.b6 | Positive short VDD | 1-bit code; LSB0 | Unscaled integer |
| B2.b7 | Positive short GND | 1-bit code; LSB0 | Unscaled integer |
| B3 | Other error code 3 | Raw byte / signed 8-bit rendering | Unscaled integer |
| B3.b0 | Error INTC | 1-bit code; LSB0 | Unscaled integer |
| B3.b1 | Error IO | 1-bit code; LSB0 | Unscaled integer |
| B3.b2 | Error AD | 1-bit code; LSB0 | Unscaled integer |
| B3.b3 | Error flash | 1-bit code; LSB0 | Unscaled integer |
| B3.b4 | Error RAM | 1-bit code; LSB0 | Unscaled integer |
| B3.b5 | Error stack | 1-bit code; LSB0 | Unscaled integer |
| B3.b6 | Error clock | 1-bit code; LSB0 | Unscaled integer |
| B3.b7 | Error core | 1-bit code; LSB0 | Unscaled integer |
| B4 | Other error code 4 | Raw byte / signed 8-bit rendering | Unscaled integer |
| B4.b6 | SBMS terminal | 1-bit code; LSB0 | Unscaled integer |
| B4.b7 | MBMS terminal | 1-bit code; LSB0 | Unscaled integer |
| B5 | Other error code 5 | Raw byte / signed 8-bit rendering | Unscaled integer |
| B6 | Other error code 6 | Raw byte / signed 8-bit rendering | Unscaled integer |
| B7 | Other error code 7 | Raw byte / signed 8-bit rendering | Unscaled integer |

### `040D0000` — Hardware error state

| Position | Signal | Encoding | Conversion / interpretation |
|---|---|---|---|
| B0 | Hardware error code 0 | Raw byte / signed 8-bit rendering | Unscaled integer |
| B0.bits1:0 | Detect iso voltage | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B0.bits3:2 | Detect current | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B0.bits5:4 | Detect temperature | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B0.bits7:6 | Detect cell voltage | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B1 | Hardware error code 1 | Raw byte / signed 8-bit rendering | Unscaled integer |
| B1.bits1:0 | Detect fuse | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B1.bits3:2 | Detect balance | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B1.bits5:4 | Detect external voltage | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B1.bits7:6 | Detect internal voltage | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B2 | Hardware error code 2 | Raw byte / signed 8-bit rendering | Unscaled integer |
| B2.bits5:4 | EEPROM communication | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B2.bits7:6 | External flash communication | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B3 | Hardware error code 3 | Raw byte / signed 8-bit rendering | Unscaled integer |
| B3.bits1:0 | BMU address fault | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B3.bits3:2 | BMU power fault | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B3.bits5:4 | IVU communication | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B3.bits7:6 | BMU communication | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B4 | Hardware error code 4 | Raw byte / signed 8-bit rendering | Unscaled integer |
| B4.bits3:2 | RS485 communication | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B4.bits5:4 | External CAN communication | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B4.bits7:6 | Internal CAN communication | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B5 | Hardware error code 5 | Raw byte / signed 8-bit rendering | Unscaled integer |
| B5.bits3:2 | Detect BMU sum voltage | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B6 | Hardware error code 6 | Raw byte / signed 8-bit rendering | Unscaled integer |
| B6.bits1:0 | MOSFET actor | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B6.bits5:4 | RTC fault | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B6.bits7:6 | AFE communication | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B7 | Hardware error code 7 | Raw byte / signed 8-bit rendering | Unscaled integer |
| B7.bits1:0 | Detect load minus voltage | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B7.bits3:2 | Detect relay voltage | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B7.bits5:4 | Detect breaker voltage | 2-bit code; LSB0 | Code 0–3; severity not assigned |
| B7.bits7:6 | Detect leak voltage | 2-bit code; LSB0 | Code 0–3; severity not assigned |

### `04100000` — Hardware state and capacity

| Position | Signal | Encoding | Conversion / interpretation |
|---|---|---|---|
| B0 | Hardware state code 0 | Raw byte / signed 8-bit rendering | Unscaled integer |
| B0.b0 | M IVU alarm | 1-bit code; LSB0 | Unscaled integer |
| B0.b1 | M short | 1-bit code; LSB0 | Unscaled integer |
| B0.b2 | USB INT | 1-bit code; LSB0 | Unscaled integer |
| B0.b3 | M fault | 1-bit code; LSB0 | Unscaled integer |
| B0.b4 | M IVU power fault | 1-bit code; LSB0 | Unscaled integer |
| B0.b5 | M S power fault | 1-bit code; LSB0 | Unscaled integer |
| B1 | Hardware state code 1 | Raw byte / signed 8-bit rendering | Unscaled integer |
| B2 | Hardware state code 2 | Raw byte / signed 8-bit rendering | Unscaled integer |
| B3 | Hardware state code 3 | Raw byte / signed 8-bit rendering | Unscaled integer |
| B4–B5 | Qmax | LE16 unsigned | raw × 0.1 Ah |
| B6–B7 | RCC | LE16 unsigned | raw × 0.1 mΩ |

### `04110000` — Actuator and operating state

| Position | Signal | Encoding | Conversion / interpretation |
|---|---|---|---|
| B0 | Actuator state code 0 | Raw byte / signed 8-bit rendering | Unscaled integer |
| B1 | Actuator state code 1 | Raw byte / signed 8-bit rendering | Unscaled integer |
| B2 | Run mode | Run-mode enum | Enum below; unknown codes remain raw |
| B3 | Work mode | Work-mode enum | Enum below; unknown codes remain raw |
| B4–B5 | Maximum sum charge current | LE16 unsigned | raw × 0.1; unit unspecified |
| B6–B7 | Maximum sum discharge current | LE16 signed | raw × 0.1; unit unspecified |

### `04120000` — Version and numeric serial

| Position | Signal | Encoding | Conversion / interpretation |
|---|---|---|---|
| B0 | Main software version | Raw byte / signed 8-bit rendering | Unscaled integer |
| B1 | Sub software version | Raw byte / signed 8-bit rendering | Unscaled integer |
| B2 | Main hardware version | Raw byte / signed 8-bit rendering | Unscaled integer |
| B3 | Sub hardware version | Raw byte / signed 8-bit rendering | Unscaled integer |
| B4–B7 | BMS numeric serial number | Four bytes; integer byte order unspecified | After byte-order qualification: Unscaled integer |

### `04130000` — Current thresholds and SOC estimates

| Position | Signal | Encoding | Conversion / interpretation |
|---|---|---|---|
| B0–B1 | Charge current alarm threshold | LE16 unsigned | raw × 0.1 A |
| B2–B3 | Discharge current alarm threshold | LE16 unsigned | raw × 0.1 A |
| B4–B5 | ASOC OCV | LE16 unsigned | raw × 0.1 % |
| B6–B7 | ASOC Ah 0 | LE16 unsigned | raw × 0.1 % |

### `04140000` — SOC estimates

| Position | Signal | Encoding | Conversion / interpretation |
|---|---|---|---|
| B0–B1 | ASOC Ah 1 | LE16 unsigned | raw × 0.1 % |
| B2–B3 | ASOC full 0 | LE16 unsigned | raw × 0.1 % |
| B4–B5 | ASOC full 1 | LE16 unsigned | raw × 0.1 % |
| B6–B7 | ASOC empty 0 | LE16 unsigned | raw × 0.1 % |

### `04150000` — Passed-charge estimates and SOC flags

| Position | Signal | Encoding | Conversion / interpretation |
|---|---|---|---|
| B0–B1 | ASOC empty 1 | LE16 unsigned | raw × 0.1 % |
| B2–B3 | Passed charge 0 | LE16 unsigned | raw × 0.1 % |
| B4–B5 | Passed charge 1 | LE16 unsigned | raw × 0.1 % |
| B6–B7 | SOC flag | LE16 unsigned | Unscaled integer |

### `04160000` — Configuration quantities

| Position | Signal | Encoding | Conversion / interpretation |
|---|---|---|---|
| B0–B1 | Cell number | LE16 unsigned | Unscaled integer |
| B2–B3 | Cell capacity | LE16 unsigned | Unscaled integer |
| B4–B5 | Breaker voltage | LE16 unsigned | raw × 0.1 V |
| B6–B7 | Sum voltage | LE16 unsigned | raw × 0.1 V |

### `04170000` — Insulation resistance

| Position | Signal | Encoding | Conversion / interpretation |
|---|---|---|---|
| B0–B1 | Insulation resistance | LE16 unsigned | raw × 0.01 MΩ |

### `08000000` — Cell slots 1–4

| Position | Signal | Encoding | Conversion / interpretation |
|---|---|---|---|
| B0–B1 | Cell voltage 1 | LE16 unsigned | raw mV |
| B2–B3 | Cell voltage 2 | LE16 unsigned | raw mV |
| B4–B5 | Cell voltage 3 | LE16 unsigned | raw mV |
| B6–B7 | Cell voltage 4 | LE16 unsigned | raw mV |

### `08010000` — Cell slots 5–8

| Position | Signal | Encoding | Conversion / interpretation |
|---|---|---|---|
| B0–B1 | Cell voltage 5 | LE16 unsigned | raw mV |
| B2–B3 | Cell voltage 6 | LE16 unsigned | raw mV |
| B4–B5 | Cell voltage 7 | LE16 unsigned | raw mV |
| B6–B7 | Cell voltage 8 | LE16 unsigned | raw mV |

### `08020000` — Cell slots 9–12

| Position | Signal | Encoding | Conversion / interpretation |
|---|---|---|---|
| B0–B1 | Cell voltage 9 | LE16 unsigned | raw mV |
| B2–B3 | Cell voltage 10 | LE16 unsigned | raw mV |
| B4–B5 | Cell voltage 11 | LE16 unsigned | raw mV |
| B6–B7 | Cell voltage 12 | LE16 unsigned | raw mV |

### `08030000` — Cell slots 13–16

| Position | Signal | Encoding | Conversion / interpretation |
|---|---|---|---|
| B0–B1 | Cell voltage 13 | LE16 unsigned | raw mV |
| B2–B3 | Cell voltage 14 | LE16 unsigned | raw mV |
| B4–B5 | Cell voltage 15 | LE16 unsigned | raw mV |
| B6–B7 | Cell voltage 16 | LE16 unsigned | raw mV |

### `10000000` — Temperature slots

| Position | Signal | Encoding | Conversion / interpretation |
|---|---|---|---|
| B0–B1 | Cell temperature 1 | LE16 unsigned | (raw − 400) × 0.1 °C |
| B2–B3 | Cell temperature 2 | LE16 unsigned | (raw − 400) × 0.1 °C |
| B4–B5 | Cell temperature 3 | LE16 unsigned | (raw − 400) × 0.1 °C |
| B6–B7 | Balance temperature 1 | LE16 unsigned | (raw − 400) × 0.1 °C |

### `10010000` — Additional balance temperature

| Position | Signal | Encoding | Conversion / interpretation |
|---|---|---|---|
| B0–B1 | Balance temperature 2 | LE16 unsigned | (raw − 400) × 0.1 °C |

### `14000000` — Balancing flags

| Position | Signal | Encoding | Conversion / interpretation |
|---|---|---|---|
| B0–B1 | Balance flag | LE16 unsigned | Unscaled integer |
| B0.b7 | Cell balance 1 | Boolean; MSB0 field placement | 0 / 1; physical interpretation remains profile-qualified |
| B0.b6 | Cell balance 2 | Boolean; MSB0 field placement | 0 / 1; physical interpretation remains profile-qualified |
| B0.b5 | Cell balance 3 | Boolean; MSB0 field placement | 0 / 1; physical interpretation remains profile-qualified |
| B0.b4 | Cell balance 4 | Boolean; MSB0 field placement | 0 / 1; physical interpretation remains profile-qualified |
| B0.b3 | Cell balance 5 | Boolean; MSB0 field placement | 0 / 1; physical interpretation remains profile-qualified |
| B0.b2 | Cell balance 6 | Boolean; MSB0 field placement | 0 / 1; physical interpretation remains profile-qualified |
| B0.b1 | Cell balance 7 | Boolean; MSB0 field placement | 0 / 1; physical interpretation remains profile-qualified |
| B0.b0 | Cell balance 8 | Boolean; MSB0 field placement | 0 / 1; physical interpretation remains profile-qualified |
| B1.b7 | Cell balance 9 | Boolean; MSB0 field placement | 0 / 1; physical interpretation remains profile-qualified |
| B1.b6 | Cell balance 10 | Boolean; MSB0 field placement | 0 / 1; physical interpretation remains profile-qualified |
| B1.b5 | Cell balance 11 | Boolean; MSB0 field placement | 0 / 1; physical interpretation remains profile-qualified |
| B1.b4 | Cell balance 12 | Boolean; MSB0 field placement | 0 / 1; physical interpretation remains profile-qualified |
| B1.b3 | Cell balance 13 | Boolean; MSB0 field placement | 0 / 1; physical interpretation remains profile-qualified |
| B1.b2 | Cell balance 14 | Boolean; MSB0 field placement | 0 / 1; physical interpretation remains profile-qualified |
| B1.b1 | Cell balance 15 | Boolean; MSB0 field placement | 0 / 1; physical interpretation remains profile-qualified |
| B1.b0 | Cell balance 16 | Boolean; MSB0 field placement | 0 / 1; physical interpretation remains profile-qualified |

### `18810000` — Product information

Request-family label `18810000` / response-family label `18A10000`. The fields below occupy at least **64 bytes of a reassembled record**, not one CAN frame. `R0` is the first byte of the record after transport headers are removed. Reception of matching IDs alone does not select this record contract. This document defines no request transaction for this record and authorizes none; the request-family label names an identifier family only.

| Position | Signal | Encoding | Conversion / interpretation |
|---|---|---|---|
| R0–R3 | Product date | DATE | Structured format below |
| R4–R7 | BMS serial number | HEX | Structured format below |
| R8–R9 | Cell number | UINT16; record-specific byte order | Unscaled integer |
| R10–R11 | Cell type | UINT16; record-specific byte order | Unscaled integer |
| R12–R13 | Cell design capacity | UINT16; record-specific byte order | raw × 0.1; unit unspecified |
| R14–R15 | Design voltage | UINT16; record-specific byte order | raw × 0.1; unit unspecified |
| R16–R53 | Barcode | ASCII | Structured format below |
| R54–R61 | Manufacturer | ASCII | Structured format below |
| R62–R63 | Hardware version | VXX | Structured format below |

### `18870000` — Historical record

Request-family label `18870000` / response-family label `18A70000`. The fields below occupy at least **124 bytes of a reassembled record**, not one CAN frame. `R0` is the first byte of the record after transport headers are removed. Reception of matching IDs alone does not select this record contract. This document defines no request transaction for this record and authorizes none; the request-family label names an identifier family only.

The record has no valid inferred length from a zero stream-count hint; the session must establish framing and completion. Its cell/temperature slots are record capacity, not an assumed physical channel count. Historical timestamps and values remain separate from current telemetry.

| Position | Signal | Encoding | Conversion / interpretation |
|---|---|---|---|
| R0–R3 | Number | UINT32; record-specific byte order | Unscaled integer |
| R4–R7 | RTC | DATETIME | Structured format below |
| R8–R9 | Protect alarm code 0 | HEX | Structured format below |
| R10–R11 | Protect alarm code 1 | HEX | Structured format below |
| R12–R13 | Protect alarm code 2 | HEX | Structured format below |
| R14–R15 | Protect alarm code 3 | HEX | Structured format below |
| R16–R17 | System fault code 0 | HEX | Structured format below |
| R18–R19 | System fault code 1 | HEX | Structured format below |
| R20–R21 | System fault code 2 | HEX | Structured format below |
| R22–R23 | System fault code 3 | HEX | Structured format below |
| R24–R25 | Hardware error code 0 | HEX | Structured format below |
| R26–R27 | Hardware error code 1 | HEX | Structured format below |
| R28–R29 | Hardware error code 2 | HEX | Structured format below |
| R30–R31 | Hardware error code 3 | HEX | Structured format below |
| R32–R33 | Cell voltage 1 | UINT16; record-specific byte order | raw mV |
| R34–R35 | Cell voltage 2 | UINT16; record-specific byte order | raw mV |
| R36–R37 | Cell voltage 3 | UINT16; record-specific byte order | raw mV |
| R38–R39 | Cell voltage 4 | UINT16; record-specific byte order | raw mV |
| R40–R41 | Cell voltage 5 | UINT16; record-specific byte order | raw mV |
| R42–R43 | Cell voltage 6 | UINT16; record-specific byte order | raw mV |
| R44–R45 | Cell voltage 7 | UINT16; record-specific byte order | raw mV |
| R46–R47 | Cell voltage 8 | UINT16; record-specific byte order | raw mV |
| R48–R49 | Cell voltage 9 | UINT16; record-specific byte order | raw mV |
| R50–R51 | Cell voltage 10 | UINT16; record-specific byte order | raw mV |
| R52–R53 | Cell voltage 11 | UINT16; record-specific byte order | raw mV |
| R54–R55 | Cell voltage 12 | UINT16; record-specific byte order | raw mV |
| R56–R57 | Cell voltage 13 | UINT16; record-specific byte order | raw mV |
| R58–R59 | Cell voltage 14 | UINT16; record-specific byte order | raw mV |
| R60–R61 | Cell voltage 15 | UINT16; record-specific byte order | raw mV |
| R62–R63 | Cell voltage 16 | UINT16; record-specific byte order | raw mV |
| R64–R65 | Cell temperature 1 | UINT16; record-specific byte order | (raw − 400) × 0.1 °C |
| R66–R67 | Cell temperature 2 | UINT16; record-specific byte order | (raw − 400) × 0.1 °C |
| R68–R69 | Cell temperature 3 | UINT16; record-specific byte order | (raw − 400) × 0.1 °C |
| R70–R71 | Balance temperature 1 | UINT16; record-specific byte order | (raw − 400) × 0.1 °C |
| R72–R73 | Balance temperature 2 | UINT16; record-specific byte order | (raw − 400) × 0.1 °C |
| R74–R75 | Positive temperature 1 | UINT16; record-specific byte order | (raw − 400) × 0.1 °C |
| R76–R77 | Positive temperature 2 | UINT16; record-specific byte order | (raw − 400) × 0.1 °C |
| R78–R79 | Precharge temperature 1 | UINT16; record-specific byte order | (raw − 400) × 0.1 °C |
| R80–R81 | Balance flag | UINT16; record-specific byte order | Unscaled integer |
| R82–R83 | Battery voltage | UINT16; record-specific byte order | raw × 0.1 V |
| R84–R85 | Pack current | UINT16; record-specific byte order | (raw − 30000) × 0.1 A |
| R86–R87 | Pack voltage | UINT16; record-specific byte order | raw × 0.1 V |
| R88–R89 | Maximum cell voltage | UINT16; record-specific byte order | raw mV |
| R90–R91 | Minimum cell voltage | UINT16; record-specific byte order | raw mV |
| R92–R93 | Maximum cell temperature | UINT16; record-specific byte order | (raw − 400) × 0.1 °C |
| R94–R95 | Minimum cell temperature | UINT16; record-specific byte order | (raw − 400) × 0.1 °C |
| R96–R97 | SOC | UINT16; record-specific byte order | raw × 0.1 % |
| R98–R99 | SOH | UINT16; record-specific byte order | raw × 0.1 % |
| R100–R101 | User SOC | UINT16; record-specific byte order | raw × 0.1 % |
| R102–R103 | Cycle | UINT16; record-specific byte order | raw × 0.1; unit unspecified |
| R104–R105 | Maximum charging current | UINT16; record-specific byte order | raw × 0.1 A |
| R106–R107 | Maximum discharge current | UINT16; record-specific byte order | raw × 0.1 A |
| R108–R109 | Full charge capacity | UINT16; record-specific byte order | raw × 0.1; unit unspecified |
| R110–R111 | Remaining capacity | UINT16; record-specific byte order | raw × 0.1; unit unspecified |
| R112–R113 | Other fault code 0 | HEX | Structured format below |
| R114–R115 | Other fault code 1 | HEX | Structured format below |
| R116–R117 | Other fault code 2 | HEX | Structured format below |
| R118–R119 | Other fault code 3 | HEX | Structured format below |
| R120–R121 | Actuator state | UINT16; record-specific byte order | Unscaled integer |
| R122 | Run mode | UINT8 | Unscaled integer |
| R123 | Work mode | UINT8 | Unscaled integer |

### `188B0000` — Controller information

Request-family label `188B0000` / response-family label `18AB0000`. The fields below occupy at least **24 bytes of a reassembled record**, not one CAN frame. `R0` is the first byte of the record after transport headers are removed. Reception of matching IDs alone does not select this record contract. This document defines no request transaction for this record and authorizes none; the request-family label names an identifier family only.

The SOC version field uses the complete two-byte VXXX structure. It must not be truncated to a four-bit scalar.

| Position | Signal | Encoding | Conversion / interpretation |
|---|---|---|---|
| R0–R3 | Software version (v) | VXXXX | Structured format below |
| R4–R5 | Software version (R) | RXX | Structured format below |
| R6–R7 | Hardware version | VXX | Structured format below |
| R8–R19 | Product number | ASCII | Structured format below |
| R20–R21 | IVU version (HV) | RXX | Structured format below |
| R22–R23 | SOC version | Version VXXX; both bytes significant | Structured format below |

### `188E0000` — Module information

Request-family label `188E0000` / response-family label `18AE0000`. The fields below occupy at least **70 bytes of a reassembled record**, not one CAN frame. `R0` is the first byte of the record after transport headers are removed. Reception of matching IDs alone does not select this record contract. This document defines no request transaction for this record and authorizes none; the request-family label names an identifier family only.

| Position | Signal | Encoding | Conversion / interpretation |
|---|---|---|---|
| R0–R3 | Product date | DATE | Structured format below |
| R4–R7 | BMS serial number | HEX | Structured format below |
| R8–R9 | Cell number | UINT16; record-specific byte order | Unscaled integer |
| R10–R11 | Cell type | UINT16; record-specific byte order | Unscaled integer |
| R12–R13 | Cell design capacity | UINT16; record-specific byte order | raw × 0.1; unit unspecified |
| R14–R15 | Design voltage | UINT16; record-specific byte order | raw × 0.1; unit unspecified |
| R16–R53 | Barcode | ASCII | Structured format below |
| R54–R61 | Manufacturer | ASCII | Structured format below |
| R62–R63 | Hardware version | VXX | Structured format below |
| R64–R67 | Software version (v) | VXXXX | Structured format below |
| R68–R69 | Software version (R) | RXX | Structured format below |

### Operating-state enums

The following labels are reported state, not commands. Unknown values remain
numeric and must not select an actuator or maintenance operation.

| Run-mode code | Label | Run-mode code | Label |
|---:|---|---:|---|
| 0 | Default | 8 | Debug |
| 1 | System init | 9 | Shut down |
| 2 | System wait | 10 | PCS control |
| 3 | HV enable | 11 | Factory |
| 4 | HV output | 12 | Sleep |
| 5 | Fault | 13 | Upgrade |
| 6 | Diagnostic | 14 | Power off |
| 7 | Calibration | 15 | Maintenance |

Work-mode codes: `0` static, `1` discharge, `2` charge. History fields for run mode
and work mode are raw U8 in their record; apply these labels only when the
record's enum contract agrees. Two-bit alarm codes do not universally imply
warning/protection severity; preserve codes 0–3 and the exact named bit field.

### Structured diagnostic fields

Diagnostic records require their own byte-order and framing qualification.
The LE16 live-wire convention does not automatically select their integer order.

| Type | Interpretation |
|---|---|
| ASCII | Fixed-length bytes, retaining meaningful spaces; remove only declared padding for display. Keep the original bytes |
| HEX | Preserve the complete byte sequence; it is not automatically a signed or little-endian integer |
| DATE | First byte is year offset from 2000, followed by month and day; fourth byte is outside those three calendar components |
| VXX / RXX | Two component bytes displayed as `Vfirst.second` / `Rfirst.second`; do not decode as a U16 version |
| VXXX | High nibble of first byte, low nibble of first byte, complete second byte: three version components |
| VXXXX | First byte, second byte, then a big-endian 16-bit component from the next two bytes; structured version format rather than a generic UINT32 |
| DATETIME | A qualified 32-bit code uses bits31:26 year−2000, bits25:22 month, bits21:17 day, bits16:12 hour, bits11:6 minute, bits5:0 second. Timezone is absent; validate calendar values |

History `Cycle` is scaled by **0.1**, while the live cycle count has factor **1**.
The two passed-charge fields here are percentage-labelled quantities, not Ah counters.
Do not infer capacity units for a field whose unit is unspecified.

For the addressed diagnostic contract, request addressing places BCU in bits8–15
and response addressing places it in bits0–7. A compatible record transport
removes two leading transport bytes from each reply frame and contributes up to
six bytes to the record. These facts describe identifier layout and record
framing only; this document defines no discovery or query transaction. Native
`1881`, `1887`, `188B` and `188C` are maintenance-only; record-field offsets are
not arbitrary device-memory addresses.
