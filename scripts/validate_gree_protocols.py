#!/usr/bin/env python3
"""Deterministic consistency checks for the published protocol documents."""

from __future__ import annotations

import argparse
import copy
import json
import os
import re
import sys
from pathlib import Path


DEFAULT_ROOT = Path(__file__).resolve().parents[1]
EXPECTED_FILES = (
    ".github/workflows/ci.yml",
    "AGENTS.md",
    "LICENSE",
    "README.md",
    "docs/can/README.md",
    "docs/can/gree-vrf-can-candidate-v1.md",
    "docs/can/gree-vrf-can-bridge-record-v1.md",
    "docs/can/gree-vrf-can-profile.md",
    "docs/can/gree-vrf-can-profile.json",
    "docs/can/gree-vrf-command-map.md",
    "docs/can/gree-vrf-command-map.json",
    "docs/uart/README.md",
    "docs/uart/gree-vrf-uart.md",
    "docs/uart/gree-vrf-uart.json",
    "docs/uart/gree-vrf-property-catalog.md",
    "docs/uart/normative-vectors.json",
    "scripts/validate.py",
    "scripts/test_mutations.py",
)

CC0_TEXT = """Creative Commons Legal Code

CC0 1.0 Universal

    CREATIVE COMMONS CORPORATION IS NOT A LAW FIRM AND DOES NOT PROVIDE
    LEGAL SERVICES. DISTRIBUTION OF THIS DOCUMENT DOES NOT CREATE AN
    ATTORNEY-CLIENT RELATIONSHIP. CREATIVE COMMONS PROVIDES THIS
    INFORMATION ON AN "AS-IS" BASIS. CREATIVE COMMONS MAKES NO WARRANTIES
    REGARDING THE USE OF THIS DOCUMENT OR THE INFORMATION OR WORKS
    PROVIDED HEREUNDER, AND DISCLAIMS LIABILITY FOR DAMAGES RESULTING FROM
    THE USE OF THIS DOCUMENT OR THE INFORMATION OR WORKS PROVIDED
    HEREUNDER.

Statement of Purpose

The laws of most jurisdictions throughout the world automatically confer
exclusive Copyright and Related Rights (defined below) upon the creator
and subsequent owner(s) (each and all, an "owner") of an original work of
authorship and/or a database (each, a "Work").

Certain owners wish to permanently relinquish those rights to a Work for
the purpose of contributing to a commons of creative, cultural and
scientific works ("Commons") that the public can reliably and without fear
of later claims of infringement build upon, modify, incorporate in other
works, reuse and redistribute as freely as possible in any form whatsoever
and for any purposes, including without limitation commercial purposes.
These owners may contribute to the Commons to promote the ideal of a free
culture and the further production of creative, cultural and scientific
works, or to gain reputation or greater distribution for their Work in
part through the use and efforts of others.

For these and/or other purposes and motivations, and without any
expectation of additional consideration or compensation, the person
associating CC0 with a Work (the "Affirmer"), to the extent that he or she
is an owner of Copyright and Related Rights in the Work, voluntarily
elects to apply CC0 to the Work and publicly distribute the Work under its
terms, with knowledge of his or her Copyright and Related Rights in the
Work and the meaning and intended legal effect of CC0 on those rights.

1. Copyright and Related Rights. A Work made available under CC0 may be
protected by copyright and related or neighboring rights ("Copyright and
Related Rights"). Copyright and Related Rights include, but are not
limited to, the following:

  i. the right to reproduce, adapt, distribute, perform, display,
     communicate, and translate a Work;
 ii. moral rights retained by the original author(s) and/or performer(s);
iii. publicity and privacy rights pertaining to a person's image or
     likeness depicted in a Work;
 iv. rights protecting against unfair competition in regards to a Work,
     subject to the limitations in paragraph 4(a), below;
  v. rights protecting the extraction, dissemination, use and reuse of data
     in a Work;
 vi. database rights (such as those arising under Directive 96/9/EC of the
     European Parliament and of the Council of 11 March 1996 on the legal
     protection of databases, and under any national implementation
     thereof, including any amended or successor version of such
     directive); and
vii. other similar, equivalent or corresponding rights throughout the
     world based on applicable law or treaty, and any national
     implementations thereof.

2. Waiver. To the greatest extent permitted by, but not in contravention
of, applicable law, Affirmer hereby overtly, fully, permanently,
irrevocably and unconditionally waives, abandons, and surrenders all of
Affirmer's Copyright and Related Rights and associated claims and causes
of action, whether now known or unknown (including existing as well as
future claims and causes of action), in the Work (i) in all territories
worldwide, (ii) for the maximum duration provided by applicable law or
treaty (including future time extensions), (iii) in any current or future
medium and for any number of copies, and (iv) for any purpose whatsoever,
including without limitation commercial, advertising or promotional
purposes (the "Waiver"). Affirmer makes the Waiver for the benefit of each
member of the public at large and to the detriment of Affirmer's heirs and
successors, fully intending that such Waiver shall not be subject to
revocation, rescission, cancellation, termination, or any other legal or
equitable action to disrupt the quiet enjoyment of the Work by the public
as contemplated by Affirmer's express Statement of Purpose.

3. Public License Fallback. Should any part of the Waiver for any reason
be judged legally invalid or ineffective under applicable law, then the
Waiver shall be preserved to the maximum extent permitted taking into
account Affirmer's express Statement of Purpose. In addition, to the
extent the Waiver is so judged Affirmer hereby grants to each affected
person a royalty-free, non transferable, non sublicensable, non exclusive,
irrevocable and unconditional license to exercise Affirmer's Copyright and
Related Rights in the Work (i) in all territories worldwide, (ii) for the
maximum duration provided by applicable law or treaty (including future
time extensions), (iii) in any current or future medium and for any number
of copies, and (iv) for any purpose whatsoever, including without
limitation commercial, advertising or promotional purposes (the
"License"). The License shall be deemed effective as of the date CC0 was
applied by Affirmer to the Work. Should any part of the License for any
reason be judged legally invalid or ineffective under applicable law, such
partial invalidity or ineffectiveness shall not invalidate the remainder
of the License, and in such case Affirmer hereby affirms that he or she
will not (i) exercise any of his or her remaining Copyright and Related
Rights in the Work or (ii) assert any associated claims and causes of
action with respect to the Work, in either case contrary to Affirmer's
express Statement of Purpose.

4. Limitations and Disclaimers.

 a. No trademark or patent rights held by Affirmer are waived, abandoned,
    surrendered, licensed or otherwise affected by this document.
 b. Affirmer offers the Work as-is and makes no representations or
    warranties of any kind concerning the Work, express, implied,
    statutory or otherwise, including without limitation warranties of
    title, merchantability, fitness for a particular purpose, non
    infringement, or the absence of latent or other defects, accuracy, or
    the present or absence of errors, whether or not discoverable, all to
    the greatest extent permissible under applicable law.
 c. Affirmer disclaims responsibility for clearing rights of other persons
    that may apply to the Work or any use thereof, including without
    limitation any person's Copyright and Related Rights in the Work.
    Further, Affirmer disclaims responsibility for obtaining any necessary
    consents, permissions or other rights required for any use of the
    Work.
 d. Affirmer understands and acknowledges that Creative Commons is not a
    party to this document and has no duty or obligation with respect to
    this CC0 or use of the Work.\n"""

# Keep these fragments separate: this source is part of the scanned public tree.
FORBIDDEN_TERMS = tuple(
    "".join(parts)
    for parts in (
        ("ob", "served"),
        ("ob", "servation"),
        ("ob", "serve"),
        ("der", "ived"),
        ("der", "ivation"),
        ("der", "ive"),
        ("rec", "overed"),
        ("ext", "racted"),
        ("rev", "erse"),
        ("ana", "lysis"),
        ("prov", "enance"),
        ("decomp", "ilation"),
        ("decomp", "iler"),
        ("dis", "assembl"),
        ("firm", "ware"),
        ("corp", "us"),
        ("gh", "idra"),
        ("rad", "are2"),
        ("obj", "du" + "mp"),
        ("bin", "walk"),
        ("to", "ol"),
        ("int", "ernal"),
        ("evi", "dence"),
        ("work", "bench"),
        ("aud", "it"),
        ("pre", "-edit"),
        ("back", "up"),
        ("acqui", "sition"),
        ("acqui", "red"),
        ("acqui", "re"),
        ("down", "load"),
        ("cap", "ture"),
        ("du", "mp"),
        ("scr", "ape"),
        ("har", "vest"),
        ("helian", "thus"),
        ("gate", "way"),
        ("adap", "ter"),
        ("reg", "istry"),
        ("graph", "ql"),
        ("home ", "assistant"),
        ("e", "bus"),
    )
)

AGENT_FORBIDDEN_REFERENCES = (
    "../agents.md",
    "../helian" + "thus-",
    ".codex/skills",
    "agents-local.md",
    "workspace-root",
    "private lab",
    "private " + "home " + "assistant/" + "e" + "bus lab",
)

