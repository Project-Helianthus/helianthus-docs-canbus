# Gree VRF Binary UART Protocol

This document defines the binary Gree VRF UART envelope and the Q, R, U, p, s,
and w payload families. Unknown bytes remain opaque.

## Serial And Segmentation

| Parameter | Value |
| --- | --- |
| Serial format | `57600 8N1` |
| Sync | `7e 7e` |
| Nominal inter-segment idle gap | `20 ms` |

The `20 ms` value is a nominal segmentation parameter. Stream-specific timing
and scheduling still require runtime validation. A collector accumulates bytes
until the idle gap closes the candidate segment, then passes the complete
segment to the envelope parser.

## Envelope

| Offset | Size | Field |
| ---: | ---: | --- |
| `0x00` | 2 | Sync `7e 7e` |
| `0x02` | 7 | Opaque header segment 0 |
| `0x09` | 7 | Opaque header segment 1 |
| `0x10` | 2 | Payload length `N`, unsigned big-endian |
| `0x12` | `N` | Payload |
| `0x12 + N` | 1 | Checksum |

Total frame length is `N + 19`. The maximum payload length is `0x05d1`.
Header segments are opaque seven-byte values and must not be assigned endpoint
names without runtime validation.

A reply swaps the two segments:

```text
reply.segment_0 = request.segment_1
reply.segment_1 = request.segment_0
```

## Checksum

The checksum is a table fold. Start with `c = 0`; for each byte from offset
`0x02` through the final payload byte, set:

```text
c = table[c XOR byte]
```

Sync and the checksum byte are excluded. The 256-byte lookup table is in
[gree-vrf-uart.json](gree-vrf-uart.json).

## Envelope Parser

A strict parser applies these gates in order:

1. require at least 19 bytes;
2. require sync `0x7e7e`;
3. decode `N` from offsets `0x10..0x11` as big-endian;
4. reject `N > 0x05d1`;
5. require exactly `N + 19` bytes for one collected segment;
6. verify the checksum;
7. select the payload contract by direction and type;
8. apply that contract's profile-independent structural gates;
9. apply unit-selection and profile gates;
10. apply profile-qualified typed-value gates, then decode typed fields while
    preserving raw bytes.

Malformed, unknown, or policy-rejected frames produce no reply and must not
mutate state. No reply is a protocol outcome distinct from a serial transport
failure.

## Builder

A builder writes sync, the two header segments, big-endian payload length,
payload, and checksum in that order. Reject payloads above `0x05d1`. Reply
builders swap the saved request segments before calculating the checksum.

## Unit Identity

Unit identity is an opaque seven-byte value. Identity matching is exact across
all seven bytes. The identity selects a unit record and its profile-qualified
property namespace; it does not establish a canonical product or endpoint
name.

## Q Vector Update (`0x51`)

```text
51 field0 base_id count values[count]
```

For peer-to-controller requests, the minimum payload length is 4 and
`payload_len >= 4 + count` is required. The numeric ID of item `i` is
`base_id + i`. Only after Profile-A selection, IDs `0x10`, `0x12`, `0x14`,
`0x16`, `0x18`, and `0x1a` consume the current byte and the following byte as
one big-endian value; the following position is not an independent scalar
item. For every such Profile-A item, `i + 1 < count` is required. A missing
following value is a structural error, receives no reply, and must not mutate
state.

Profile-B Q values have no established typed width. Each vector byte is kept
opaque, with no two-byte combination, byte consumption, or semantic
projection. A catalog storage marker is not a Q parser-width rule.

The controller-to-peer reply payload is exactly the single byte `51`. Reply
classification precedes the request minimum-length gate.

## R Entry Update (`0x52`)

```text
52 field0 count
repeat count times:
    id length data[length]
```

For peer-to-controller requests, the minimum payload length is 3. Every entry
header and declared data span must fit inside the payload. Numeric IDs and raw
entry bytes are authoritative. Unknown IDs remain opaque and are not dropped
solely because a label is absent.

Only after Profile-A selection, IDs `0x10`, `0x12`, `0x14`, `0x16`, `0x18`,
`0x1a`, `0x42`, and `0x4b` require at least two declared data bytes for a
typed big-endian value. Short data for one of these Profile-A IDs is a
structural error: produce no reply and do not mutate state. Profile-B R values
have no established typed width, so each declared entry payload remains opaque
with no semantic projection. Catalog storage markers do not establish R parser
width.

The controller-to-peer reply payload is exactly the single byte `52`. Reply
classification precedes the request minimum-length gate. A reply only
acknowledges local handling. It does not prove a downstream command was
transmitted or accepted.

## U State-Bank Request And Response (`0x55`)

Request:

```text
55 mode_status start count
```

Response:

```text
55 count field16_be data[count]
```

The peer-to-controller request payload is exactly four bytes. The
controller-to-peer response requires `payload_len >= 4 + count`;
`field16_be` is unsigned big-endian. The standard candidate Profile-A request
uses `55 00 00 57`; the candidate Profile-B request uses `55 00 00 5b`.
`0x57` and `0x5b` are byte counts, not property IDs.

A response carries opaque state-bank bytes. It does not promote them to named
properties.

## p State Delta (`0x70`)

```text
70 [00 state_cell_id value]N
```

The length rule is `payload_len == 1 + 3*N`. Each triplet prefix is zero.
There is no wire terminator; state-cell ID `0xff` is not valid in this payload.
The seven-byte unit identity occupies header segment 1 and header segment 0 is
seven `ff` bytes for this directional form.

This payload is Profile-A/M94 qualified, decoded only in its documented
controller-to-peer direction, and has no reply. M115 does not emit this delta
form.

## s Status Event (`0x73`)

```text
73 reserved[2] opaque_status[13]
```

Payload length is exactly `0x10`, making the full frame length `0x23`.
Deterministic senders set both reserved bytes to zero. The remaining 13 bytes
stay opaque. This directional event has no reply.

## w Packed-Decimal Status (`0x77`)

```text
77 bcd0 bcd1 bcd2 bcd3 bcd4 bcd5 bcd6
```

The peer-to-controller request has minimum payload length 8. Each value uses
packed decimal. The decoded numeric vector is:

```text
[decode(bcd0) + 100, decode(bcd1) - 1, decode(bcd2)..decode(bcd6)]
```

The controller-to-peer reply payload is exactly the single byte `77`. Reply
classification precedes the request minimum-length gate. Command transmission
for this payload remains disabled and unsafe.

## No-Reply Distinctions

No reply is required for:

- an empty segment;
- a short frame, bad sync, oversized payload, truncation, or checksum error;
- a structurally invalid Q, R, U, p, s, or w payload;
- an unknown payload type;
- failed unit-identity or profile gating;
- p or s in the wrong direction;
- accepted p and s directional events, which are intrinsically no-reply.

Implementations should expose the reason separately from serial I/O errors.

## Property And Write Boundary

See the [property catalog](gree-vrf-property-catalog.md) for noncanonical,
profile-qualified candidate labels. Preserve unknown fields as opaque data.

Writes are disabled and unsafe. Command encodings are documentation only.
