# Changelog

## Unreleased

- Breaking coordinated CAN library field names: `maximum_temperature` becomes
  `temperature_maximum` and `minimum_temperature` becomes
  `temperature_minimum` for the supported LINK and PCS fields. There is no
  alias, fallback or migration path. See the [name contract](architecture/naming-contract.md).
- The Growatt common projection lists the allowed values of each topology
  context member (`bank`, `scope`, `endpoint`, `group`, `slot`), marks each as
  asserted by configuration or observed on the wire, and states the PCS flavor
  and bank pairing; the PCS and LINK pages link the table. See the
  [topology context values](protocols/growatt/growatt-low-voltage-bms-can-common-projection-v1.md#topology-context-values).
- The Gree VRF CAN page states what one interface establishes about system
  membership and unit roles. Each unresolved relation has an evidence grade.
  The unit field is a coordinate and never an identity anchor. Its
  source/destination polarity and any sender field stay unknown. See
  [What one interface establishes](protocols/gree/vrf-canbus.md#what-one-interface-establishes).
