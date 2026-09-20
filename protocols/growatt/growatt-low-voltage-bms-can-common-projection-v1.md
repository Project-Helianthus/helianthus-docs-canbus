# Growatt Low-Voltage BMS CAN Common Projection V1

## Scope and Safety

This contract defines a caller-selected, receive-only projection for fields
that are shared by the documented Growatt low-voltage BMS CAN V1.04 and V1.08
layouts. It is an implementation-neutral projection boundary, not a revision
profile, decoder admission rule, equipment match, electrical claim, or control
contract.

The caller explicitly selects this common projection for one source interface.
That selection does not identify a connected BMS, select V1.04, V1.07, or
V1.08, or establish a firmware-to-protocol-revision relation. The documents
provide no published firmware-to-protocol-revision correlation; firmware MUST
NOT select a revision.

A conforming implementation MUST remain receive-only. It MUST NOT transmit,
acknowledge, probe, configure, or change a CAN interface or attached equipment.
This contract does not establish a physical result, equipment health, or
installed-product compatibility.

## Input Boundary

An eligible observation is a standard 11-bit, non-RTR data frame with DLC 8.
The caller keeps each interface and source isolated: no raw frame, field, or
state from one interface or source can complete, replace, or conflict-resolve
data for another. A frame with another identifier form, RTR state, or DLC is
raw evidence only.

The projection retains every eligible and ineligible input as available raw
evidence with interface identity, source identity when available, listener
sequence, monotonic observation time, identifier, extended-identifier state,
RTR state, effective payload length, raw DLC, and all data bytes. A provider
that lacks an item leaves it unavailable and MUST NOT fabricate it. Unknown
identifiers, malformed frames, and fields not listed below remain raw.

## Common Field Projection

The following common fields are available when their individual frame geometry
is valid. Unknown revision and revision conflict do not suppress these shared
fields. They suppress only fields whose documented layouts diverge.

| ID | Shared projection | Withheld divergent content | Evidence |
| --- | --- | --- | --- |
| `0x311` | Charge-voltage, charge-current, and discharge-current limits, each as big-endian `u16` in the existing 0.1 V or 0.1 A units. | Status remains raw: V1.04 defines status bits 10--11, while V1.08 reserves those bits. | [V1.04 contract](low-voltage-bms-can-v104.md); [V1.08 p. 5](https://www.scribd.com/document/541900756/Growatt-BMS-CAN-Bus-protocol-low-voltage-V1-08#page=5) |
| `0x312` | Raw protection bytes 0--1, raw warning bytes 2--3, and pack count at byte 4. | Bytes 5--7: V1.04 defines manufacturer bytes and total-cell count; V1.08 defines a derating reason and reserved bytes. | [V1.04 contract](low-voltage-bms-can-v104.md); [V1.08 p. 8](https://www.scribd.com/document/541900756/Growatt-BMS-CAN-Bus-protocol-low-voltage-V1-08#page=8) |
| `0x313` | Pack voltage, pack current, SOC, and SOH. | Bytes 4--5: V1.04 defines maximum-cell temperature; V1.08 defines average temperature. | [V1.04 contract](low-voltage-bms-can-v104.md); [V1.08 p. 10](https://www.scribd.com/document/541900756/Growatt-BMS-CAN-Bus-protocol-low-voltage-V1-08#page=10) |

Multi-byte shared values are big-endian. A named status, protection, warning,
or reserved bit is not inferred from the raw bytes unless a separately selected
revision contract defines it. A set raw protection or warning bit is an
observation, not a health conclusion.

## Revision and Conflict Handling

The projection does not inspect firmware or construct a revision from frames.
When an external caller supplies an unknown, absent, or conflicting revision
label, valid shared fields remain available and every divergent field is
withheld. The same rule applies when later revision-specific evidence conflicts
with the layouts listed here. No fallback selects V1.04, V1.07, or V1.08.

Selecting `growatt.bms.low_voltage.can.v1_04` remains a separate operation
under the [V1.04 contract](low-voltage-bms-can-v104.md). This common projection
does not alter that contract's admission, decoded fields, raw evidence, or
`RawStatus` behavior.

## Non-Claims

V1.07 has only revision-note evidence in the linked version record and does
not supply a complete field layout here. Sigineer material is a distinct family
and supplies neither Growatt fields nor revision selection. This contract does
not define a command, polling behavior, active balancing, or a capability to
control equipment.
