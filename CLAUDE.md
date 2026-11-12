# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Godot 4.4 (GDScript) project: "Self_study", a Balatro-inspired cooking roguelike deckbuilder. No build system, no test suite, no linter — development happens in the Godot editor. Run with `godot` (or the editor); main scene is `scences/MatchManager.tscn` (note: the folder is spelled `scences/`, not `scenes/`).

## Docs are the source of truth

The game rules are specified in `doc/`, and they are more authoritative than any code comment:
- `doc/GDD.md` — game rules, content spec (how to add ingredients/recipes/items), known tech debt list (§6), open questions (§9). Read §6 before touching scoring/matching code: it lists 14 unfixed bugs (e.g. `RiceAccumlator` hook is spelled `_on_play` so it never fires; `ShopManager.buy_item()` ignores the 5-item cap; target table out-of-bounds from stage 28).
- `doc/BALANCE.md` — all balance numbers (stage targets, shop prices, rarity weights, content tables).
- `doc/DECISIONS.md` — locked design decisions (D-01…D-10). Don't contradict them without flagging it.
- `doc/Change*.md` — changelogs; check the newest one (`Change1011.md`) for the latest refactors.

## Architecture

Layering, roughly top-down:

1. **Autoloads** (`scripts/autoloads/`, registered in `project.godot`): `IngredientDB`, `RecipeDB`, `ItemDB` (each scans its resource folder for `.tres` at startup), plus `GameManager` (currency, `player_deck` = owned cards, `active_items`), `StageManager` (stage progression, boss rolls, target scores), `ShopManager` (shop data only).
2. **Content resources**: `.tres` files under `resources/` typed by `scripts/resources/*.gd` — `IngredientData`/`IngredientInstance` (a "card" in the deck), `RecipeData`, `ItemData`/`ItemInstance`. Adding a new item = new `.tres` + a script in `scripts/items/` extending `ItemInstance` with hook overrides; the DBs pick it up automatically, no registration needed.
3. **System scripts** (`scripts/system/`), attached as child nodes of the main scene: `DeckManager` (shuffle/draw), `HandManager` (selection), `ScoringSystem` (auto recipe-matching + trigger pipeline), `MatchManager` (stage lifecycle, main scene script), `ShopUI` (UI-side logic for the shop scene).

### Key data flow

- **Recipe matching is automatic (decision D-01)**: the player only selects ≤5 ingredient cards; `ScoringSystem` greedily picks the highest-value unlocked recipe, consumes its ingredients, repeats; leftover ingredients score nothing.
- **Scoring pipeline**: each cooked dish emits a list of `TriggerResult`s (`scripts/resources/TriggerResult.gd`). Final = `(Σ score) × final_mult`, where additive triggers (`x_mult=false`) add to mult and multiplicative ones (`x_mult=true`) multiply it.
- **Items (Jokers) hook into the pipeline** via overridable methods on `ItemInstance`: `on_stage_start`, `on_play` (currently disconnected), `on_ingredient_scored`, `on_recipe_scored`, `after_match`. Bosses are items with `is_boss = true`, equipped temporarily by `MatchManager` on every 3rd stage and do NOT count toward the 5-item cap (D-10).
- **Run loop**: stage → 4 plays + 3 discards → win if score ≥ target → shop (`ShopScence.tscn` with `scripts/system/ShopUI.gd` data driven by `ShopManager` autoload) → next stage. Discarded cards are not reused within the stage (D-02).

## Conventions & constraints

- **Design pillar P4 (from GDD)**: new items/recipes must not require editing `ScoringSystem` or `MatchManager`. New effects go into `MatchManager.effect_handlers` — the single place effects are registered.
- **Recent refactor (Change1011)**: shop logic was split — `ShopManager` (autoload, `scripts/autoloads/`) handles data; `ShopUI` (`scripts/system/ShopUI.gd`, the old `scripts/system/ShopManager.gd`) is the scene script for `ShopScence.tscn`. Don't put data logic in `ShopUI`.
- `control.gd`/`control.tscn` at repo root and `old_code/` are dead playground/legacy code — ignore them.
- Code comments and docs are mostly in **Vietnamese**.
- `.editorconfig` sets charset UTF-8; Godot 4.4 generates `.uid` files alongside scripts — commit them.
