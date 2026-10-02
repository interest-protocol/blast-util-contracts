// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Jose Manuel Vasconcelos Cerqueira

#[test_only]
module blast_fun_merkle::blast_fun_merkle_tests;

// === Tests ===

#[test]
fun a_single_leaf_is_its_own_root_with_an_empty_proof() {
    let leaf = digest(b"a");

    assert!(merkle::verify(leaf, leaf, 0, 1, &vector[]));
    assert!(!merkle::verify(leaf, digest(b"b"), 0, 1, &vector[]));
}

#[test]
fun proofs_are_positional() {
    let (left, right) = (digest(b"left"), digest(b"right"));
    let root = merkle::node(left, right);

    assert!(merkle::verify(root, left, 0, 2, &vector[right]));
    assert!(merkle::verify(root, right, 1, 2, &vector[left]));
    assert!(!merkle::verify(root, right, 0, 2, &vector[left]));
    assert!(root != merkle::node(right, left));
}

#[test]
fun an_odd_node_pairs_with_itself() {
    let (a, b, c) = (digest(b"a"), digest(b"b"), digest(b"c"));
    let (ab, cc) = (merkle::node(a, b), merkle::node(c, c));
    let root = merkle::node(ab, cc);

    assert!(merkle::verify(root, a, 0, 3, &vector[b, cc]));
    assert!(merkle::verify(root, b, 1, 3, &vector[a, cc]));
    assert!(merkle::verify(root, c, 2, 3, &vector[c, ab]));
}

#[test]
fun malformed_digests_and_out_of_tree_indexes_are_rejected() {
    let (left, right) = (digest(b"left"), digest(b"right"));
    let root = merkle::node(left, right);

    assert!(!merkle::verify(vector[0], left, 0, 2, &vector[right]));
    assert!(!merkle::verify(root, vector[0], 0, 2, &vector[right]));
    assert!(!merkle::verify(root, left, 0, 0, &vector[right]));
    assert!(!merkle::verify(root, right, 2, 2, &vector[left]));
}

#[test]
fun proofs_of_the_wrong_depth_or_sibling_length_are_rejected() {
    let leaf = digest(b"a");

    assert!(!merkle::verify(leaf, leaf, 0, 2, &vector[]));
    assert!(!merkle::verify(leaf, leaf, 0, 2, &vector[vector[1u8]]));
    assert!(!merkle::verify(leaf, leaf, 0, 1, &vector[leaf]));
}

#[test]
fun digests_are_thirty_two_bytes() {
    assert_eq!(merkle::digest_length(), 32);
    assert_eq!(merkle::node(digest(b"a"), digest(b"b")).length(), merkle::digest_length());
}

// === Test Helpers ===

fun digest(bytes: vector<u8>): vector<u8> {
    hash::blake2b256(&bytes)
}

// === Imports ===

use blast_fun_merkle::blast_fun_merkle as merkle;

use std::unit_test::assert_eq;

use sui::hash;
