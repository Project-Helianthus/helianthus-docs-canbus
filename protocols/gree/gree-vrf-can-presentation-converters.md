# Gree VRF CAN Presentation Converters

## Status and Relationship

Declared from the vendor documentation. `gree-vrf-can` is qualified with
these pages as its specification evidence. The hardware test level is recorded
per class. The publication basis is stated in the
[protocol index](README.md#publication-basis).

Dictionary entries can name a presentation converter. A converter is a
display layer: it does not change the native value, its unit or its identity.
A decoder never applies a converter. A consumer that applies one for display
says so and keeps the native value. The machine-readable form, with vectors
and both tables, is
[gree-vrf-can-presentation-converters.json](gree-vrf-can-presentation-converters.json).

## Rounding

| Name | Rule |
| --- | --- |
| `trunc` | truncate toward zero |
| `round_half_away` | round to the nearest integer; a half rounds away from zero |
| `round2_half_even` | round to two decimals; a half rounds to the even digit |

Each converter has a display state, active or inactive. The state is a
display selector and does not depend on the native value.

## Converters

| Converter | Active forward | Active inverse | Inactive forward | Inactive inverse | Active unit |
| --- | --- | --- | --- | --- | --- |
| `CeVsFa` | `round_half_away(x*9/5+32)` | `trunc((y-32)*5/9)` | `round_half_away(x)` | `trunc(y)` | °F |
| `kWVskBtuh` | `round2_half_even(x*3.412)` | `trunc(y*0.2931)` | `x` | `trunc(y)` | kBtu/h |
| `kPaVsinWG` | `4*x` | `y/4` | `x` | `trunc(y)` | inWG |

In the inactive state the converter adds no unit. `kPaVsinWG` also has an
integer inverse, `trunc(y)`, in both states.

`Blur` has two forms that do not depend on the display state. The masked form
is `trunc(x) - rem(trunc(x), 10)`, where the sign of `rem` follows the left
operand; the unmasked form is `x`. Its inverse is `trunc(y)` and it adds no
unit. Which form applies is a property of the displaying application, not of
the bus value.

## Saturation Tables

`CeVskPa` starts from `x = trunc(t)`, with `t` a temperature in °C.

- Temperature mode: `x` in °C, or `x*9/5+32` in °F when active, without
  rounding.
- Pressure mode: the pressure is `R410A[x+70]` or `R22[x+56]`, in kPa; in the
  active state it is multiplied by 4 and shown in inWG.

| Table | Entries | Indexes | Temperature span |
| --- | ---: | --- | --- |
| R410A | 142 | 0..141 | -70 °C to 71 °C |
| R22 | 127 | 0..126 | -56 °C to 70 °C |

Rules:

- Values between entries are not interpolated.
- An index outside the table, or an unknown refrigerant, gives no pressure.
- The inverse is `trunc(y)`; the table is not inverted.
- Whether a table pressure is absolute or relative is not established.
  `31:91` and `31:93` are defined separately as absolute pressures.
- The register that selects the refrigerant for a converted value is not
  established.

Five R410A entries break the monotonic sequence or its step: index 60
(`557`), 69 (`799`), 80 (`1096`), 110 (`2439`) and 141 (`4893`). They are
kept as defined and are not corrected.

## Not Established

- Absolute or relative reference of the table pressures.
- The register that selects the refrigerant.
- Whether the flagged R410A entries are intended values.
