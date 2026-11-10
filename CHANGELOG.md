# Changelog

## Unreleased

- Breaking coordinated CAN library field names: `maximum_temperature` becomes
  `temperature_maximum` and `minimum_temperature` becomes
  `temperature_minimum` for the supported LINK and PCS fields. There is no
  alias, fallback or migration path. See the [name contract](architecture/naming-contract.md).
