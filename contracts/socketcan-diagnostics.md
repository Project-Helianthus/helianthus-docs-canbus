# Passive SocketCAN Diagnostic Model

## Scope

This contract defines the diagnostic outcome of a passive Linux SocketCAN
classic-CAN receiver. It applies to the generic transport boundary only. It
does not define a bus profile, frame meaning, device identity, controller
configuration, or physical-layer behavior.

The Linux SocketCAN ABI represents a classic CAN record as a 16-byte
`struct can_frame`. The `can_id` field contains identifier bits plus SocketCAN
flags, and the `len` field is a payload length rather than a wire DLC. The
Linux kernel documents this ABI and the `len8_dlc` extension at
https://docs.kernel.org/networking/can.html.

## Observation Record

An accepted observation MUST retain these immutable fields:

| Field | Requirement |
| --- | --- |
| Interface identity | Interface name and numeric index captured when the endpoint opens. |
| Sequence | Listener-local sequence beginning at one and increasing only for accepted observations. |
| Monotonic timestamp | Nondecreasing elapsed time since listener creation. |
| Identifier | Identifier kind plus identifier value, with SocketCAN flags removed from the value. |
| Payload | A copy limited to the accepted payload length. |
| Effective payload length | An integer in `0..8`. |
| Raw DLC | The native payload length, or a preserved `len8_dlc` value when applicable. |
| Raw record | An exact immutable copy of the accepted 16-byte SocketCAN record. |

The transport MUST distinguish identifier kinds. A standard identifier is an
11-bit value; an extended identifier is a 29-bit value with the SocketCAN
extended-frame flag present in the raw record. The distinction is transport
evidence, not a classification of the source.

## Record Classification and Outcome

Only an exactly 16-byte classic SocketCAN record can produce an observation.
The following outcomes are terminal for the current listener after the
appropriate diagnostic counter is updated:

| Input condition | Outcome |
| --- | --- |
| A read shorter or longer than 16 bytes, except a 72-byte record | Reject as malformed record; emit no observation. |
| A 72-byte SocketCAN record | Reject as unsupported CAN FD; emit no observation. |
| RTR or SocketCAN error-frame flag | Reject as unsupported; emit no observation. |
| An unflagged identifier above 11 bits | Reject as invalid standard identifier; emit no observation. |
| Payload length above eight | Reject as invalid classic payload length; emit no observation. |
| Invalid `len8_dlc` combination | Reject as malformed length encoding; emit no observation. |

For payload lengths below eight, `len8_dlc` MUST be zero and raw DLC equals
the payload length. For an eight-byte payload, a zero `len8_dlc` produces raw
DLC eight; values `9..15` are retained as raw DLC; every other value is
invalid. Raw DLC is diagnostic metadata and never extends the eight-byte
payload.

SocketCAN error frames are not normal observations in this contract. Linux
documents error-message frames as optional diagnostic input controlled by a raw
socket error filter; a receiver conforming to this contract does not turn one
into a transport or vendor health projection.

## Queue and Loss Reporting

The listener queue MUST have an explicit capacity in `1..65536` and one
explicit overflow policy:

| Policy | Queue outcome when full |
| --- | --- |
| `DropNewest` | Retain queued observations and discard the newly accepted observation. |
| `DropOldest` | Discard the oldest queued observation and retain the newly accepted observation. |

A diagnostic snapshot MUST expose these monotonic counters:

| Counter | Meaning |
| --- | --- |
| `Received` | Backend records read before structural classification. |
| `Enqueued` | Accepted observations admitted to the queue, including a retained newest observation under `DropOldest`. |
| `Delivered` | Observations returned to a caller. |
| `Dropped` | Accepted observations lost through the selected queue-overflow policy. |
| `Rejected` | Records rejected during structural classification. |

`Dropped` and sequence gaps are loss evidence. They do not identify a bus,
source, device state, or property value. Callers MUST retain the active queue
capacity and overflow policy alongside any diagnostic report.

## Receive Lifecycle

`Receive` accepts a non-nil context. Cancellation or deadline expiry returns
the context result, performs no retry, and preserves existing queued evidence.
A receiver MUST treat a nil context as an input error.

A backend read failure or structural rejection ends further acquisition. The
receiver can still deliver observations already queued before reporting the
terminal error. `Close` is idempotent; it ends acquisition, unblocks pending
receives with a closed result, and prevents subsequent delivery. Closing does
not convert queued or rejected input into a semantic event.

## Adapter Boundary

An adapter can expose an accepted observation as raw diagnostic material:
interface identity, sequence, monotonic timestamp, identifier kind and value,
payload, effective length, raw DLC, raw record, listener counters, and terminal
transport outcome.

An adapter MUST NOT infer a vendor, source direction, unit identity, property,
capability, value, unit, range, writability, or health state from this generic
material. Such a projection requires an independently defined profile and its
complete admission gate. Unsupported and malformed records remain diagnostic
outcomes, not semantic observations.

## Receive-Only Boundary

This contract provides no frame-submission surface. It does not configure,
verify, or alter controller listen-only mode, bit rate, interface state,
termination, or physical layer. The system owner MUST establish physical
listen-only mode before opening the endpoint; a receive-only API alone is not
proof of electrical silence.
