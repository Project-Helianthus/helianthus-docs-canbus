# Growatt Low-Voltage BMS CAN V1.05 Candidate

## Scope and Safety

This page is documentation-only candidate metadata for
growatt.bms.low_voltage.can.v1_05. It does not authorize a registry flavor or
classifier. It does not define a universal CAN profile, electrical layer,
connector, transceiver, frame identifier, payload layout, or send operation.

A conforming implementation MUST remain receive-only. It MUST NOT transmit,
acknowledge, probe, configure, or otherwise change a CAN interface or attached
equipment.

## Candidate Link Metadata

| Parameter | Candidate value | Boundary |
| --- | --- | --- |
| Protocol name | Growatt BMS CAN-Bus Protocol Low Voltage | Candidate profile label |
| Version | V1.05 | Candidate profile revision |
| Transport | CAN | Not a generic SocketCAN default |
| Nominal bit rate | 500 kbit/s | Candidate metadata only |
| CAN+ | Not specified | No electrical inference is permitted |

The metadata MUST be selected explicitly. It MUST NOT be inferred from an
interface name, voltage, connector, inverter brand, frame identifier, or a
single observed frame.

## Candidate Applicability

The candidate is limited to an installation that explicitly declares this
profile revision and a compatible low-voltage Growatt BMS integration. Product
families reported with this candidate include SPF TL HVM-WPV-P and SPF KT HVM.
This list is not an automatic identification rule.

An installation not meeting every declared condition remains unknown. A
different Growatt protocol revision or a similarly named profile remains a
separate candidate.

## Admission and Evidence

No V1.05 frame authority, positive frame discriminator, or sanitized
conformance vector is defined by this page. Therefore every received frame MUST
remain opaque and no Growatt registry classifier, projection, capability, unit,
state, or property may be exposed.

An implementation MAY retain bounded raw classic-CAN evidence only. It MUST
preserve the transport observation boundary and MUST NOT invent field names,
units, limits, or control semantics.

## Compatibility

This document does not establish physical interoperability, installed-device
support, arbitration behavior, timing behavior, or delivery on a bus. A future
revision may add a frame contract only with complete deterministic layout,
positive admission gates, bounded evidence rules, and read-only conformance
vectors.