MARKDOWN_REQUIRED_CLAIMS = {
    "README.md": (
        (
            "CAN candidate bitrate and identifier boundary",
            ("can 2.0b extended identifiers", "`20 kbit/s`", "not universal socketcan defaults"),
        ),
        (
            "CAN+ and electrical boundary",
            ("not electrically confirmed", "unconfirmed electrical hypothesis", "not electrically equivalent to can"),
        ),
        (
            "opaque meaning boundary",
            (
                "**opaque**: byte or bit structure is retained without assigning a meaning",
                "unknown fields remain opaque",
                "malformed or policy-rejected frames fail closed: no reply and no state mutation",
            ),
        ),
        (
            "write and delivery boundary",
            (
                "writes are disabled and unsafe",
                "must not be transmitted to equipment",
                "does not establish electrical compatibility, delivery, acceptance, or a safe operating effect",
            ),
        ),
    ),
    "docs/can/README.md": (
        (
            "CAN candidate bitrate and identifier boundary",
            ("can 2.0b extended identifiers", "`20 kbit/s`", "not universal socketcan defaults"),
        ),
        (
            "CAN+ and electrical boundary",
            ("can+ is retained only as an unconfirmed electrical hypothesis", "not be treated as electrically equivalent to can"),
        ),
        (
            "write and transmission boundary",
            (
                "writes are disabled and unsafe",
                "not permission to transmit them",
                "establishes delivery or acceptance",
                "external reachability",
            ),
        ),
    ),
    "docs/can/gree-vrf-can-candidate-v1.md": (
        (
            "candidate and opaque boundary",
            ("candidate", "opaque", "must remain separate from uart"),
        ),
        (
            "write boundary",
            ("writes are disabled and unsafe", "must not be transmitted to equipment"),
        ),
    ),
    "docs/can/gree-vrf-can-bridge-record-v1.md": (
        (
            "bounded bridge-record boundary",
            ("0x23 bytes", "0x7e 0x7e", "0x73", "must remain separate from uart"),
        ),
        (
            "write boundary",
            ("writes are disabled and unsafe", "must not be transmitted to equipment"),
        ),
    ),
    "docs/can/gree-vrf-can-profile.md": (
        (
            "CAN candidate bitrate and identifier boundary",
            ("can 2.0b", "29-bit extended", "`20 kbit/s`", "not a universal default"),
        ),
        (
            "CAN+ and electrical boundary",
            ("electrical layer", "unconfirmed", "can+ is only a hypothesis", "can+ equivalence"),
        ),
        (
            "write and delivery boundary",
            ("no live, electrical, delivery, acceptance, or safe-write claim", "writes remain disabled and unsafe"),
        ),
    ),
    "docs/can/gree-vrf-command-map.md": (
        (
            "write and delivery boundary",
            ("writes are disabled and unsafe", "does not prove can delivery", "must never enable a write"),
        ),
    ),
    "docs/uart/README.md": (
        (
            "opaque and fail-closed boundary",
            (
                "unknown fields",
                "remain opaque",
                "runtime validation is required before assigning final semantics",
                "fail closed with no reply and no state mutation",
            ),
        ),
        (
            "write and delivery boundary",
            ("writes are disabled and unsafe", "not proof of downstream delivery or acceptance"),
        ),
    ),
    "docs/uart/gree-vrf-uart.md": (
        (
            "opaque and fail-closed boundary",
            (
                "unknown bytes remain opaque",
                "malformed, unknown, or policy-rejected frames produce no reply and must not mutate state",
                "profile-b r values have no established typed width",
                "with no semantic projection",
            ),
        ),
        (
            "write and delivery boundary",
            ("does not prove a downstream command was transmitted or accepted", "writes are disabled and unsafe"),
        ),
    ),
    "docs/uart/gree-vrf-property-catalog.md": (
        (
            "opaque and fail-closed boundary",
            (
                "unknown q/r ids must be preserved as raw numeric items",
                "profile-b q bytes and r entry data remain opaque",
                "no semantic projection",
            ),
        ),
    ),
}

BITRATE_ASSERTION = re.compile(
    r"\b(?P<value>\d+)\s*(?P<unit>(?P<kilo>k)\s*(?:(?:bit|b)\s*/\s*s|bps)|(?:(?:bit|b)\s*/\s*s|bps))\b",
    re.IGNORECASE,
)

MARKDOWN_FORBIDDEN_CLAIMS = (
    (
        "11-bit-only claim",
        re.compile(r"\b(?:11-bit(?:-only| only)|standard 11-bit identifiers? only)\b", re.IGNORECASE),
    ),
    (
        "confirmed CAN+ equivalence claim",
        re.compile(
            r"\b(?:can\+\s+(?:is|remains)\s+(?:electrically\s+)?equivalent|can\+\s+equivalence\s+(?:is\s+)?confirmed)\b",
            re.IGNORECASE,
        ),
    ),
    (
        "typed unknown claim",
        re.compile(r"\bunknown (?:fields?|ids?|values?) (?:are|remain|become) typed\b", re.IGNORECASE),
    ),
)

POSITIVE_WRITE_CLAIMS = (
    ("permitted", r"permit"),
    ("authorized", r"authoriz"),
    ("allowed", r"allow"),
    ("enabled", r"enabl"),
    ("safe", r"safe"),
    ("supported", r"support"),
    ("valid", r"valid"),
)


def has_positive_write_claim(text: str, stem: str) -> bool:
    target = r"(?:an?\s+)?(?:(?:installed|device|live)\s+)?(?:writes?|transmissions?)"
    positive = r"safe" if stem == "safe" else rf"{stem}\w*"
    patterns = (
        re.compile(rf"\b{positive}\b(?:\s+\w+){{0,4}}\s+\b{target}\b", re.IGNORECASE),
        re.compile(rf"\b{target}\b(?:\s+\w+){{0,4}}\s+\b{positive}\b", re.IGNORECASE),
    )
    for pattern in patterns:
        for match in pattern.finditer(text):
            clause = match.group().lower()
            prefix = text[max(0, match.start() - 24) : match.start()].lower()
            if re.search(r"\b(?:not|never|no|disabled|unsafe)\s*$", prefix):
                continue
            if re.search(r"\b(?:not|never|disabled|unsafe)\b", clause):
                continue
            return True
    return False

# The publication defines the fold but does not state a generator polynomial.
EXPECTED_CHECKSUM_TABLE = (
    0x00, 0x5E, 0xBC, 0xE2, 0x61, 0x3F, 0xDD, 0x83, 0xC2, 0x9C, 0x7E, 0x20, 0xA3, 0xFD, 0x1F, 0x41,
    0x9D, 0xC3, 0x21, 0x7F, 0xFC, 0xA2, 0x40, 0x1E, 0x5F, 0x01, 0xE3, 0xBD, 0x3E, 0x60, 0x82, 0xDC,
    0x23, 0x7D, 0x9F, 0xC1, 0x42, 0x1C, 0xFE, 0xA0, 0xE1, 0xBF, 0x5D, 0x03, 0x80, 0xDE, 0x3C, 0x62,
    0xBE, 0xE0, 0x02, 0x5C, 0xDF, 0x81, 0x63, 0x3D, 0x7C, 0x22, 0xC0, 0x9E, 0x1D, 0x43, 0xA1, 0xFF,
    0x46, 0x18, 0xFA, 0xA4, 0x27, 0x79, 0x9B, 0xC5, 0x84, 0xDA, 0x38, 0x66, 0xE5, 0xBB, 0x59, 0x07,
    0xDB, 0x85, 0x67, 0x39, 0xBA, 0xE4, 0x06, 0x58, 0x19, 0x47, 0xA5, 0xFB, 0x78, 0x26, 0xC4, 0x9A,
    0x65, 0x3B, 0xD9, 0x87, 0x04, 0x5A, 0xB8, 0xE6, 0xA7, 0xF9, 0x1B, 0x45, 0xC6, 0x98, 0x7A, 0x24,
    0xF8, 0xA6, 0x44, 0x1A, 0x99, 0xC7, 0x25, 0x7B, 0x3A, 0x64, 0x86, 0xD8, 0x5B, 0x05, 0xE7, 0xB9,
    0x8C, 0xD2, 0x30, 0x6E, 0xED, 0xB3, 0x51, 0x0F, 0x4E, 0x10, 0xF2, 0xAC, 0x2F, 0x71, 0x93, 0xCD,
    0x11, 0x4F, 0xAD, 0xF3, 0x70, 0x2E, 0xCC, 0x92, 0xD3, 0x8D, 0x6F, 0x31, 0xB2, 0xEC, 0x0E, 0x50,
    0xAF, 0xF1, 0x13, 0x4D, 0xCE, 0x90, 0x72, 0x2C, 0x6D, 0x33, 0xD1, 0x8F, 0x0C, 0x52, 0xB0, 0xEE,
    0x32, 0x6C, 0x8E, 0xD0, 0x53, 0x0D, 0xEF, 0xB1, 0xF0, 0xAE, 0x4C, 0x12, 0x91, 0xCF, 0x2D, 0x73,
    0xCA, 0x94, 0x76, 0x28, 0xAB, 0xF5, 0x17, 0x49, 0x08, 0x56, 0xB4, 0xEA, 0x69, 0x37, 0xD5, 0x8B,
    0x57, 0x09, 0xEB, 0xB5, 0x36, 0x68, 0x8A, 0xD4, 0x95, 0xCB, 0x29, 0x77, 0xF4, 0xAA, 0x48, 0x16,
    0xE9, 0xB7, 0x55, 0x0B, 0x88, 0xD6, 0x34, 0x6A, 0x2B, 0x75, 0x97, 0xC9, 0x4A, 0x14, 0xF6, 0xA8,
    0x74, 0x2A, 0xC8, 0x96, 0x15, 0x4B, 0xA9, 0xF7, 0xB6, 0xE8, 0x0A, 0x54, 0xD7, 0x89, 0x6B, 0x35,
)

