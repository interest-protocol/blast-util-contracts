// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Jose Manuel Vasconcelos Cerqueira

#[test_only]
module blast_fun_timelock::blast_fun_timelock_tests;

// === Constants ===

const DELAY_MS: u64 = 7 * 24 * 60 * 60 * 1_000;
const START_MS: u64 = 1_000;

// === Tests ===

#[test]
fun a_new_value_is_in_force_at_once_with_nothing_scheduled() {
    let (ctx, clock) = start();
    let locked = timelock::new(5u64, DELAY_MS);

    assert_eq!(locked.value(&clock), 5);
    assert_eq!(locked.scheduled(), 5);
    assert_eq!(vector[locked.scheduled_at_ms(), locked.delay_ms()], vector[0, DELAY_MS]);

    end(ctx, clock);
}

#[test]
/// One millisecond before the delay ends the old value is in force; at the end the new one is.
fun a_scheduled_value_takes_effect_exactly_after_the_delay() {
    let (ctx, mut clock) = start();
    let mut locked = timelock::new(5u64, DELAY_MS);

    locked.schedule(9, &clock);

    assert_eq!(vector[locked.scheduled(), locked.scheduled_at_ms()], vector[9, START_MS + DELAY_MS]);
    clock.set_for_testing(START_MS + DELAY_MS - 1);
    assert_eq!(locked.value(&clock), 5);
    clock.set_for_testing(START_MS + DELAY_MS);
    assert_eq!(locked.value(&clock), 9);

    end(ctx, clock);
}

#[test]
/// A new schedule keeps the value in force and restarts the delay.
fun a_new_schedule_replaces_a_pending_one_and_restarts_the_delay() {
    let (ctx, mut clock) = start();
    let mut locked = timelock::new(5u64, DELAY_MS);
    locked.schedule(9, &clock);
    clock.increment_for_testing(DELAY_MS - 1);

    locked.schedule(7, &clock);

    let rescheduled_at = clock.timestamp_ms();
    clock.set_for_testing(rescheduled_at + DELAY_MS - 1);
    assert_eq!(locked.value(&clock), 5);
    clock.set_for_testing(rescheduled_at + DELAY_MS);
    assert_eq!(locked.value(&clock), 7);

    end(ctx, clock);
}

#[test]
fun scheduling_the_value_in_force_cancels_a_pending_change() {
    let (ctx, mut clock) = start();
    let mut locked = timelock::new(5u64, DELAY_MS);
    locked.schedule(9, &clock);

    locked.schedule(5, &clock);

    clock.increment_for_testing(10 * DELAY_MS);
    assert_eq!(locked.value(&clock), 5);

    end(ctx, clock);
}

#[test]
/// Once a change has taken effect, the next schedule starts from it.
fun a_schedule_after_the_switch_starts_from_the_new_value() {
    let (ctx, mut clock) = start();
    let mut locked = timelock::new(5u64, DELAY_MS);
    locked.schedule(9, &clock);
    clock.increment_for_testing(DELAY_MS);

    locked.schedule(3, &clock);

    assert_eq!(locked.value(&clock), 9);
    clock.increment_for_testing(DELAY_MS);
    assert_eq!(locked.value(&clock), 3);

    end(ctx, clock);
}

#[test]
fun the_shortest_and_longest_delays_are_accepted() {
    let (ctx, mut clock) = start();
    let mut shortest = timelock::new(@0xA, 1);
    let longest = timelock::new(@0xA, timelock::max_delay_ms_for_testing());

    shortest.schedule(@0xB, &clock);

    assert_eq!(shortest.value(&clock), @0xA);
    clock.increment_for_testing(1);
    assert_eq!(shortest.value(&clock), @0xB);
    assert_eq!(longest.delay_ms(), timelock::max_delay_ms_for_testing());

    end(ctx, clock);
}

#[test]
/// The test constructor builds a value mid-change, for dependents' own tests.
fun a_value_can_be_built_mid_change_for_tests() {
    let (ctx, mut clock) = start();
    let locked = timelock::new_scheduled_for_testing(5u64, 9, START_MS + 1, DELAY_MS);

    assert_eq!(locked.value(&clock), 5);
    clock.increment_for_testing(1);
    assert_eq!(locked.value(&clock), 9);

    end(ctx, clock);
}

#[test]
#[expected_failure(abort_code = timelock::EInvalidDelay, location = blast_fun_timelock::blast_fun_timelock)]
fun a_zero_delay_is_refused() {
    timelock::new(5u64, 0);
}

#[test]
#[expected_failure(abort_code = timelock::EInvalidDelay, location = blast_fun_timelock::blast_fun_timelock)]
fun a_delay_one_above_ten_years_is_refused() {
    timelock::new(5u64, timelock::max_delay_ms_for_testing() + 1);
}

// === Test Helpers ===

fun start(): (TxContext, Clock) {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);
    clock.set_for_testing(START_MS);

    (ctx, clock)
}

fun end(ctx: TxContext, clock: Clock) {
    clock.destroy_for_testing();
    destroy(ctx);
}

// === Imports ===

use blast_fun_timelock::blast_fun_timelock as timelock;

use std::unit_test::{assert_eq, destroy};

use sui::clock::{Self, Clock};
