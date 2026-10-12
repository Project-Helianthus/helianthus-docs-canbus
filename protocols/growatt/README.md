# Growatt Low-Voltage BMS CAN Protocol Contracts

These documents are implementation-neutral protocol contracts for Growatt
low-voltage battery management systems on CAN. They are published in the CC0
`protocols/` lane of this repository. They are receive-only documentation:
none of them authorizes a transmission or any other live bus action, and none
is qualified by Helianthus against hardware.

The documents form two independent sets. They are selected by different
inputs and never select each other.

## Revision-labelled inverter link (V1.04)

Frames described by published, revision-labelled documents. The caller selects
a revision profile explicitly.

- [V1.04 contract](low-voltage-bms-can-v104.md)
- [V1.04 qualification card](growatt-low-voltage-bms-can-v104-qualification-card-v1.md)
- [Version evidence](growatt-low-voltage-bms-can-version-evidence-v1.md)
- [Common projection](growatt-low-voltage-bms-can-common-projection-v1.md)

## Project-code profiles (PCS and LINK)

Profiles selected by a project code with a release, such as `QAAA0006`.

- [PCS protocol](growatt-low-voltage-bms-can-pcs-protocol-v1.md): the
  inverter-facing, stack-facing and parallel-group interfaces, including the
  extended-19 profile and the diagnostic code dictionary.
- [LINK protocol](growatt-low-voltage-bms-can-link-protocol-v1.md): the module
  bus behind the coordinator, with module identity, cell and temperature
  reports, coordination, and configuration and maintenance receiver gates.

## Evidence

The V1.04 documents cite published revision documents. The PCS and LINK
documents are owner-contributed candidate records: they cite no public source,
and every statement in them is an unverified candidate claim.

## Relationship

- The same CAN identifier can carry a different layout in each set. An
  identifier match never selects a document.
- No correlation between project codes and published revision labels is
  established. A project-code selector MUST NOT select a revision label, and a
  revision label MUST NOT select a project code.
- The project-code documents do not change admission, decoding or raw-evidence
  rules of the V1.04 contract. PCS traffic uses standard 11-bit frames with
  `0x311`, `0x312` and `0x313`, which satisfies the frame geometry of the V1.04
  admission tuple. V1.04 applies only when the caller explicitly selects it for
  an interface; such traffic is never admitted as V1.04 by identifier match.
- Conditions described in the PCS and LINK documents are necessary for a device
  to accept a message and are never sufficient. This repository defines no
  condition under which Helianthus software transmits.
