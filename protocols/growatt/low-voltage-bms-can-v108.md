# Growatt Low-Voltage BMS CAN V1.08 Contract

## Scope

This page is the complete revision contract for
`growatt.bms.low_voltage.can.v1_08`. It is used when an endpoint is configured
with that revision. It does not infer a V1.04, V1.05, or V1.07 layout, and a
V1.04 observation does not select it.

Support is declared from the protocol documents. Frames the specification
documents as commands have a transmit path. The transport offers the
publication API and canbusreg decides what is sent.

The documented link is a standard 11-bit bus at 500 kbit/s. Multi-byte
integers are big-endian: the lower address holds the high byte. A bit the
document leaves undefined stays raw and is named below.

## Frame map

| CAN identifier | frame | byte | length | type | scale | unit | meaning (own words) |
| --- | --- | --- | ---: | --- | --- | --- | --- |
| `0x301` | inverter heartbeat | 0–7 | 8 | fixed bytes | none | none | Inverter-side standard frame sent every second. The document lists the bytes as `0x0B 0x16 0x21 0x2C 0x37 0x42 0x4D 0x58` and assigns no further field meaning. |
| `0x211` | write data | 0 | 1 | unsigned | none | none | Frequency-adjustment enable: 1 enable, 0 disable. |
| `0x211` | write data | 1 | 1 | unsigned | 1 | year | Clock year, domain 20–250. |
| `0x211` | write data | 2 | 1 | unsigned | 1 | month | Clock month, domain 1–12. |
| `0x211` | write data | 3 | 1 | unsigned | 1 | day | Clock day, domain 1–31. |
| `0x211` | write data | 4 | 1 | unsigned | 1 | hour | Clock hour, domain 0–23. |
| `0x211` | write data | 5 | 1 | unsigned | 1 | minute | Clock minute, domain 0–59. |
| `0x211` | write data | 6 | 1 | unsigned | 1 | second | Clock second, domain 0–59. |
| `0x211` | write data | 7 | 1 | unsigned | none | none | Fault-clear enable: 1 enable, 0 disable. |
| `0x212` | host query | 0 | 1 | bits | none | none | Query select. Bit 0 is the serial-number query. Bit 1 is the history-fault query. Bits 2–7 are reserved and stay raw. |
| `0x212` | host query | 1 | 1 | unsigned | 1 | none | Battery ID to query. |
| `0x212` | host query | 2–7 | 6 | raw | none | none | Reserved. The document leaves these bytes undefined; they stay raw. |
| `0x311` | limits | 0–1 | 2 | uint16 | 0.1 | V | Suggested charge voltage. |
| `0x311` | limits | 2–3 | 2 | uint16 | 0.1 | A | Charge-current limit. |
| `0x311` | limits | 4–5 | 2 | uint16 | 0.1 | A | Discharge-current limit. |
| `0x311` | limits | 6–7 | 2 | bits | none | none | Status word, bits 0–11 defined below. Bits 12–15 are not defined and stay raw. |
| `0x312` | protection | 0 | 1 | bits | none | none | Protection byte 1. See the bit table. |
| `0x312` | protection | 1 | 1 | bits | none | none | Protection byte 2. See the bit table. |
| `0x312` | protection | 2 | 1 | bits | none | none | Warning byte 1. See the bit table. |
| `0x312` | protection | 3 | 1 | bits | none | none | Warning byte 2. See the bit table. |
| `0x312` | protection | 4 | 1 | uint8 | 1 | count | Pack count, domain 1–254. |
| `0x312` | protection | 5–6 | 2 | bits | none | none | Derating reason, high byte then low byte. See the derating bits. |
| `0x312` | protection | 7 | 1 | raw | none | none | Reserved. The document leaves this byte undefined; it stays raw. |
| `0x313` | measurements | 0–1 | 2 | sint16 | 0.01 | V | Module voltage or average system voltage. |
| `0x313` | measurements | 2–3 | 2 | sint16 | 0.1 | A | Module or system current. |
| `0x313` | measurements | 4–5 | 2 | sint16 | 0.1 | °C | Average battery temperature. |
| `0x313` | measurements | 6 | 1 | uint8 | 1 | % | Average state of charge. |
| `0x313` | measurements | 7 | 1 | bits | none | none | Bits 0–6 are state of health. Bit 7 is the life warning flag. |
| `0x314` | capacity | 0–1 | 2 | uint16 | 10 | mAh | Remaining capacity. |
| `0x314` | capacity | 2–3 | 2 | uint16 | 10 | mAh | Full-charge capacity. |
| `0x314` | capacity | 4–5 | 2 | uint16 | 1 | mV | Difference between maximum and minimum cell voltage. |
| `0x314` | capacity | 6–7 | 2 | uint16 | 1 | count | Cycle count. |
| `0x315` | legacy cells | 0–7 | 8 | uint16 | 1 | mV | Optional cell voltages 1–4, four big-endian words. Absence is not a missing-cell fault. |
| `0x316` | legacy cells | 0–7 | 8 | uint16 | 1 | mV | Optional cell voltages 5–8. |
| `0x317` | legacy cells | 0–7 | 8 | uint16 | 1 | mV | Optional cell voltages 9–12. |
| `0x318` | legacy cells | 0–7 | 8 | uint16 | 1 | mV | Optional cell voltages 13–16. |
| `0x319` | extrema | 0 | 1 | bits | none | none | Request and battery-type flags. See the request bits. |
| `0x319` | extrema | 1–2 | 2 | uint16 | 1 | mV | Maximum cell voltage. |
| `0x319` | extrema | 3–4 | 2 | uint16 | 1 | mV | Minimum cell voltage. |
| `0x319` | extrema | 5 | 1 | uint8 | 1 | index | Maximum-cell index. |
| `0x319` | extrema | 6 | 1 | uint8 | 1 | index | Minimum-cell index. |
| `0x319` | extrema | 7 | 1 | uint8 | 1 | index | Pack ID that reported protection. |
| `0x320` | identity | 0–1 | 2 | bytes | none | none | Manufacturer name bytes. A battery with no special compatibility need may send 0. |
| `0x320` | identity | 2 | 1 | uint8 | 1 | none | Hardware version, domain 1–9. |
| `0x320` | identity | 3 | 1 | uint8 | 1 | none | Software-version low byte. A one-byte version reports the low byte and 0 in the high byte. |
| `0x320` | identity | 4 | 1 | uint8 | 1 | none | Software-version high byte. |
| `0x320` | identity | 5 | 1 | uint8 | 1 | none | Highest parallel software version, low byte. |
| `0x320` | identity | 6 | 1 | uint8 | 1 | none | Highest parallel software version, high byte. |
| `0x320` | identity | 7 | 1 | raw | none | none | Reserved. The document leaves this byte undefined; it stays raw. |
| `0x321` | update | 0 | 1 | bits | none | none | Update status. The document groups bits 5–7, 3–4, 1–2, and 0–1, so the assignment of bit 1 is not established; undefined overlap stays raw. |
| `0x321` | update | 1 | 1 | uint8 | 1 | % | Pack update progress, domain 0–100. |
| `0x321` | update | 2 | 1 | uint8 | 1 | none | Programming status of the pack. |
| `0x321` | update | 3–6 | 4 | raw | none | none | Reserved. The document leaves these bytes undefined; they stay raw. |
| `0x322` | cell extrema | 0–1 | 2 | sint16 | 0.1 | °C | Highest cell temperature. |
| `0x322` | cell extrema | 2–3 | 2 | sint16 | 0.1 | °C | Lowest cell temperature. |
| `0x322` | cell extrema | 4 | 1 | uint8 | 1 | index | Index of the highest-temperature cell. |
| `0x322` | cell extrema | 5 | 1 | uint8 | 1 | index | Index of the lowest-temperature cell. |
| `0x322` | cell extrema | 6 | 1 | uint8 | 1 | % | Highest state of charge, domain 0–100. |
| `0x322` | cell extrema | 7 | 1 | uint8 | 1 | % | Lowest state of charge, domain 0–100. |
| `0x323` | extended status | 0 | 1 | uint8 | 1 | count | Total cell count, domain 1–254. |
| `0x323` | extended status | 1–3 | 3 | raw | none | none | Reserved. The document leaves these bytes undefined; they stay raw. |
| `0x323` | extended status | 4 | 1 | bits | none | none | Protection group 3. Bits not listed stay raw. |
| `0x323` | extended status | 5 | 1 | bits | none | none | Protection group 4. |
| `0x323` | extended status | 6 | 1 | bits | none | none | Protection group 5. Bits 4–7 are not listed and stay raw. |
| `0x323` | extended status | 7 | 1 | bits | none | none | Warning group 3. Bits 4–7 are not listed and stay raw. |
| `0x324` | serial response | 0 | 1 | uint8 | 1 | none | Frame number of the serial-number response. |
| `0x324` | serial response | 1–7 | 7 | bytes | none | none | Frame 0: byte 1 is the battery ID and bytes 2–7 are serial characters. Later frames continue the serial characters. A serial longer than 16 characters may add frames, up to 32 serial bytes. Bytes the document marks reserved stay raw. |
| `0x325` | history response | 0 | 1 | uint8 | 1 | none | Frame number, shown in the document with the value 0. |
| `0x325` | history response | 1 | 1 | uint8 | 1 | none | Battery ID. |
| `0x325` | history response | 2–7 | 6 | raw | none | none | No history layout is defined. The document marks history status unresolved; these bytes stay raw and no history record is published. |

