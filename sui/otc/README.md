# Blast OTC

Fixed-price coin swaps between two parties. A maker escrows a `Coin<Offered>`
in a shared `Offer<Offered, Wanted>` and names the `Wanted` amount that buys all
of it. `Offered` and `Wanted` must be different coin types, compared by their
original package IDs. When creating the offer, the maker chooses:

- **Counterparty:** anyone, or one named taker address.
- **Fills:** all-or-nothing, or partial fills at the same fixed rate.

```move
// Maker: escrow and share.
let offer = blast_fun_otc::new<Offered, Wanted>(offered, wanted_amount, taker, partial_fills, ctx);
offer.share();

// Taker: buy `amount`, paying the maker from `payment`.
let bought = offer.take(amount, &mut payment, ctx);

// Maker: delete the offer and recover what is left.
let remainder = offer.cancel(ctx);
```

Each fill costs `amount * wanted_amount / offered_amount`, rounded up for the
maker. A full take costs exactly `wanted_amount`. A partial fill never pays
below the rate, so across several fills the maker can receive up to one extra
unit per fill. Payment goes straight to the maker; the bought coins return to
the taker. The rate, maker, and counterparty never change. Only the maker can
cancel.

Events carry no sender field: the sender of `OfferCreated` is the maker, and
the sender of `OfferTaken` is the taker.

A coin whose issuer keeps a deny list can block a fill: `take` fails while the
maker is denied `Wanted`, and a global pause on `Offered` blocks both `take`
and `cancel` until it lifts.

The package has no fees or expiry and depends only on the Sui framework. Use
`scripts/check_coverage.sh` for the package coverage gate.

## Publication

Publish and call `sui::package::make_immutable` on the returned `UpgradeCap`
in the same transaction, then record the digest. Until the cap is consumed,
its holder could upgrade the module and reach every offer's escrow. Once it is
consumed, no one can change the code, and only each offer's maker can cancel
it.
