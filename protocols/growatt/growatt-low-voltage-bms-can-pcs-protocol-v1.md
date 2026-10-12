# Growatt Low-Voltage BMS CAN PCS Protocol V1

The PCS interface carries battery limits, state of charge, electrical values,
cell extrema and diagnostics to an inverter or system controller. Standard,
extended and parallel operation use different message layouts.

For a receive-only implementation, start with **Scope and conventions**, select
one compatible profile, then use the telemetry tables. **Diagnostic codes**
contains the complete numeric DTC contract and the defined condition names.
**Opaque fields** lists values that may be retained but have no assigned
physical interpretation. Control and maintenance messages are separate sections.
This document includes all PCS version and diagnostic rules it requires.

[Profile selection](#identify-the-profile-before-decoding-version-dependent-fields) · [Telemetry](#standard-pcs-host-input-and-telemetry) · [Diagnostics](#diagnostic-codes) · [Parallel operation](#standard-parallel--clustering-profile) · [Extended PCS](#extended-pcs-19xx) · [Opaque fields](#opaque-fields)

## Status and Relationship

This is an implementation-neutral protocol contract. It records candidate protocol claims and is published in the CC0 `protocols/` lane of this repository. CC0 does not grant rights in vendor specifications, trademarks, patents, software images or other third-party content.

**Helianthus status: candidate.** Nothing in this document is qualified by Helianthus against hardware, and no live trial has been run. A statement here is a documentation claim, not a support claim for any installed product. No public source is cited, and every statement is an unverified candidate claim. The words "qualified" and "qualification" below name a decoder's profile-matching state; they are not repository qualification claims.

**Receive-only boundary.** This repository authorizes no transmission, acknowledgement, probing, configuration, update or other live bus action. Where this document describes a message that a device accepts, it records the protocol's receiver behavior so that a decoder can interpret traffic correctly. It does not make that message available to Helianthus software. The capability and qualification conditions described here are necessary for a device to accept a message and are never sufficient: this repository defines no condition under which Helianthus software transmits.

**Relationship to the existing Growatt documents.** The [V1.04 contract](low-voltage-bms-can-v104.md), its [version evidence](growatt-low-voltage-bms-can-version-evidence-v1.md) and the [common projection](growatt-low-voltage-bms-can-common-projection-v1.md) describe frames from published, revision-labelled documents. This document uses a different selector, a project code with a release such as `QAAA0006`, and a different frame vocabulary. The two sets are independent:

- The same CAN identifier can carry a different layout in each set. For example, `0x321` is an update-status frame in the V1.04 contract and an identity-and-family frame here. An identifier match never selects a document. In particular, the standard-frame traffic in this document carries `0x311`, `0x312` and `0x313`, which satisfies the frame geometry of the V1.04 admission tuple, so that tuple alone does not distinguish PCS from V1.04 traffic. V1.04 applies only when the caller explicitly selects it for an interface.
- No correlation between project codes and published revision labels (V1.04, V1.05, V1.07, V1.08) is established. A project-code selector MUST NOT select a revision label, and a revision label MUST NOT select a project code.
- This document does not change admission, decoding or raw-evidence rules of the V1.04 contract.
- PID notation below is hexadecimal and is written without the `0x` prefix, except where `0x` marks V1.04 identifiers or raw words.

The companion [LINK protocol](growatt-low-voltage-bms-can-link-protocol-v1.md) defines the module bus behind the coordinator. See the [Growatt protocol index](README.md) for all documents in this family.

## Reading a field correctly

A field has one of four contracts:

| Contract | Decoder behavior | Display example |
|---|---|---|
| **Measurement** | Apply the stated signedness, scale, validity and version/profile gate | `Pack voltage: 53.10 V` |
| **State or diagnostic code** | Decode only listed values; retain every unlisted value as a number | `State: 0x07 (unassigned)` |
| **Opaque value** | Read the declared integer or bytes without a physical unit, severity or actuator meaning | `Algorithm checkpoint: 2082` |
| **Fixed padding** | Ignore only bytes expressly defined as fixed padding for the selected contract | `No value` |

“Opaque” is an intentional decoder outcome. It does not authorize a default
unit, a guessed enum or a control action. A zero measurement, a zero state,
a stale value, an unassigned byte and an unsupported feature are distinct.
The raw frame remains available alongside any decoded value.
Unassigned fields and bits remain opaque and visible; they are not padding.

For example, an unresolved DTC is displayed as `DTC 0x04A1`; it is not displayed
as “no fault”. A compatibility set may enable a field only when every candidate
agrees on its format, meaning, scale and validity. Selection is per field,
not one global “latest firmware” switch.


## Scope and conventions

This specification defines the inverter-facing, stack-facing and parallel-group CAN interfaces of low-voltage battery controllers and gateways. The companion [LINK protocol](growatt-low-voltage-bms-can-link-protocol-v1.md) defines communication within a stack.

An endpoint is a controller on one physical bus. A module, stack, parallel group and gateway are different scopes. An endpoint can report cached measurements or identities belonging to other devices. A connector label, product name or battery enclosure does not establish the active protocol profile.

The normal bus rate is **500 kbit/s**. Use classical CAN, data frames, normally **DLC 8**. Standard identifiers use `IDE=0`; extended identifiers use `IDE=1`. Identifier width is part of the message key. All IDs and bit masks below are hexadecimal. `B0…B7` are payload bytes; `U8`, `BE16`, `LE16` and `BE24` specify unsigned wire quantities. Signed fields are explicitly marked. A raw field has no universal physical unit or enumeration assigned by this specification.

Do not assume a fixed cell count, module count, temperature-sensor count, chemistry or charge limit. Configuration counts, observed channels, valid measurements and aggregate counts are separate properties. Unknown and stale values must remain distinguishable from zero.

## Identify the profile before decoding version-dependent fields

PCS compatibility is selected per message and feature. A LINK identity is
optional associated metadata, not a prerequisite for decoding PCS or a reason
to split a shared PCS contract. The standard and parallel release-11 contracts
below are common to `QAAA0011` and `QAAa9011`. Their identity values remain
metadata; only declared field and behavior differences select variant gates.
`QAAa9011` also has a legacy extended-19 contract. Resolve the native
contract using the rules below before selecting release-11 features.

### Identity and version signals

| Signal | Interpretation | What it establishes |
|---|---|---|
| LINK `1802F4SS`, eight ASCII bytes | Four-character, case-sensitive project code followed by four release characters; retain the complete token | Identity announced by LINK source `SS`. A separate topology association is required before applying it to a PCS endpoint |
| Standard `321`, B1–B4 | Case-sensitive family such as `QAAA`, `QAAa`, `QAAb` or `QAAB`; zeros mean no family information | A positive family discriminator, not a complete release |
| Standard `320`, LE16(B3), LE16(B5) | Version words with profile-dependent encoding and scope | May describe a local controller, parallel controller or downstream aggregate; cannot universally recover the full release |
| Extended `1900F2SS`, LE16(B3) | Encoded version word | Some profiles retain only the final three release digits; branch information may be absent |
| Standard `60X`, LE16(B3) | Bit 15 is a multiplexer; low 15 bits are an encoded version value | Keep both multiplexer states separately; neither ASCII nor an unqualified four-digit release |
| Extended `191DDFF2`, `01 rr rr 51 43 41 41 30` | LE16(B1) is the gateway release; B3–B7 are ASCII `QCAA0` | Release 1 identifies gateway profile `QCAA0001` on its downstream bus |

The complete token selects a release within a project code. Keep it unchanged: `QAAA`, `QAAa`, `QAAb`, `QAAB` and `QAaT` are different codes. `QAaT8252` is a distinct token.

**A numeric version word of 6 does not select `QAAA0006`.** It can describe another branch or an aggregate. Likewise, gateway upstream `320` may repeat a downstream stack version and does not report the gateway's own release.

### Version ranges and compatibility rules

The notation `QAAA[0007–0010]` means project code `QAAA` and a four-character decimal release in the inclusive interval `0007` through `0010`. It expands to `QAAA0007`, `QAAA0008`, `QAAA0009` and `QAAA0010`. `QAAa[6008–6009]` has the same meaning within the case-sensitive project code `QAAa`. A comma-separated list is a set of alternatives, not the interval between them. CAN identifiers and masks remain hexadecimal.

Ranges apply only to the PID, field, direction or feature named by their table. They do not declare that every field in those releases is interchangeable. In particular, a common `316` layout does not establish a common `321` identity payload, current scale, fault dictionary or control input.

The receiver MUST apply the following rules:

1. Match the complete project code before applying a release range. Never compare releases across different project codes.
2. Use only the bounded ranges and exact selectors declared here. Unlisted releases, including gaps between listed releases, have unspecified capabilities. A later numeric release does not inherit earlier features automatically.
3. Keep layout, physical units, active profile, role, direction and source scope as separate conditions. A range match alone does not enable transmission.
4. A partial version may select a compatibility class without selecting one exact release, but only when all remaining candidates agree on the particular field's layout, meaning, scale and validity rules.
5. Invalidate the selected class and dependent fragment assemblies when identity, address ownership or active profile changes.

`QAAA[0009–0010]`, `QAAa[6008–6009]` and `QAAa[9005–9006]` are bounded compatibility intervals for the shared layouts specified below. No interval extends beyond its stated endpoints. Releases such as `QAAa2005` and `QAAa2007` are separate selectors; they do not define a `2005–2007` interval.

### PCS feature availability by version

`Y` means the profile defines the feature, subject to its role and state conditions. `N` means the feature is not part of that profile. `U` means its contract is unspecified. An output feature does not establish a same-PID input.

| Project/release selector | Standard PCS | Extended PCS 19xx | Standard parallel | Standard slot reports `326/327/333/334` |
|---|:---:|:---:|:---:|:---:|
| `QAaT8252`, `QAAA0002` | Y | N | N | N |
| `QAAA[0005–0010]` | Y | Y | N | N |
| `QAAa1011`, `QAAa2005`, `QAAa2007`, `QAAa3005`, `QAAa[4010–4011]`, `QAAa5005`, `QAAa6005`, `QAAa[6008–6009]`, `QAAa7004`, `QAAa8008`, `QAAa[9005–9006]`, `QAAa9010` | Y | Y | N | N |
| `QAAb5004` | Y | Y | Y | U |
| `QAAa9011`, legacy extended-19 contract | Y | Y | N | N |
| `QAAA0011`, `QAAa9011` release-11 standard/parallel contract | Y | N | Y | Y |
| `QCAA0001`, upstream / downstream | Y / N | N / Y | N | N |

The slot-report feature is independent of parallel mode: `QAAA0011` and `QAAa9011` can publish it on ordinary standard PCS. Parallel operation changes the source scope. The release-11 standard/parallel contract does not support the extended-19 downstream interface required by `QCAA0001`. The legacy `QAAa9011` contract is a separate candidate with extended-19 support.

The parallel feature table later in this document defines the separate `QAAB` contracts. An unlisted selector has `U` capability; it MUST NOT be admitted using a numerically adjacent release.

### Same-identity variants and native-contract selection

A complete identity is not a capability bitmap. In particular, `QAAa9011`
can select either of the following native contracts:

| Positive indication from the attributed endpoint | Compatible contract | Features that must not be inherited |
|---|---|---|
| Coherent extended `1900…1909` publications | Legacy extended-19; LINK L4 | No standard slot reports, parallel `37F/3F7` or `7F8/78F` contract follows from the identity |
| Release-11 `326/327/333/334` or qualified standard parallel traffic | Release-11 standard/parallel; LINK L8 | No extended-19 contract follows from the identity |
| Only identity, `311…325`, or silence | Both contracts remain candidates | Decode shared fields only; optional inputs and DTC encoding remain unresolved |

If both incompatible indications appear, resolve multiple transmitters,
association or an identity epoch change. Do not merge them into one endpoint.
LINK observation is optional for PCS; an associated LINK identity cannot
replace native PCS profile qualification. `321=QAAa` also does not resolve
these two `QAAa9011` contracts.

`QAAA0006` has compatible variants with either a raw extra word or a zero tail
in `321.B6–B7`. A nonzero tail excludes the zero-tail form; zero cannot select
it. This difference does not change the `316` gauge layout. `QAAA0010`
variants also differ in a synchronization side effect on reception; their
PCS payload definitions are common. Full release identity alone does not
select these optional behaviors.


### Common release-11 PCS contract

`QAAA0011` and `QAAa9011` share one release-11 standard/parallel contract:
identifiers, identifier width, schedules, timeout parameters, fragment formats,
source-scope rules and the defined standard/parallel message families.
This includes `37F/3F7`, `782/728` and `7F8/78F`. Maintenance state and image
compatibility remain separate conditions. This common contract provides no
extended PCS `19xx`; the same-token legacy `QAAa9011` contract is excluded.

Use one parser with the following independent feature gates. The version
columns select behavior within this common contract; they are not separate
PCS transport profiles.

| Field or behavior | `QAAA0011` | `QAAa9011` |
|---|---|---|
| `321` family metadata | ASCII `QAAA` | ASCII `QAAa`; same payload layout |
| Diagnostic words in `333`, `52X` | Packed-decimal code table | Binary-decimal code table; see Diagnostic codes below |
| `301` heartbeat input B7 | Ignored | Retained as raw heartbeat state; `00` and `58` normalize to zero |
| `334` output B1 | Zero | Coordinator state code; B2–B7 remain zero in both versions |
| `51X` output B7 | Local: zero. Aggregate: unspecified; not assigned in this payload | Fourth raw state byte in both scopes |
| `51X` input B7 | Ignored | Retained with the reporting slot |
| `590` input B7 | Ignored | Retained and propagated as additional state. The native `590` output is zero at B7 in both versions |
| `37F` parallel-count branch, with B0 bit 0 set and local count 1–8 | B7 other than 1 enters count selection, including zero | Only B7 greater than 1 enters count selection; zero does not enter it |

The common layout may be decoded before the exact variant is known. Keep DTC
words and optional state bytes raw until their particular gate is resolved.
The family in `321`, when available and associated with an already qualified
release-11 PCS endpoint, can select the corresponding gates without LINK.
A nonzero additional-state byte is positive evidence for the extended state
form within these two candidates; zero does not select the zero-tail form.
An unassigned aggregate `51X.B7` is never a version discriminator.

### Profile selection

| Profile | Positive wire indication | Remaining qualification |
|---|---|---|
| Standard PCS | Coherent `311…325` traffic, IDE=0 | Identity, role and field layout remain separate; multiple unidentified transmitters make this stream ambiguous |
| Extended PCS 19 | Coherent `1900F2SS…1909F2SS` and/or `1910FFF4`, IDE=1 | Preserve source address and distinguish local versus aggregate records |
| Standard parallel | Coherent addressed `60X…68X`, `6CX`, and profile-specific `50X…52X`/summary traffic | Establish the group address, coordinator/participant role and the particular parallel contract |
| Gateway upstream | Topology association with a gateway identified by downstream `191D`, or an equivalent trusted endpoint identity | All-zero `315/316/321/324` alone is insufficient |

Standard PCS 3xx IDs do not encode a sender address. LINK identity, a PCS serial fragment and another interface cannot be associated merely because they arrived close together. A serial published by a master may identify a cached slave. Preserve the key `(physical bus, IDE, endpoint/group, slot, active profile, identity epoch)` and retain unresolved attribution explicitly.

| From | To | Condition |
|---|---|---|
| Start | Unknown | Initial state |
| Unknown | Candidates | Valid traffic and identity clues |
| Candidates | Qualified | Identity, profile and scope resolved |
| Candidates | Partial | Only common fields are unambiguous |
| Partial | Qualified | Additional positive discriminator |
| Qualified | Conflict | Contradictory identity or role |
| Partial | Conflict | Incompatible payloads or sources |
| Conflict | Unknown | New identity epoch |

The receiver may decode a field while several candidate profiles remain only if all candidates assign that field the same width, byte order, meaning and scale. Otherwise preserve the payload as raw. Missing traffic does not prove an absent feature; traffic that happens to resemble a voltage does not identify a layout.

### `316` layout selection from identity and other PIDs

The following table applies to the **local measurement scope**. Aggregate scopes require their own slot attribution; `316` does not contain a slot identifier.

| Complete endpoint identity | Local `316` layout | Additional passive discriminator |
|---|---|---|
| `QAaT8252`, `QAAA0002`, `QAAA0005`, `QAAa2005`, `QAAa3005`, `QAAa5005`, `QAAa6005`, `QAAa[9005–9006]` | Four BE16 cell values | `321` has no ASCII family; this absence is not sufficient to select this row |
| `QAAA0006`, `QAAB[0002–0003]` | Three BE16 gauge quantities followed by two gauge bytes | `321` has no ASCII family; numeric `320` alone cannot disambiguate every branch |
| `QAAA[0007–0011]`, `QAAa1011`, `QAAa2007`, `QAAa[4010–4011]`, `QAAa[6008–6009]`, `QAAa7004`, `QAAa8008`, `QAAa[9010–9011]` | Fault byte, gauge byte, three BE16 quantities | Positive `321` family bytes narrow the project-code candidates; they do not establish a complete release. `QAAA0007`, `QAAa7004` and `QAAa8008` can have zero family bytes |
| `QAAb5004`, `QAAB0004`, `QAAB0006` | Fault byte, gauge byte, BE16 gauge quantity, U8 capacity, U8 selected gauge state, BE16 cycles | Positive `321=QAAb` or `QAAB` is required when selecting from PCS alone; resolve the complete profile and scope before applying units |
| `QCAA0001`, upstream | Eight zero bytes; no measurement in this PID | Identify the gateway through downstream `191D` or established topology |

LINK `1852` or `1862`, PCS `330`, extrema `319`, plausible cell values and all-zero placeholders do **not** uniquely select `316`. In particular, `QAAB0004` and late `QAAa` releases share fault/gauge prefixes but differ at B4–B5. If the complete identity is unavailable, retain the candidate set and decode only common fields.

### Reporting a compatible release set

Report a candidate set or bounded range when exact release selection remains
unresolved. For example, a shared gauge layout can be selected without
selecting a DTC dictionary. Conflicting positive indications invalidate the
affected interpretation. Silence and all-zero placeholders never select a release.

### Receive capability of an endpoint

There is no universal, side-effect-free CAN command that enumerates application handlers. Track capability per **endpoint, direction, PID, active profile and state**:

| Capability state | Meaning |
|---|---|
| `unknown` | Identity, profile or receive semantics are unresolved |
| `observed-output` | The endpoint emits this PID; establishes its output contract only |
| `qualified-input` | The identified endpoint contract includes this incoming PID and the required role/state is established |
| `unsupported` | The identified contract omits the operation or implements only a no-op/placeholder |

A device accepts an incoming PID only when its contract includes that PID, the addressing is compatible and the specified state holds (`qualified-input`). When several candidate contracts remain, the incoming operation is identified only if it has identical semantics and prerequisites in **all** of them. A previously observed application-level response (seen passively, in reply to another party) can corroborate support for that operation in that state; it does not qualify other commands or future roles. These conditions describe device behavior; they are necessary and never sufficient, and this repository defines no condition under which Helianthus software transmits.

A CAN ACK, local loopback, another sender's request, or telemetry from the peer does not prove application acceptance. Periodic `324` does not prove a `212` query handler. For inputs with no defined application acknowledgment, delivery is unconfirmed. Do not use profile switching, clock writes, service entry or balancing/configuration commands as identification probes.

## Standard PCS: host input and telemetry

In this section, **host → endpoint** is an input to the PCS controller; **endpoint → host** is published telemetry. A telemetry consumer does not transmit an output PID back to the endpoint to request its value. Typical telemetry recurrence is sub-second to several seconds; serial fragments can be slower. Scheduling and silence are not capability negotiation.

A host's `301` heartbeat shows that the host sends `301`; it does not show that the host consumes every `311…334` extension. Without an identified receiver contract or an operation-specific application confirmation, support for an optional outgoing PID remains unknown even when this document defines its payload.

### `211`, `212`, `301`: host input

| PID | Detection and input gate | Payload and effect | Confirmation |
|---|---|---|---|
| `211` | Identified standard PCS contract with time synchronization | Battery calendar form: B0 unused; B1 year offset from 2000; B2 month; B3 day; B4 hour; B5 minute; B6 second; B7 unused. Binary integers. Mutates the clock and may propagate time to another bus. Gateway accepts/forwards time, but its exact calendar encoding needs a separately qualified time contract | No universal application ACK. Passive telemetry does not involve clock writes |
| `212` | Standard input in profiles that define it; no operation in the legacy battery, QAAB and gateway forms; absent from `QAAA0011` and `QAAa9011` | Payload has no defined serial/history-query operation in these profiles | `unsupported` for query purposes, even if CAN acknowledges it. `324` is not a response to it |
| `301` | Qualified standard heartbeat input on the active profile; never infer the corresponding extended-19 input | Communications heartbeat. B2 is retained/consumed by several battery profiles, including early QAAB; later QAAB and the gateway can ignore payload bytes. Release-11 B7 behavior is defined by the common-contract feature table; other bytes have no common cross-profile meaning | No dedicated response. Continued telemetry is not a unique acknowledgment of a particular heartbeat. An inverter host is described as sending `301` about every 1 s only where this heartbeat contract applies |

Heartbeat fields are not arbitrary: the host-state encoding is profile-specific, and heartbeat participation changes the device's communications state even when it writes no persistent parameters.

### `311…314`: limits, summary and capacity

These outputs describe the selected local or aggregate scope. Gateway ordering is defined separately below.

| PID | Bytes / type | Field | Interpretation |
|---|---|---|---|
| `311` | B0–B1 BE16 | Charge-voltage limit | Scale requires the measurement contract |
| `311` | B2–B3 BE16 | Charge-current limit | Gateway uses the discharge aggregation path here |
| `311` | B4–B5 BE16 | Discharge-current limit | Gateway uses the charge aggregation path here |
| `311` | B6–B7 BE16 | Status bitmap | Profile-specific summary; not a second voltage |
| `312` | B0–B1 LE16 | Fault/status summary A | Synthesized summary; not direct fault indices |
| `312` | B2–B3 LE16 | Fault/status summary B | Separate from summary A |
| `312` | B4 U8 | Reported count | Module/group scope; not a cell count |
| `312` | B5–B7 | Zero padding | No measurement |
| `313` | B0–B1 BE16 | Voltage summary | Qualified conversions below |
| `313` | B2–B3 signed BE16 | Current | Positive charging in the specified measurement contracts |
| `313` | B4–B5 signed BE16 | Temperature summary | Keep apart from channel extrema |
| `313` | B6 U8 | Reported SOC | May be substituted by a completion state in release-11 |
| `313` | B7 U8 | SOH and status | Mask the SOH value; retain bit 7 separately |
| `314` | B0–B1 BE16 | Remaining capacity | Estimated capacity |
| `314` | B2–B3 BE16 | Full-charge capacity | Estimated capacity |
| `314` | B4–B5 BE16 | Cell-voltage spread | mV in the qualified measurement contract |
| `314` | B6–B7 BE16 | Cycles | Whole cycles; distinct from the fine gauge counter |

Other profiles can preserve the wire shape while changing scaling or source scope. Preserve raw values unless their scale is qualified. Reported SOC, SOH and full-charge capacity describe controller estimates; they do not assert physical charge completion. A zero balancing-related status bit does not establish that all bleed paths are inactive.

| `313` field | Width | Byte order |
|---|---:|---|
| Voltage | 16 bits | BE16 |
| Current | 16 bits | signed BE16 |
| Temperature | 16 bits | signed BE16 |
| SOC | 8 bits | U8 |
| SOH / status | 8 bits | U8 |

### Measurement conversions

These conversions apply to **local QAAA0006** and to the qualified common
**release-11 standard/parallel contract**. They do not select a profile by
themselves. A gateway or cached participant retains its own source contract.
An unlisted release can share a layout without inheriting these conversions.

| Field | Conversion | Detail |
|---|---|---|
| `313` voltage | BE16(B0) / 100 V | `QAAA0006`: pack voltage. Release-11: output-port voltage. This meaning requires its own version gate |
| `313` current | signed BE16(B2) / 10 A | Positive is charging; negative is discharging |
| `313` temperature | signed BE16(B4) / 10 °C | `QAAA0006`: coded minimum temperature. Release-11 count-aware path: fine average temperature, converted with truncation to tenths |
| `313` SOC | B6 % | Reported estimate; release-11 can substitute 100 when its completion state is set |
| `313` SOH | B7 & 0x7F, in % | Produced by rounding the tenths-percent estimate upward. Bit 7 is a separate status flag |
| `314` remaining / full capacity | BE16(B0) / 100 Ah; BE16(B2) / 100 Ah | Estimates, not independently measured capacity |
| `314` cell spread / cycles | BE16(B4) mV; BE16(B6) cycles | Whole cycles here; fine cycles are elsewhere |
| `319`, `327`, `330` cell values | Unsigned word in mV | Preserve the message's own byte order and indices |
| `322` temperature extrema | signed BE16(B0) / 10 °C; signed BE16(B2) / 10 °C | B4/B5 are positions, not temperatures |
| Release-11 `326` voltage | BE16(B1) / 100 V | Voltage in 0.01 V steps; the 16-bit value wraps rather than saturates |
| Release-11 `326` current | Standard bank: `(BE16(B3)−4000)/10 A`; parallel bank: `(BE16(B3)−10000)/10 A` | Unsigned biased code. Resolve active bank first; the frame has no bank selector |
| Release-11 `326.B5` | Low byte of the cached SOC-tenths word | Lossy code, not a percentage. Do not reconstruct SOC from this byte |
| Release-11 `61X` current | (LE16(B2) − 10000) / 10 A | Zero current is wire code 10000, unlike the 4000-biased standard-bank `326` current code |
| Release-11 `61X` voltage | (LE16(B0) & 0x7FFF) / 10 V | Keep the multiplexer separately; aggregate states select different voltage summaries |
| Release-11 `61X` port voltage | LE16(B4) / 10 V | This is a voltage, not a temperature, in the release-11 contract |
| Release-11 `61X` SOC | LE16(B6) / 10 % | Do not apply the current offset to this word |
| Release-11 `65X` temperatures | B2 − 40 °C; B5 − 40 °C; B6 − 40 °C | B6 is the coded average on the local temperature path |
| Release-11 local `323` parameter | BE16(B1), in mV | A cell-voltage parameter in mV; its relation to device configuration is not specified |
| Release-11 local `6DX` first word | LE16(B0) / 10 V, except `FFFF` | Voltage derived from the sum of local cells; it is not one cell voltage |

For example, standard-bank `326 = 02 14 BE 10 9A DA 00 00` reports slot 2,
**53.10 V**, **25.0 A**, and SOC code **218**. A source SOC of 73.0% is
expressed in tenths as 730, which becomes `730 mod 256 = 218`. That byte
cannot uniquely recover the original SOC. Use `313.B6`, native module SOC,
or qualified `61X.B6–B7` for a percentage. In the parallel bank the same current is
code 10250 (`28 0A`) instead of 4250 (`10 9A`). The voltage remains code 5310.
Do not select a current offset by testing which result looks plausible.

In release-11, `313.B7` bit 7 is set for a low SOH estimate
or when a separate diagnostic aggregate condition is present. It is not part
of the SOH number and does not identify one particular defect.

### Gauge and algorithm values

| Field | Defined meaning | Conversion and limits |
|---|---|---|
| `QAAA0006` `315.B6–B7` | Full-charge-capacity estimate | BE16 / 10 Ah |
| `QAAA0006` `316.B0–B1` | Biased current-derived accumulator | Includes corrections and resets; do not convert it directly to Ah or SOC |
| `QAAA0006` `316.B2–B3` | Full-charge-capacity estimate | BE16 / 10 Ah |
| `QAAA0006` `316.B4–B5` | Fine cycle count | BE16 / 10 cycles |
| `QAAA0006` `316.B6` | Latched algorithm state code | A previous nonzero code can persist. Code 100 is used on a failed algorithm precheck; no complete physical mode enum is assigned |
| `QAAA0006` `316.B7` | Residual balancing budget | Integer budget with mode-dependent accounting. It is neither a per-cell mask nor proof of balancing current |
| Release-11 `316.B2–B3` | Biased accumulator | BE16 code; no direct Ah conversion |
| Release-11 `316.B4–B5`, B6–B7 | Full-charge capacity; fine cycles | BE16 / 10 Ah; BE16 / 10 cycles, for the local gauge path |
| Local `317.B6` | Truncated SOH | Under these measurement contracts, integer part of the tenths-percent estimate / 10 |

`313` rounds SOH upward; `317` truncates it. An underlying 99.6% can therefore
produce 100 in `313` and 99 in `317`. This is not a disagreement between sensors.
A nonzero residual budget does not prove that any balance switch is conducting.

### `315…318`: cells, gauge fields and retained faults

Select the layout from the version tables before decoding these outputs. Gateway placeholders carry no measurement. Retained faults are separate from current faults and historical records.

| PID / variant | Payload | Interpretation |
|---|---|---|
| `315`, early `QAaT8252` / `QAAA0002` | BE16(B0), BE16(B2), BE16(B4), BE16(B6) | Four profile data words. Keep unqualified positions raw; do not infer complete cell coverage from adjacency to `316` |
| `315`, later battery standard profile | BE16(B0), BE16(B2), BE16(B4), BE16(B6) | First cell-source value, checkpoint, algorithm estimate/summary, algorithm capacity. Only the first word is a cell value in this local contract. It is not a four-cell array |
| `316`, four-cell | BE16(B0), BE16(B2), BE16(B4), BE16(B6) | Cell positions 5–8 in this local layout. The device publishes only positions allowed by the reported cell count; this is not a complete scan |
| `316`, three-word gauge | BE16(B0), BE16(B2), BE16(B4), B6, B7 | Biased current accumulator, full-charge capacity, fine cycles, latched algorithm code, residual balancing budget. In `QAAA0006`: capacity is 0.1 Ah/count and cycles are 0.1 cycle/count. The first word has no direct Ah conversion; see the gauge contract below |
| `316`, fault + three words | B0, B1, BE16(B2), BE16(B4), BE16(B6) | Retained-fault extension, latched algorithm code, biased accumulator, full-charge capacity, fine cycles. The accumulator is an opaque algorithm value, not a capacity; units for the other words require the measurement gate |
| `316`, byte-capacity | B0, B1, BE16(B2), B4, B5, BE16(B6) | Retained-fault extension, gauge state, gauge quantity, capacity quantity divided by ten and narrowed to U8, selected gauge-state byte, cycle quantity. B4–B5 must not be combined into a BE16 capacity |
| `317`, early `QAaT8252` / `QAAA0002` local | Four BE16 words | Profile data words; separate from the later retained-fault formats |
| `317`, older full-fault form | B0–B7 | Retained fault bytes 8–15. Use only the qualified fault dictionary |
| `317`, fault + SOH/slot form | B0–B5; B6; B7 | Retained fault bytes 8–13; derived SOH-like byte; slot. Local slot can be zero; aggregate slot can rotate |
| `318`, `QAaT8252` local | Four BE16 words | Profile data words; do not apply the later fault bitmap |
| `318`, later battery | B0–B7 | Retained fault bytes 0–7 in the profile's byte/bit order |
| `315/316/317/318`, gateway upstream | Eight zero bytes | No measurement or retained-fault data provided by these PIDs |
| `315`, `QAAb5004` / `QAAB0002/0003/0004/0006` parallel | Eight zero bytes | Placeholder; does not inherit the standard-profile `315` measurements |

`317` requires its own version/scope gate. `QAAA0005`, `QAAa2005`, `QAAa3005`, `QAAa5005`, `QAAa6005` and `QAAa[9005–9006]` have the full-fault form. `QAAA0006`, `QAAA[0007–0011]`, the listed later fault/gauge releases, `QAAb5004` and QAAB profiles use the SOH/slot form. `QAAA0011` and `QAAa9011` share this SOH/slot form, including its bank/source-scope branches. The early profile-data form remains separate. Aggregate `317` has additional source-dependent differences; unresolved bytes remain raw.

### `319`, `322`, `330`: extrema and location

These outputs report extrema and their positions. Check each position against the count and scope of the same endpoint/slot; extrema do not supply a full cell vector.

| PID | Payload | Scope rules |
|---|---|---|
| `319` | B0 status; BE16(B1) maximum cell value; BE16(B3) minimum; B5 maximum index; B6 minimum index; B7 extra status | Cell values are mV in the qualified measurement profile. Preserve raw index convention until local/aggregate scope is established |
| `322` | Signed BE16(B0) maximum temperature quantity; signed BE16(B2) minimum; B4 maximum index; B5 minimum index; B6/B7 extra bytes | Temperature scale and the final bytes are profile-dependent. Gateway upstream B6/B7 carry maximum/minimum SOC |
| `330` | B0 location of maximum; B1 maximum cell index; B2 location of minimum; B3 minimum cell index; BE16(B4) maximum; BE16(B6) minimum | In gateway upstream, B0/B2 are winning downstream stack addresses. In ordinary QAAB they are fixed 1 even in an aggregate path. In other parallel profiles they can carry aggregate location. Do not universally label them actual module IDs |

### `320`, `321`, `323`: identity and configuration

These outputs carry identity and configured counts; counts do not establish measured channel coverage.

| PID | Payload | Interpretation |
|---|---|---|
| `320` | B0–B1 manufacturer/product bytes; B2 hardware; LE16(B3) version A; LE16(B5) version B; B7 zero | Mixed byte order. `GT` may appear in B0–B1. Local versus parallel version source differs. Gateway upstream duplicates a downstream aggregate software word in both version fields |
| `321`, family form | B0 zero; B1–B4 ASCII family; B5 zero; BE16(B6) extra word | Positive family indication; final word raw |
| `321`, unlabelled form | B0–B5 zero; BE16(B6) extra word | Does not identify a family. Some legacy endpoints and gateway placeholders emit all zeros |
| `323`, simple count | B0 configured count; BE16(B1) parameter; B3 extra/reserved; B4–B7 status bytes | B3 cannot universally be ignored. Parameter and bitmap meanings are profile-specific; they are not an assumed balancing mask |
| `323`, gateway count | Count=`B0 + 256*B3`; BE16(B1) parameter; B4–B7 status bytes | Non-contiguous count. An aggregate count is not the cell count of one module |

The following interpretation gates are independent of the `316` layout gate:

| Field / interpretation | Project/release condition | Detection and restriction |
|---|---|---|
| `321` optional zero tail | `QAAA0006`, compatible image variants | B6–B7 may be a raw extra word or fixed zero. Neither zero nor numeric release selects the variant |
| `321` zero-family form | `QAaT8252`, `QAAA0002`, `QAAA[0005–0007]`, `QAAa7004`, `QAAa8008`; gateway placeholder | Zero B1–B4 provides no positive family identity. It cannot distinguish these selectors |
| `321` family-bearing form | `QAAA[0008–0011]`, `QAAa1011`, `QAAa[4010–4011]`, `QAAa[6008–6009]`, `QAAa[9010–9011]`, `QAAb5004`, applicable `QAAB` profiles | Interpret the bytes actually received. A family field may depend on runtime state; zero does not exclude a family-bearing profile |
| `320` numeric version words | Selected standard or parallel profile | Retain both words and their scope; neither recovers a missing project code universally |
| `323` parameter in early standard PCS | `QAaT8252` versus `QAAA0002` | These are distinct parameter contracts despite their shared `316` layout. No cross-release physical meaning is assigned to the raw word |
| `323` count split across B0/B3 | `QCAA0001` upstream | Apply the gateway layout; do not combine those bytes for ordinary module profiles |
| `317` aggregate fault bytes | Selected aggregate profile and slot association | `QAAa1011` and `QAAa9010` are not interchangeable for every source field; preserve bytes without an aggregate contract |

Any additional selector not assigned by this table retains the general raw-field
rules. A zero family field is never a request to fall back to another project code.

### `324`, `325`: serial fragments and placeholder

**Detection/gate:** a valid ordered `324` fragment sequence supports serial publication. `QAaT8252`, `QAAA0002` and gateway upstream provide only a zero placeholder in this PID. `325` has no defined fault-history export in these profiles. Neither frame grants an incoming query capability.

| `324` fragment | Payload |
|---|---|
| 0 | B0=0; B1=module/slot; B2–B7=serial bytes 0–5 |
| 1 | B0=1; B1–B7=serial bytes 6–12 |
| 2 | B0=2; B1–B3=serial bytes 13–15; B4–B7=zero |

The serial field is 16 bytes; this length is unrelated to cell count. Only fragment 0 carries the slot. Reassemble with an ordered context anchored by fragment 0, scoped to the same bus, endpoint and identity epoch. Reject interrupted, conflicting or interleaved sequences; fragments 1/2 alone cannot recover the missing slot. Do not infer a gap-free inventory from a partial serial cycle. Masters can publish cached slave serials periodically, independently of any `212` traffic.

`325` contains an all-zero placeholder in the supported contracts. It does not mean that a device has no historical faults and must not be used as a fault-history query/response.

### `326`, `327`, `329`, `333`, `334`: optional slot extensions

| Feature | Version gate | Scope / additional condition |
|---|---|---|
| `326`, `327`, `333` slot reports | `QAAA0011`, `QAAa9011` | Ordinary standard PCS or the selected parallel profile; retain the slot/group and selected scope |
| `334` one-state form | `QAAA0011` | B0 status; B1–B7 zero |
| `334` two-state form | `QAAa9011` | B0/B1 status; B2–B7 zero |
| `329` serial-associated quantity | Later standard profiles that define `329`; not `QAaT8252` or `QAAA0002` | Independent of `326/327`; never infer physical units or the tail extension from mere PID presence |

For other project/release selectors, positive reception can establish an output candidate but does not assign these payload meanings automatically. In particular, `QAAA[0005–0010]` does not inherit the release-11 slot-report feature.

**Detection/gate:** require the specific extension's output contract or coherent reception from an already attributed endpoint. `326/327/333/334` belong to the common release-11 standard telemetry contract; ordinary QAAB profiles do not acquire these extensions merely by sharing other 3xx IDs. Do not transmit them to request data.

| PID | Payload | Interpretation |
|---|---|---|
| `326` | B0 slot; BE16(B1) voltage; BE16(B3) biased current; B5 truncated SOC-tenths code; B6–B7 zero | Per-slot summary. Voltage is 0.01 V/count; current is an unsigned biased 0.1 A/count code; B5 is a lossy SOC-tenths code. See Measurement conversions |
| `327` | B0 slot; BE16(B1) maximum cell; BE16(B3) minimum; B5/B6 indices; B7 zero | Per-slot extrema, not a complete cell array |
| `329` | B0 module; BE24(B1) derived quantity; B4–B5 zero; BE16(B6) optional extension | Present on several standard profiles. The extension is zero in older forms and meaningful/raw in later forms; units are not universal |
| `333` | B0 group; B1 slot; BE16(B2) DTC A; BE16(B4) DTC B; B6–B7 zero | Numeric diagnostic codes; select the diagnostic code table for the reporting source. LINK representation can use little-endian words; convert byte order without silently changing the source code table |
| `334` | B0 status A; B1 version-dependent; B2–B7 zero | `QAAA0011`: B1=0. `QAAa9011`: B1 coordinator state code (see Opaque fields). No complete cell-balancing bitmap defined |

## Diagnostic codes

### Fault bits, selected codes and retained records

A **current-fault bitmap** identifies active fault indices. A **DTC word** is
one selected diagnostic code. A **retained bitmap** records faults kept by the
controller after their original activation. None is a complete historical log.
Two zero DTC words mean “no code selected”, not “every fault bit is clear”.

Native bitmaps use index `i = 8 × byte_offset + bit`, with bit 0 least
significant. LINK `1850/1851/1852` and parallel PCS `66X/67X/50X` carry current
bytes 0–7, 8–15 and 16–23 respectively where those features are supported.
Extended PCS `1907/1908` carry current bytes 0–7 and 8–15. Standard PCS
`318` carries retained bytes 0–7; `317` has a version-dependent partial
retained block. `312` and `323` are synthesized summaries and must not be
indexed as direct bitmaps.

The following **DTC contract applies only to L8 / the common release-11
standard/parallel contract**, not the legacy extended-19 form of `QAAa9011`.
It defines 134 indices for `QAAA0011` and 136 for `QAAa9011`. Bits outside the
applicable index range remain visible as unassigned fault positions.

| Message | DTC A | DTC B | Reported source |
|---|---|---|---|
| LINK `1853F4SS` | LE16(B0) | LE16(B2) | Module SS |
| Standard PCS `333` | BE16(B2) | BE16(B4) | Group B0, slot B1 |
| Parallel PCS `52X` | BE16(B1) | BE16(B3) | Group X, slot B0 |

A coordinator forwards a member's code without necessarily translating it.
Select the dictionary for that member. The coordinator's own identity is not
sufficient. Reordering bytes does not convert between the two numeric tables.

### Numeric dictionary and version gate

Indices and displayed decimal codes below are decimal; raw words prefixed
`0x` are hexadecimal. Zero is the empty selection in either table.

| Index | `QAAA0011` raw word | `QAAa9011` raw word / decimal code |
|---|---|---|
| 0–130 | Pack the four decimal digits of `1000 + index` into four nibbles: `0x1000`–`0x1130` | Binary integer `1000 + index`: `0x03E8`–`0x046A` |
| 131 | `0x1131` | `0x04A1` / 1185 |
| 132 | `0x1132` | `0x047F` / 1151 |
| 133 | `0x1133` | `0x0489` / 1161 |
| 134 | Unassigned | `0x049D` / 1181 |
| 135 | Unassigned | `0x04A4` / 1188 |

To decode packed decimal, first verify every nibble is 0–9, decode its four
digits, subtract 1000, and accept only index 0–133. For binary decimal, match
the five exceptional entries above before applying the contiguous 1000–1130
range. Any other nonzero word remains an unknown code; never clamp it into
the nearest index. A recognized index with no named condition remains a
recognized diagnostic with an opaque condition.

Example: LINK bytes `A1 04` are raw `0x04A1`, code 1185, index 131 for the
release-11 `QAAa9011` table. PCS represents that same word as `04 A1`.
It is not a valid packed-decimal `QAAA0011` code. Conversely, raw `0x1100`
is index 100 only in the packed-decimal table.

### Defined condition names

A condition name describes what the diagnostic monitors; it is not a repair
diagnosis. Different indices for the same quantity have independent thresholds,
hysteresis and state gates. The suffix “condition N” preserves that distinction
without assigning a warning/protection level that the numeric code does not carry.
Thresholds are configuration and operating-state properties and are not
specified here.

| Index | Condition | Interpretation gate |
|---:|---|---|
| 0 | Cell overvoltage — condition 0 | Both release-11 variants |
| 1 | Cell overvoltage — condition 1 | Both release-11 variants |
| 2 | Cell undervoltage — condition 2 | Both release-11 variants |
| 3 | Cell undervoltage — condition 3 | Both release-11 variants |
| 4 | Cell-voltage spread high — condition 4 | Both release-11 variants |
| 5 | Cell-voltage spread high — condition 5 | Both release-11 variants |
| 6 | Pack overvoltage — condition 6 | Both release-11 variants |
| 7 | Pack overvoltage — condition 7 | Both release-11 variants |
| 8 | Pack undervoltage — condition 8 | Both release-11 variants |
| 9 | Pack undervoltage — condition 9 | Both release-11 variants |
| 11 | Reported SOC low | Both release-11 variants |
| 12 | Cell temperature high — condition 12 | Both release-11 variants |
| 13 | Cell temperature high — condition 13 | Both release-11 variants |
| 14 | Cell temperature low — condition 14 | Both release-11 variants |
| 15 | Cell temperature low — condition 15 | Both release-11 variants |
| 16 | Cell-temperature spread high — condition 16 | Both release-11 variants |
| 17 | Cell-temperature spread high — condition 17 | Both release-11 variants |
| 20 | Discharge current high — condition 20 | Both release-11 variants |
| 21 | Discharge current high — condition 21 | Both release-11 variants |
| 22 | Charge current high — condition 22 | Both release-11 variants |
| 23 | Charge current high — condition 23 | Both release-11 variants |
| 30 | Cell-voltage plausibility | Both release-11 variants |
| 31 | Current zero-offset calibration out of range | `QAAa9011` release-11 only |
| 33 | Cell temperature high — condition 33 | Both release-11 variants |
| 34 | Cell temperature high — condition 34 | Both release-11 variants |
| 35 | Measurement acquisition communication failure | `QAAa9011` release-11 only |
| 38 | Nonvolatile storage access failure | Both release-11 variants |
| 39 | Charging current while a low-temperature condition is active | Both release-11 variants |
| 40 | Cell temperature low — condition 40 | Both release-11 variants |
| 41 | Cell temperature low — condition 41 | Both release-11 variants |
| 42 | Pack-voltage consistency difference | Both release-11 variants |
| 44 | Configuration record failure | Both release-11 variants |
| 45 | Hardware status condition | Both release-11 variants |
| 52 | Output-port overvoltage | Both release-11 variants |
| 57 | Charging current high — additional condition | Both release-11 variants |
| 58 | Discharging current high — additional condition | Both release-11 variants |
| 60 | Pack voltage exceeds port voltage | Both release-11 variants |
| 61 | Port voltage exceeds pack voltage | Both release-11 variants |
| 62 | Maximum cell voltage high | Both release-11 variants |
| 91 | Parallel discovery/association timeout | `QAAa9011` release-11 only |
| 93 | Parallel peer-word spread in 61X.B4–B5 | `QAAa9011` release-11 only |
| 102 | LINK member serial conflict | `QAAa9011` release-11 only |
| 103 | Parallel member serial conflict | `QAAa9011` release-11 only |
| 128 | Startup integrity check A failed | `QAAa9011` release-11 only |
| 129 | Algorithm status condition — condition 129 | Both release-11 variants |
| 130 | Algorithm status condition — condition 130 | Both release-11 variants |
| 131 | Adjacent member state mismatch | `QAAa9011` release-11 only |
| 133 | Startup integrity check B failed | `QAAa9011` release-11 only |
| 134 | Measurement status flag set | `QAAa9011` release-11 only |
| 135 | Pack/port voltage difference with hardware status | `QAAa9011` release-11 only |

### Disabled local selections

Indices 10, 27, 36–37, 54–55, 64–82, 104–108, 111–122 and 124–127 are never
selected into a DTC word by this device. "Disabled" applies to DTC A/B selection
only; a disabled index can still be the source of a summary bit. A received code
for such an index remains visible and attributable. The same first 134 entries
apply to both release-11 variants.

Every applicable index not named in Defined condition names is **opaque-condition**.
Decode its numeric index and bitmap position, retain the code and present
`Diagnostic condition N (unassigned)`. Do not borrow names from another
release, another profile, the addressed monitor profile or a similarly numbered
vendor protocol. In particular, the meaning of one named index does not
qualify the intervening unnamed indices.

### Selection, severity and clearing

DTC A and B are priority selections, not a two-entry list of every active
fault. Which active index is reported follows a fixed priority that is **not a
severity ranking**. Disabled indices never contribute a selected code.

An incoming DTC alone cannot reconstruct all active bits, the selection
priority, the configured thresholds or a repair action. Preserve current
fault bits and selected DTCs separately. No DTC value requests automatic fault
clearing, reboot, contactor operation or balancing. An unknown nonzero code
must remain visible even if all named faults are absent.

### PCS summary bits and their diagnostic sources

The following mappings apply to **local** `QAAA0006` and **local common
release-11** status. A stack, gateway or parallel aggregate requires its own
source contract. All indices are decimal. `OR` means that any listed condition
can set the bit; it does not establish that all of them are active.

In `312`, word A is LE16(B0), word B is LE16(B2). Bits below are numbered
0–15 within each word. Read the named condition from the version-gated table;
an index without a condition name remains a visible diagnostic index.

| Word / bit | Release-11 diagnostic source | `QAAA0006` diagnostic source |
|---|---|---|
| A / 1 | 9 | 9 |
| A / 2 | 7 | 7 |
| A / 3 | 3 | 3 |
| A / 4 | 1 OR 62 | 1 OR 62 OR 99 |
| A / 5 | 24 | 24 |
| A / 6 | 23 OR 49 OR 88 OR 97 | 23 OR 49 OR 88 OR 97 |
| A / 7 | 21 OR 24 | 21 OR 24 |
| A / 10 | 5 | 5 |
| A / 11 | 87 OR 90 OR 128 OR 133 | 87 OR 90 |
| A / 12 | 41 OR state-gated 40 | 41 |
| A / 13 | 15 | 15 |
| A / 14 | 34 | 34 |
| A / 15 | 13 | 13 |
| B / 1 | 8 | 8 |
| B / 2 | 6 | 6 |
| B / 3 | 2 | 2 |
| B / 4 | 0 OR 98 | 0 OR 98 |
| B / 6 | 22 OR 89 | 22 OR 89 |
| B / 7 | 20 | 20 |
| B / 12 | 40 | 40 |
| B / 13 | 14 | 14 |
| B / 14 | 33 | 33 |
| B / 15 | 12 | 12 |
| A / 0 | Cleared in the local contract | Local state code equals 5; not a fault index |
| A / 9 | Cleared in the local contract | Unassigned source |
| B / 9 | Cleared | Unassigned source |
| B / 10 | Parallel diagnostic/status selector 4; not a local DTC index | 4 |

Release-11 A/12 includes condition 40 unless the local control bit is set
and conditions 131 and 132 are both inactive; condition 41 still contributes.
The control bit has no complete physical enum here. Consequently, a clear
A/12 does not by itself exclude condition 40.

A/8 and B/0, B/5, B/11 are not assigned by the release-11 summary
and can retain their previous contents. B/8 has a separate status source.
Keep those bits visible without assigning a fault name or assuming zero.
Other unlisted legacy bits likewise have no diagnostic-index mapping here.

`323.B4–B7` uses the following additional mapping in the same local contracts.
The earlier bytes are separate status/parameter fields. Bits are numbered
0–7 within each byte.

| Byte / bit | Diagnostic source indices |
|---|---|
| B4 / 2 | 25 OR 83 |
| B4 / 3 | 27 OR 28 OR 29 |
| B4 / 4 | 38 |
| B4 / 5 | 35 |
| B4 / 6 | 30 |
| B4 / 7 | 31 |
| B5 / 0 | 42 |
| B5 / 1 | 43 |
| B5 / 2 | 44 |
| B5 / 3 | 45 |
| B5 / 4 | 48 |
| B5 / 5 | 49 |
| B5 / 6 | 51 |
| B6 / 0 | 53 |
| B6 / 1 | 54 OR 39 |
| B6 / 2 | 55 |
| B6 / 3 | 56 |
| B6 / 4 | 84 |
| B6 / 5 | 88 OR 97 |
| B7 / 2 | 57 |
| B7 / 3 | 58 |
| B7 / 4 | 85 |
| B7 / 5 | 89 |

In local release-11, `323.B4` bits 0–1, B5 bit 7 and B7 bits 0–1 are cleared.
B6/B7 bits 6–7 are unassigned in this summary and can retain prior values.
Do not treat the four summary bytes as consecutive native fault bytes.

For example, `323.B4` bit 2 reports **25 OR 83**. It cannot identify one
of those indices without additional current-fault data. A retained `318`
bit can provide a separate historical indication, but does not turn that
summary into a current, uniquely attributed fault.

## Standard parallel / clustering profile

Parallel communication shares the PCS bus; it is not a claim that a third CAN controller or dedicated cluster connector exists. The profile separates **coordinator summaries** from **addressed group publications**. `X` below is the low-nibble group address: `ID = base | X`, for example `641` belongs to family `64X`, group 1. It is not the module slot embedded in a payload and not a LINK address. Qualified addressed publishers use the profile's assigned range; these contracts limit their normal group address to values below 8. Do not allocate an address by observing a silent ID.

### Feature and role gates

| Identity/profile | Parallel publications in addition to shared 3xx | Profile-control input |
|---|---|---|
| `QAAB0002`, `QAAB0003` | `60X…68X`, `6CX`, `690`, `6A0`, `6B0` | Legacy `190A` exists; parallel discovery/state remains a separate prerequisite |
| `QAAB0004`, `QAAb5004` | Above plus `50X`, `6DX`, `6E0` | Do not apply `37F` semantics |
| `QAAB0006` | Above plus `51X`, `590`; no old 19xx profile | No qualified `37F`/`3F7` contract or legacy `190A` input; do not guess a replacement switch |
| `QAAA0011`, `QAAa9011` release-11 standard/parallel contract | Above plus `52X`; optional standard slot extensions `326/327/333/334` | Common `37F` control with `3F7` status; count-zero behavior and optional fields use the release-11 feature gates |

`70X` is not a defined periodic publication in these contracts. Its absence provides no version clue. A future unknown `70X` frame is raw traffic until a matching contract is established.

**Publisher roles for addressed telemetry:** only a qualified participant/coordinator role is a valid publisher under its assigned group address, and the receiver's active parallel contract accepts that family and source. A listener seeing `60X` has learned about output support; this does not establish a compatible input path for `62X` or another family. Coordinator-summary inputs apply only to the participant roles that consume them. If role or address assignment is unresolved, receive support remains `unknown`.

### Addressed families `50X…68X`, `6CX`, `6DX`

Detection requires the family, `IDE=0`, DLC 8, an attributable group address and the corresponding feature gate above. Every family is a publication with a role-dependent receiving peer; no family is a generic request/reply pair.

| Family | Payload | Interpretation and validity |
|---|---|---|
| `50X` | B0–B7 | Third fault block, bytes 16–23; requires the extended-fault feature |
| `51X` | B0 slot; LE16(B1) minimum cell; B3 index/raw; B4–B7 state | `QAAB0006` and `QAAA0011`: B4–B6 are three state bytes; local B7 is zero and aggregate B7 is unspecified. `QAAa9011`: B7 is a fourth state byte. B3 has a local/aggregate distinction; preserve raw until its scope is known |
| `52X` | B0 slot; BE16(B1) DTC A; BE16(B3) DTC B; B5–B7 zero | DTC feature; only the declared numeric dictionary assigns meanings |
| `60X` | LE16(B0) product; B2 hardware; LE16(B3) version/mux; B5–B7 advertised count/config bytes | Version=`LE16(B3)&7FFF`, mux=`B4>>7`; retain both states. `FFFF` product can mark invalid aggregate identity. Count fields must not be replaced by fixed constants |
| `61X` | LE16(B0) voltage/mux; LE16(B2) current code; LE16(B4) local port voltage in release-11, opaque word in unqualified profiles; LE16(B6) SOC ×10 | Voltage data=`LE16(B0)&7FFF`, mux=`B1>>7`. Local mux states may repeat one voltage; aggregate states may represent different quantities. Release-11 current is `(code−10000)/10 A`; B4–B5 is local port voltage in 0.1 V/count. Other selectors retain an opaque code until their measurement contract is selected |
| `62X` | LE16(B0) limit A; LE16(B2) limit B; B4/B5 permission flags; B6 state; B7 packed flags | Permission is reported state, not an actuator command. Invalid aggregate limits can appear as zero; retain validity separately |
| `63X` | LE16(B0) full-charge capacity; LE16(B2) remaining capacity; LE16(B4) cycles; LE16(B6) extra configuration | Same field widths across these parallel profiles; units require the selected measurement contract |
| `64X` | B0 maximum index; B1 zero; LE16(B2) maximum cell; B4 minimum index; B5 zero; LE16(B6) minimum cell | Extrema. Zero high bytes do not impose a universal maximum cell count; do not manufacture a complete cell array |
| `65X` | B0 maximum-temperature index; B1 zero; B2 maximum temperature; B3 minimum index; B4 zero; B5 minimum temperature; B6 extra temperature raw; B7 derived SOH | Release-11 local B6 is the coded temperature average. Local B7 is a derived SOH byte on a percent scale; aggregate B7 is a cached byte. Other selectors require their own conversion |
| `66X` | B0–B7 | Fault bytes 0–7 |
| `67X` | B0–B7 | Fault bytes 8–15 |
| `68X` | LE16(B0) limit A; LE16(B2) limit B; LE16(B4) percentage-like quantity; B6/B7 flags | Several profiles zero the limit words outside their applicable state. In release-11 local scope B4–B5 reports SOC ×10 when its permission-state bit is set, but substitutes code 10 for SOC zero. Otherwise it emits zero. B6/B7 copy state bits 2/1 respectively; an aggregate may have different sourcing |
| `6CX` | B0 low nibble fragment, high nibble module; B1–B7 serial bytes | Fragment 0: bytes 0–6; fragment 1: bytes 7–13; fragment 2: only B1/B2 are bytes 14/15. **B3–B7 of fragment 2 are unspecified**, not guaranteed zero |
| `6DX` | LE16(B0) measurement quantity; B2 flag; B3 state flag; B4–B7 zero | Release-11 local word is cell-sum voltage in 0.1 V/count. `FFFF` marks the word invalid; the invalidation condition is not specified. B2 is a pack-voltage flag; B3 reports a nonzero state code, without assigning its physical enum |

Reassemble `6CX` by bus, group `X`, module, identity epoch and fragment order. Its 7/7/2 layout differs from the 6/7/3 layout of standard `324`. Serial identity alone does not make other cached fields simultaneous.

| `6CX` part | Width | Meaning |
|---|---:|---|
| B0 low nibble | 4 bits | Fragment number |
| B0 high nibble | 4 bits | Module |
| B1–B7 | 56 bits | Serial bytes; only B1 and B2 are valid in fragment 2 |

### Coordinator summaries `590`, `690`, `6A0`, `6B0`, `6E0`

**Detection/gate:** qualified parallel profile and coordinator scope; the exact zero-address ID is distinct from addressed participant IDs. Only the corresponding participant input contract qualifies reception. These are not interchangeable with standard PCS `311…334` or extended PCS `19xx`.

| PID | Payload | Version feature |
|---|---|---|
| `590` | B0/B1/B2 state bytes; LE16(B3), LE16(B5) raw aggregate words; native output B7 zero | Gateway-summary extension in `QAAB0006`, `QAAA0011`, `QAAa9011`. Release-11 input B7 has its own feature gate |
| `690` | Eight raw summary bytes | Common summary contract; not one byte per battery |
| `6A0` | Four LE16 aggregate words | Field units are not universally assigned |
| `6B0` | State bytes followed by zero padding | `QAAB0002/0003`: only B0; `QAAB0004`: B0–B3; `QAAb5004`, `QAAB0006`, `QAAA0011`, `QAAa9011`: B0–B4. Do not decode earlier padding as additional state |
| `6E0` | LE16(B0), LE16(B2), four raw state bytes B4–B7 | Extended aggregate-state feature; separate layout from `6A0` |

### `37F`, `3F7`, `6F0`, `6FF`: profile and discovery control

| PID | Direction and role/state condition | Payload and interpretation |
|---|---|---|
| `37F` | Controller → qualified common release-11 endpoint; explicit profile/role change, not a detection probe | B0 control flags; B1–B6 profile-specific; B7 parallel configuration. Changes active profile, role or transmit state. Count-zero behavior follows the release-11 feature table. No generic encoder for unknown flags is defined |
| `3F7` | Endpoint → controller status for that profile | Periodic form: B0 protocol state; B1 state flag; B2–B4 zero; B5 alarm flag; B6 additional state; B7 address/state. Direct reply form has only B0/B1 and zeros B2–B7; a zero alarm byte in that form does not clear an alarm |
| `6F0` | Coordinator → qualified participant in the discovery/control state | B0 phase/control, B1 coordination parameter, B2–B7 zero in the defined form. Mutates discovery/communication state; do not replay to test support |
| `6FF` | Participant → discovery coordinator, correlated with the current discovery session | B0 reported count; B2–B3 BE16 peer parameter; B1 and B4–B7 unspecified for the common consumed form. It is not a universal presence probe |

Existing discovery traffic may establish a relationship between coordinator and participant. A node takes that role only through the applicable role-assignment procedure. Do not reuse `190A` bit meanings in `37F`; do not assume QAAB accepts `37F` because it publishes `60X`.

## Extended PCS 19xx

### Addressing and eligibility

Extended profile frames use `IDE=1`. Stack telemetry uses `190nF2SS`, where `SS` is the source address; coordinator traffic commonly uses `190nDFF2` or `191nDFF2`. `1910FFF4` is a fixed status identifier whose B7 carries an address. Treat `F2`, `F4`, `F5`, `DF` and `FF` as protocol role/address fields, not arbitrary bytes to swap. The family notation `1900` below is not a complete CAN identifier.

| Identified profile | 19xx capability |
|---|---|
| `QAaT8252`, `QAAA0002` | No qualified 19xx contract |
| `QAAA[0005–0010]`; `QAAa1011`, `QAAa2005`, `QAAa2007`, `QAAa3005`, `QAAa5005`, `QAAa6005`, `QAAa[6008–6009]`, `QAAa7004`, `QAAa8008`, `QAAa[9005–9006]`, `QAAa9010`; `QAAb5004` | Extended profile and `190A` control; each release retains its own payload/role gates. Unlisted releases remain unknown |
| `QAAB[0002–0004]` | Extended profile present alongside standard/parallel profiles |
| `QAAB0006`, `QAAA0011`, `QAAa9011` release-11 standard/parallel contract | No legacy 19xx input/output contract; do not send `190A` to select it |
| `QAAa[4010–4011]`, `QAAa9011` legacy extended-19 contract | Legacy 19xx input/output contract; a `190A` input applies only after the native contract and role are resolved |
| `QCAA0001`, downstream | Coordinator accepting stack addresses 1–8; no ordinary 3xx downstream fallback |

For a stack endpoint, active extended profile, an assigned nonzero address and transmit eligibility are separate conditions. A compatible endpoint can receive `190A` while its standard profile is active; that does not make arbitrary 19xx inputs eligible before the profile transition.

### `1900…1909`, `1910`: stack publications

**Detection/gate:** coherent addressed telemetry on the extended profile. The coordinator's input contract must accept the specific family and source address. A monitor decodes these outputs without sending a same-ID query. The gateway's source range 1–8 is a receiver limit, not a universal battery count.

| Family | Payload | Interpretation |
|---|---|---|
| `1900` | B0/B1 product bytes; B2 hardware/type; LE16(B3) version; B5–B7 zero | Product representation differs between legacy forms; `FFFF` can invalidate aggregate product. The version word can omit branch information |
| `1901` | B0/B1/B2 count/configuration bytes; B3 state; LE16(B4), LE16(B6) configuration words | Count-like fields require local/aggregate attribution. Do not turn a report of one stack into one physical module or hardcode cell/sensor count |
| `1902` | LE16(B0) pack voltage quantity; LE16(B2) current code; LE16(B4) port voltage quantity; LE16(B6) SOC ×10 | Qualified `QAAA0006` units: 0.1 V/count, current=`(code−10000)/10 A` positive charge, SOC 0.1 %/count. Other profiles need their own current encoding. Pack and port are different quantities |
| `1903` | LE16(B0/B2) limits; B4/B5 gates; B6 packed status; B7 role/flags | Aggregate invalid values can become zero. No universal physical dictionary for every status bit |
| `1904` | LE16(B0) full-charge capacity; LE16(B2) remaining capacity; LE16(B4) cycles; B6–B7 zero | Qualified `QAAA0006` capacity fields use 0.1 Ah/count; distinguish whole-cycle summary from gauge fine-cycle fields |
| `1905` | LE16(B0) maximum index; LE16(B2) maximum cell; LE16(B4) minimum index; LE16(B6) minimum cell | Index high bytes can be zero in local battery publications. A coordinator can consume the full LE16 indices. This is two extrema, not four individual cells |
| `1906` | LE16(B0) maximum-temperature index; B2 maximum temperature code; LE16(B3) minimum index; B5 minimum temperature code; B6 extra/mean code; B7 SOH-like value | Deliberately unaligned words. B1/B4 can be zero in local publications. Temperature offset and SOH transformation depend on profile |
| `1907` | B0–B7 | Fault block 0, bytes 0–7 |
| `1908` | B0–B7 | Fault block 1, bytes 8–15. LINK `1852` does not create an automatic third 19xx fault frame |
| `1909` | LE16(B0/B2) limit quantities; LE16(B4) derived percentage-like value; B6/B7 flags | Gate-dependent; a substituted value is not a measurement. Do not copy the semantics of `1903` just because its first words have the same widths |
| `1910FFF4` | B0 protocol state; B1 state flag; B2–B6 zero; B7 runtime address | Status/handshake, not serial or firmware identity. Gateway may consume only B0 for its handshake |

### `190A…190F`, `191A…191E`: coordinator output and endpoint input

The same frame can be coordinator status on its outgoing side and a mutative input on the stack side. The receiver's contract, not merely the sender's, determines acceptance. Where no accepted-input contract is listed, keep receive support unknown and do not inject the frame.

| Complete family / typical ID | Coordinator payload | Receiver gate and effect |
|---|---|---|
| `190ADFF2` | B0 control flags; B1–B7 coordinator-specific state | Only legacy extended-compatible stack endpoints. Changes profile, communication state and transmit gates; not a harmless heartbeat. No generic unknown-profile switch is defined |
| `190BDFF2` | B0 year−2000, B1 month, B2 day, B3 hour, B4 minute, B5 second; B6 extension/reserved, B7 zero | Qualified extended time input; writes RTC and may propagate time. Different byte positions from `211` |
| `190CDFF2` | Gateway: eight aggregate fault bytes, block 0 | Several legacy stack profiles accept it as a no-op. Does not implement a history, serial or memory query |
| `190DDFF2` | Gateway: eight aggregate fault bytes, block 1 | Output support does not establish a matching battery input handler |
| `190EDFF2` | B0–B3 gateway faults; B4 stack-fault mask/status; B5 zero; B6 fault/timeout mask; B7 zero | Gateway publication; battery receive semantics remain profile-specific/unknown |
| `190FDFF2` | B0/B1 topology/state; B2 zero; B3 state; B4 zero; B5 state; B6 reported aggregate count; B7 flags | Gateway publication, not serial enumeration |
| `191ADFF2` | Gateway: LE16(B0) selected port voltage quantity; LE16(B2) aggregate current code; LE16(B4) aggregate SOC; B6 SOH-like minimum; B7 sequence counter | Qualified legacy stack input consumes B2–B3 and B4–B5 as setters. Sending is a state change, not a telemetry read |
| `191BDFF2` | LE16(B0/B2) aggregate current-limit quantities; LE16(B4/B6) maximum/minimum cell quantities | Gateway publication; do not assume a stack input handler from adjacent `191A/191C` support |
| `191CDFF2` | B0/B1 maximum/minimum temperature codes; LE16(B2) secondary percentage quantity; B4–B7 zero in the gateway form | Qualified legacy stack input consumes LE16(B2) and B4 as setters; mutative |
| `191DDFF2` | B0=1; LE16(B1) gateway release; B3–B7=`QCAA0` | Gateway identity output. No ordinary battery command is implied |
| `191EDFF2` | B0 update-session coordination parameter; B1–B7 zero in the gateway form | Qualified legacy update coordination input. May propagate to LINK `18B1DFF4`; does not carry an image block or act as a read-only identity query |

### `1918`, `1919`: local gateway serial service

**Detection/gate:** gateway maintenance profile on its downstream interface, separately qualified from normal stack telemetry. These IDs do not enumerate serials beneath a gateway.

| ID | Direction | Contract |
|---|---|---|
| `1919F2F5` | Service peer → gateway | Queues publication of the gateway's local serial/calibration identity. Payload is not a generic register selection |
| `1918F5F2` | Gateway → service peer | B0 fragment/length header; B1–B7 local serial fragments in 7/7/2 groups; unused outgoing tail bytes are zero |
| `1918F2F5` | Service peer → gateway | Receives serial/calibration fragments into local state; **mutative**. Not a read acknowledgment to replay |

The fragment-header bit encoding is not defined for a generic writer here. Retain the raw header and payload when observing maintenance traffic. Mere presence of `1918` does not permit writing a serial or establish a slave identity.

## Gateway interpretation rules

`QCAA0001` exposes an upstream standard PCS view and a downstream extended-19 view. They are distinct endpoints for parsing and capability tracking. The gateway aggregates selected stack data; it does not transparently forward every battery PID.

| Upstream field | Gateway meaning |
|---|---|
| `311` B0–B1 | Selected aggregate voltage-limit quantity |
| `311` B2–B3 / B4–B5 | Current quantities from the **discharge / charge** aggregation paths respectively. Preserve this gateway mapping; do not apply the battery order without an explicit translation |
| `312` B4 | Sum of selected stacks' reported count fields; no serial inventory |
| `313` voltage/current/temperature | Selected downstream port voltage, aggregate current and aggregate temperature. For the compatible measurement contract: 0.01 V, 0.1 A and 0.1 °C per count. SOH occupies a mixed status byte |
| `314` | Summed/clamped capacities, global cell spread and maximum reported cycle counter |
| `315/316/317/318/321/324/325` | Zero placeholders; no hidden slave measurements or serial fragments |
| `319` B5/B6 | Local extrema indices from the winning stacks, not a global cell number. B7 identifies the first selected faulty stack where available |
| `320` | Downstream maximum version word, duplicated; not the gateway release |
| `322` | Global temperature extrema; composite sensor indices; B6/B7 maximum/minimum reported SOC |
| `323` | Non-contiguous aggregate count in B0/B3; threshold parameter and synthesized status |
| `330` | Winning stack addresses and their local cell indices; preserves location better than `319` alone |

A connected inverter can therefore receive useful aggregate SOC, limits and extrema while seeing no individual slave serials. A `212` frame does not change that visibility. For individual-cell telemetry or balancing-state observation, use a separately identified LINK interface with the corresponding features. Standard 3xx output from a stack is not a downstream fallback for this gateway; a participant must support the compatible extended-19 contract.

## Opaque fields

The following values have a defined wire representation, but no additional
physical meaning or complete enum is assigned here. Retaining them is supported;
turning them into a measurement or a command is not. The message tables supply
their applicable profile, source and direction gates.

| Fields | Supported interpretation | Meaning that is not assigned |
|---|---|---|
| Early `315`, `317`, `318` profile words | Separate BE16 values | Complete cell coverage, capacity or fault-bit meanings |
| `315` checkpoint and algorithm-summary words | Independent algorithm integers | SOC %, Ah, Wh or balance mode |
| `316` biased accumulator and state code | Gauge code and retained algorithm code | Direct calibrated capacity; complete physical state enum |
| `321.B6–B7` | Optional BE16 metadata word, or fixed-zero variant | A universal version, temperature or capacity |
| `319.B0/B7`, `323` status and parameter outside the explicit measurement gate | Separate state/summary fields | Per-cell balance map or a direct fault bitmap |
| `322.B6/B7` outside the gateway mapping | Two separate bytes | Maximum/minimum SOC without the gateway gate |
| `329.B1–B3` | BE24 integer associated with module B0 | Energy, charge, elapsed seconds or remaining lifetime |
| Release-11 `329.B6–B7` | Low 16 bits of ten times a separate signed state value | A physical unit; the multiplication alone does not supply one |
| Release-11 `334.B1` | Coordinator state code carried through the additional state path; fixed zero for `QAAA0011` | Heartbeat `301.B7` state, balance mode or a fault severity |
| `51X` and `1861` state bytes | Slot-attributed state codes | A run or work mode taken from another profile |
| `590`, `690`, `6A0`, `6B0`, `6E0` summaries | Separate bytes/words exactly as laid out | A measurement unit or complete coordination enum |
| `60X` version/mux, `63X` extra word, `62X` packed status | Typed metadata/flags | Complete release token or command support |
| `37F`, `3F7`, `6F0`, `6FF`, opaque maintenance selectors | State-dependent control/status values | A generic writer or harmless discovery sequence |
| Unlisted DTC condition names and summary bits | Raw code, diagnostic index where recognized, bit position | Imported symbolic name, severity or root cause |

The release-11 `334` additional state can be received from PCS `590.B7` or
LINK `1869DFF4.B7` and propagated through the coordinator/member caches.
Its routing is defined, but its complete numeric enum is not. The retained
heartbeat byte `301.B7` is a separate state and must not be aliased to it.
Native `590` transmission still writes B7 zero in both release-11 variants.

For release-11 `329`, the three-byte quantity is an integer code derived from a 32-bit counter by a fixed transform. It is not an energy value, cached module and parallel values are copies of the stored code, and a cached code must not be transformed a second time.

## Maintenance and firmware coordination channels

These are separate stateful maintenance protocols. They are not identification probes or transparent bridges to arbitrary LINK commands. A generic telemetry client must keep their receive capability and maintenance-session eligibility separate.

| Channel | Direction/purpose | Eligibility and interpretation |
|---|---|---|
| `782` | Stack maintenance/update input | Identified stack service contract and established maintenance state; control frames and fragments must be distinguished before interpreting a function code. The qualified QAAA reply route is `728`; QAAB input support alone does not establish that reply route |
| `7F8` | Parallel-group maintenance/update input | Separate cluster service feature in profiles such as `QAAb5004`, QAAB and the common release-11 contract; never inferred solely from `782` support. The qualified common release-11 reply route is `78F`; other profiles require their own response-routing contract |
| `728`, `78F` | Profile-specific maintenance responses | Correlate to the exact request/session and routing contract. Do not assign these response IDs to every endpoint accepting `782` or `7F8` |
| `18B0DFF4`, `18B1DFF4` | LINK-side update coordination | Defined by the LINK specification; phase/session parameters, not automatically firmware data blocks |
| `191EDFF2` | Extended-PCS update coordination | The state-changing session parameter described above; absent from the non-19xx profiles |

Service functions cover update progress/result, image metadata, staging preparation, data transfer, validation and activation. Context-specific memory or storage operations are not a common telemetry contract and are excluded from generic discovery and automatic diagnostic reads. A response can itself be consumed as an input to a staging workflow; request/response direction does not establish harmlessness.

A common service envelope does not make firmware images interchangeable across release identities.

This specification does not assign a portable payload to opaque maintenance function codes. Maintenance exchanges depend on the exact service contract, transaction correlation, flow control, image compatibility and session state. Unsupported or unresolved operations remain `unknown`; a successful normal PCS exchange does not qualify them.

## Data validity and consumer obligations

- Retain the raw CAN record alongside decoded fields, including IDE, DLC, timestamp, physical interface and attributed endpoint/scope.
- Reject malformed length, impossible fragment order and conflicting identities. Do not pad missing bytes into valid values.
- Keep `configured_count`, `observed_indices`, `valid_indices` and `coverage_complete` separate. A full set of extrema is not a full set of cells.
- Track per-field or per-frame age. A fresh aggregate frame can contain stale cached participants; do not promote all slots to fresh solely from the gateway's timestamp.
- Apply units, signedness, invalid sentinels and fault dictionaries only after their feature/profile gate is resolved. Preserve unknown bits.
- Invalidate dependent decoders and fragment assemblies when identity, active profile, role or address ownership changes.
- Treat reported permissions, SOC and fault status as data. They do not implicitly command power equipment or establish electrical safety.
- Keep configuration, time, profile and maintenance operations out of passive discovery. LINK families `1881`, `1887`, `188B` and `188C` are maintenance-only and MUST NOT be used as generic identification or telemetry queries.
