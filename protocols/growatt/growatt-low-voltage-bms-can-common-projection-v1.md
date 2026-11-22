# Growatt Low-Voltage BMS CAN Common Projection V1

## Scope and Safety

This contract defines a caller-selected projection for fields
that are shared by the documented Growatt low-voltage BMS CAN V1.04 and V1.08
layouts. It is an implementation-neutral projection boundary, not a revision
profile, decoder admission rule, equipment match, electrical claim, or control
contract.

The caller explicitly selects this common projection for one source interface.
That selection does not identify a connected BMS, select V1.04, V1.07, or
V1.08, or establish a firmware-to-protocol-revision relation. The documents
provide no published firmware-to-protocol-revision correlation; firmware MUST
NOT select a revision.

Support is declared from the protocol documents. Frames the specification
documents as commands have a transmit path. The transport offers the
publication API and canbusreg decides what is sent. This contract does not
establish a physical result, equipment health, or installed-product
compatibility.

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
| `0x311` | Charge-voltage, charge-current, and discharge-current limits, each as big-endian `u16` in the existing 0.1 V or 0.1 A units. | Status remains raw: V1.04 defines status bits 10--11, while V1.08 reserves those bits. | [V1.04 Rev_04 p. 4](https://www.amosplanet.org/wp-content/uploads/2022/04/Growatt-BMS-CAN-Bus-protocol-low-voltage-V1.04-1.pdf#page=4); [V1.08 p. 5](https://www.scribd.com/document/541900756/Growatt-BMS-CAN-Bus-protocol-low-voltage-V1-08#page=5) |
| `0x312` | Raw protection bytes 0--1, raw warning bytes 2--3, and pack count at byte 4. | Bytes 5--7: V1.04 defines manufacturer bytes and total-cell count; V1.08 defines a derating reason and reserved bytes. | [V1.04 Rev_04 p. 5](https://www.amosplanet.org/wp-content/uploads/2022/04/Growatt-BMS-CAN-Bus-protocol-low-voltage-V1.04-1.pdf#page=5); [V1.08 p. 8](https://www.scribd.com/document/541900756/Growatt-BMS-CAN-Bus-protocol-low-voltage-V1-08#page=8) |
| `0x313` | Pack voltage, pack current, SOC, and SOH. | Bytes 4--5: V1.04 defines maximum-cell temperature; V1.08 defines average temperature. | [V1.04 Rev_04 p. 6](https://www.amosplanet.org/wp-content/uploads/2022/04/Growatt-BMS-CAN-Bus-protocol-low-voltage-V1.04-1.pdf#page=6); [V1.08 p. 10](https://www.scribd.com/document/541900756/Growatt-BMS-CAN-Bus-protocol-low-voltage-V1-08#page=10) |

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

## Topology Context Values

The project-code [PCS protocol](growatt-low-voltage-bms-can-pcs-protocol-v1.md)
and [LINK protocol](growatt-low-voltage-bms-can-link-protocol-v1.md) bind each
decoded value to a caller-selected topology context. The following table lists
every allowed value of each context member and states whether the member is
asserted by configuration or observed on the wire. It does not change this
projection's admission, its shared fields, or any frame layout.

| Member | Allowed values | Asserted or observed | Rule |
| --- | --- | --- | --- |
| `bank` | `ordinary`, `parallel` | Asserted by configuration | `ordinary` is the documented standard bank; `parallel` is the documented parallel bank. The frame carries no bank selector, so traffic and decoded plausibility never select the bank. |
| `scope` | `local`, `aggregate` | Asserted by configuration | `local` is the reporting controller's own measurement scope. `aggregate` is a stack, gateway, or parallel-group summary. No frame carries a scope selector. |
| `endpoint` | PCS: `coordinator`, `participant`, `gateway`. LINK: the runtime source address `SS` as two uppercase hexadecimal digits, except `FF` | PCS: asserted by configuration. LINK: observed on the wire | Standard PCS identifiers carry no sender address. A LINK frame whose source address differs from the asserted endpoint does not bind to it. |
| `group` | `0` to `7`, or absent | Observed on the wire | Parallel addressed families carry the group address as the identifier low nibble `X`; `333` carries a group in B0. The member is absent when the selected frame family carries no group. |
| `slot` | `0` to `255`, or absent | Observed on the wire | The frame's own slot byte, such as `326.B0`, `327.B0`, `333.B1`, `51X.B0` or `52X.B0`. The member is absent when the selected frame family carries no slot. |

A value outside this table is not admitted: the frame remains raw evidence and
every context-dependent interpretation is withheld. An observed member confirms
or conflicts with the caller's selection; it never changes it, and a conflict
withholds the dependent interpretation.

The PCS flavor and the bank are asserted together. Standard PCS pairs with the
`ordinary` bank and parallel PCS pairs with the `parallel` bank; any other
pairing is a context conflict that withholds every bank-dependent field, such
as the `326` current offset. Release-11 slot reports `326`, `327` and `333`
exist for the standard PCS and for the selected parallel profile.

## Non-Claims

V1.07 has only revision-note evidence in the linked version record and does
not supply a complete field layout here. Sigineer material is a distinct family
and supplies neither Growatt fields nor revision selection. This contract does
not define a command, polling behavior, active balancing, or a capability to
control equipment.