### `0x311` status bits

Bits 0–1 are the operating state: `00` soft-starting, `01` standby, `10`
charging, `11` discharging. Bit 2 is the error-byte valid flag. Bit 3 is
cell-balance status, `0` unbalance and `1` balance. Bit 4 is sleep status.
Bit 5 is discharge-output status. Bit 6 is charge-output status. Bit 7 is
battery-terminal status, `0` connected and `1` open. Bits 8–9 are the master
operation mode: `00` standalone, `01` parallel, `10` parallel preparation.
Bits 10–11 are reserved and stay raw. Bits 12–15 are not defined and stay raw.

### `0x312` protection and warning bits

Protection byte 0, bit 7 to bit 0: discharge over-current, charge
over-current, short-circuit discharge, cell over-voltage, cell under-voltage,
module over-voltage, module under-voltage, soft-start failure.

Protection byte 1, bit 7 to bit 0: discharge over-temperature, charge
over-temperature, discharge under-temperature, charge under-temperature,
system error, delta-voltage failure, parallel failure, parallel-version
disagreement.

Warning byte 0, bit 7 to bit 0: discharge over-current, charge over-current,
bit 5 undefined and raw, cell over-voltage, cell under-voltage, module
over-voltage, module under-voltage, bit 0 undefined and raw.

