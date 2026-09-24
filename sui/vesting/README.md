# Blast vesting

This independent, framework-only package provides fully funded,
fixed-beneficiary linear and bounded-checkpoint schedules. Claims are
permissionless and cannot redirect payouts; cancellable schedules return only
unvested value to their fixed refund recipient.

The design is recorded in
[ADR 0052](../../docs/decisions/0052-stepped-linear-vesting.md) and
[ADR 0055](../../docs/decisions/0055-global-vesting-package-and-checkpoints.md);
[`vesting.json`](../../docs/vectors/vesting.json) fixes the chain-neutral
arithmetic boundaries. Use `scripts/check_coverage.sh` for the package coverage
gate. Source and tests own the current API, errors, events, and schedule
behavior.

Events carry no sender field; indexers read the sender from the transaction
and join later events to `VestingCreated` by `vesting_id`.

A coin whose issuer keeps a deny list can stall a schedule. While the
beneficiary is denied, claims fail, and so does cancellation whenever vested
value is owed. While the refund recipient is denied, cancellation fails until
nothing is left to refund.

## Mainnet gate

Before making vesting immutable on mainnet, create irrevocable and cancellable
schedules with the full 256-checkpoint vector. Decode the complete vectors,
exercise first, middle, and final claims plus cancellation and closure, and
record transaction digests, gas, serialized object size, and the absence of
checkpoint dynamic fields.
