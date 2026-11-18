# BeerJSON format

## Which format

BeerJSON.jl implements BeerJSON format **1.0.1**: its types are generated from the schemas of
tag `v1.0.1` of [beerjson/beerjson](https://github.com/beerjson/beerjson), and its test samples
are copies of the `tests/` of that tag.

Upstream has since published format **3.0**, with the schemas in JSON Schema 2020-12, a
description for every property, and some types closed to unknown keys (see its
[CHANGELOG](https://github.com/beerjson/beerjson/blob/main/CHANGELOG.md)). Its `main` branch is
still changing, so BeerJSON.jl stays on 1.0.1 for now; updating is planned once upstream
settles.

## Clarifications that also apply to 1.0.1

Format 1.0.1 left these implicit; upstream has since made them explicit, and they hold for
1.0.1 documents too.

* `TimingType.time` is measured from a reference that depends on `use`: forward from the
  start of the step for `add_to_mash`, `add_to_fermentation` and `add_to_package`, and
  backward from the end of the boil for `add_to_boil`. So a boil addition at 60 min boils
  for 60 minutes ([beerjson/beerjson#220](https://github.com/beerjson/beerjson/issues/220)).
* For a boil addition, `duration` is how long it steeps after the boil (a hop stand), not how
  long it boils ([beerjson/beerjson#266](https://github.com/beerjson/beerjson/issues/266)).

## Known errors in the bundled samples

The samples in `test/samples/` are copied verbatim from upstream `v1.0.1`, errors included, so
that the round-trip tests stay faithful to them. Some are fixed on upstream `main`.

* Some `yield.potential` values are in gravity points but labelled `sg` (e.g. `1038` for
  1.038), in `real/`: `BrettDosedKegsSaison`, `KettleSour`, `MedievalAle`,
  `SourFruitedCopitch`, `SourMash` and `SpargeAcidification`.
* `converted/punk-ipa-2010-current.json` gives its dry hops as boil additions of 10080
  minutes, and the hop additions of the converted samples carry a leftover BeerXML property
  `use` (shown under `_extra`). Both are fixed upstream
  ([beerjson/beerjson#268](https://github.com/beerjson/beerjson/issues/268)).
* Strings in `converted/Kolsh.json` and `converted/GenericOneHF.json` contain HTML entities
  (`"Lloyd&#39;s"`, `"K&#246;lsch"`).
