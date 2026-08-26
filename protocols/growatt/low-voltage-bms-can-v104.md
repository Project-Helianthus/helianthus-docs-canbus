# Growatt Low-Voltage BMS CAN V1.04 Contract

## Scope and Safety

This contract defines passive decoding for
`growatt.bms.low_voltage.can.v1_04`. It applies only to a low-voltage BMS
interface explicitly selected as V1.04.

A conforming implementation MUST remain receive-only. It MUST NOT transmit,
acknowledge, probe, configure, or otherwise change a CAN interface or attached
equipment. It MUST NOT infer connector wiring, transceiver voltage, termination,
or any other electrical property from this contract.

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

The standard data frame `0x301` occurs in protocol exchange as a query or
keepalive observation. This receive-only contract does not interpret that frame
and does not require that it be observed.

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

For `0x311`, the low two bits of the status word are the BMS operating state:
`0` soft-starting, `1` standby, `2` charging, and `3` discharging. The status
word also contains an error-valid flag, balance state, sleep state, charge and
discharge output-enable states, battery-terminal state, master-box mode, and
storage-system state. A decoder MUST retain unrecognized or reserved bits as
raw status; it MUST NOT convert their absence into a healthy state.

For `0x312`, bytes 0-1 are protection flags and bytes 2-3 are warning flags.
Named conditions include over-current, short-circuit discharge, cell and module
over- and under-voltage, charge and discharge temperature limits, system error,
delta-voltage failure, pre-shutdown, and internal-communication failure. A set
bit is a reported condition. A clear bit is not an independent proof that the
condition is absent outside this frame's observation time.

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

The registry MAY classify evidence as
`growatt.bms.low_voltage.can.v1_04` only after it observes valid `0x311`,
`0x312`, and `0x313` frames with the required geometry among the most recent
16 accepted observations from one interface. A malformed listed frame resets
the admission window for that interface. The tuple is a positive
V1.04-compatible discriminator; `0x301`, a single listed ID, or a bitrate
setting is insufficient.

If two profiles admit the same evidence, the registry MUST return no profile
and no semantic projection. If the required tuple is incomplete, malformed, or
inconsistent, the evidence MUST remain raw and opaque.

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

`outbound_allowed` reflects the provider's available capability state. It does
not authorize a caller to transmit, acknowledge, probe, configure, or mutate a
CAN interface or attached equipment.

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
interoperability. A different protocol revision is a separate profile. Control
semantics, polling, and transmit behavior are outside this contract.