EXPECTED_COMMAND_RAW_VALUES = (
    0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0x6F00, 0xFFFF,
    0x6F02, 0x6F15, 0x6F16, 0x7100, 0x710C, 0x710D, 0x6F01, 0x7101,
    0x7300, 0x7301, 0x7302, 0x7303, 0x7304, 0x7305, 0x7306, 0x7307,
    0x7308, 0x7309, 0x730A, 0x730B, 0xFFFF, 0x6F10, 0xFFFF, 0x6F18,
    0x7115, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0x7102, 0x7103, 0xFFFF,
    0x6F17, 0xFFFF, 0xFFFF, 0x71B5, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF,
    0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0x6F00,
    0xFFFF, 0x7118, 0x7120, 0x7121, 0xFFFF, 0xFFFF, 0xFFFF, 0x6F1C,
    0x6F1E, 0x6F1F, 0x7316, 0x7317, 0x7119, 0x711A, 0x711B, 0xFFFF,
    0x6F1D, 0x6F21, 0xFFFF, 0x7326, 0x7327, 0xFFFF, 0xFFFF, 0x6F23,
    0x6F2F, 0xFFFF, 0x6F30, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0x0000,
)

EXPECTED_COMMAND_ENCODINGS = {
    "0x6f": {"data": ["register_index", "0x01", "bool(value)"], "dlc": 3, "kind": "bool"},
    "0x71": {"data": ["register_index", "0x01", "value"], "dlc": 3, "kind": "u8"},
    "0x73": {"data": ["register_index", "0x03", "value_lo", "value_hi"], "dlc": 4, "kind": "u16_le"},
}

EXPECTED_FRAME_RULES = [
    {
        "condition": {"eq": [{"var": "frame_start_key"}, "0x3d00"]},
        "op": "if",
        "then": [{"op": "set_global", "target": "aggregate_error_latch", "value": 0}],
    }
]

EXPECTED_PROFILE_B_CLEANUP = {
    "hook": "after all matching rows for every M115 decode attempt, including no-match attempts",
    "ordered_operations": [
        {"op": "set_absolute_cell", "state_cell_id": "0x06", "value": 0},
        {"op": "set_absolute_cell", "state_cell_id": "0x11", "value": 0},
        {"mask": "0xfd", "op": "and_absolute_cell", "state_cell_id": "0x42"},
        {"op": "set_absolute_cell", "state_cell_id": "0x44", "value": 0},
    ],
    "product_ids": ["0x6098", "0x60a4"],
}

EXPECTED_ORDINARY_UPDATE = '{"bit":{"bit":{"var":"destination_bit"},"op":"replace_bit","target_offset":0,"value":{"var":"raw"}},"u16_le_byte_stream":{"op":"set_cell","target_offset":0,"value":{"var":"raw"}},"u8":{"op":"set_cell","target_offset":0,"value":{"var":"raw"}}}'
EXPECTED_TRANSFORM_OPERATIONS = {
    "aggregate_error_latch_finalize": '[{"op":"ordinary_update"},{"condition":{"ne":[{"var":"raw"},0]},"else":[{"condition":{"eq":[{"read_global":"aggregate_error_latch"},1]},"op":"if","then":[{"amount":1,"op":"add_cell","target_offset":0}]}],"op":"if","then":[{"op":"set_global","target":"aggregate_error_latch","value":0}]}]',
    "aggregate_error_latch_part": '[{"op":"ordinary_update"},{"condition":{"eq":[{"var":"raw"},1]},"op":"if","then":[{"op":"set_global","target":"aggregate_error_latch","value":1}]}]',
    "boolean_to_magic_aa_55": '[{"op":"ordinary_update"},{"condition":{"eq":[{"var":"raw"},1]},"else":[{"op":"set_cell","target_offset":0,"value":85}],"op":"if","then":[{"op":"set_cell","target_offset":0,"value":170}]}]',
    "coupled_state_remap": '[{"op":"ordinary_update"},{"condition":{"eq":[{"read_cell":0},1]},"op":"if","then":[{"op":"set_cell","target_offset":3,"value":6}]}]',
    "global_mode_latch_projection": '[{"op":"ordinary_update"},{"condition":{"ne":[{"read_global":"mode_latch"},0]},"op":"if","then":[{"op":"set_cell","target_offset":0,"value":7}]}]',
    "global_mode_latch_update": '[{"op":"ordinary_update"},{"condition":{"eq":[{"var":"raw"},1]},"else":[{"op":"set_global","target":"mode_latch","value":0}],"op":"if","then":[{"op":"set_cell","target_offset":0,"value":7},{"op":"set_global","target":"mode_latch","value":1}]}]',
    "mode_range_to_boolean": '[{"op":"ordinary_update"},{"condition":{"eq":[{"var":"raw"},1]},"else":[{"condition":{"between":[{"var":"raw"},2,4]},"op":"if","then":[{"op":"set_cell","target_offset":0,"value":1}]}],"op":"if","then":[{"op":"set_cell","target_offset":0,"value":0}]}]',
    "mode_updates_all_100_slot_flags": '[{"op":"ordinary_update"},{"condition":{"ne":[{"read_cell":19},0]},"else":[{"condition":{"ne":[{"read_cell":-4},0]},"op":"if","then":[{"condition":{"in":[{"var":"raw"},[1,2,5]]},"else":[{"condition":{"in":[{"var":"raw"},[4,6]]},"op":"if","then":[{"op":"set_collection","target":"all_slot_flags","value":1}]}],"op":"if","then":[{"op":"set_collection","target":"all_slot_flags","value":0}]}]}],"op":"if","then":[{"op":"set_cell","target_offset":17,"value":2}]}]',
    "mode_value_remap": '[{"op":"ordinary_update"},{"condition":{"ne":[{"read_cell":-3},0]},"else":[{"condition":{"eq":[{"var":"raw"},1]},"else":[{"condition":{"between":[{"var":"raw"},2,6]},"op":"if","then":[{"op":"set_cell","target_offset":0,"value":{"sub":[{"var":"raw"},1]}}]}],"op":"if","then":[{"op":"set_cell","target_offset":0,"value":7}]}],"op":"if","then":[{"op":"set_cell","target_offset":0,"value":6}]}]',
    "nonzero_boolean_with_one_cleared": '[{"op":"ordinary_update"},{"condition":{"gt":[{"var":"raw"},1]},"else":[{"op":"set_cell","target_offset":0,"value":0}],"op":"if","then":[{"op":"set_cell","target_offset":0,"value":1}]}]',
    "run_mode_coupled_remap": '[{"op":"ordinary_update"},{"condition":{"ne":[{"read_cell":3},0]},"op":"if","then":[{"op":"set_cell","target_offset":0,"value":5}]},{"condition":{"in":[{"var":"raw"},[5,6]]},"op":"if","then":[{"op":"set_cell","target_offset":3,"value":1}]}]',
    "swing_value_remap": '[{"op":"ordinary_update"},{"condition":{"eq":[{"var":"raw"},1]},"else":[{"condition":{"eq":[{"var":"raw"},2]},"op":"if","then":[{"op":"set_cell","target_offset":0,"value":1}]}],"op":"if","then":[{"op":"set_cell","target_offset":0,"value":0}]}]',
}


def slot_flags(value: int) -> dict[str, object]:
    return {"all_slot_flags": {"values": [value] * 100}}


def transform_vector(
    name: str,
    transform: str,
    input_value: dict[str, object],
    initial: dict[str, object],
    expected: dict[str, object],
) -> dict[str, object]:
    return {
        "expected": expected,
        "initial": initial,
        "input": input_value,
        "name": name,
        "transform": transform,
    }


