# Growatt Low-Voltage BMS CAN V1.04 Qualification Card V1

## Scope

This card defines a bounded, provider-local offline replay check for the
existing Growatt low-voltage BMS CAN V1.04 contract. It consumes already
accepted receive-only observations. It does not establish generic CAN
behavior, equipment identity, electrical compatibility, battery health,
control capability, gateway integration, or a physical result.

The selected source interface and the V1.04 profile are explicit inputs. A
rejected observation has no V1.04 provider result. The check has no transport
handle, controller configuration, or live-bus operation.

## Preconditions

The replay uses only synthetic structural input described by the V1.04
contract. A later physical trial requires an operator-selected interface backed
by a controller already in listen-only mode before its descriptor opens. The
V1.04 link metadata does not establish a controller setting, electrical layer,
or equipment compatibility.

Only the explicit V1.04 low-voltage profile is selected here. V1.05,
high-voltage, and all other Growatt families are unsupported at this provider
boundary until separate evidence and a separate contract qualify them.

## Sanitized Replay Input

The positive sequence uses one interface and three standard, eight-byte data
frames. The tuples below are synthetic structural values only.

| Sequence | Interface | ID | Payload |
| --- | --- | --- | --- |
| `1` | `can7`, index `7` | `0x311` | `02 38 00 fa 01 f4 00 43` |
| `2` | `can7`, index `7` | `0x312` | `00 80 00 00 02 aa bb 10` |
| `3` | `can7`, index `7` | `0x313` | `14 00 ff f6 01 2c 50 ff` |

Each observation retains its interface identity, listener sequence, monotonic
time, frame geometry, and raw record when the provider has them. The card does
not reinterpret raw-record byte order.

## Expected Native Result

After the complete tuple on the selected interface, the provider-local result
is `growatt.bms.low_voltage.can.v1_04` and retains all three source
observations. It contains only the native values defined by the V1.04 contract:

| Result | Expected value |
| --- | --- |
| Charge voltage limit | `568` decivolts |
| Charge-current limit | `250` deciamps |
| Discharge-current limit | `500` deciamps |
| Pack voltage | `5120` centivolts |
| Pack current | `-10` deciamps |
| Maximum cell temperature | `300` deci-degrees C |
| SOC | `80` percent |
| SOH value / validity | `127` / `true` |
| Protection bits | `00 80` retained raw |
| Warning bits | `00 00` retained raw |
| Pack / total-cell count | `2` / `16` |

A set protection or warning bit is a native observation. A clear bit, an
absent tuple, or an unavailable observation is not a health conclusion. The
result provides no command, control, or equipment-health semantic.

## Required Negative Controls

Each control produces no V1.04 provider result for the attempted sequence. It
does not identify an alternative interface, version, profile, or device.

| Control | Sanitized input change |
| --- | --- |
| Incomplete tuple | Omit any of `0x311`, `0x312`, or `0x313` |
| Malformed listed frame | Give a listed frame a payload shorter than eight bytes |
| Invalid declared range | Use `0x312` with pack count or total-cell count `0` |
| Wrong interface | Put one required frame on `can8`, index `8` |
| Wrong revision / extended ID | Use extended `0x311`; the listed malformed frame resets the selected interface window |
| Window expiry | Separate required frames by more than the most recent 16 accepted observations |
| Window rollover | Confirm that a later valid `0x311` is the retained limits source inside the window |

## Qualification Status and Handoff

The outcome is contract-evidenced candidate readiness for this offline provider
check. Physical qualification is `false`; live trials are `false`. A successful
replay shows only that the selected V1.04 provider path preserves the defined
native evidence and values.

Raw diagnostic expectations belong to their separately scoped integration
work. This card does not define an MCP or gateway surface, runtime admission,
or semantic promotion. It introduces no path for frame submission,
acknowledgement, probing, controller change, or state-changing operation.
