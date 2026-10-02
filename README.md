# Blast util contracts

Standalone Sui Move packages that Blast composes with in transactions. None of
them imports the Blast launchpad, and the launchpad imports none of them.

[`sui/merkle/`](sui/merkle/) (`blast_fun_merkle`), the Merkle proof check the
presale and migrators packages share, is not yet published; the table below
lists the published packages.

## Mainnet

All three packages are published on Sui mainnet and are **immutable**: each
package's `UpgradeCap` was consumed by `0x2::package::make_immutable`, so no
one, including the deployer, can upgrade or change them.

| Package | Named address | Path | Mainnet package ID |
| --- | --- | --- | --- |
| OTC | `blast_fun_otc` | [`sui/otc/`](sui/otc/) | [`0x40e0c95f73af329e7a6a8eafee9d152a1f3090736d35052842288232f7eb5968`](https://suiscan.xyz/mainnet/object/0x40e0c95f73af329e7a6a8eafee9d152a1f3090736d35052842288232f7eb5968) |
| Vesting | `blast_fun_vesting` | [`sui/vesting/`](sui/vesting/) | [`0x85fdb7e3d28162b99e0df758069a3d23cff874c400b2160fc0d4618aefd3ec5c`](https://suiscan.xyz/mainnet/object/0x85fdb7e3d28162b99e0df758069a3d23cff874c400b2160fc0d4618aefd3ec5c) |
| Timelock | `blast_fun_timelock` | [`sui/timelock/`](sui/timelock/) | [`0x1749b76a3ae065dedfe847578b07826fa83d1e18ff485d9e4f9647f3698e104d`](https://suiscan.xyz/mainnet/object/0x1749b76a3ae065dedfe847578b07826fa83d1e18ff485d9e4f9647f3698e104d) |

OTC and vesting were built from commit `8600b8f` with Sui CLI `1.77.2` and published by
`0x52ecee5e58e2f3a7461cc604f4efcc3b68031e4715456d821e3a2719b0593600`.
Timelock was built from commit `96e9d25` with the same CLI and deployer.

### Proof of immutability

**OTC** was published and frozen in one transaction,
[`B2K4fgF5ABbYiTytg6Q8iTGxyfvTZuvL9WXWK3DBehoE`](https://suiscan.xyz/mainnet/tx/B2K4fgF5ABbYiTytg6Q8iTGxyfvTZuvL9WXWK3DBehoE).
Its programmable transaction has exactly two commands: `Publish`, then
`0x2::package::make_immutable(Result(0))`. `Result(0)` is the `UpgradeCap` that
`Publish` returns, so the cap was destroyed before the transaction ended and
never existed as an object.

**Vesting** was published in
[`Bcm7Npd9CEnC8NWvYkTwBk7ZdxhaDn8azvvANyU3aBeV`](https://suiscan.xyz/mainnet/tx/Bcm7Npd9CEnC8NWvYkTwBk7ZdxhaDn8azvvANyU3aBeV)
with `UpgradeCap`
`0xa4140133b2a6972824b83899398d63ddcc03ca0c4eea40f0c0e82cf4e4ab28e3`. It then
passed the ADR 0055 mainnet gate: 256-checkpoint irrevocable and cancellable
schedules were created, decoded, claimed at their first, middle, and final
checkpoints, canceled, and closed. Finally,
[`3wvDSfNADFGP9SvxWPuiBGvdYMvzf7BabUBpGWKD1FWu`](https://suiscan.xyz/mainnet/tx/3wvDSfNADFGP9SvxWPuiBGvdYMvzf7BabUBpGWKD1FWu)
called `0x2::package::make_immutable` on that cap while the package was still at
version 1, deleting the cap.

**Timelock** was published and frozen in one transaction,
[`FQhZPuNDEzBENZhvRuCW5oYme9KAeYKZtnaGBF2yR7oZ`](https://suiscan.xyz/mainnet/tx/FQhZPuNDEzBENZhvRuCW5oYme9KAeYKZtnaGBF2yR7oZ).
Its programmable transaction has exactly two commands: `Publish`, then
`0x2::package::make_immutable(Result(0))`. The only created object is the
immutable package, so no `UpgradeCap` survived publication.

An earlier immutable package,
[`0x7e17a8d6c068ccdfb7e8a0c222da363d9c9dcf9fcda97befa3352a7b54ff2f29`](https://suiscan.xyz/mainnet/object/0x7e17a8d6c068ccdfb7e8a0c222da363d9c9dcf9fcda97befa3352a7b54ff2f29),
is superseded because it imposed a ten-year maximum delay. It remains on-chain
and immutable, but new integrations must use the package listed above, which
accepts every positive `u64` delay.

Check it yourself:

```bash
# OTC: the command list is Publish, then make_immutable(Result(0))
sui client tx-block B2K4fgF5ABbYiTytg6Q8iTGxyfvTZuvL9WXWK3DBehoE
```

```bash
# Vesting: the transaction deletes the package's UpgradeCap
sui client tx-block 3wvDSfNADFGP9SvxWPuiBGvdYMvzf7BabUBpGWKD1FWu
```

```bash
# Vesting: the UpgradeCap no longer exists ("not found")
sui client object 0xa4140133b2a6972824b83899398d63ddcc03ca0c4eea40f0c0e82cf4e4ab28e3
```

```bash
# Timelock: the command list is Publish, then make_immutable(Result(0))
sui client tx-block FQhZPuNDEzBENZhvRuCW5oYme9KAeYKZtnaGBF2yR7oZ
```

The on-chain bytecode matches this repository's source at the publish commit.
The `#[error]` abort codes encode source line numbers, and later style cleanups
moved lines without changing behaviour, so verify at `e1a7c62`:

```bash
git checkout e1a7c62
```

```bash
sui client verify-source sui/otc
```

```bash
sui client verify-source sui/vesting
```

Timelock's on-chain bytecode was verified against source commit `96e9d25`
after adding its publication metadata:

```bash
sui client verify-source sui/timelock
```

The deployment records for [OTC and vesting](deployments/sui/mainnet/2026-09-24-otc-and-vesting.json),
the [superseded timelock](deployments/sui/mainnet/2026-09-26-timelock.json), and
the [canonical timelock](deployments/sui/mainnet/2026-09-26-timelock-unbounded-delay.json)
list every transaction, gas cost, and release-gate result.

## Use as a dependency

Add the packages you need to your `Move.toml`, pinned to a commit that contains
their `Published.toml` files:

```toml
[dependencies]
blast_fun_otc = { git = "https://github.com/interest-protocol/blast-util-contracts.git", subdir = "sui/otc", rev = "e1a7c62d4d13eba1f6cd68b0ea05f159c4c87af9" }
blast_fun_vesting = { git = "https://github.com/interest-protocol/blast-util-contracts.git", subdir = "sui/vesting", rev = "e1a7c62d4d13eba1f6cd68b0ea05f159c4c87af9" }
blast_fun_timelock = { git = "https://github.com/interest-protocol/blast-util-contracts.git", subdir = "sui/timelock", rev = "c6c428b3b3205fbc65a515eb5e59ad1f2953cdc7" }
```

Each package's `Published.toml` records its mainnet ID, so a mainnet build or
publish (`sui move build -e mainnet`, `sui client publish`) links your package
to the deployed, immutable code instead of publishing a copy. Import the
modules by their named addresses:

```move
use blast_fun_otc::blast_fun_otc::{Self, Offer};
use blast_fun_vesting::blast_fun_linear_vesting;
use blast_fun_vesting::blast_fun_checkpoint_vesting;
use blast_fun_timelock::blast_fun_timelock::{Self, Timelocked};
```

Programmable transactions and SDKs call the package IDs directly, for example
`0x40e0c95f73af329e7a6a8eafee9d152a1f3090736d35052842288232f7eb5968::blast_fun_otc::new`
or
`0x85fdb7e3d28162b99e0df758069a3d23cff874c400b2160fc0d4618aefd3ec5c::blast_fun_linear_vesting::new_irrevocable`.

## TypeScript SDK

[`sdk/`](sdk/) is `@interest-protocol/blast-util-sdk`: transaction builders,
state reads, event decoders, and replay reducers for both packages, with their
mainnet IDs built in. Its tests check every builder and decoder against the
frozen ABI of the deployed code. See the [SDK README](sdk/README.md).

## Development

Each package has its own manifest and lockfile and builds with the pinned Sui
CLI (`mainnet-v1.77.2`):

```bash
sui move test --path sui/vesting
```

```bash
bash sui/vesting/scripts/check_coverage.sh
```

```bash
sui move test --path sui/otc
```

```bash
bash sui/otc/scripts/check_coverage.sh
```

```bash
sui move test --path sui/timelock
```

```bash
bash sui/timelock/scripts/check_coverage.sh
```

```bash
sui move test --path sui/merkle
```

```bash
bash sui/merkle/scripts/check_coverage.sh
```

Design records live in [`docs/decisions/`](docs/decisions/). Their numbers
continue the Blast V2 contracts decision log they were written in.

Licensed under the [MIT License](LICENSE).