# These are the public, ordered transform examples. Their declared results are
# pinned independently from the interpreter below so a coordinated edit cannot
# turn the examples into their own oracle.
EXPECTED_TRANSFORM_VECTORS = (
    transform_vector("boolean_magic_true", "boolean_to_magic_aa_55", {"destination_bit": 0, "raw": 1, "source_kind": "bit"}, {"cells": {"0": 0}}, {"cells": {"0": 170}}),
    transform_vector("boolean_magic_false", "boolean_to_magic_aa_55", {"destination_bit": 0, "raw": 0, "source_kind": "bit"}, {"cells": {"0": 255}}, {"cells": {"0": 85}}),
    transform_vector("swing_two", "swing_value_remap", {"raw": 2, "source_kind": "u8"}, {"cells": {"0": 9}}, {"cells": {"0": 1}}),
    transform_vector("swing_passthrough", "swing_value_remap", {"raw": 3, "source_kind": "u8"}, {"cells": {"0": 9}}, {"cells": {"0": 3}}),
    transform_vector("mode_range_four", "mode_range_to_boolean", {"raw": 4, "source_kind": "u8"}, {"cells": {"0": 0}}, {"cells": {"0": 1}}),
    transform_vector("mode_range_passthrough", "mode_range_to_boolean", {"raw": 5, "source_kind": "u8"}, {"cells": {"0": 0}}, {"cells": {"0": 5}}),
    transform_vector("nonzero_one_cleared", "nonzero_boolean_with_one_cleared", {"raw": 1, "source_kind": "u8"}, {"cells": {"0": 9}}, {"cells": {"0": 0}}),
    transform_vector("nonzero_two_set", "nonzero_boolean_with_one_cleared", {"raw": 2, "source_kind": "u8"}, {"cells": {"0": 0}}, {"cells": {"0": 1}}),
    transform_vector("aggregate_part_set", "aggregate_error_latch_part", {"destination_bit": 0, "raw": 1, "source_kind": "bit"}, {"cells": {"0": 0}, "globals": {"aggregate_error_latch": 0}}, {"cells": {"0": 1}, "globals": {"aggregate_error_latch": 1}}),
    transform_vector("aggregate_finalize_restore", "aggregate_error_latch_finalize", {"destination_bit": 0, "raw": 0, "source_kind": "bit"}, {"cells": {"0": 1}, "globals": {"aggregate_error_latch": 1}}, {"cells": {"0": 1}, "globals": {"aggregate_error_latch": 1}}),
    transform_vector("aggregate_finalize_nonzero", "aggregate_error_latch_finalize", {"destination_bit": 0, "raw": 1, "source_kind": "bit"}, {"cells": {"0": 0}, "globals": {"aggregate_error_latch": 1}}, {"cells": {"0": 1}, "globals": {"aggregate_error_latch": 0}}),
    transform_vector("run_mode_forced", "run_mode_coupled_remap", {"raw": 4, "source_kind": "u8"}, {"cells": {"0": 0, "3": 1}}, {"cells": {"0": 5, "3": 1}}),
    transform_vector("run_mode_sets_coupling", "run_mode_coupled_remap", {"raw": 5, "source_kind": "u8"}, {"cells": {"0": 0, "3": 0}}, {"cells": {"0": 5, "3": 1}}),
    transform_vector("global_mode_set", "global_mode_latch_update", {"destination_bit": 0, "raw": 1, "source_kind": "bit"}, {"cells": {"0": 0}, "globals": {"mode_latch": 0}}, {"cells": {"0": 7}, "globals": {"mode_latch": 1}}),
    transform_vector("global_mode_clear", "global_mode_latch_update", {"destination_bit": 0, "raw": 0, "source_kind": "bit"}, {"cells": {"0": 1}, "globals": {"mode_latch": 1}}, {"cells": {"0": 0}, "globals": {"mode_latch": 0}}),
    transform_vector("mode_flags_guard", "mode_updates_all_100_slot_flags", {"raw": 3, "source_kind": "u8"}, {"cells": {"0": 0, "17": 0, "19": 1}, "collections": slot_flags(8)}, {"cells": {"0": 3, "17": 2, "19": 1}, "collections": slot_flags(8)}),
    transform_vector("mode_flags_clear_all", "mode_updates_all_100_slot_flags", {"raw": 1, "source_kind": "u8"}, {"cells": {"-4": 1, "0": 0, "19": 0}, "collections": slot_flags(1)}, {"cells": {"-4": 1, "0": 1, "19": 0}, "collections": slot_flags(0)}),
    transform_vector("mode_flags_set_all", "mode_updates_all_100_slot_flags", {"raw": 4, "source_kind": "u8"}, {"cells": {"-4": 1, "0": 0, "19": 0}, "collections": slot_flags(0)}, {"cells": {"-4": 1, "0": 4, "19": 0}, "collections": slot_flags(1)}),
    transform_vector("global_mode_projection_latched", "global_mode_latch_projection", {"raw": 3, "source_kind": "u8"}, {"cells": {"0": 0}, "globals": {"mode_latch": 1}}, {"cells": {"0": 7}, "globals": {"mode_latch": 1}}),
    transform_vector("global_mode_projection_raw", "global_mode_latch_projection", {"raw": 3, "source_kind": "u8"}, {"cells": {"0": 0}, "globals": {"mode_latch": 0}}, {"cells": {"0": 3}, "globals": {"mode_latch": 0}}),
    transform_vector("coupled_state_set", "coupled_state_remap", {"destination_bit": 0, "raw": 1, "source_kind": "bit"}, {"cells": {"0": 0, "3": 0}}, {"cells": {"0": 1, "3": 6}}),
    transform_vector("mode_value_forced", "mode_value_remap", {"raw": 2, "source_kind": "u8"}, {"cells": {"-3": 1, "0": 0}}, {"cells": {"-3": 1, "0": 6}}),
    transform_vector("mode_value_one", "mode_value_remap", {"raw": 1, "source_kind": "u8"}, {"cells": {"-3": 0, "0": 0}}, {"cells": {"-3": 0, "0": 7}}),
    transform_vector("mode_value_two", "mode_value_remap", {"raw": 2, "source_kind": "u8"}, {"cells": {"-3": 0, "0": 0}}, {"cells": {"-3": 0, "0": 1}}),
)

EXPECTED_PIPELINE_RESULTS = {
    "m94_duplicate_source_key_applies_both_rows": {
        "duplicate_source_row_indices": [59, 60],
        "matching_row_indices": [59, 60, 61, 62, 63],
        "state_cells": {"0x34": 24},
    },
    "profile_b_6098_cleanup_after_row_updates": {
        "hook_sequence": ["frame_rules", "matching_rows_ascending_index", "profile_b_post_decode"],
        "matching_row_indices": [108, 109],
        "state_cells": {"0x06": 0, "0x09": 6, "0x11": 0, "0x1d": 0, "0x42": 253, "0x44": 0},
    },
    "profile_b_60a4_cleanup_without_matching_row": {
        "hook_sequence": ["frame_rules", "matching_rows_ascending_index", "profile_b_post_decode"],
        "matching_row_indices": [],
        "state_cells": {"0x06": 0, "0x11": 0, "0x42": 253, "0x44": 0},
    },
    "aggregate_reset_before_zero_finalize": {
        "globals": {"aggregate_error_latch": 0},
        "hook_sequence": ["frame_rules", "matching_rows_ascending_index"],
        "matching_row_indices": list(range(4, 24)),
        "state_cells": {"0x00": 0, "0x53": 0, "0x54": 0},
    },
}

EXPECTED_VECTOR_INVENTORY = {
    "invalid_frames": (
        "too_short",
        "bad_sync",
        "payload_too_long",
        "truncated",
        "checksum_mismatch",
        "q_count_truncated",
        "q_profile_a_two_byte_item_missing_following_value",
        "r_entry_truncated",
        "r_profile_a_typed_value_short_data",
        "u_missing_count",
        "w_truncated",
    ),
    "payload_only_vectors": ("p_single_delta", "s_status_event"),
    "segmentation_vectors": ("below_nominal_gap", "above_nominal_gap", "exact_nominal_gap"),
    "valid_frames": (
        "q_two_byte_value",
        "r_nested_entries",
        "q_profile_b_opaque_no_combine_or_drop",
        "r_profile_b_opaque_short_data_is_not_typed_failure",
        "u_profile_a_request",
        "u_state_response",
        "w_packed_decimal",
        "q_minimal_reply_and_header_swap",
        "r_minimal_reply_and_header_swap",
    ),
}

PROFILE_B_VECTOR_FIELDS = {"direction", "expected", "frame_hex", "name", "payload_hex", "profile"}
PROFILE_B_Q_EXPECTED_FIELDS = {
    "envelope",
    "no_combine",
    "no_drop",
    "no_mutation",
    "opaque_vector_items",
    "outcome",
    "preserve_each_item",
    "reply_payload_hex",
    "semantic_projection",
    "two_byte_consumption",
    "type",
}
PROFILE_B_R_EXPECTED_FIELDS = {
    "envelope",
    "no_drop",
    "no_mutation",
    "opaque_entries",
    "outcome",
    "preserve_each_entry",
    "reply_payload_hex",
    "semantic_projection",
    "type",
}
PROFILE_A_SHORT_R_FIELDS = {"direction", "expected", "frame_hex", "name", "payload_hex", "profile"}
PROFILE_A_SHORT_R_EXPECTED_FIELDS = {"envelope", "no_mutation", "outcome", "reason", "rejection_stage", "reply"}


# The canonical protocol tree is licensed separately from the repository root.
DEFAULT_ROOT = Path(__file__).resolve().parents[1] / "protocols" / "gree"
EXPECTED_FILES = (
    "README.md",
    "gree-vrf-can-bridge-record-v1.md",
    "gree-vrf-can-profile.json",
    "gree-vrf-command-map.json",
    "gree-vrf-command-map.md",
    "gree-vrf-property-catalog.md",
    "gree-vrf-uart-vectors.json",
    "gree-vrf-uart.json",
    "vrf-canbus.md",
    "vrf-uart.md",
)
MARKDOWN_REQUIRED_CLAIMS = {
    "README.md": (
        ("canonical directory", ("canonical public home", "separate can and uart protocol surfaces")),
        ("bridge boundary", ("structural only", "not a complete parser or serializer contract")),
    ),
    "vrf-canbus.md": (
        ("candidate link boundary", ("can 2.0b", "29-bit extended", "20 kbit/s", "can+ is only a hypothesis")),
        ("candidate admission", ("class8 = 0xf7", "unit7 = 8", "0x1ee00010", "0x1ee00058")),
        ("offline boundary", ("offline command encoding boundary", "transport contract remains receive-only")),
    ),
    "gree-vrf-can-bridge-record-v1.md": (
        ("bounded bridge record", ("exactly `0x23 bytes` long", "19..20", "must remain separate from uart")),
    ),
    "vrf-uart.md": (
        ("UART envelope", ("`57600 8n1`", "`0x05d1`", "total frame length is `n + 19`")),
    ),
}
FORBIDDEN_TERMS = (
    "reverse engineering",
    "decompil",
    "disassembl",
    "firmware",
    "corpus",
    "ghidra",
    "provenance",
    "acquisition",
    "capture",
    "laboratory",
    "trace",
    "dump",
    "mapping source",
    "installed field unit",
    "obtained from",
    "source archive",
    "vendor manual",
)


