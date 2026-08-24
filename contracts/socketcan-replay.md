# Passive SocketCAN Conformance Replay Guide

## Scope

This guide defines a deterministic, offline replay procedure for a passive
classic-CAN observation adapter. It covers raw observation behavior only. It
does not define frame meaning, device identity, profile selection, controller
configuration, or physical-layer behavior.

The complete executable conformance matrix is maintained by
`helianthus-canbus` as T01 through T88. This guide is a human-readable
crosswalk and MUST NOT replace that matrix or duplicate its fixtures.

## Replay Input

A replay run MUST declare all of the following before processing an event:

| Input | Requirement |
| --- | --- |
| Interface identity | Stable interface name and numeric index. |
| Queue configuration | Capacity in `1..65536` and exactly one overflow policy. |
| Clock | A deterministic listener start time and ordered elapsed-time values. |
| Event sequence | Ordered raw-record, backend-failure, receive, cancellation, deadline, or close events. |

A raw-record event is either a structured classic CAN record or an explicit
byte record. A structured record MUST declare its logical `can_id`, payload
length, `len8_dlc`, and up to eight payload bytes. It MUST be encoded using
the native byte order of the executing Linux SocketCAN ABI before comparison
with a retained raw record. A portable fixture MUST NOT treat a host-specific
raw-record byte order as an identifier value.

## Replay Rules

Process events in declaration order. A structurally valid classic record is
assigned the next listener-local sequence before the queue policy is applied.
Therefore a queue loss consumes a sequence even when no caller receives that
observation.

`DropNewest` retains older queued observations and discards the new one.
`DropOldest` removes the oldest queued observation and retains the new one.
Both outcomes increase `Dropped`; only the latter increases `Enqueued` for the
replacement observation. A delivered sequence gap is evidence of queue loss,
not evidence about frame content.

An invalid record, unsupported CAN FD record, RTR record, error-frame record,
invalid identifier, invalid length, or invalid `len8_dlc` ends acquisition
after increasing `Rejected`. No later backend record is acquired. A backend
failure also ends acquisition but is not a structural rejection.

Cancellation and deadline expiry apply only to the affected `Receive` call;
they perform no retry and do not change queued evidence. `Close` is idempotent,
ends acquisition, and makes pending and later receive calls return the closed
outcome.

## Outcome Assertions

For every delivered observation, a replay MUST compare:

- interface name and index;
- sequence and nondecreasing monotonic timestamp;
- standard or extended identifier kind and identifier value;
- payload limited to the effective length;
- effective payload length and raw DLC; and
- the exact retained 16-byte raw record.

For every terminal path, a replay MUST compare the outcome class: invalid
record length, unsupported CAN FD, unsupported RTR, unsupported error frame,
invalid identifier, invalid length encoding, context cancellation, deadline,
backend failure, or closed listener. It MUST also compare the final
`Received`, `Enqueued`, `Delivered`, `Dropped`, and `Rejected` counters.

Bytes beyond the effective payload length are not frame payload. A replay can
compare them only through the raw-record field, never as decoded payload.

## Matrix Crosswalk

The replay suite MUST cover these categories in the executable T01..T88
matrix:

| Cases | Required category |
| --- | --- |
| T01..T16 | Standard and extended identifier bounds. |
| T17..T42 | Classic payload lengths, raw DLC retention, malformed records, CAN FD, RTR, and error frames. |
| T43..T50 | Bounded queue behavior, ordering, and both overflow policies. |
| T51..T54 | Invalid queue configuration before endpoint opening. |
| T55..T66 | Immutable provenance, sequence, timestamp, raw record, and identifier-kind evidence. |
| T67..T78 | Cancellation, deadline, terminal error, close, and opener behavior. |
| T79..T88 | Receive-only public surface, no live endpoint in tests, portability, and bounded resources. |

The current matrix is available at
https://github.com/Project-Helianthus/helianthus-canbus/blob/main/testdata/transport_matrix.json.

## Safety Boundary

Replay input MUST be delivered through an injected backend or an equivalent
offline source. It MUST NOT open a platform endpoint, change an interface,
configure a controller, or submit a frame. The replay result is raw transport
evidence only and MUST NOT create a semantic projection.
