# Blast util contracts

Standalone Sui Move packages that Blast composes with in transactions. None of
them imports the Blast launchpad, and the launchpad imports none of them.

## Mainnet

Both packages are published on Sui mainnet and are **immutable**: each
package's `UpgradeCap` was consumed by `0x2::package::make_immutable`, so no
one, including the deployer, can upgrade or change them.

| Package | Named address | Path | Mainnet package ID |
| --- | --- | --- | --- |
| OTC | `blast_fun_otc` | [`sui/otc/`](sui/otc/) | [`0x40e0c95f73af329e7a6a8eafee9d152a1f3090736d35052842288232f7eb5968`](https://suiscan.xyz/mainnet/object/0x40e0c95f73af329e7a6a8eafee9d152a1f3090736d35052842288232f7eb5968) |
| Vesting | `blast_fun_vesting` | [`sui/vesting/`](sui/vesting/) | [`0x85fdb7e3d28162b99e0df758069a3d23cff874c400b2160fc0d4618aefd3ec5c`](https://suiscan.xyz/mainnet/object/0x85fdb7e3d28162b99e0df758069a3d23cff874c400b2160fc0d4618aefd3ec5c) |

Both were built from commit `8600b8f` with Sui CLI `1.77.2` and published by
`0x52ecee5e58e2f3a7461cc604f4efcc3b68031e4715456d821e3a2719b0593600`.

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
# The on-chain bytecode matches this repository's source
sui client verify-source sui/otc
```

```bash
sui client verify-source sui/vesting
```

The [deployment record](deployments/sui/mainnet/2026-09-24-otc-and-vesting.json)
lists every transaction, gas cost, and piece of vesting gate evidence.

## Use as a dependency

Add the packages you need to your `Move.toml`, pinned to commit `e1a7c62`, which
adds the `Published.toml` files, or any later commit:

```toml
[dependencies]
blast_fun_otc = { git = "https://github.com/interest-protocol/blast-util-contracts.git", subdir = "sui/otc", rev = "e1a7c62d4d13eba1f6cd68b0ea05f159c4c87af9" }
blast_fun_vesting = { git = "https://github.com/interest-protocol/blast-util-contracts.git", subdir = "sui/vesting", rev = "e1a7c62d4d13eba1f6cd68b0ea05f159c4c87af9" }
```

Each package's `Published.toml` records its mainnet ID, so a mainnet build or
publish (`sui move build -e mainnet`, `sui client publish`) links your package
to the deployed, immutable code instead of publishing a copy. Import the
modules by their named addresses:

```move
use blast_fun_otc::blast_fun_otc::{Self, Offer};
use blast_fun_vesting::blast_fun_linear_vesting;
use blast_fun_vesting::blast_fun_checkpoint_vesting;
```

Programmable transactions and SDKs call the package IDs directly, for example
`0x40e0c95f73af329e7a6a8eafee9d152a1f3090736d35052842288232f7eb5968::blast_fun_otc::new`
or
`0x85fdb7e3d28162b99e0df758069a3d23cff874c400b2160fc0d4618aefd3ec5c::blast_fun_linear_vesting::new_irrevocable`.

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

Design records live in [`docs/decisions/`](docs/decisions/). Their numbers
continue the Blast V2 contracts decision log they were written in.

Licensed under the [MIT License](LICENSE).
