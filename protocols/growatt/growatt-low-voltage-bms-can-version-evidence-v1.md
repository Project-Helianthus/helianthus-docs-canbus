# Growatt Low-Voltage BMS CAN Version Evidence V1

## Scope and Safety

This evidence record compares the revision labels V1.04, V1.05, V1.07, and
V1.08 for the low-voltage BMS CAN family. It is a documentation boundary, not
a decoder, admission rule, equipment match, electrical claim, or control
contract.

`growatt.bms.low_voltage.can.v1_04` remains the only selected revision
profile. Its defined status word remains available as `RawStatus`, including
reserved bits. This record assigns neither a balance polarity nor a health
conclusion to that raw value. The separately opt-in
[common projection](growatt-low-voltage-bms-can-common-projection-v1.md)
does not select, infer, or admit a revision profile.

The cited documents are inspected only for revision-scoped facts. This record
paraphrases them and does not reproduce their prose, frame tables, or example
payloads. Synthetic V1.04 material remains in the separate V1.04 contract and
qualification card.

## Evidence Classes

| Class | Meaning | Profile consequence |
| --- | --- | --- |
| Selected contract | A Helianthus contract currently limits one named profile. | It is not evidence for a different revision. |
| Revision note | A later revision document names an earlier revision change. | Candidate evidence only; it supplies no complete earlier-revision layout. |
| Revision document | A revision document describes fields for its own revision. | It requires a separate rights-safe contract and synthetic vectors before any profile work. |
| Complementary family | A document from another named family reports a similar identifier or flag. | It never changes a Growatt profile. |

## Source-Confidence and Version-Feature Matrix

