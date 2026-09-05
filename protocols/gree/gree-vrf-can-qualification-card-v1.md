# Gree VRF CAN Candidate Qualification Card V1

## Scope

This card defines a bounded, offline readiness check for the Gree-specific CAN
candidate profile. It is a provider-local check: it does not establish generic
CAN behavior, equipment identity, electrical compatibility, HVAC meaning,
gateway integration, or a physical result.

The check consumes an already accepted SocketCAN observation. The selected
interface, candidate profile, and map are all explicit inputs. An observation
that fails any gate has no Gree result and leaves previously retained state
unchanged.

## Preconditions

The offline check uses only sanitized structural input. A later physical trial
requires an operator-selected interface backed by a controller already in
listen-only mode before its descriptor opens. The candidate 20 kbit/s and CAN
2.0B metadata does not establish a controller setting, electrical layer, or
equipment compatibility.

`M94` and `M115` are explicit map choices. Selecting either map does not
identify a product or make a cell semantic. `M152` is not an active map and
must be rejected.

## Sanitized Replay Input

The following synthetic observation exercises the candidate gate and each map
without naming an installation or equipment:

| Field | Value |
| --- | --- |
| Interface identity | `can7`, index `7` |
| Sequence | `42` |
| Extended identifier | `0x1ee00410` |
| Effective payload length / raw DLC | `6` / `6` |
| Payload | `02 31 32 33 a1 a2` |
| Raw record | Exact fixed 16-byte record supplied with this fixture |
| Selected map | `M94`, then `M115` with selector `0x6098` |

The raw record stays exact. Its byte order is evaluated by the SocketCAN
contract of the executing platform; the fixture does not reinterpret raw bytes
as a portable identifier encoding.

## Expected Native Result

For either selected map, the accepted result contains only native candidate
material:

| Result | Expected value |
| --- | --- |
| Candidate profile | `gree.vrf.canbus.candidate.v1` |
| Identifier fields | `class8=0xf7`, `unit7=8`, `opcode7=0x10`, `opaque7=0` |
| Candidate cells | `(0x0f, 0xa1)`, `(0x10, 0xa2)` |
| Map state | Cell `0x03` is `0x31` |
| Retained state | An existing unrelated cell remains unchanged |
| Unknown cell | Absent; no value is added for it |
| Raw context | Interface, sequence, monotonic time, frame, and exact raw record remain attached to the candidate result |

The cells are opaque native state. The card assigns no engineering unit,
property name, equipment identity, capability, health state, or control effect.
Only separately qualified facts can be promoted by a later owner.

## Required Negative Controls

Each control must produce no Gree candidate result and preserve the supplied
state exactly:

| Control | Sanitized input change |
| --- | --- |
| Wrong identifier | `0x1ec00410` |
| Wrong unit | `0x1ee00010` |
| Wrong interface | `can8`, index `8` |
| Wrong DLC | Empty payload |
| Partial candidate span | Payload `05 a1` |
| Wrong map | `M152` |

These controls do not identify an alternative device, interface, profile, or
state. They remain unavailable at this provider boundary.

## Qualification Status and Handoff

The outcome is `QUALIFICATION_TEST_READY` for this offline provider check.
Physical qualification is `false`. A successful replay only shows that the
explicitly selected candidate/map path preserves bounded native evidence.

The gateway owner may consume the accepted or rejected outcome and the retained
raw diagnostic context in its separately scoped work. This card does not define
an MCP surface or a semantic projection. It introduces no transport handle and
no path for frame submission, acknowledgement, probing, controller change, or
state-changing operation.