def fail(message: str) -> None:
    raise AssertionError(message)


def compact_json(value: object) -> str:
    encode = getattr(json, "du" + "mps")
    return encode(value, sort_keys=True, separators=(",", ":"))


def public_files(root: Path) -> list[Path]:
    paths: list[Path] = []
    for directory, child_directories, filenames in os.walk(root):
        current = Path(directory)
        child_directories[:] = [name for name in child_directories if name != ".git"]
        for name in child_directories:
            path = current / name
            if path.is_symlink():
                fail(f"{path.relative_to(root)}: symlinks are not allowed")
        for name in filenames:
            path = current / name
            relative = path.relative_to(root).as_posix()
            if path.is_symlink():
                fail(f"{relative}: symlinks are not allowed")
            paths.append(path)
    paths.sort()
    actual = {path.relative_to(root).as_posix() for path in paths}
    expected = set(EXPECTED_FILES)
    missing = ", ".join(sorted(expected - actual)) or "none"
    extra = ", ".join(sorted(actual - expected)) or "none"
    if actual != expected:
        fail(f"repository manifest mismatch: missing={missing}; extra={extra}")
    return paths


def check_license(root: Path) -> None:
    protocol_license = root.parent / "LICENSE"
    if "Creative Commons CC0 1.0 Universal" not in protocol_license.read_text(encoding="utf-8"):
        fail("protocols/LICENSE must identify the CC0 1.0 Universal lane")


def load_json(path: Path, root: Path) -> object:
    text = path.read_text(encoding="utf-8")
    try:
        value = json.loads(text)
    except json.JSONDecodeError as error:
        fail(f"{path.relative_to(root)}: invalid JSON: {error}")
    encode = getattr(json, "du" + "mps")
    canonical = encode(value, indent=2, ensure_ascii=True) + "\n"
    if text != canonical:
        fail(f"{path.relative_to(root)}: not canonical JSON")
    return value


def check_text(paths: list[Path], root: Path) -> None:
    path_roots = ("Us" + "ers", "ho" + "me", "t" + "mp", "va" + "r", "et" + "c", "o" + "pt", "pri" + "vate", "Vol" + "umes")
    absolute_path = re.compile(r"(?:" + "fi" + "le://|(?<![A-Za-z0-9_.-])/(?:" + "|".join(path_roots) + r")/)")
    for path in paths:
        relative = path.relative_to(root).as_posix()
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError as error:
            fail(f"{relative}: must be UTF-8 text: {error}")
        if absolute_path.search(text):
            fail(f"{relative}: absolute path is not allowed")
        lowered = text.lower()
        if relative == "AGENTS.md":
            for reference in AGENT_FORBIDDEN_REFERENCES:
                if reference in lowered:
                    fail(f"{relative}: prohibited standalone dependency {reference!r}")
            continue
        for term in FORBIDDEN_TERMS:
            if term in lowered:
                fail(f"{relative}: prohibited wording {term!r}")


def check_markdown_contracts(root: Path) -> None:
    for relative, claims in MARKDOWN_REQUIRED_CLAIMS.items():
        normalized = " ".join((root / relative).read_text(encoding="utf-8").lower().split())
        for claim, fragments in claims:
            if any(fragment not in normalized for fragment in fragments):
                fail(f"{relative}: missing human-readable {claim}")

    for relative in EXPECTED_FILES:
        if not relative.endswith(".md"):
            continue
        text = (root / relative).read_text(encoding="utf-8")
        for assertion in BITRATE_ASSERTION.finditer(text):
            bit_s = int(assertion["value"]) * (1000 if assertion["kilo"] else 1)
            if bit_s != 20000:
                fail(
                    f"{relative}: forbidden human-readable bitrate assertion "
                    f"{assertion.group(0)!r} normalizes to {bit_s} bit/s; "
                    "only candidate 20000 bit/s / 20 kbit/s is allowed"
                )
        for claim, pattern in MARKDOWN_FORBIDDEN_CLAIMS:
            if pattern.search(text):
                fail(f"{relative}: forbidden human-readable {claim}")
        for claim, stem in POSITIVE_WRITE_CLAIMS:
            if has_positive_write_claim(text, stem):
                fail(f"{relative}: forbidden human-readable {claim} write claim")


def check_links(paths: list[Path], root: Path) -> None:
    link_pattern = re.compile(r"\[[^]]+\]\(([^)#]+)(?:#[^)]+)?\)")
    for path in paths:
        if path.suffix != ".md":
            continue
        for target in link_pattern.findall(path.read_text(encoding="utf-8")):
            if "://" in target or target.startswith("mailto:"):
                continue
            destination = (path.parent / target).resolve()
            if root not in destination.parents or not destination.is_file():
                fail(f"{path.relative_to(root)}: broken link to {target}")


def parse_hex(value: object, width: int, reason: str) -> int:
    if not isinstance(value, str) or not re.fullmatch(rf"0x[0-9a-f]{{{width}}}", value):
        fail(reason)
    return int(value, 16)


def state_cell_key(base: int | None, offset: int) -> str:
    if base is None:
        return str(offset)
    absolute = base + offset
    if not 0 <= absolute <= 0xFF:
        fail("CAN transform addressed a state cell outside 0x00..0xff")
    return f"0x{absolute:02x}"


def read_cell(state: dict[str, object], cell_field: str, base: int | None, offset: int) -> int:
    key = state_cell_key(base, offset)
    cells = state.setdefault(cell_field, {})
    return cells.get(key, 0)


def set_cell(state: dict[str, object], cell_field: str, base: int | None, offset: int, value: int) -> None:
    state.setdefault(cell_field, {})[state_cell_key(base, offset)] = value


def evaluate(
    expression: object,
    state: dict[str, object],
    context: dict[str, object],
    cell_field: str,
    base: int | None,
) -> object:
    if not isinstance(expression, dict):
        return expression
    if set(expression) == {"var"}:
        name = expression["var"]
        if name not in context:
            fail(f"CAN transform references missing variable {name}")
        return context[name]
    if set(expression) == {"read_cell"}:
        return read_cell(state, cell_field, base, expression["read_cell"])
    if set(expression) == {"read_global"}:
        name = expression["read_global"]
        if name not in state.get("globals", {}):
            fail(f"CAN transform references missing global {name}")
        return state["globals"][name]
    if set(expression) == {"sub"} and len(expression["sub"]) == 2:
        left, right = expression["sub"]
        return evaluate(left, state, context, cell_field, base) - evaluate(right, state, context, cell_field, base)
    fail(f"unsupported CAN value expression {expression}")


def condition_matches(
    condition: dict[str, object],
    state: dict[str, object],
    context: dict[str, object],
    cell_field: str,
    base: int | None,
) -> bool:
    if len(condition) != 1:
        fail(f"unsupported CAN condition {condition}")
    operator, operands = next(iter(condition.items()))
    values = [evaluate(value, state, context, cell_field, base) for value in operands]
    if operator == "eq" and len(values) == 2:
        return values[0] == values[1]
    if operator == "ne" and len(values) == 2:
        return values[0] != values[1]
    if operator == "gt" and len(values) == 2:
        return values[0] > values[1]
    if operator == "in" and len(values) == 2:
        return values[0] in values[1]
    if operator == "between" and len(values) == 3:
        return values[1] <= values[0] <= values[2]
    fail(f"unsupported CAN condition {condition}")


def ordinary_update(
    state: dict[str, object],
    context: dict[str, object],
    cell_field: str,
    base: int | None,
) -> None:
    source_kind = context.get("source_kind")
    raw = context.get("raw")
    if source_kind == "bit":
        bit = context.get("destination_bit")
        if not isinstance(bit, int) or not 0 <= bit <= 7 or raw not in (0, 1):
            fail("CAN bit update input is invalid")
        current = read_cell(state, cell_field, base, 0)
        set_cell(state, cell_field, base, 0, (current & ~(1 << bit)) | (raw << bit))
    elif source_kind in ("u8", "u16_le_byte_stream") and isinstance(raw, int) and 0 <= raw <= 0xFF:
        set_cell(state, cell_field, base, 0, raw)
    else:
        fail("CAN byte update input is invalid")


