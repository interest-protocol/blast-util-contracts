// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Jose Manuel Vasconcelos Cerqueira

/// Positional Blake2b-256 Merkle proofs, independent of what a leaf commits to.
///
/// An internal node hashes a `0x01` byte before its two children, so a caller that hashes its
/// leaves under any other first byte can never pass a node off as a leaf. An odd node at any level
/// pairs with itself, so a proof over `leaves` leaves always carries exactly one sibling per level.
module blast_fun_merkle::blast_fun_merkle;

// === Constants ===

const DIGEST_LENGTH: u64 = 32;

// === Public Functions ===

/// Hashes one ordered pair as an internal node.
public fun node(left: vector<u8>, right: vector<u8>): vector<u8> {
    let mut bytes = vector[1u8];
    bytes.append(left);
    bytes.append(right);

    hash::blake2b256(&bytes)
}

/// Whether `proof` places `digest` at `index` among `leaves` leaves under `root`. Rejects malformed
/// digests, an index outside the tree, and a proof of the wrong depth before hashing anything.
public fun verify(
    root: vector<u8>,
    mut digest: vector<u8>,
    mut index: u64,
    leaves: u64,
    proof: &vector<vector<u8>>,
): bool {
    if (
        root.length() != DIGEST_LENGTH
            || digest.length() != DIGEST_LENGTH
            || leaves == 0
            || index >= leaves
    ) return false;

    if (
        proof.length() != proof_depth(leaves)
            || !proof.all!(|sibling| sibling.length() == DIGEST_LENGTH)
    ) return false;

    proof.do_ref!(|sibling| {
        digest = if (index % 2 == 0) node(digest, *sibling) else node(*sibling, digest);
        index = index / 2;
    });

    digest == root
}

/// The byte length of every root, leaf digest, and proof sibling.
public fun digest_length(): u64 {
    DIGEST_LENGTH
}

// === Private Functions ===

/// The number of levels above `leaves` leaves, one sibling each in a proof.
fun proof_depth(leaves: u64): u64 {
    let mut width = leaves;
    let mut depth = 0;
    while (width > 1) {
        width = width.div_ceil(2);
        depth = depth + 1;
    };

    depth
}

// === Imports ===

use sui::hash;
