# Growatt Low-Voltage BMS CAN LINK Protocol V1

LINK connects battery modules, the stack coordinator and a service monitor.
It provides module identity, individual cell values, temperatures, diagnostics
and coordination. The source address is part of the message identity.

Start with the identity/group table, then read the ordinary telemetry and cell
sections. **Diagnostic codes** defines the DTC encoding and condition names in
this document. Configuration and maintenance have their own receiver gates.
The addressed monitor profile is separate; it is not a native
LINK fallback and this document assigns no layout to it. This document
includes all LINK version and diagnostic rules it requires.

[Version groups](#identify-the-peer-before-interpreting-version-dependent-fields) · [Module telemetry](#identity-and-ordinary-module-telemetry) · [Cells and temperatures](#cell-voltages-temperatures-and-balancing) · [Diagnostics](#diagnostic-codes) · [Addressed monitor profile](#addressed-monitor-profile)

## Status and Relationship

This is an implementation-neutral protocol contract. It records candidate protocol claims and is published in the CC0 `protocols/` lane of this repository. CC0 does not grant rights in vendor specifications, trademarks, patents, software images or other third-party content.

**Helianthus status: candidate.** Nothing in this document is qualified by Helianthus against hardware, and no live trial has been run. A statement here is a documentation claim, not a support claim for any installed product. No public source is cited, and every statement is an unverified candidate claim. The words "qualified" and "qualification" below name a decoder's profile-matching state; they are not repository qualification claims.

**Receive-only boundary.** This repository authorizes no transmission, acknowledgement, probing, configuration, update or other live bus action. Where this document describes a message that a device accepts, it records the protocol's receiver behavior so that a decoder can interpret traffic correctly. It does not make that message available to Helianthus software. The capability and qualification conditions described here are necessary for a device to accept a message and are never sufficient: this repository defines no condition under which Helianthus software transmits.

**Relationship to the existing Growatt documents.** The [V1.04 contract](low-voltage-bms-can-v104.md), its [version evidence](growatt-low-voltage-bms-can-version-evidence-v1.md) and the [common projection](growatt-low-voltage-bms-can-common-projection-v1.md) describe frames from published, revision-labelled documents. This document uses a different selector, a project code with a release such as `QAAA0006`, and a different frame vocabulary. The two sets are independent:

- The same CAN identifier can carry a different layout in each set. For example, `0x321` is an update-status frame in the V1.04 contract and an identity-and-family frame in the PCS document. LINK uses extended 29-bit identifiers, so it has no identifier overlap with the standard 11-bit V1.04 frames. An identifier match never selects a document.
- No correlation between project codes and published revision labels (V1.04, V1.05, V1.07, V1.08) is established. A project-code selector MUST NOT select a revision label, and a revision label MUST NOT select a project code.
- This document does not change admission, decoding or raw-evidence rules of the V1.04 contract.
- PID notation below is hexadecimal and is written without the `0x` prefix, except where `0x` marks V1.04 identifiers or raw words.

The companion [PCS protocol](growatt-low-voltage-bms-can-pcs-protocol-v1.md) defines the inverter-facing, stack-facing and parallel-group interfaces. LINK uses extended 29-bit identifiers of the form `18xxDDSS` on an addressed module bus. See the [Growatt protocol index](README.md) for all documents in this family.

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


## Interface scope

This specification describes the addressed LINK bus used for module telemetry,
stack coordination and service. Select fields by the **identity advertised on
the wire, message format, source, destination and role**. Product names and
connector labels do not select a decoder. [PCS, including alternate and cluster
profiles](growatt-low-voltage-bms-can-pcs-protocol-v1.md), is a separate protocol context.

## Identify the peer before interpreting version-dependent fields

1. Receive extended CAN frames with their full identifier and eight data bytes.
   Keep the physical bus, source address and session separate.
2. On `1802F4SS`, read **all eight ASCII bytes**, preserving case. Associate this
   identity with source `SS` on this bus. Do not replace it with a numeric
   software word from PCS or the identity of a nearby module.
3. Select the feature group and `180B` layout below. Check that other received
   frames agree. An unknown or conflicting identity leaves affected fields raw.
4. Independently establish the sender's role and route. Data sent by the stack
   coordinator can describe an aggregate; it is not automatically a local module.
5. Track capabilities separately: `unknown`, `observed`, `qualified`,
   `unsupported`. Receiving a PID establishes **observed transmission** of that
   PID. A compatible identity, route and specified layout can qualify decoding.
   A qualified transmit capability does not establish a receive handler.

There is no universal LINK capability bitmap or harmless query that establishes
every receive handler. CAN ACK only acknowledges bus-level reception. A missing
frame does not prove that its handler is absent. Presence of an optional message
can narrow the profile candidates, but does not identify a unique release.

| Group | Exact `1802` identity selectors | `180B` layout | Optional telemetry/features |
|---|---|---|---|
| L0 | `QAaT8252`, `QAAA0002` | C: checkpoint words | `1850` only; no periodic `18FB` serial announcement |
| L1 | `QAAA0005`, `QAAa2005`, `QAAa3005`, `QAAa5005`, `QAAa6005`, `QAAa[9005–9006]` | C | `1851`, serial/date announcements, coordinator synchronization |
| L2 | `QAAA0006` | W: word capacity | Same optional PID set as L1 |
| L3 | `QAAA[0007–0008]`, `QAAa2007`, `QAAa[6008–6009]`, `QAAa7004`, `QAAa8008` | W | `1851`, `1852`, serial/date and propagated PCS state; synchronization has its own receiver gate |
| L4 | `QAAA[0009–0010]`, `QAAa1011`, `QAAa[4010–4011]`, `QAAa9010`, `QAAa9011` legacy extended-19 contract | W | `1851`, `1852`, `1862`, serial/date and propagated PCS state; synchronization has its own receiver gate |
| L5 | `QAAb5004`, `QAAB0004` | B: byte capacity | `1851`, `1852`, serial/date, synchronization, aging-status channel; reduced configuration set |
| L6 | `QAAB[0002–0003]` | W | `1851`, serial/date, synchronization; broad configuration set |
| L7 | `QAAB0006` | B | L5 telemetry plus `1861`, `1869`; configuration set reduced further |
| L8 | `QAAA0011`, `QAAa9011` release-11 standard/parallel contract | W | Common release-11 TX/RX capability set: `1851`, `1852`, `1853`, `1861`, `1862`, `1869`, serial/date, synchronization and aging status; field/behavior gates below |

`QAAa9011` intentionally occurs in L4 and L8. Its eight-byte identity alone
does not select either group. An attributed extended-19 PCS contract selects
L4; an attributed release-11 standard/parallel PCS contract selects L8.
On LINK, native L8 `1853/1861/1869` output is a positive L8 discriminator;
common `1800…180C`, `1850…1852`, `1862` or identity alone leaves both groups
possible. Silence does not establish L4. Keep the candidate set when profile
association is unavailable.

These groups describe protocol features, not products or hardware revisions.
In particular, `QAAb5004`, `QAAB0004` and `QAAa5005` are distinct selectors.
Preserve `QAaT8252` literally. Do not rewrite it as `QAAA0001`.
Project code and release are independent selectors. A shared group is an
explicit compatibility definition, including the two L8 identities; no
implicit cross-project or cross-branch inheritance is defined.

### Version-range notation and matching

`QAAA[0007–0008]` denotes project code `QAAA` and either decimal release `0007`
or `0008`. Both endpoints are included. `QAAa[6008–6009]` and
`QAAB[0002–0003]` use the same rule within their respective case-sensitive
project codes. A comma-separated selector list does not include intermediate
releases. Identifiers such as `1810` and masks remain hexadecimal.

Version intervals are bounded and feature-specific. `QAAA[0007–0010]` shares
the W `180B` layout, but `1862` is defined only for the `0009–0010` portion.
`QAAa[9005–9006]` uses C; `QAAa9010` uses W; `QAAa9011` has both
legacy and release-11 receiver contracts. No `9005–9011` interval or open-ended minimum-version rule is
defined. `QAAa2005` and `QAAa2007` do not define a `2005–2007` interval.

A receiver MUST match `(project code, release interval or exact release,
PID, direction, source, destination, role)` before selecting a version-dependent
interpretation. Physical units and validity conditions MUST be matched
separately. Group membership does not imply that every field, scale or
configuration operation is identical within the group.

When only a compatibility set can be determined, a receiver MAY decode the
intersection of its contracts. It MUST retain the candidate set or bounded
range rather than manufacture an exact release. Missing traffic is not a
negative version test. Unlisted releases and conflicting identities retain
unspecified capability and raw version-dependent fields.

### Detection of layout and feature classes

| Positive indication | Applicable class or feature | Remaining condition |
|---|---|---|
| Complete `1802F4SS` token | Exact selector or one of its bounded intervals | Identity belongs only to this source and session; resolve role independently |
| `1852F4SS` | Additional current-fault block; candidate groups L3/L4/L5/L7/L8 | Does not distinguish W from B `180B` layouts; unlisted profiles remain possible until identity is resolved |
| `1862F4SS` | Additional-word feature; candidate groups L4/L8 | Does not uniquely identify `QAAA[0009–0010]` or assign physical units |
| `1853F4SS` with a compatible identity | DTC output feature in L8 | Does not establish a DTC input handler or a complete fault dictionary |
| `1810…1813` from one source | Native cell-block output candidate | Neither exact release nor configured cell count follows from these IDs alone |
| `1801F4SS` | Balance/status output candidate | Bit mapping and balance-readback semantics require their own profile condition |

For example, a compatibility set containing only `QAAA0009` and `QAAA0010`
selects W for `180B` and the common `1862` word layout without requiring the
exact release. A set containing `QAAA0010` and `QAAA0011` does not select one
common receiver capability matrix. Shared output layout is insufficient.

### Release-11 field and behavior gates

L8 defines a common LINK contract for `QAAA0011` and the release-11
standard/parallel form of `QAAa9011`, including the
complete receiver matrices below. Preserve each source's full `1802` token;
identity is not replaced by group membership. Shared framing, scheduling,
addressing, telemetry layouts, service families and accepted PID routes do not
require duplicate definitions.

| Field or behavior | `QAAA0011` | `QAAa9011` |
|---|---|---|
| `1802` identity | ASCII `QAAA0011` | ASCII `QAAa9011` |
| `1853` DTC words | Packed-decimal code table | Binary-decimal code table; both use LE16 words |
| `1861` output B7 | Zero | Additional state code; B0–B6 share the common layout |
| `1861` input B7 on the module → coordinator route | Ignored | Retained per source slot |
| `1869` output B7 | Zero | Additional state code; B0–B6 share the common layout |
| `1869DFF4` input B7 | Ignored | Retained as additional coordinator state |
| `18FD` maintenance clear branch | Clears the selected persistent records | Same record clearing plus reset of additional coordination state |

The Diagnostic codes section below defines the numeric DTC gates. Byte order is unchanged; numeric code equality is not assumed.
Unknown state enumerations remain raw. A zero additional-state byte cannot
identify which of the two variants emitted a frame.

Both L8 receivers omit native incoming `1801`, `1809`, `1810…1813`, `1830`
and `1840` on the module → coordinator route. Their own output support does not
create a full-cell or balancing-map aggregation input. Configuration and
maintenance support in the matrices is state-changing and remains class Q.
The `18FD` branch above does not define an automatic clear command or a generic
balance-control encoder.

If identity is unavailable, retain a candidate set. Decode a field only when
every remaining candidate agrees on its layout, units and scope. For example,
`1852` establishes an additional fault block but does not alone select the
`180B` layout. Similar voltages or plausible SOC values are not profile gates.

| From | To | Condition |
|---|---|---|
| Start | Unknown | Initial state |
| Unknown | Candidate | Identity or distinctive traffic |
| Candidate | Qualified | Identity, route and layout agree |
| Candidate | Ambiguous | Contradictory identity or layout |
| Qualified | Ambiguous | Source reuse or conflicting identity |
| Qualified | Stale | Identity or data freshness expires |
| Stale | Candidate | Fresh identity received |
| Ambiguous | Unknown | New association or session |

### Receive-handler classes

Each PID section states the applicable receiver class. These classes are part
of the protocol contract:

| Class | Receive support and conditions |
|---|---|
| T — module telemetry | Intended receiver is the stack coordinator. Acceptance depends on the coordinator's own identity/profile, role and the exact destination route. Seeing another module transmit this PID proves neither coordinator acceptance nor storage of every field. No telemetry request is implied. |
| A — aggregate telemetry | Intended receiver is a monitor or higher-level participant. Transmission from `F4` proves aggregate output only. Do not infer a reverse command handler. |
| C — coordination | Acceptance depends on whether the target profile supports this precise family, source/destination role and current coordination state. Passive traffic can establish a candidate; a defined correlated response seen passively, or independent capability qualification, is needed to claim live acceptance. No automatic discovery transmission follows from this specification. |
| Q — configuration/service | State-changing or insufficiently qualified. Excluded from automatic identification, polling and replay. A service role or an observed response does not make the operation read-only. |
| U — undefined | Handler support or payload semantics are unknown. Preserve frames; do not transmit a guessed request. |

`qualified` receive support means the particular receiver, route and operation
are satisfied. A state-changing operation also requires the applicable
coordination or maintenance session. Where the
table cannot establish those conditions, receive support remains `unknown`.
Do not infer symmetric support from a shared PID or a monitor's advertised field. These classes describe device behavior; their conditions are necessary and never sufficient, and this repository defines no condition under which Helianthus software transmits.

### Native receiver capability matrix

Select the column from the **receiver's own** `1802` identity and qualified
native contract, not the identity of the module whose telemetry is being decoded. `Y` means the native receiver
defines a handler for the stated route, subject to role, destination and session
gates. It does not promise that every field is retained, forwarded or acted on.
`N` means this profile has no defined native handler for the stated family/route;
it must not be selected as a compatible receiver. An unknown receiver identity
is `unknown`, not `Y` or `N`.

The telemetry matrix applies to **module → coordinator** reception on
`18xxF4SS`. Only an assigned module role is a valid sender on this route.

| Incoming PID / family | L0 | L1 | L2 | L3 | L4 | L5 | L6 | L7 | L8 |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| `1800`, `1802`–`1808`, `180A`–`180C` | Y | Y | Y | Y | Y | Y | Y | Y | Y |
| `1801` balance/status report | Y | Y | Y | Y | Y | Y | Y | Y | **N** |
| `1809` clock report on the coordinator receive route | Y | Y | Y | Y | Y | Y | Y | Y | **N** |
| `1810`–`1813` cell blocks | Y | Y | Y | Y | Y | Y | Y | Y | **N** |
| `1830` temperature block, `1840` mixed status | Y | Y | Y | Y | Y | Y | Y | Y | **N** |
| `1850` fault bytes 0–7 | Y | Y | Y | Y | Y | Y | Y | Y | Y |
| `1851` fault bytes 8–15 | N | Y | Y | Y | Y | Y | Y | Y | Y |
| `1852` fault bytes 16–23 | N | N | N | Y | Y | Y | N | Y | Y |
| `1853` DTC words | N | N | N | N | N | N | N | N | Y |
| `1861` additional state | N | N | N | N | N | N | N | Y | Y |
| `1862` additional words | N | N | N | N | Y | N | N | N | Y |
| `18FB` serial fragments | N | Y | Y | Y | Y | Y | Y | Y | Y |

In particular, L8 can transmit its own `1801`, `1810`–`1813`, `1830` and `1840`
while lacking the corresponding incoming module handlers. Its emitted telemetry
therefore cannot be used to qualify an incoming full-cell or balance-data path.
Earlier `1801` handlers can record reception without updating a forwarded balance
mask; `Y` is not proof that a coordinator will expose that mask on PCS.

For coordination and service, use the following additional matrix **and** the
class C/Q restrictions. `S` requires the exact selector/profile below the table.

| Incoming PID / family | L0 | L1 | L2 | L3 | L4 | L5 | L6 | L7 | L8 |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Coordinator `1800DFF4`, `1805DFF4`, `180ADFF4` | Y | Y | Y | Y | Y | Y | Y | Y | Y |
| `1860DFF4` synchronization | N | Y | Y | Y | Y | Y | Y | Y | Y |
| `18FEDFF4` propagated PCS state | N | Y | Y | Y | Y | Y | Y | Y | Y |
| `18B0DFF4` update coordination | Y | Y | Y | Y | Y | Y | Y | Y | Y |
| `18B0FFF5` service update route | Y | Y | Y | Y | Y | Y | Y | Y | Y |
| `18B1DFF4` update parameter | N | Y | Y | Y | Y | Y | Y | Y | Y |
| `1869DFF4` coordinator state | N | N | N | N | N | N | N | Y | Y |
| `18F0` discovery/addressing, matched route | Y | Y | Y | Y | Y | Y | Y | Y | Y |
| `1871`, `1877`, `187B` service blocks | Y | Y | Y | Y | Y | Y | Y | N | N |
| Other `1870`–`1889` service blocks | Y | Y | Y | Y | Y | N | Y | N | N |
| `188A`, `188C`, `18A0`, `18FD`, matched service route | Y | Y | Y | Y | Y | Y | Y | Y | Y |
| `188B`, `18DF` service configuration | Y | Y | Y | Y | Y | N | Y | N | N |
| `1892` date/configuration | N | Y | Y | Y | Y | Y | Y | Y | Y |
| `1894` configuration flag | N | Y | Y | Y | Y | N | Y | N | N |
| `1899` additional configuration | N | Y | Y | Y | Y | N | N | N | N |
| `18FC` aging/configuration | N | N | N | N | S | **N** | N | Y | Y |

For `18FC`, `S` is **Y** only for the legacy extended-19 contract of
`QAAa9011`; it is **N** for other L4 selectors. This legacy input stores B3 as
a configuration byte and LE16(B4) as a configuration word. It does not add a
native `18FC` report to the legacy transmit set.

Synchronization input support is present in L1–L8, subject to receiver state
and route. In the defined legacy branch, B0=`AA` triggers synchronization,
subject to receiver state. Some `QAAA0010` variants and
`QAAa4010` also react to a received synchronization frame; that reaction
is not a different payload layout or a version probe.
L5's `18FC` report is a transmit-only feature; it does not qualify an incoming
aging command. Aggregate `180D`–`180F` and date report `18F9` have no matching
native module/coordinator receive contract in these groups; a monitor
implementation is a separate receiver class.

### Legacy receive behavior

The legacy `QAAa9011` contract shares L4 payload layouts. Peer-timeout behavior,
configuration, calibration defaults, fault thresholds and protection behavior
are not implied equal by a shared CAN payload contract, and a release number
alone does not select a timeout variant.

Service `Y` entries define input support, not read-only behavior: configuration,
time, identity, calibration, control and update operations remain class Q.
`1881`, `1887`, `188B` and `188C` are maintenance-only; no `Y` entry makes them
eligible for generic identification or telemetry polling.

## Transport, addressing and data validity

Native LINK uses **classic CAN, extended identifiers, DLC 8**, normally at
**500 kbit/s**. Bit rate is a transport setting, not a model/version identifier.
LINK-IN and LINK-OUT do not designate distinct wire layouts in this protocol.
Physical bus topology and connector wiring remain separate from protocol identity.

The identifier is written `18xxDDSS`:

| Component | Meaning |
|---|---|
| `18xx` | PID family; this document abbreviates it to `1802`, `1810`, etc. |
| `DD` | Destination or protocol group |
| `SS` | Runtime source address |
| `F4` | Stack coordinator role on the routes described below |
| `F5` | Monitor/service role on the routes described below |
| `DF`, `FF` | Protocol group/special-address values; not universal synonyms for broadcast |

The native route `18xxF4SS` carries module data toward the coordinator.
Coordinator-originated traffic may instead use `18xxDFF4` or `18xxF5F4`.
Keep the whole ID: `18B0DFF4` and `18B0FFF5` are not interchangeable.
Source addresses `01`–`09` occur in module aggregation, but this is not a generic
maximum module count or an address range to impose on every future profile.
`FF` must not be treated as an identified ordinary module.

`B0`–`B7` refer to data bytes. `LE16`/`BE16` indicate low/high byte first;
`LE32` and `LE64` use the same convention. Bit zero of a numeric field is its
least significant bit. A field-layout table describes a logical layout,
not physical CAN bit order, arbitration or stuffing. Unknown and reserved
fields remain raw; reserved does not mean safe to write.

### Cell and sensor counts

The profile's **addressable slots**, a peer's **configured count**, and the
**fresh valid channels actually received** are different quantities.
`1810`–`1813` address slots 1–16; they do not prove a 16-cell product.
`1800.B2` reports a configuration count, while `1800.B3` reports a sensor count
under the native configuration layout. Treat them as reported metadata until
the peer/profile and consistency with channel traffic are qualified.

Do not fill missing slots with zero, infer cell count from a product name, or
truncate an unknown product to 16 cells. If the reported count exceeds the
documented slot capacity, coverage is incomplete and additional PID layouts
are required. An unqualified count remains `unknown`.

A complete cell vector requires every configured, supported channel to have a
valid recent value from the **same module association**. Maintain each channel's
timestamp and the span of the vector. Four received frames are not an atomic
measurement. Fresh CAN reception does not necessarily mean a fresh sensor sample.
Expiration policies belong to the application and must be explicit; the protocol
does not supply a universal timeout for charge or balancing decisions.

## Identity and ordinary module telemetry

Unless a row states otherwise, the route is `18xxF4SS`, direction is
**module → coordinator**, receiver class **T**, and availability is L0–L8.
Periodic telemetry requires an assigned source and an active LINK session;
service/discovery states can suppress it. No request is needed to decode traffic
already present. Generic zero-payload queries are not defined.

| PID | Detection / gate | Payload and interpretation |
|---|---|---|
| `1800` | Native route; identify source before interpreting state flags. The coordinator side uses `1800DFF4`, class C. | B0 bitmap; B1 role/flags; B2 configured cell count; B3 configured sensor count; B4 bitmap; B5 mode/flags; B6 I/O/status flags; B7 SOC/status mixture. Do not treat B7 as an unmasked SOC percentage. Bit meanings require a qualified profile. |
| `1801` | Native route; balance-readback semantics qualified for `QAAA0005`, `QAAA0006`, `QAAB0002/0003/0004/0006`. Other selectors retain the first word as raw mask unless independently qualified. | B0–B1 LE16 mask; B2 algorithm/SOC byte; B3–B4 BE16 mixed field; B5–B6 cache/version bytes; B7 zero. See balancing section. |
| `1802` | Extended `1802F4SS`, DLC 8; exact-case selector table above. | B0–B7 eight ASCII identity bytes. No terminator. Select only for this source/session; the message is not an authentication or capability bitmap. |
| `1803` | Native profile. Do not infer meanings from percentage-like values. | B0/B1 configuration bytes; B2–B3 algorithm estimates; B4–B5 LE16 full-charge-capacity field; B6–B7 configuration/version fields. `QAAA0006` capacity uses 0.1 Ah/count; other units require their own qualification. |
| `1804` | Native profile. | B0–B3 LE32 accumulator A; B4–B7 LE32 accumulator B. Units and accumulation period unspecified. Do not rename as Ah or Wh by similarity to another protocol. |
| `1805` | Native packed-status profile. Coordinator can send `1805DFF4`, class C. | LE64 packed fields: bits 0–13 pack-voltage code; 14–26 current code; 27–40 port-voltage code; 41–52 discharge-limit code; 53–63 charge-limit code. See scaling below. |
| `1806` | Native cell-extrema layout. | B0 profile-specific raw byte; B1–B2 LE16 maximum cell voltage; B3 minimum-cell index; B4–B5 LE16 minimum cell voltage; B6–B7 LE16 mean cell voltage in the local release-11 measurement path. In `QAAA0005/0006`, B0 is the low byte of cell-voltage spread, **not maximum-cell index**. Voltage unit is mV in the qualified native measurement profile. |
| `1807` | Native profile. | B0–B1 LE16 cell spread in mV; B2/B3 two byte counts of active diagnostic conditions in release-11, in groups whose membership is not defined here; B4–B5 additional LE16 algorithm field; B6 algorithm/SOC byte; B7 configuration. Remaining semantics raw. |
| `1808` | Native temperature-extrema layout. | B0 maximum-channel index; B1 maximum temperature code; B2 minimum-channel index; B3 minimum code; B4 additional/average code; B5 temperature spread code; B6/B7 additional channel codes. For the local release-11 count-aware path B4 is the truncated average of the one-byte channel codes and B5 is maximum minus minimum. Qualified native temperature codes use `raw − 40 °C`. |
| `1809` | Normally `1809F5SS`, module → monitor. Class A; coordinator-side routes require separate receiver qualification. | B0–B1 LE16 full year; B2 month; B3 day; B4 hour; B5 minute; B6 second; B7 clock status. Binary fields, not BCD. Validate calendar values; timezone is not carried. Clock setting uses a separate input contract. |
| `180A` | Native module report; `180ADFF4` is coordinator wake/coordination, class C. Do not decode a marker as a normal report. | B0 status; B1–B3 LE24 derived quantity; B4–B5 LE16 result; B6–B7 extra LE16 or zero, profile-dependent. Units unspecified. |
| `180B` | Exact selector required: C, W or B in the identity table. | Capacity/checkpoint layout below. Same PID does not imply the same first word. |
| `180C` | Native profile. | B0–B1, B2–B3, B4–B5 three LE16 values; B6 status; B7 zero. Physical meaning and units unspecified. |
| `1840` | Native profile. | B0–B5 six raw state/configuration bytes; B6–B7 LE16 capacity-related field. Do not assign units without a qualified capacity profile. |

### `1805` packed fields

| `1805` field | Bits of the LE64 value | Width |
|---|---|---:|
| Pack voltage code | 0–13 | 14 bits |
| Current code | 14–26 | 13 bits |
| Port voltage code | 27–40 | 14 bits |
| Discharge limit code | 41–52 | 12 bits |
| Charge limit code | 53–63 | 11 bits |

For local `QAAA0006` and the common local release-11 measurement contract,
pack and port voltage codes use 0.1 V/count and current uses
`(code − 4000) / 10 A`. Do not apply a current offset from another profile
to this field. Other selectors can share the packing without qualifying the same
physical scale or current direction. Limit codes remain raw unless their units
and applicability to the module or aggregate are qualified.

### `180B` version-dependent layouts

| Byte(s) | C — checkpoint | W — word capacity | B — byte capacity |
|---|---|---|---|
| B0–B1 | LE16 checkpoint A | LE16 full-charge-capacity field | B0 capacity-derived integer byte; B1 separate algorithm status |
| B2–B3 | LE16 checkpoint B | LE16 cycle field | LE16 cycle field |
| B4–B5 | LE16 checkpoint C | Two separate algorithm/status bytes | Two separate algorithm/status bytes |
| B6–B7 | LE16 remaining-capacity field | LE16 remaining-capacity field | LE16 remaining-capacity field |

In B, B0 represents a divided/narrowed capacity value; B1 must not be joined to
it as the high byte. `QAAA0006` W uses 0.1 Ah/count for capacity fields and
0.1 cycle/count for the cycle field. The same field widths do not establish
these units for other selectors. Algorithm/status bytes are not a per-cell
balance bitmap. C's checkpoint words must not be relabelled as W's capacity,
cycles and flags.

### Fine temperatures and algorithm fields

The following additional interpretations apply to the **local release-11**
contract. Counts and the current validity of the reporting module still apply; forwarding a cached
frame does not establish a new sensor sample.

| Field | Meaning and conversion |
|---|---|
| `1806.B6–B7` | LE16 average cell voltage, in mV; distinct from minimum and maximum. Count-aware path requires configured count 1–16; zero count can retain an old mean. The fixed-16 path averages all 16 slots and requires their validity |
| `1807.B4–B5` | LE16 fine SOC estimate, in 0.1%/count, on the local release-11 algorithm path; B6 is the separate whole-percent estimate. PCS `326.B5` truncates this word to one byte |
| `1807.B2`, B3 | Two byte counts of active diagnostic conditions in groups whose membership is not defined here. These are counts, not fault masks or severity enums |
| `1808.B4` | Integer average of coded one-byte temperatures. Subtract 40 for °C. Averaging these rounded codes loses precision |
| `1808.B5` | Maximum minus minimum of those one-byte codes, in °C |
| `1862.B0–B1`, B2–B3 | LE16 maximum and minimum of the fine temperature codes. Convert each as `code / 8 − 40 °C` |
| `1862.B4–B5`, L8 | LE16 fine average of the configured channels' fine codes. Convert as `code / 8 − 40 °C` only for the count-aware measurement path with count 1–4 |
| `1862.B4–B5`, `QAAA0009/0010` | LE16 fine average, converted as `code / 8 − 40 °C` on the count-aware path with sensor count 1–4. The wire meaning is common to L8 and `QAAA0009/0010` |
| `1861.B3` | Counter byte that saturates at 255; no duration unit is assigned |
| `1803.B0–B1` | Release-11 BE16 configuration word; `QAAA0006` emits two constant bytes, 1 and 1. The capacity word in both frames is LE16 |
| W `180B.B4` | Latched gauge/algorithm state code, independent of B5 |
| W `180B.B5` | Residual algorithm budget byte; not a balance mask |

The `1862` third-word rule for other L4 selectors is opaque unless the same
fine-average contract is selected. L4 membership alone does not select that meaning.
With zero configured sensors, the L8 average can retain its previous value.
Do not report that average as a valid fresh sample. The fixed-four-channel
measurement path does not establish the fine-average update used by the
count-aware path; preserve its third word as an opaque code until qualified.
The configured count alone does not establish valid sensor inputs. The fine
average can include an invalid channel code.
Require valid contributing channels; a numerically plausible average alone
does not qualify them. Preserve an invalid or stale average as such.

For two fine codes 520 and 560, maximum is **30 °C**, minimum **25 °C**,
and their fine average 540 is **27.5 °C**. The one-byte average can report
code 67, or **27 °C**. These fields have different precision.

The first word of `1804` and the three-byte quantity in `180A` are not assigned
energy or charge units. In release-11 the three-byte value is an integer
transform of a 32-bit counter; `180A.B6–B7` is the same biased accumulator
class exposed by PCS `316`, not a capacity. No Ah/Wh conversion is defined. Cached values must not be transformed a
second time.

## Cell voltages, temperatures and balancing

All rows below are module → coordinator, class T. Detect the native profile
and the full source/destination route first. Actual reception qualifies that
source's transmit feature; it does not create a polling command.

| PID | Gate | B0–B1 | B2–B3 | B4–B5 | B6–B7 |
|---|---|---|---|---|---|
| `1810` | L0–L8; cell-block feature | Cell slot 1 | Slot 2 | Slot 3 | Slot 4 |
| `1811` | L0–L8; cell-block feature | Slot 5 | Slot 6 | Slot 7 | Slot 8 |
| `1812` | L0–L8; cell-block feature | Slot 9 | Slot 10 | Slot 11 | Slot 12 |
| `1813` | L0–L8; cell-block feature | Slot 13 | Slot 14 | Slot 15 | Slot 16 |
| `1830` | L0–L8; native temperature feature | Sensor slot 1 | Slot 2 | Slot 3 | Slot 4 |

Each cell slot is **LE16**, in mV for the native measurement profile. Each
temperature slot is **LE16** with conversion `raw / 8 − 40 °C` under the qualified
native temperature profile. `FFFF` is an invalid-temperature marker; zero and
unconfigured channels need validity qualification and must not become a useful
temperature merely because the formula returns a number. Do not infer physical
sensor locations from slot number.

| Cell-block byte pair | Width | Content |
|---|---:|---|
| B0–B1 | 16 bits | Slot 4k + 1 (LE16) |
| B2–B3 | 16 bits | Slot 4k + 2 (LE16) |
| B4–B5 | 16 bits | Slot 4k + 3 (LE16) |
| B6–B7 | 16 bits | Slot 4k + 4 (LE16) |

Here `k=0…3` for `1810…1813`. Count, per-channel validity and freshness determine
whether these slots constitute the complete configured set. Plausible values
alone do not establish byte order or identify the product.

For the qualified `1801` balance-readback profiles, bit `n` of the first LE16
word corresponds to channel `n+1`. Report only configured channels. The word is
the balancing-channel enable state as last read by the device and can remain
unchanged between readings; its CAN arrival time is not the time of that reading. Keep these concepts
distinct: **requested mask**, **register enable state**, **measured balancing
current**. `1801` supplies the second, not the third. `18FD` is a state-changing
requested-mask/control channel and must not be used to discover balancing support.

## Faults and additional status

Routes are module → coordinator (`18xxF4SS`), class T, except the explicitly
addressed `1869` report. Detect the exact profile
or retain the intersection of candidate layouts. A fault frame can be all zero
while the feature is present; absence of a frame cannot be interpreted as no fault.

| PID | Feature gate | Payload |
|---|---|---|
| `1850` | L0–L8 | Eight current-fault bytes, positions 0–7. |
| `1851` | L1–L8 | Eight current-fault bytes, positions 8–15. L0 has no defined block here. |
| `1852` | L3, L4, L5, L7, L8 | Eight current-fault bytes, positions 16–23. These are not cell voltages. |
| `1853` | L8 | B0–B1 LE16 DTC A; B2–B3 LE16 DTC B; B4–B7 zero. Separate from the fault bitmap. |
| `1861` | L7, L8 | B0–B2 state bytes; B3 counter saturated at 255 (255 does not identify its untruncated value); B4–B6 zero. B7 additional state in L7 and `QAAa9011`; zero in `QAAA0011`. Enum values remain raw. |
| `1862` | L4, L8 | B0–B1 maximum fine temperature code; B2–B3 minimum fine code; B4–B5 version-dependent summary; B6–B7 zero. The detailed conversion and third-word gate are below. |
| `1869F5SS` | L7, L8; module → monitor, class A | B0–B2 state bytes; B3–B4 LE16 field; B5–B6 LE16 field; B7 raw state in L7 and `QAAa9011`, zero in `QAAA0011`. Describes gateway/parallel status; does not establish a separate cluster connector. Its incoming counterpart uses `1869DFF4`, not a symmetric module-to-coordinator route. |

Preserve the byte offset, bit number and raw word for every fault. Symbolic
fault names, polarity and latching are profile-specific. A current-fault bitmap
is not a historical fault record. DTC words use the Diagnostic codes section below. Do not import another profile's
alarm fields into these native bytes.

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
| A / 0 | Cleared in the local contract | Local state code; not a fault index |
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

## Coordinator and stack traffic

Coordinator identity and role must be qualified independently of its member
modules. Receiving aggregate telemetry must not overwrite a member's data.
These messages contain no generic acknowledgement that confirms a forwarded
PCS request was accepted by a particular LINK module.

| PID / route | Direction and detection gate | Payload / interpretation | RX class |
|---|---|---|---|
| `180DF5F4` | Coordinator → monitor; source F4, aggregate mode | B0 SOC/cache; B1–B3 states; B4 maximum-temperature index; B5 minimum-temperature index; B6–B7 raw temperature codes. | A |
| `180EF5F4` | Coordinator → monitor; aggregate mode | B0 maximum index; B1 minimum index; B2–B3 LE16 maximum voltage; B4–B5 LE16 minimum voltage; B6–B7 LE16 additional limit. Module/index scope must be qualified. | A |
| `180FF5F4` | Coordinator → monitor; aggregate mode | B0–B1 LE16 limit; B2–B3 LE16 current code; B4 module count; B5 SOH/cache; B6–B7 derived LE16 quotient. Unknown units raw. | A |
| `1860DFF4` | Coordinator → group; L1–L8, coordination state | B0 synchronization marker; B1–B7 zero. Not a sensor request. May be event-driven even where other traffic is periodic. | C |
| `18FEDFF4` | Coordinator → group; L1–L8 | Propagated PCS state. Earlier profiles carry a retained PCS byte in B0. L8 transmits B0 zero and a state nibble in B1; B2–B7 zero. Profile selection is mandatory. | C |
| `1869DFF4` | Coordinator → participants; L7/L8 | Gateway/parallel state input; L8 input B7 follows the release-11 gate above. Distinct from module-to-monitor `1869F5SS`; exact route and receiving role are required. | C |
| `18F0DFF4`, `18F0F4DF` and addressed `18F0` | Discovery/address coordination, L0–L8 | B0 control; B1–B7 state-dependent data. Source/destination and existing address state are material. Discovery can alter role/address state; not a passive identification query. | C |
| `1800DFF4`, `1805DFF4`, `180ADFF4` | Coordinator → group, L0–L8 | Corresponding state/control routes described above. Do not infer ordinary module payload semantics from family alone; direct marker variants may exist. | C |

A HUB may aggregate stacks through its **PCS** interfaces without implementing
the native LINK role described here. Identity `QCAA` or a downstream 19xx stream
does not establish a LINK handler. Use the PCS specification for that topology;
do not send LINK discovery through a presumed transparent PCS bridge.

## Serial number and date announcements

| PID | Detection / direction / feature gate | Payload | Receiver class |
|---|---|---|---|
| `18FBF4SS` | Module → coordinator; L1–L8 | B0 fragment header; B1–B7 serial bytes/padding. Reassembly below. | Class T; no serial request implied. |
| `18F9F5SS` | Module → monitor; L1–L8 | Eight date/status bytes. Calendar representation not fully specified; retain raw rather than guessing ASCII or BCD. | Class A; no reverse setter implied. |
| `1892` | Addressed service/configuration; L1–L8 | B0 encoded year; B1–B5 date/configuration fields; B6–B7 zero in the report layout. Encoding is profile-dependent. | Class Q; not a date query. |

For the native serial-fragment format, `length = (B0 & 0x1F) + 1` and
`fragment = (B0 >> 5) & 3`. Bit 7 is not an extension to infer automatically.
Each fragment contributes up to seven bytes. The common 16-byte form uses
headers `0F`, `2F`, `4F`: seven, seven and two serial bytes, with zero padding
after the final two bytes. Preserve the serial as an identifier string, not a
number. No separate module byte is present; source address provides the route.

Reassemble only within one source/session and consistent declared length.
Reject conflicting repeated fragments, unsupported headers, malformed padding
or mixed identities. An incomplete serial is not a physical-module association.
L0 has no defined periodic `18FB` announcement; do not replace it with an active
service operation simply to obtain a serial.

## Configuration and service channels

All channels in this section are **class Q**. They can mutate state, require
service-session gates or have insufficiently specified effects. They are not
identification probes. Receivers may retain the traffic; automatic replay is not
part of this protocol. The table describes payload envelopes without
defining an automatic command sequence.

### Configuration blocks `1870`–`1889`

Broad configuration sets are available in L0–L4 and L6. L5 retains only
`1871`, `1877`, `187B` from this set; L7/L8 have no equivalent broad set.
Each retained PID uses eight profile-specific configuration bytes, B0–B7.
Module reports normally address F5; service-to-module routes reverse the roles
and can write configuration. One direction does not establish the other.

| PID group | Interpretation | Detection and receiver gate |
|---|---|---|
| `1870`, `1871`, `1872`, `1873`, `1874`, `1875`, `1876`, `1877` | Independent eight-byte configuration blocks | Exact identity, per-PID presence, F5 service route and session required. L5 only retains `1871`/`1877` here. |
| `1878`, `1879`, `187A`, `187B`, `187C`, `187D`, `187E`, `187F` | Independent eight-byte configuration blocks | Same gate; L5 only retains `187B` here. |
| `1880`, `1881`, `1882`, `1883`, `1884`, `1885`, `1886`, `1887`, `1888`, `1889` | Independent eight-byte configuration blocks | L0–L4/L6 only; `1881` and `1887` are maintenance-only and are not generic read requests. |

No generic register addresses, units or editable fields are defined by these
block numbers. Do not transfer a configuration layout across feature groups.

### Other service and coordination families

| PID | Feature / direction gate | Payload and role |
|---|---|---|
| `188A` | L0–L8; addressed time-setting/service route | B0–B1 LE16 year; B2 month; B3 day; B4 hour; B5 minute; B6 second; B7 extra. Setting the clock is mutative. |
| `188B` | L0–L4/L6; configuration route | B0–B1 LE16 configuration word; B2 configuration byte; B3–B7 zero in report form. Maintenance-only; not an identity/version query. |
| `188C` | L0–L8; identity/service route | B0 fragment header; B1–B7 identity/padding. Received fragments can overwrite the identity assembly. Maintenance-only; not a read acknowledgment. |
| `1894` | L1–L4/L6 | B0 configuration flag; B1–B7 zero in report form. No generic meaning or safe query defined. |
| `1899` | L1–L4 | B0–B5 configuration bytes; B6–B7 LE16 configuration field. |
| `18A0` | L0–L8; calibration/status session | B0 selector; B1–B7 selector-dependent data. TX and RX selector meanings are not universally symmetric. |
| `18DF` | L0–L4/L6; service → module | Configuration-transfer/session request; B0–B7 session-dependent. Does not establish a read-only transfer. |
| `18FC` | Reports: L5/L7/L8. Additional input: L4 only for legacy extended-19 `QAAa9011` | Report B0–B1 status; B2–B7 zero. Report emission can depend on an active aging flag. RX semantics are state-changing. The additional legacy L4 input consumes B3 and LE16(B4); no legacy report is implied. L5 TX support must not be promoted to identical RX support. |
| `18FD` | L0–L8; service/control route | B0 control; B1–B2 LE16 requested mask; B3–B7 further control fields. Requested mask is not a readback. L8 clear-side effects follow the release-11 gate above. Excluded from automatic balance discovery and control. |
| `18B0DFF4` | L0–L8; coordinator → participants, active update session | B0 phase selector; B1–B5 control data; B6–B7 session parameter in L8. Earlier profiles must not inherit the L8 parameter meaning. |
| `18B0FFF5` | Service-originated update route where separately qualified | Distinct route/session from `18B0DFF4`; keep payload raw without the matching service contract. |
| `18B1DFF4` | L1–L8; coordinator → eligible participants | B0 propagated session parameter; B1–B7 other data. Acceptance depends on participant role/state; not a generic version query. |

`18B0DFF4` and `18B1DFF4` are vertical-stack update coordination. On PCS,
`782/728` is associated with stack service, while `7F8/78F` identifies a separate
cluster-service route in applicable profiles. Alternate PCS `191EDFF2` can feed
the parameter propagated through `18B1DFF4`. These associations do not imply a
transparent arbitrary PCS-to-LINK tunnel or update compatibility for an unknown
peer. Update transfer and activation are separate from telemetry decoding.

The families **`1881`, `1887`, `188B`, `188C` are maintenance-only for unknown
or mixed profiles**. A different diagnostic profile can assign another operation
to the same numeric family. Neither an apparent read response nor an
empty request makes it harmless.

## Opaque fields and implementation limits

An opaque field is still retained with its width, byte order, source and age.
Use a neutral display name and no unit. The following groups have no additional
physical enum or unit in this contract:

| Fields | Retained representation |
|---|---|
| `1800` unmapped status bits; `1801` mixed algorithm/cache bytes | Separate bits/bytes and the declared mixed word |
| `1803` algorithm estimates and configuration/version bytes | Typed independent fields; only expressly gated capacity conversions apply |
| `1804` two accumulators | Two LE32 codes; no Ah/Wh conversion |
| `1807` additional algorithm value outside the local release-11 SOC gate, and configuration byte | LE16 code and U8 code |
| `180A` status fields | U8 status, LE24 counter-derived code, LE16 result, optional LE16 algorithm code |
| `180C` three words and status; `1840` configuration/state bytes | Three LE16 codes plus U8; six bytes plus the declared capacity-related word |
| `1861` state bytes and `1869` summary state/words | Independent state codes and LE16 words; no run or work mode substitution |
| L4 `1862` third word outside the explicit fine-average gate; L8 fine average without a qualified reporting module and count | Opaque LE16; no automatic temperature display |
| `180D…180F` unassigned aggregate fields | Aggregate-scoped codes, kept apart from local module measurements |
| `1870…188C`, `189x`, `18A0`, `18B0/18B1`, `18DF`, `18F0`, `18FC/18FD/18FE` unassigned selectors or control fields | Exact payload bytes with the message's receiver class and route; no synthesized polling request |
| Unnamed fault positions and DTC conditions | Bit coordinates or code/index; no guessed symbolic name |

For release-11 the `1869` additional coordinator state is carried through PCS
`590` reception and LINK coordinator-state reception. It is separate from
PCS heartbeat `301.B7`. `1861.B7` is a member state channel with its own source;
these fields must not be collapsed into one global mode merely because they
are bytes. Unknown state codes remain visible and never become commands.

## Addressed monitor profile

Some monitor interfaces advertise an extended-ID format with `04xx`, `08xx`, `10xx` and `14xx` families (**Monitor-Addressed**). It is a separate addressed profile. It is selected only by an independently qualified peer or protocol association together with compatible traffic. A QAAB identity or a shared service PID does not establish it, and it is not a fallback decoder for native `18xx`. This contract assigns no layout to those families, and it defines no request or reply for them.

## Interoperability rules

- Preserve physical bus, full CAN ID, IDE, DLC, direction, source/destination,
  identity selector, raw payload and reception time for every decoded value.
- Keep module, stack aggregate, cluster and gateway scopes distinct. A serial
  fragment or an address is not sufficient to merge two physical bus sources.
- Expose raw/unknown fields and partial coverage explicitly. Do not borrow units,
  cell counts, fault dictionaries or handler support from another profile.
- Receiving one optional PID can establish an observed feature. Receiving a
  newer-looking numeric version cannot enable every earlier or later feature.
- Retain service/configuration traffic without automatic replay.
  A device can accept a write while the requested read feature is unsupported.
- When the source changes identity or address association, invalidate dependent
  reassembly and freshness state before attributing further data.
