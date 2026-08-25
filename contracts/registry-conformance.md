# Fail-Closed CAN Registry Conformance

## Scope

This contract defines generic public behavior for a multi-profile CAN registry.
It applies after a transport has produced an accepted raw observation. It does
not define a profile, frame meaning, device identity, or physical-layer
behavior.

The contract is aligned with `helianthus-canbusreg` revision
`429d322e676f47c4e1c950c38a2f2341951e718b`. It describes the registry result
boundary and MUST NOT replace a profile's own complete admission gate.

## Evidence Admission

The canonical transport-derived evidence constructor receives one accepted
observation and copies its frame, interface identity, listener-local sequence,
monotonic timestamp, and fixed-size raw SocketCAN record into `Evidence`.
Profiles receive that evidence by value and MUST treat it as immutable input.

The registry does not repair, normalize, or independently validate an
`Evidence` value. A conforming caller MUST construct evidence from an accepted
transport observation. A conforming profile MUST return no match whenever its
own required evidence is absent, malformed for that profile, or outside its
supported revision.

## Profile Result

A profile returns one `Classification` for each `Evidence` input. A result is
eligible only when both conditions hold:

1. `Profile` is not the empty string.
2. `Projection` is not nil.

A result missing either condition is a non-match. A nil profile is skipped and
is also a non-match. The registry does not interpret a profile name or a
projection value; those values remain owned by the matching profile.

## Conflict Resolution

The registry evaluates every configured non-nil profile. Exactly one eligible
result is returned unchanged. Zero eligible results return the zero
`Classification` value. A second eligible result is a conflict: the registry
MUST return the zero `Classification` value and MUST NOT select a winner by
profile order, name, score, or projection value.

The zero `Classification` value has an empty `Profile` and nil `Projection`.
It is the required opaque result for unknown, incomplete, unsupported, and
ambiguous input.

## Conformance Outcomes

An implementation conforming to this contract MUST verify these generic cases:

| Configured profiles and results | Required registry result |
| --- | --- |
| No profiles or only nil profiles | Zero `Classification`. |
| One profile with empty `Profile` | Zero `Classification`. |
| One profile with nil `Projection` | Zero `Classification`. |
| One profile with both required result fields | That exact `Classification`. |
| Two or more eligible profiles | Zero `Classification`; no winner. |

The executable baseline for these outcomes is
https://github.com/Project-Helianthus/helianthus-canbusreg/blob/429d322e676f47c4e1c950c38a2f2341951e718b/registry_test.go.

## Projection Boundary

The registry can carry raw evidence and an opaque profile-owned projection. It
MUST NOT manufacture a property, capability, value, unit, range, writability,
source direction, or health state. A profile can expose a projection only after
its independently defined complete gate succeeds. Every other result remains
opaque.