Warning byte 1, bit 7 to bit 0: discharge over-temperature, charge
over-temperature, discharge under-temperature, charge under-temperature,
bit 3 undefined and raw, delta-voltage failure, warning before shutdown,
internal communication failure.

### Derating reason

High byte bit 0 hardware-fault limit, bit 1 full-charge limit, bit 2
MOS-temperature limit, bit 3 ambient-temperature limit, bit 4 precharge-fault
limit, bit 5 communication-fault limit, bit 6 bus-fault limit, bit 7 reserved
and raw. Low byte bit 0 cell-voltage high limit, bit 1 cell-voltage low
limit, bit 2 cell-temperature high limit, bit 3 cell-temperature low limit,
bit 4 total-voltage high limit, bit 5 total-voltage low limit, bit 6
cell-voltage difference limit, bit 7 temperature-difference limit.

### `0x319` request byte

Bit 7 charge enable. Bit 6 discharge enable. Bit 5 force-charge request. Bit 4
is present in the document and marked unused. Bits 3–2 are not defined and
stay raw. Bits 1–0 are the battery type: `00` lithium iron phosphate, `01`
ternary, `10` lithium titanate, `11` reserved and raw.

### `0x323` named flags

Protection group 3, byte 4: bit 0 charge over-power, bit 1 discharge
over-power, bit 2 external communication fault, bit 3 precharge failure,
bit 4 hardware fault, bit 5 analog-front-end communication fault, bit 6 cell
lost, bit 7 total-current sample fault.

Protection group 4, byte 5: bit 0 total-voltage sample fault, bit 1 load-side
voltage sample fault, bit 2 calibration-parameter load fault, bit 3 bus
reverse connection, bit 4 hardware over-voltage, bit 5 hardware over-current,
bit 6 parallel fault, bit 7 primary-to-secondary voltage difference.

Protection group 5, byte 6: bit 0 hardware discharge over-current, bit 1
charge-limit failure, bit 2 discharge-limit failure, bit 3 main-path open.
Bits 4–7 stay raw.

Warning group 3, byte 7: bit 0 charge over-power, bit 1 discharge over-power,
bit 2 internal charge circulation, bit 3 internal discharge circulation.
Bits 4–7 stay raw.

## `0x211` dispatch

`0x211` is an event-triggered data command. When it is triggered it is sent
with a 1 s period, five consecutive times. Its clock-setting content is
triggered on the hour.

## `0x212` request and response

`0x212` is a host query frame that is read on demand, not sent periodically.
Byte 0 selects the query, one bit for the serial-number query and one bit for
the history-fault query. Byte 1 names the battery ID to query. On receiving
it, the battery sends the requested data once as its single application
response, which completes the exchange.

The serial-number query is answered by the `0x324` serial-number frames. The
history-fault query is answered by `0x325`. The document marks `0x325` as
pending. History status stays unresolved: this page defines no history data
layout. The `0x325` frame-map entry records byte 0 as the frame number, shown
in the document with the value 0, and byte 1 as the battery ID, and nothing
more.

This `0x212` is distinct from the PCS page's `212` host-input row, which
defines no serial or history query. A driver using the V1.08 profile takes
the query contract from this page and does not inherit that PCS
interpretation, and it does not schedule `0x212` as periodic traffic.

## Differences from V1.04

| frame | V1.04 | V1.08 |
| --- | --- | --- |
| `0x311` status bits 10–11 | storage-system state | reserved; the bits stay raw |
| `0x312` bytes 5–6 | manufacturer bytes | derating reason, high byte then low byte |
| `0x313` bytes 4–5 | maximum cell temperature | average battery temperature |

Bits the V1.08 document leaves undefined stay raw and are named in the frame
map. The V1.04 contract remains the contract of an endpoint configured as
V1.04. This page does not reconstruct a V1.05 or V1.07 frame map.
