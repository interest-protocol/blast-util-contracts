# Blast Merkle

Positional Blake2b-256 Merkle proofs that do not care what a leaf commits to.
The caller hashes its own leaf, so each application keeps its own leaf encoding
and domain.

```move
// Your module hashes the leaf under its own domain; never start it with 0x01.
let digest = my_leaf(index, wallet, amount);
assert!(blast_fun_merkle::verify(root, digest, index, leaf_count, &proof), EInvalidProof);
```

An internal node is `blake2b256(0x01 || left || right)`. Start every leaf
preimage with any other byte so a node can never pass as a leaf. An odd node at
any level pairs with itself, so a proof over `leaves` leaves has exactly one
sibling per level, ordered from the leaf up.

`verify` returns `false`, without hashing, for a root or digest that is not
`digest_length()` (32) bytes, an empty tree, an index outside the tree, a proof
of the wrong depth, or a sibling that is not 32 bytes. It never aborts.

The package holds no objects and depends only on the Sui framework. Use
`scripts/check_coverage.sh` for the package coverage gate.

## Mainnet

Not yet published.