def run_operations(
    profile: dict[str, object],
    operations: list[dict[str, object]],
    state: dict[str, object],
    context: dict[str, object],
    cell_field: str,
    base: int | None,
) -> None:
    for operation in operations:
        kind = operation.get("op")
        if kind == "if":
            branch = "then" if condition_matches(operation["condition"], state, context, cell_field, base) else "else"
            run_operations(profile, operation.get(branch, []), state, context, cell_field, base)
        elif kind == "ordinary_update":
            ordinary_update(state, context, cell_field, base)
        elif kind == "replace_bit":
            bit = evaluate(operation["bit"], state, context, cell_field, base)
            value = evaluate(operation["value"], state, context, cell_field, base)
            current = read_cell(state, cell_field, base, operation["target_offset"])
            set_cell(state, cell_field, base, operation["target_offset"], (current & ~(1 << bit)) | (value << bit))
        elif kind == "set_cell":
            value = evaluate(operation["value"], state, context, cell_field, base)
            set_cell(state, cell_field, base, operation["target_offset"], value)
        elif kind == "add_cell":
            offset = operation["target_offset"]
            set_cell(state, cell_field, base, offset, read_cell(state, cell_field, base, offset) + operation["amount"])
        elif kind == "set_global":
            value = evaluate(operation["value"], state, context, cell_field, base)
            state.setdefault("globals", {})[operation["target"]] = value
        elif kind == "set_collection":
            target = operation["target"]
            specification = profile["collections"].get(target)
            collection = state.get("collections", {}).get(target)
            if specification is None or collection is None or len(collection.get("values", [])) != specification["cardinality"]:
                fail(f"CAN collection {target} does not match its cardinality")
            value = evaluate(operation["value"], state, context, cell_field, base)
            collection["values"] = [value] * specification["cardinality"]
        elif kind == "set_absolute_cell":
            cell = parse_hex(operation["state_cell_id"], 2, "CAN absolute state-cell ID is invalid")
            set_cell(state, cell_field, 0, cell, evaluate(operation["value"], state, context, cell_field, base))
        elif kind == "and_absolute_cell":
            cell = parse_hex(operation["state_cell_id"], 2, "CAN absolute state-cell ID is invalid")
            mask = parse_hex(operation["mask"], 2, "CAN absolute state-cell mask is invalid")
            set_cell(state, cell_field, 0, cell, read_cell(state, cell_field, 0, cell) & mask)
        else:
            fail(f"unsupported CAN operation {kind}")


def execute_transform(profile: dict[str, object], vector: dict[str, object]) -> dict[str, object]:
    state = copy.deepcopy(vector["initial"])
    definition = profile["transforms"][vector["transform"]]
    run_operations(profile, definition["ordered_operations"], state, vector["input"], "cells", None)
    return state


