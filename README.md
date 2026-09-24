# Blast util contracts

Standalone Sui Move packages that Blast composes with in transactions. None of
them imports the Blast launchpad, and the launchpad imports none of them.

| Package | Path | Named address |
| --- | --- | --- |
| Vesting | [`sui/vesting/`](sui/vesting/) | `blast_fun_vesting` |
| OTC | [`sui/otc/`](sui/otc/) | `blast_fun_otc` |

Each package has its own manifest and lockfile and builds with the pinned Sui
CLI (`mainnet-v1.77.2`):

```bash
sui move test --path sui/vesting
bash sui/vesting/scripts/check_coverage.sh
sui move test --path sui/otc
bash sui/otc/scripts/check_coverage.sh
```

Design records live in [`docs/decisions/`](docs/decisions/). Their numbers
continue the Blast V2 contracts decision log they were written in.

Other packages depend on a pinned revision:

```toml
blast_fun_vesting = { git = "https://github.com/interest-protocol/blast-util-contracts.git", subdir = "sui/vesting", rev = "<commit>" }
```

Licensed under the [MIT License](LICENSE).
