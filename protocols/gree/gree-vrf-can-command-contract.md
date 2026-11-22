# Gree VRF CAN Command Contract

## Commanded rows

Every documented setting row is a command Helianthus encodes and sends when
that command is called. Commissioning-type settings and outdoor and system
service settings are included. Every one of the 47 encodable rows of the
[command map](gree-vrf-command-map.md) is likewise a command Helianthus
encodes and sends when it is called.

The command map keeps its full 88-row table. Its 40 `reserved_sentinel` rows
and its 1 `unsupported_width` row (`0x57`) stay documented with those
classifications. They are not commands, and no encoder is defined for them.

A row the [parameter dictionary](gree-vrf-can-dictionary.md) marks `conflict`
or `label_only` carries that marker. A row the dictionary does not mark
carries none.

The register families feed every map row. The
[register model](gree-vrf-can-register-model.md#addressed-write-frames)
defines three addressed-write forms. A documented setting uses one of those
forms. Forms the register model does not define are not encoded.

## Frame forms

The destination unit comes from the register image key. `S` is the start
coordinate. The value mask is the mask of value bytes present.

| register kind | start coordinate | value mask | data bytes | DLC |
| --- | --- | --- | --- | ---: |
| bit | bit coordinate `S` | `01` | `S 01 b`, where `b` is `00` or `01` | 3 |
| byte | byte coordinate `S` | `01` | `S 01 v` | 3 |
| 16-bit | byte coordinate of the low byte | `03` | `S 03 lo hi` | 4 |

Setting the on/off bit `6f:00` bit 0 of unit `0x20` is identifier
`0x1cbfd06f` with data `00 01 01`. A one-byte write to `6f:00` may also change the functions of bits 1..7 of that byte, and the actual effect of the write on those bits is not established. A start command does not imply that
those bits are preserved.

## Outcome

A by-hand native setting method with synchronous readback receives its
deadline explicitly from the caller. Refuse a missing or elapsed deadline
before any send.

For a valid invocation, listen passively for that addressed setting
coordinate on the exact configured CAN interface and active lifecycle generation of the addressed instance. A matching value from another interface
or a retired generation cannot satisfy the call. Count an original receive
receipt only if it is ordered after this generation's local accepted
submission and at or before the deadline. A matching earlier report is not
confirmation. An eligible report buffered while the submit call returns still
counts. Report `reported` for an observed matching value, or `not reported`
at expiry. Local transport acceptance stays separate from both results.

Nothing in this contract sends a read request or claims that the setting was
applied. A report after a write is not a confirmation of the physical effect.
The register model's timing observations give no completion deadline and no
freshness policy. When several controllers share the bus, the last value
reported is reported as such, and no arbitration is assumed.

## Clock frame

Two fixed identifiers have clock payloads. An encoder for either identifier
is sent only when that encoder is called. There is no periodic emission.

| Identifier | Argument domain | Data | Unknowns |
| --- | --- | --- | --- |
| `0x04820000` | packed decimal, including weekday 7 as `0x07` | `year month day hour minute second weekday 02`, DLC 8 | the reply is not a delivery receipt |
| `0x04820084` | weekday 0–6; the last byte is `0x02` | `YY MM DD hh mm ss W 02`, DLC 8; `class8` `0x24`, `opaque7` `0x08`, unit `0x01`, type `0x04` | the low 14 identifier bits, the sender, and the receivers are not established |

`0x04820000` uses the existing packed-decimal encoding. `0x04820084` requires
its documented weekday domain of 0–6. Neither identifier establishes the
other.

## Tests

Encoders are tested on the simulated bus. Nothing is sent on a real bus by a
test.
