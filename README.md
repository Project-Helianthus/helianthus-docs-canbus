# Helianthus CAN Bus Documentation

This repository documents Helianthus CAN transport and registry boundaries plus
implementation-neutral vendor protocol contracts.

## Documentation Map

- [CAN transport architecture](architecture/can-transport.md)
- [Registry boundary](architecture/registry-boundary.md)
- [Fail-closed CAN registry conformance](contracts/registry-conformance.md)
- [Passive SocketCAN diagnostic model](contracts/socketcan-diagnostics.md)
- [Passive SocketCAN conformance replay guide](contracts/socketcan-replay.md)
- [Receive-only SocketCAN contract](contracts/socketcan-receive-only.md)
- [Gree VRF protocol contracts](protocols/gree/)
- [Growatt low-voltage BMS CAN V1.04 contract](protocols/growatt/low-voltage-bms-can-v104.md)
- [Growatt low-voltage BMS CAN V1.04 qualification card](protocols/growatt/growatt-low-voltage-bms-can-v104-qualification-card-v1.md)

## Scope

helianthus-canbus owns generic CAN frame reception, SocketCAN lifecycle,
deadlines, and bounded observation delivery. It has no vendor profiles.

helianthus-canbusreg owns multi-vendor identification, bounded raw evidence,
capability profiles, and evidence-backed projections. Gree VRF is its first
vendor flavor; additional vendors are separate profiles.

SocketCAN is receive/listen-only in the current milestone. Transmit is
default-denied and no document authorizes a live bus operation.

## Licensing

This repository has two license lanes:

- [protocols/](protocols/) is dedicated to the public domain under
  [CC0-1.0](protocols/LICENSE). It contains implementation-neutral protocol
  contracts only.
- Everything outside protocols/ is licensed under [AGPL-3.0](LICENSE). It
  documents Helianthus architecture and implementation contracts.

The directory boundary is normative: generic CAN architecture and Helianthus
contracts stay outside protocols/; vendor wire contracts stay inside it.

## Validation

~~~bash
./scripts/check_docs.sh
./scripts/test_docs_gate.sh
~~~