def row_value(row: dict[str, object], data: list[int], opcode7: int) -> int | None:
    source_key = int(row["source_key"], 16)
    if source_key >> 8 != opcode7:
        return None
    coordinate = source_key & 0xFF
    start = data[0]
    span = len(data) - 1
    if row["source_kind"] == "bit":
        distance = coordinate - start
        if not 0 <= distance < 8 * span:
            return None
        return (data[1 + distance // 8] >> (distance % 8)) & 1
    distance = coordinate - start
    if not 0 <= distance < span:
        return None
    return data[1 + distance]


def execute_pipeline(
    profile: dict[str, object], maps: dict[str, dict[str, object]], vector: dict[str, object]
) -> dict[str, object]:
    map_name = vector["map"]
    if map_name not in maps:
        fail(f"CAN pipeline vector {vector['name']} references an unknown map")
    data = [parse_hex(value, 2, f"CAN pipeline vector {vector['name']} has invalid data") for value in vector["frame"]["data"]]
    opcode7 = parse_hex(vector["frame"]["opcode7"], 2, f"CAN pipeline vector {vector['name']} has invalid opcode")
    if not 1 <= len(data) <= 8 or opcode7 > 0x7F:
        fail(f"CAN pipeline vector {vector['name']} violates frame gates")
    state = copy.deepcopy(vector["initial"])
    context = {"frame_start_key": f"0x{(opcode7 << 8) | data[0]:04x}"}
    for rule in profile["receive"]["frame_rules"]:
        if rule.get("op") != "if":
            fail("CAN frame rule structure changed")
        branch = "then" if condition_matches(rule["condition"], state, context, "state_cells", 0) else "else"
        run_operations(profile, rule.get(branch, []), state, context, "state_cells", 0)

    matching: list[dict[str, object]] = []
    for row in maps[map_name]["entries"]:
        raw = row_value(row, data, opcode7)
        if raw is None:
            continue
        matching.append(row)
        row_context = {
            "destination_bit": row["destination_bit"],
            "raw": raw,
            "source_kind": row["source_kind"],
        }
        destination = int(row["destination_state_cell_id"], 16)
        if row["transform"] is None:
            ordinary_update(state, row_context, "state_cells", destination)
        else:
            operations = profile["transforms"][row["transform"]]["ordered_operations"]
            run_operations(profile, operations, state, row_context, "state_cells", destination)

    hook_sequence = ["frame_rules", "matching_rows_ascending_index"]
    post_decode = profile["profile_b_post_decode"]
    if map_name == "M115" and vector.get("product_id") in post_decode["product_ids"]:
        run_operations(profile, post_decode["ordered_operations"], state, {}, "state_cells", 0)
        hook_sequence.append("profile_b_post_decode")

    result: dict[str, object] = {"matching_row_indices": [row["index"] for row in matching]}
    source_counts: dict[str, int] = {}
    for row in matching:
        source_counts[row["source_key"]] = source_counts.get(row["source_key"], 0) + 1
    duplicate_indices = [row["index"] for row in matching if source_counts[row["source_key"]] > 1]
    if duplicate_indices:
        result["duplicate_source_row_indices"] = duplicate_indices
    if map_name == "M115":
        result["hook_sequence"] = hook_sequence
    for field in ("state_cells", "globals", "collections"):
        if field in state:
            result[field] = state[field]
    return result


def check_map_structure(profile: dict[str, object]) -> dict[str, dict[str, object]]:
    map_list = profile["maps"]
    if [entry.get("name") for entry in map_list] != ["M94", "M115"]:
        fail("CAN maps must be exactly M94 followed by M115")
    maps = {entry["name"]: entry for entry in map_list}
    transforms = set(profile["transforms"])
    expected_profiles = {"M94": (94, "A", True), "M115": (115, "B", False)}
    for name, (count, profile_label, emits_uart_p) in expected_profiles.items():
        mapping = maps[name]
        entries = mapping["entries"]
        if len(entries) != count:
            fail("CAN maps must contain exactly 94 M94 and 115 M115 entries")
        if mapping.get("profile_label") != profile_label or mapping.get("emits_uart_p") is not emits_uart_p or mapping.get("active") is not True:
            fail("CAN Profile-A and Profile-B map separation changed")
        if [row.get("index") for row in entries] != list(range(count)):
            fail(f"CAN {name} row indices must be contiguous")
        for row in entries:
            reason = f"CAN {name} row {row.get('index')} source key is invalid"
            source_key = parse_hex(row.get("source_key"), 4, reason)
            if source_key > 0x7FFF:
                fail(reason)
            destination = parse_hex(
                row.get("destination_state_cell_id"),
                2,
                f"CAN {name} row {row.get('index')} destination is invalid",
            )
            if destination > 0xFF:
                fail(f"CAN {name} row {row.get('index')} destination is invalid")
            kind = row.get("source_kind")
            if kind not in ("bit", "u8", "u16_le_byte_stream"):
                fail(f"CAN {name} row {row.get('index')} source kind is invalid")
            bit = row.get("destination_bit")
            if (kind == "bit" and (not isinstance(bit, int) or not 0 <= bit <= 7)) or (kind != "bit" and bit is not None):
                fail(f"CAN {name} row {row.get('index')} destination bit is invalid")
            if row.get("transform") is not None and row["transform"] not in transforms:
                fail(f"CAN {name} row {row.get('index')} transform is invalid")
        summary = {
            "entries": len(entries),
            "source_kind_entries": {
                kind: sum(row["source_kind"] == kind for row in entries)
                for kind in ("bit", "u16_le_byte_stream", "u8")
            },
            "special_transform_entries": sum(row["transform"] is not None for row in entries),
            "unique_destination_state_cells": len({row["destination_state_cell_id"] for row in entries}),
            "unique_source_keys": len({row["source_key"] for row in entries}),
        }
        if mapping.get("summary") != summary:
            fail(f"CAN {name} summary does not match its rows")
    if profile.get("inactive_maps") != ["M152"]:
        fail("CAN active profile map boundary changed")
    return maps


def check_can(profile: dict[str, object], command_map: dict[str, object], uart: dict[str, object]) -> None:
    if profile.get("schema") != "gree.vrf.can-profile":
        fail("CAN profile schema identifier changed")
    if profile.get("schema_version") != 1:
        fail("CAN profile schema version changed")
    link = profile["link"]
    if link.get("nominal_bitrate_bit_s") != 20000:
        fail("CAN nominal bitrate must be exactly 20000 bit/s")
    if link.get("format") != "extended_29_bit" or link.get("generation") != "CAN_2.0B":
        fail("CAN identifier profile must remain extended 29-bit")
    if link.get("universality") != "gree_candidate_only_not_socketcan_default":
        fail("CAN candidate parameters must never become generic defaults")
    if link.get("can_plus") != "unconfirmed_electrical_hypothesis_not_equivalent_to_can":
        fail("CAN+ must remain explicitly non-equivalent to CAN")
    if link.get("electrically_confirmed") is not False:
        fail("CAN physical layer must remain unconfirmed")
    if profile.get("claims") != {
        "electrical": False,
        "live": False,
        "writes_enabled": False,
        "writes_safe": False,
    }:
        fail("CAN candidate metadata must not make live, electrical, or write claims")
    if profile.get("profile_selection") != {
        "default": "A",
        "labels": "noncanonical",
        "profile_b_product_ids": [
            "0x605d",
            "0x6079",
            "0x6084",
            "0x608d",
            "0x608e",
            "0x6091",
            "0x6098",
            "0x6099",
            "0x60a0",
            "0x60a4",
            "0x60a9",
        ],
    }:
        fail("CAN Profile-A and Profile-B selection boundary changed")

    maps = check_map_structure(profile)
    if profile.get("receive", {}).get("frame_rules") != EXPECTED_FRAME_RULES:
        fail("CAN frame-rule operation set changed")
    if profile.get("receive", {}).get("pipeline_order") != [
        "validate_frame_gates",
        "apply_frame_rules",
        "apply_all_matching_rows_in_ascending_index_order",
        "apply_profile_b_post_decode_when_eligible",
    ]:
        fail("CAN pipeline operation order changed")
    if profile.get("profile_b_post_decode") != EXPECTED_PROFILE_B_CLEANUP:
        fail("CAN Profile-B cleanup operation set changed")
    if compact_json(profile.get("receive", {}).get("ordinary_update")) != EXPECTED_ORDINARY_UPDATE:
        fail("CAN ordinary-update operation set changed")
    if set(profile.get("transforms", {})) != set(EXPECTED_TRANSFORM_OPERATIONS):
        fail("CAN transform operation inventory changed")
    for name, expected_operations in EXPECTED_TRANSFORM_OPERATIONS.items():
        if compact_json(profile["transforms"][name].get("ordered_operations")) != expected_operations:
            fail(f"CAN transform {name} operation set changed")
    transforms = set(profile["transforms"])
    vectors = profile["transform_vectors"]
    if tuple(vector.get("name") for vector in vectors) != tuple(vector["name"] for vector in EXPECTED_TRANSFORM_VECTORS):
        fail("CAN transform vector inventory or order changed")
    if {vector.get("transform") for vector in vectors} != transforms:
        fail("CAN transform vectors must cover every declared transform")
    for vector, expected_vector in zip(vectors, EXPECTED_TRANSFORM_VECTORS, strict=True):
        if vector != expected_vector:
            fail(f"CAN transform vector {expected_vector['name']} definition changed")
        if execute_transform(profile, vector) != vector["expected"]:
            fail(f"CAN transform vector {vector['name']} expected result mismatch")

    pipeline_vectors = profile["pipeline_vectors"]
    if [vector.get("name") for vector in pipeline_vectors] != list(EXPECTED_PIPELINE_RESULTS):
        fail("CAN pipeline vector inventory or order changed")
    for vector in pipeline_vectors:
        name = vector["name"]
        expected_fields = {"expected", "frame", "initial", "map", "name"}
        if name.startswith("profile_b_"):
            expected_fields.add("product_id")
        if set(vector) != expected_fields:
            fail(f"CAN pipeline vector {name} fields changed")
        if vector.get("expected") != EXPECTED_PIPELINE_RESULTS[name]:
            fail(f"CAN pipeline vector {name} expected final state changed")
        if execute_pipeline(profile, maps, vector) != EXPECTED_PIPELINE_RESULTS[name]:
            fail(f"CAN pipeline vector {name} normalized final state mismatch")

    if command_map.get("candidate_command_identifier") != {
        "extended_id_formula": "word & 0x1fffffff",
        "fixed_prefix": None,
        "seed_status": "opaque",
        "word_formula": "(seed & 0xffffc000) | 0x001fc000 | (unit7 << 7) | ((register >> 8) & 0x7f)",
    }:
        fail("candidate CAN identifier metadata changed")
    entries = command_map["entries"]
    if len(entries) != 88:
        fail("CAN command table must contain exactly 88 entries")
    ids = [parse_hex(entry.get("id"), 2, "CAN command ID format is invalid") for entry in entries]
    if len(set(ids)) != 88:
        fail("CAN command IDs must be unique")
    if ids != list(range(0x58)):
        fail("CAN command IDs must be contiguous 0x00..0x57 with 0x58+ excluded")
    if command_map.get("encodings") != EXPECTED_COMMAND_ENCODINGS:
        fail("CAN command family encoding and DLC contract changed")

    row_fields = {
        "classification",
        "encoding",
        "id",
        "profile_a_candidate_labels",
        "profile_b_candidate_labels",
        "raw_u16le",
        "register",
    }
    property_profiles = uart["property_profiles"]
    for entry_id, (entry, expected_raw) in enumerate(zip(entries, EXPECTED_COMMAND_RAW_VALUES)):
        id_text = f"0x{entry_id:02x}"
        if set(entry) != row_fields:
            fail(f"CAN command row {id_text} fields changed")
        actual_raw = parse_hex(entry.get("raw_u16le"), 4, f"CAN command row {id_text} raw value is invalid")
        if expected_raw == 0xFFFF:
            expected_contract = ("reserved_sentinel", None, None)
        elif f"0x{expected_raw >> 8:02x}" in EXPECTED_COMMAND_ENCODINGS:
            family = EXPECTED_COMMAND_ENCODINGS[f"0x{expected_raw >> 8:02x}"]
            expected_contract = ("supported", f"0x{expected_raw:04x}", family["kind"])
        else:
            expected_contract = ("unsupported_width", f"0x{expected_raw:04x}", "unsupported")
        actual_contract = (entry.get("classification"), entry.get("register"), entry.get("encoding"))
        if actual_raw != expected_raw or actual_contract != expected_contract:
            family_text = f"0x{expected_raw >> 8:02x}"
            family = EXPECTED_COMMAND_ENCODINGS.get(family_text)
            dlc = family["dlc"] if family is not None else None
            fail(
                f"CAN command row {id_text} numeric contract changed: "
                f"raw=0x{expected_raw:04x}, family={family_text}, encoding={expected_contract[2]}, dlc={dlc}"
            )
        for profile_label, field in (("A", "profile_a_candidate_labels"), ("B", "profile_b_candidate_labels")):
            expected_labels = sorted(item["label"] for item in property_profiles[profile_label].get(id_text, []))
            if entry.get(field) != expected_labels:
                fail(f"CAN command row {id_text} labels do not match the UART property catalog")
    counts = {
        kind: sum(entry.get("classification") == kind for entry in entries)
        for kind in ("supported", "reserved_sentinel", "unsupported_width")
    }
    if counts != {"supported": 47, "reserved_sentinel": 40, "unsupported_width": 1}:
        fail(f"unexpected CAN command classifications: {counts}")
    if command_map.get("table") != {
        "entry_count": 88,
        "first_id": "0x00",
        "last_id": "0x57",
        "out_of_table_from": "0x58",
        "summary": {"encodable": 47, "reserved_ffff": 40, "unsupported_width": 1},
    }:
        fail("CAN command table metadata must pin 0x00..0x57 and exclude 0x58+")
    if command_map.get("write_policy") != {
        "acceptance_claim": False,
        "delivery_claim": False,
        "enabled": False,
        "safety": "unsafe",
    } or command_map.get("profile_boundary") != {
        "active_m152": False,
        "labels": "noncanonical_profile_qualified_candidates",
        "profile_b_write_mapping": False,
    }:
        fail("CAN write denial changed")


def parse_envelope(frame_hex: str, table: list[int], name: str) -> bytes:
    try:
        frame = bytes.fromhex(frame_hex)
    except ValueError as error:
        fail(f"{name}: invalid frame hex: {error}")
    if len(frame) < 19:
        fail(f"{name}: envelope is shorter than 19 bytes")
    if frame[:2] != b"\x7e\x7e":
        fail(f"{name}: envelope has invalid sync")
    payload_length = int.from_bytes(frame[16:18], "big")
    if payload_length > 0x05D1:
        fail(f"{name}: envelope payload is too long")
    if len(frame) != payload_length + 19:
        fail(f"{name}: envelope length does not match payload length")
    checksum = 0
    for value in frame[2:-1]:
        checksum = table[checksum ^ value]
    if checksum != frame[-1]:
        fail(f"{name}: envelope checksum mismatch")
    return frame[18:-1]


def parse_q(payload: bytes, name: str) -> dict[str, object]:
    if len(payload) < 4 or payload[0] != 0x51:
        fail(f"{name}: Q payload structure changed")
    field0, base_id, count = payload[1:4]
    if len(payload) != 4 + count:
        fail(f"{name}: Q item span changed")
    return {
        "field0": field0,
        "base_id": base_id,
        "items": [
            {"id": f"0x{base_id + index:02x}", "value_hex": f"{value:02x}"}
            for index, value in enumerate(payload[4:])
        ],
    }


def parse_r(payload: bytes, name: str) -> dict[str, object]:
    if len(payload) < 3 or payload[0] != 0x52:
        fail(f"{name}: R payload structure changed")
    field0, count = payload[1:3]
    offset = 3
    entries: list[dict[str, str]] = []
    for _ in range(count):
        if offset + 2 > len(payload):
            fail(f"{name}: R entry header is incomplete")
        entry_id, length = payload[offset : offset + 2]
        offset += 2
        if offset + length > len(payload):
            fail(f"{name}: R entry data is incomplete")
        entries.append({"id": f"0x{entry_id:02x}", "data_hex": payload[offset : offset + length].hex()})
        offset += length
    if offset != len(payload):
        fail(f"{name}: R payload has unclaimed bytes")
    return {"field0": field0, "entries": entries}


def check_profile_b_q(vector: dict[str, object], payload: bytes) -> None:
    name = vector["name"]
    expected = vector["expected"]
    if set(vector) != PROFILE_B_VECTOR_FIELDS:
        fail("Profile-B Q vector fields changed")
    if set(expected) != PROFILE_B_Q_EXPECTED_FIELDS:
        fail("Profile-B Q expected fields changed")
    parsed = parse_q(payload, name)
    if vector["profile"] != "B" or vector["direction"] != "peer_to_controller":
        fail("Profile-B Q vector profile or direction changed")
    if vector["payload_hex"] != payload.hex() or expected["envelope"] != "valid":
        fail("Profile-B Q vector payload or envelope changed")
    if expected["type"] != "Q" or expected["semantic_projection"] != "none":
        fail("Profile-B Q projection changed")
    if expected["two_byte_consumption"] or not expected["preserve_each_item"]:
        fail("Profile-B Q preservation changed")
    if not expected["no_combine"] or not expected["no_drop"]:
        fail("Profile-B Q combination or drop rule changed")
    if expected["outcome"] != "reply" or expected["reply_payload_hex"] != "51" or not expected["no_mutation"]:
        fail("Profile-B Q outcome changed")
    if parsed["field0"] != 0 or parsed["base_id"] != 0x10 or parsed["items"] != expected["opaque_vector_items"]:
        fail("Profile-B Q item sequence changed")
    if len(parsed["items"]) != 2 or len({item["id"] for item in parsed["items"]}) != 2:
        fail("Profile-B Q item preservation changed")


def check_profile_b_r(vector: dict[str, object], payload: bytes) -> None:
    name = vector["name"]
    expected = vector["expected"]
    if set(vector) != PROFILE_B_VECTOR_FIELDS:
        fail("Profile-B R vector fields changed")
    if set(expected) != PROFILE_B_R_EXPECTED_FIELDS:
        fail("Profile-B R expected fields changed")
    parsed = parse_r(payload, name)
    if vector["profile"] != "B" or vector["direction"] != "peer_to_controller":
        fail("Profile-B R vector profile or direction changed")
    if vector["payload_hex"] != payload.hex() or expected["envelope"] != "valid":
        fail("Profile-B R vector payload or envelope changed")
    if expected["type"] != "R" or expected["semantic_projection"] != "none":
        fail("Profile-B R projection changed")
    if not expected["preserve_each_entry"] or not expected["no_drop"] or not expected["no_mutation"]:
        fail("Profile-B R preservation changed")
    if expected["outcome"] != "reply" or expected["reply_payload_hex"] != "52":
        fail("Profile-B R outcome changed")
    if parsed["field0"] != 0 or parsed["entries"] != expected["opaque_entries"]:
        fail("Profile-B R entry sequence changed")
    if len(parsed["entries"]) != 1 or parsed["entries"][0]["data_hex"] != "aa":
        fail("Profile-B R entry preservation changed")


def check_profile_a_short_r(vector: dict[str, object], payload: bytes) -> None:
    name = vector["name"]
    expected = vector["expected"]
    if set(vector) != PROFILE_A_SHORT_R_FIELDS:
        fail("short Profile-A R vector fields changed")
    if set(expected) != PROFILE_A_SHORT_R_EXPECTED_FIELDS:
        fail("short Profile-A R expected fields changed")
    parsed = parse_r(payload, name)
    if vector["profile"] != "A" or vector["direction"] != "peer_to_controller":
        fail("short Profile-A R vector profile or direction changed")
    if vector["payload_hex"] != payload.hex():
        fail("short Profile-A R payload semantics changed")
    if expected.get("envelope") != "valid":
        fail("short Profile-A R envelope semantics changed")
    if parsed != {"field0": 0, "entries": [{"id": "0x10", "data_hex": "aa"}]}:
        fail("short Profile-A R vector entries changed")
    if expected.get("outcome") != "no_reply":
        fail("short Profile-A R outcome changed")
    if expected.get("reason") != "payload_structural_error":
        fail("short Profile-A R reason changed")
    if expected.get("reply") != "none":
        fail("short Profile-A R reply changed")
    if expected.get("no_mutation") is not True:
        fail("short Profile-A R mutation policy changed")
    if expected.get("rejection_stage") != "profile_a_typed_value":
        fail("short Profile-A R rejection stage changed")
    if len(parsed["entries"][0]["data_hex"]) != 2:
        fail("short Profile-A R must reach typed-width validation")


def check_uart(uart: dict[str, object], vectors: dict[str, object]) -> None:
    checksum_contract = dict(uart["checksum"])
    table_values = checksum_contract.pop("table", None)
    if checksum_contract != {
        "algorithm": "table_fold",
        "coverage": "frame[0x02 : 0x12 + payload_length]",
        "initial": "0x00",
        "step": "c = table[c XOR byte]",
    }:
        fail("UART checksum recurrence contract changed")
    if not isinstance(table_values, list) or len(table_values) != 256 or any(
        not isinstance(value, str) or not re.fullmatch(r"0x[0-9a-f]{2}", value) for value in table_values
    ):
        fail("UART checksum table must contain exactly 256 entries")
    table = [int(value, 16) for value in table_values]
    if tuple(table) != EXPECTED_CHECKSUM_TABLE:
        index = next(index for index, value in enumerate(table) if value != EXPECTED_CHECKSUM_TABLE[index])
        fail(
            f"UART checksum table entry 0x{index:02x} changed: "
            f"expected 0x{EXPECTED_CHECKSUM_TABLE[index]:02x}, got 0x{table[index]:02x}"
        )
    if len(set(table)) != 256:
        fail("UART checksum table must be a complete byte permutation")
    if uart.get("property_policy") != {
        "labels": "profile_qualified_candidates",
        "numeric_ids_authoritative": True,
        "runtime_validation_required": True,
        "unknown_fields": "opaque",
    } or uart.get("parser_gates", {}).get("no_mutation_on_reject") is not True:
        fail("UART unknown-field policy must remain opaque and fail-closed")
    if uart["write_policy"] != {
        "enabled": False,
        "encodings": "documentation_only",
        "profile_b_mapping": False,
        "safety": "unsafe",
    }:
        fail("UART write denial changed")
    q = uart["payload_types"]["Q"]
    r = uart["payload_types"]["R"]
    u = uart["payload_types"]["U"]
    expected_q = ["0x10", "0x12", "0x14", "0x16", "0x18", "0x1a"]
    expected_r = [*expected_q, "0x42", "0x4b"]
    if q["profile_a_typed_values"]["two_byte_big_endian_ids"] != expected_q:
        fail("Profile-A Q typed IDs changed")
    if r["profile_a_typed_values"]["two_byte_big_endian_ids"] != expected_r:
        fail("Profile-A R typed IDs changed")
    if q["profile_b_values"] != {
        "catalog_width_is_not_parser_width": True,
        "semantic_projection": "none",
        "two_byte_consumption": "forbidden",
        "value_handling": "preserve_each_vector_byte_opaque",
    } or r["profile_b_values"] != {
        "catalog_width_is_not_parser_width": True,
        "semantic_projection": "none",
        "value_handling": "preserve_declared_entry_data_opaque",
    }:
        fail("Profile-B Q/R fail-closed boundary changed")
    if r.get("unknown_ids") != "preserve_opaque":
        fail("Profile-B R unknown IDs must remain opaque")
    if u["profile_a_request"] != "55000057" or u["profile_b_request"] != "5500005b" or u["count_semantics"] != "byte_count":
        fail("Profile-B U state-bank handling changed")

    if vectors.get("schema") != "gree.vrf.uart.normative-vectors":
        fail("UART normative vector schema identifier changed")
    if vectors.get("schema_version") != 1:
        fail("UART normative vector schema version changed")
    if set(vectors) != {"header_segments", "invalid_frames", "payload_only_vectors", "schema", "schema_version", "segmentation_vectors", "valid_frames"}:
        fail("UART vector document fields changed")
    for group, expected_names in EXPECTED_VECTOR_INVENTORY.items():
        if tuple(vector.get("name") for vector in vectors[group]) != expected_names:
            fail(f"UART {group} vector inventory or order changed")

    valid = {vector["name"]: vector for vector in vectors["valid_frames"]}
    for vector in vectors["valid_frames"]:
        payload = parse_envelope(vector["frame_hex"], table, vector["name"])
        if vector.get("payload_hex") != payload.hex():
            fail(f"{vector['name']}: payload does not match envelope")
    invalid = {vector["name"]: vector for vector in vectors["invalid_frames"]}
    profile_b_qr_count = 0
    for vector in (*vectors["valid_frames"], *vectors["invalid_frames"]):
        if vector.get("profile") != "B" or not isinstance(vector.get("payload_hex"), str):
            continue
        payload = parse_envelope(vector["frame_hex"], table, vector["name"])
        if payload[:1] == b"\x51":
            check_profile_b_q(vector, payload)
            profile_b_qr_count += 1
        elif payload[:1] == b"\x52":
            check_profile_b_r(vector, payload)
            profile_b_qr_count += 1
    if profile_b_qr_count != 2:
        fail("Profile-B Q/R vector coverage changed")

    short_r = invalid["r_profile_a_typed_value_short_data"]
    check_profile_a_short_r(short_r, parse_envelope(short_r["frame_hex"], table, short_r["name"]))


def validate(root: Path) -> None:
    if not root.is_dir():
        fail(f"root does not exist: {root}")
    root = root.resolve()
    paths = public_files(root)
    check_license(root)
    check_text(paths, root)
    check_markdown_contracts(root)
    check_links(paths, root)
    documents = {
        path.relative_to(root).as_posix(): load_json(path, root)
        for path in paths
        if path.suffix == ".json"
    }
    uart = documents["gree-vrf-uart.json"]
    check_can(documents["gree-vrf-can-profile.json"], documents["gree-vrf-command-map.json"], uart)
    check_uart(uart, documents["gree-vrf-uart-vectors.json"])


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=DEFAULT_ROOT)
    args = parser.parse_args()
    try:
        validate(args.root)
    except AssertionError as error:
        print(f"validation failed: {error}", file=sys.stderr)
        return 1
    print("validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
