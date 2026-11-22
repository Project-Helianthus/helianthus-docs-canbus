# Growatt Low-Voltage BMS CAN V1.04 Contract

## Scope and Safety

This contract defines passive decoding for
`growatt.bms.low_voltage.can.v1_04`. It applies only to a low-voltage BMS
interface explicitly selected as V1.04.

Support is declared from the protocol documents. Frames the specification
documents as commands have a transmit path. The transport offers the
publication API and canbusreg decides what is sent. This contract does not
infer connector wiring, transceiver voltage, termination, or any other
electrical property.

## Link Profile

| Property | Required value |
| --- | --- |
| CAN frame type | 11-bit standard |
| Nominal bit rate | 500 kbit/s |
| Byte order for multi-byte values | big-endian |
| Data-frame payload length | 8 bytes for every defined frame |
| Remote-transmission request | Not a defined contract frame |

The link profile is not a generic SocketCAN default. A caller selects it only
for an interface already known to use this V1.04 protocol.

## Required Frame Geometry

Defined BMS report frames use a standard, non-RTR identifier and DLC 8. A
frame with a listed identifier but another identifier format, RTR state, or DLC
MUST remain opaque.

The inverter side sends the standard (11-bit) frame `0x301` every second. Its
payload is the one the document lists, `11-22-33-44-55-66-77-88`, which the
document presents as a standard frame in decimal and which this page states
as the source presents it, assigning no further meaning to it. An
inverter-side endpoint configured with the V1.04 profile therefore has the
revision's frame, sender, cadence and payload on this page. A caller that
only observes may still observe `0x301`, which is optional and required of no
decoder.

## Frame Map

| ID | Meaning | Required payload interpretation |
| --- | --- | --- |
| `0x311` | Charge and discharge limits | `u16be` charge voltage in 0.1 V; `u16be` charge-current limit in 0.1 A; `u16be` discharge-current limit in 0.1 A; status word |
| `0x312` | Protection, warning, and pack metadata | Four status bytes; pack count at byte 4; manufacturer bytes 5-6; total cell count at byte 7 |
| `0x313` | Pack or system measurements | `i16be` voltage in 0.01 V; `i16be` current in 0.1 A; `i16be` maximum cell temperature in 0.1 degrees C; SOC byte; SOH byte with flag |
| `0x314` | Capacity and lifecycle measurements | `u16be` remaining capacity in 10 mAh; `u16be` full-charge capacity in 10 mAh; `u16be` cell-voltage spread in 1 mV; `u16be` cycle count |
| `0x319` | Request, battery type, and extrema | Request/type flags; `u16be` maximum and minimum cell voltage in 1 mV; maximum-cell index; minimum-cell index; protected-pack ID |
| `0x320` | Manufacturer and build time | Manufacturer bytes; hardware version byte; software version byte; packed date and time |
| `0x321` | Update status | Update state byte; per-pack progress; programming-pack ID; successful-update count; remaining bytes opaque |

An implementation MUST preserve the original frame alongside a decoded value.
It MUST preserve the full status and reserved bits even where it projects a
named value.

## Status and Errors

For `0x311`, the status word is bytes 6-7. Bits 0-1 are the operating state:
`00` soft-starting, `01` standby, `10` charging, and `11` discharging. Bit 2
is the error-byte valid flag. Bit 3 is cell-balance status, `0` unbalance and
`1` balance. Bit 4 is sleep status. Bit 5 is discharge-output status. Bit 6
is charge-output status. Bit 7 is battery-terminal status, `0` connected and
`1` open. Bits 8-9 are the master operation mode: `00` standalone, `01`
parallel, `10` parallel preparation. Bits 10-11 are the storage-system state:
`00` none, `01` standby, `10` charging, `11` discharging. Bits 12-15 are not
defined and stay raw. A decoder MUST retain unrecognized or reserved bits as
raw status; it MUST NOT convert their absence into a healthy state.

For `0x312`, byte 0 and byte 1 are protection and byte 2 and byte 3 are
warning. A set bit is a reported condition. A clear bit is not an independent
proof that the condition is absent outside this frame's observation time.

Protection byte 0, bit 7 to bit 0: discharge over-current, charge
over-current, short-circuit discharge, cell over-voltage, cell under-voltage,
module over-voltage, module under-voltage, soft-start failure.

