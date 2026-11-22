# Growatt Low-Voltage BMS CAN Protocol Contracts

These documents are implementation-neutral protocol contracts for Growatt
low-voltage battery management systems on CAN. They are published in the CC0
`protocols/` lane of this repository. Support is declared from the protocol
documents. Frames the specification documents as commands have a transmit
path. The transport offers the publication API and canbusreg decides what is
sent.

The documents form two independent sets and one separate addressed profile. They are selected by different
inputs and never select each other.

## Revision-labelled inverter link (V1.04)

Frames described by published, revision-labelled documents. The caller selects
a revision profile explicitly.

- [V1.04 contract](low-voltage-bms-can-v104.md)
- [V1.08 contract](low-voltage-bms-can-v108.md)
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

## Addressed monitor profile

A separate addressed profile that some monitor interfaces advertise, independent of both sets above.

- [Addressed monitor profile](growatt-low-voltage-bms-can-monitor-addressed-profile-v1.md): the `04xx`, `08xx`, `10xx` and `14xx`
  families, the diagnostic record families and the per-signal field reference.

## Evidence

The V1.04 documents cite published revision documents. The PCS, LINK and addressed monitor profile layouts are declared from those owner-contributed documents and are the decode contract when an endpoint is configured with them. The hardware test level is recorded. They cite no public source. They
are published at the repository owner's direction (issues #37 and #39), and
the public-URL rule in `AGENTS.md` is waived for them only.

## Relationship

- The same CAN identifier can carry a different layout in each set. An
  identifier match never selects a document.
- No correlation between project codes and published revision labels is
  established. A project-code selector MUST NOT select a revision label, and a
  revision label MUST NOT select a project code.
- The project-code documents do not change decoding or raw-evidence rules of
  the V1.04 contract. Standard PCS traffic uses 11-bit frames with `0x311`,
  `0x312` and `0x313`. Those identifiers do not select the V1.04 profile. An
  endpoint configured with the V1.04 profile is recognised by that
  configuration. V1.04 applies only when the caller explicitly selects it for
  an interface.
- Conditions described in the PCS, LINK and addressed monitor profile documents
  are necessary for a device to accept a message and are insufficient for
  acceptance. The documented configured inverter-side transmission scope is
  separate: frames the specification documents as commands have a transmit
  path, the transport offers the publication API, and canbusreg decides what
  is sent.
