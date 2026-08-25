# helianthus-docs-canbus Contributor Guide

## Purpose and Ownership

This repository is the canonical public documentation home for generic CAN
transport and CAN product/profile contracts. It owns implementation-neutral
contracts, safety boundaries, conformance guidance, and publishable supporting
material. It does not own transport I/O, registry implementation, consumer
semantics, universal cross-protocol semantics, or live-device control.

Keep generic CAN transport separate from product profiles. Preserve native
facts and explicit projection loss; distinguish candidate, qualified,
unsupported, and unknown claims. Receive-only remains default-denied for
transmit, probing, configuration, acknowledgment, and live bus actions.

## Documentation Routing

This repository is the public CAN documentation destination:
https://github.com/Project-Helianthus/helianthus-docs-canbus. Gree VRF CAN
protocol material is canonical under `protocols/gree/`; UART remains a
separate protocol surface and MUST NOT be conflated with CAN.

## Workflow

- Use one scoped issue, one `issue/<id>-<slug>` branch from current `main`, and
  one linked PR. Do not modify another contributor's branch.
- Publish only material supported by public URLs; label hypotheses and unknowns
  clearly and do not include credentials, local paths, captures, or lab data.
- Before push, run `./scripts/check_docs.sh` and `./scripts/test_docs_gate.sh`.
- Record applicable documentation, transport, conformance, and smoke gates in
  the PR; T01..T88 applies only to its transport-owner repository.
- Resolve P0-P2 findings and obtain a fresh exact-HEAD no-blocker review.
- Squash merge only after all applicable checks and gates are green. Do not
  merge during implementation work unless the operator explicitly requests it.

Do not add plan hashes, authority tokens, attestations, or executable workflow
state.