Protection byte 1, bit 7 to bit 2: discharge over-temperature, charge
over-temperature, discharge under-temperature, charge under-temperature,
system error, delta-voltage failure. Bits 1 and 0 are not defined and stay raw.

Warning byte 0, bit 7 to bit 0: discharge over-current, charge over-current,
bit 5 undefined and raw, cell over-voltage, cell under-voltage, module
over-voltage, module under-voltage, bit 0 undefined and raw.

Warning byte 1, bit 7 to bit 0: discharge over-temperature, charge
over-temperature, discharge under-temperature, charge under-temperature,
bit 3 undefined and raw, delta-voltage failure, warning before shutdown,
internal communication failure.

For `0x319`, the request/type byte records battery chemistry in bits 0-1,
force-charge request in bit 5, discharge enable in bit 6, and charge enable in
bit 7. Bits not defined by this contract MUST remain opaque.

The packed `0x320` date and time has fields for second, minute, hour, day,
month, and a year offset from 2000. Invalid field ranges MUST be reported as a
decode error rather than normalized to another timestamp.

## Optional Frames

The per-cell voltage reports are optional and are not required for admission:

| ID | Cells | Encoding |
| --- | --- | --- |
| `0x315` | 1-4 | four `u16be` voltages in 1 mV |
| `0x316` | 5-8 | four `u16be` voltages in 1 mV |
| `0x317` | 9-12 | four `u16be` voltages in 1 mV |
| `0x318` | 13-16 | four `u16be` voltages in 1 mV |

An absent optional frame means only that no value was observed. It MUST NOT be
represented as zero voltage or as a missing-cell fault.

## Registry Admission

An endpoint configured with the V1.04 profile is recognised by that
configuration. The `0x311`, `0x312`, and `0x313` geometry decides only whether
a complete V1.04 snapshot is decoded and published. An incomplete, malformed,
or inconsistent snapshot stays raw for that snapshot and never makes the
configured profile unrecognised. `0x301`, a single listed ID, or a bitrate
setting does not by itself publish a complete snapshot.

If two profiles admit the same evidence, the registry MUST return no profile
and no semantic projection.

## Native MCP Observation Boundary

An MCP status result for an admitted V1.04 snapshot MUST retain each available
native observation alongside its decoded fields. `raw_evidence` records use the
following fields when the provider has them: interface identity, listener
sequence, monotonic observation time, identifier, extended-identifier state,
RTR state, effective payload length, raw DLC, and data bytes.

The implementation MUST preserve an available native field without replacing it
with a digest, a placeholder, or a semantic substitute. A provider that lacks a
field leaves that field unavailable; it MUST NOT fabricate a value from another
observation. Payload bytes beyond the effective payload length are not frame
payload and MUST NOT be reported as live data. The V1.04 frames defined here
have effective payload length eight, so all eight data bytes are preserved for
an accepted report frame. Raw DLC remains transport metadata and does not extend
the payload beyond eight bytes.

An invalid individual raw observation MUST NOT clear an otherwise admitted
snapshot or its valid decoded values. It remains a transport diagnostic outcome
and is either excluded from `raw_evidence` or reported by the transport's error
contract without becoming a V1.04 frame projection.

`outbound_allowed` reflects the provider's available capability state. It is
separate from an applied effect. The driver decides what is sent.

The following is synthetic structural data only:

```json
{
  "profile": "growatt.bms.low_voltage.can.v1_04",
  "outbound_allowed": false,
  "raw_evidence": [
    {
      "interface": "can0",
      "sequence": 1,
      "monotonic_nanos": 0,
      "identifier": 785,
      "extended": false,
      "rtr": false,
      "dlc": 8,
      "raw_dlc": 8,
      "data": [0, 0, 0, 0, 0, 0, 0, 0]
    }
  ]
}
```

## Unknown Data

Frames outside the listed identifiers, reserved payload bits, unknown version
values, malformed values, and incomplete evidence MUST remain opaque. A decoder
MUST NOT synthesize capability, health, control, or physical-layer claims from
them.

## Compatibility

This contract establishes neither installed-device compatibility nor electrical
interoperability. A different protocol revision is a separate profile. The
documented one-second `0x301` send of the inverter-side endpoint configured
with the V1.04 profile is within this contract. Control semantics, polling,
and any other transmit behavior the V1.04 document does not declare stay
outside it.