| Revision label | Evidence and exact page | Confidence boundary | Feature boundary | Current treatment |
| --- | --- | --- | --- | --- |
| V1.04 | [Existing V1.04 contract](low-voltage-bms-can-v104.md) | Selected-contract baseline; this record does not re-qualify its underlying revision evidence. | `0x320` byte 3 is the BMS software version; bytes 4--7 are packed date and time. The V1.04 contract owns its frame map and preserves `RawStatus`. | The only selected low-voltage revision profile. |
| V1.05 | [V1.08 revision history, p. 1](https://www.scribd.com/document/541900756/Growatt-BMS-CAN-Bus-protocol-low-voltage-V1-08#page=1) | Revision note only; no complete V1.05 layout is established here. | The note identifies a frequency-regulation enable associated with `0x211`; it does not establish a V1.08 behavior for V1.05. | Unsupported; no V1.05 admission, decoder, or fallback. |
| V1.07 | [V1.08 revision history, p. 1](https://www.scribd.com/document/541900756/Growatt-BMS-CAN-Bus-protocol-low-voltage-V1-08#page=1) | Revision note only; no standalone complete V1.07 layout is established here. | The note identifies a software-version high-byte extension in `0x320`. | Unsupported; no generic `>= V1.07` rule. |
| V1.08 | [V1.08 revision history and frame descriptions, pp. 1, 4, 5, 8, 10, and 11-12](https://www.scribd.com/document/541900756/Growatt-BMS-CAN-Bus-protocol-low-voltage-V1-08#page=1) | Revision document available through a third-party host; it is not a V1.04 or V1.07 contract. | It changes `0x211` to event-driven handling and adds fault-clear enable ([p. 4](https://www.scribd.com/document/541900756/Growatt-BMS-CAN-Bus-protocol-low-voltage-V1-08#page=4)); for `0x320`, byte 3 is software-version low and byte 4 is software-version high ([p. 10](https://www.scribd.com/document/541900756/Growatt-BMS-CAN-Bus-protocol-low-voltage-V1-08#page=10)); `0x323` has one total-cell-count byte limited to 1--254 plus extension flags; `0x315` through `0x318` are legacy optional cell reports. | Candidate only; a separate V1.08 profile needs a rights-safe contract and synthetic vectors. |

The V1.08 links identify every consulted frame-description page: [p. 4](https://www.scribd.com/document/541900756/Growatt-BMS-CAN-Bus-protocol-low-voltage-V1-08#page=4), [p. 5](https://www.scribd.com/document/541900756/Growatt-BMS-CAN-Bus-protocol-low-voltage-V1-08#page=5), [p. 8](https://www.scribd.com/document/541900756/Growatt-BMS-CAN-Bus-protocol-low-voltage-V1-08#page=8), [p. 10](https://www.scribd.com/document/541900756/Growatt-BMS-CAN-Bus-protocol-low-voltage-V1-08#page=10), [p. 11](https://www.scribd.com/document/541900756/Growatt-BMS-CAN-Bus-protocol-low-voltage-V1-08#page=11), and [p. 12](https://www.scribd.com/document/541900756/Growatt-BMS-CAN-Bus-protocol-low-voltage-V1-08#page=12).

## Profile Separation

A revision label is an explicit input when a caller selects a revision profile;
it is not inferred from a shared identifier, link setting, partial frame, or
firmware value. In particular, the published documents establish no
firmware-to-protocol-revision correlation, so firmware MUST NOT select V1.04,
V1.07, or V1.08. No V1.05, V1.07, or V1.08 evidence may widen V1.04 admission,
alter its frame interpretation, or provide an alternate version path. An
incomplete, malformed, conflicting, or unselected-revision observation remains
raw and opaque under the V1.04 contract.

A later revision profile, if separately established, must preserve its own
native observations and state its own geometry, version discriminator, and
negative vectors. The common projection does not provide a version
discriminator or substitute for a revision profile.

The V1.08 legacy optional reports `0x315` through `0x318` do not contribute a missing-cell failure when absent. Their absence says only that those optional
reports were not observed; it does not change V1.04 optional-frame handling.

## `0x311` Balance-Flag Ambiguity

The V1.08 document places its `0x311` status word in bytes 6--7 and describes
bit 3 as `0` unbalance and `1` balance
([p. 5](https://www.scribd.com/document/541900756/Growatt-BMS-CAN-Bus-protocol-low-voltage-V1-08#page=5)). A distinct Sigineer
document describes its named byte-seven bit 3 with the opposite polarity:
`0` equilibrium and `1` unbalanced
([p. 9](https://www.sigineer.com/wp-content/uploads/2021/01/Sigineer-Power-Solar-Inverter-CANBUS-Protocol-20210122.pdf#page=9)).

The Sigineer document is complementary-family evidence, not a Growatt revision.
The disagreement therefore remains unresolved and profile-local: it MUST NOT
invert, normalize, or reinterpret V1.04 `RawStatus` as a polarity correction;
it MUST NOT admit V1.08;
and it MUST NOT establish active-balancer behavior, equipment behavior, or a
control capability. A future selected revision contract must state the exact
bit position, byte order, and polarity from its revision-bound evidence, while
retaining the raw status word.

## Sigineer Non-Admission Boundaries

The Sigineer document splits its `0x323` count between byte 0 and byte 3
([p. 16](https://www.sigineer.com/wp-content/uploads/2021/01/Sigineer-Power-Solar-Inverter-CANBUS-Protocol-20210122.pdf#page=16)). Its
`0x330` describes extrema with cluster and cell coordinates, not complete per-cell telemetry
([p. 19](https://www.sigineer.com/wp-content/uploads/2021/01/Sigineer-Power-Solar-Inverter-CANBUS-Protocol-20210122.pdf#page=19)). The same document also describes a 29-bit identifier while
calling the corresponding frame a standard frame
([p. 5](https://www.sigineer.com/wp-content/uploads/2021/01/Sigineer-Power-Solar-Inverter-CANBUS-Protocol-20210122.pdf#page=5)).

Those are Sigineer-local observations. The count layout, extrema coordinates,
and identifier/frame-form contradiction MUST NOT be imported into a Growatt
profile. No Sigineer profile admission is defined until that contradiction is
resolved by revision-bound evidence; meanwhile `0x330` cannot be projected as
complete per-cell telemetry.

## Non-Claims and Next Evidence

This record establishes no installed-product compatibility, hardware identity,
connector or electrical property, live-bus result, or state-changing operation.
It does not authorize transmission, acknowledgement, probing, configuration, or
admission of an unselected profile.

Before a V1.05, V1.07, or V1.08 profile can be considered, its owner needs a
complete revision-bound, rights-safe contract and synthetic positive and
negative vectors. Until then, the V1.04 contract is unchanged and all other
revision-labelled observations remain unsupported and opaque.
