// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Jose Manuel Vasconcelos Cerqueira

/// A value behind a timelock. Every change to a `Timelocked<T>` takes effect
/// exactly its `delay_ms` after it is scheduled, and the delay is fixed when the
/// value is created, so no caller can ask for a shorter one.
///
/// A module stores a `Timelocked` in its own object and decides who may call
/// `schedule` on it; everyone reads the value in force with `value`. The
/// guarantee holds as long as the storing module changes the value only
/// through `schedule`.
module blast_fun_timelock::blast_fun_timelock;

// === Constants ===

/// The longest delay a timelock may have: ten years, so a scheduled time never overflows.
const MAX_DELAY_MS: u64 = 10 * 365 * 24 * 60 * 60 * 1_000;

// === Public Types ===

/// A value that is `before` until `at_ms` and `after` from then on. Every
/// schedule sets `at_ms` to `delay_ms` after it.
public struct Timelocked<T: copy + drop + store> has copy, drop, store {
    before: T,
    after: T,
    at_ms: u64,
    delay_ms: u64,
}

// === Public Functions ===

/// A timelocked `value`, in force at once; every later change waits `delay_ms`.
public fun new<T: copy + drop + store>(value: T, delay_ms: u64): Timelocked<T> {
    assert!(delay_ms > 0 && delay_ms <= MAX_DELAY_MS, EInvalidDelay);

    Timelocked { before: value, after: value, at_ms: 0, delay_ms }
}

/// Schedules `value` to take effect `delay_ms` from now. The value in force now
/// stays in force until then; a new schedule replaces a pending one and
/// restarts the delay, so scheduling the value in force cancels a pending change.
public fun schedule<T: copy + drop + store>(self: &mut Timelocked<T>, value: T, clock: &Clock) {
    let now_ms = clock.timestamp_ms();

    self.before = self.value(clock);
    self.after = value;
    self.at_ms = now_ms + self.delay_ms;
}

/// The value in force at `clock`.
public fun value<T: copy + drop + store>(self: &Timelocked<T>, clock: &Clock): T {
    if (clock.timestamp_ms() >= self.at_ms) self.after else self.before
}

/// The value the latest schedule set, in force from `scheduled_at_ms`.
public fun scheduled<T: copy + drop + store>(self: &Timelocked<T>): T {
    self.after
}

/// When the latest scheduled value takes effect; zero if nothing was ever scheduled.
public fun scheduled_at_ms<T: copy + drop + store>(self: &Timelocked<T>): u64 {
    self.at_ms
}

/// The delay every change waits.
public fun delay_ms<T: copy + drop + store>(self: &Timelocked<T>): u64 {
    self.delay_ms
}

// === Test-Only Functions ===

#[test_only]
public fun max_delay_ms_for_testing(): u64 {
    MAX_DELAY_MS
}

#[test_only]
/// A value that is `before` until `at_ms` and `after` from then on, for dependents' own tests.
public fun new_scheduled_for_testing<T: copy + drop + store>(
    before: T,
    after: T,
    at_ms: u64,
    delay_ms: u64,
): Timelocked<T> {
    Timelocked { before, after, at_ms, delay_ms }
}

// === Errors ===

#[error(code = 0)]
const EInvalidDelay: vector<u8> = b"A timelock's delay must be positive and at most ten years.";

// === Imports ===

use sui::clock::Clock;
