# AzeroCombat Session Notes

## Tank Targeting Refactor

- Shared tank targeting now lives in `Core.lua`.
- Warrior, Druid, Paladin, and Death Knight all call the shared tank controller.
- Class-specific gap closers remain class-specific:
  - Warrior: `Charge`, `Intercept`
  - Death Knight: `Death Grip`
  - Druid / Paladin: use shared taunt and target logic only

## Warrior Cleanup

- Removed the old Protection-only warrior taunt engine from `Classes/Warrior.lua`.
- Removed dead warrior wrappers for target switching and repeat-taunt handling.
- `FindBestWarriorTarget()` still exists and delegates to the shared tank target finder because Arms/Fury still call it.
- Protection Warrior now enters the shared tank controller directly.

## Druid Tank Updates

- Bear tank uses the shared tank controller.
- Bear tank defensives now include emergency racials through `UseRacialsDruid(false, true)`.
- Druid emergency racials are debuff-aware:
  - `Stoneform` for poison, disease, bleed, or low-health fallback
  - `Will of the Forsaken` for fear/charm/sleep
  - `Escape Artist` for root/snare/slow
  - `Every Man for Himself` for stun/fear/charm/sleep
  - `War Stomp` remains the Tauren emergency stun
- `Shadowmeld` and `Arcane Torrent` are not used by the bear emergency branch.

## Druid Buffing

- Druid buffing is out of combat only.
- Combat rebuff helper was removed.
- Group `Mark of the Wild` / `Gift of the Wild` scanning now uses a rotating cursor so it does not restart from the top every pass.
- The cursor scans a small slice per pass, which speeds coverage without spamming every tick.
- `CheckDruidBuffs()` and `CheckDruidGroupBuffs()` both use a 1.5 second throttle.

## Validation

- Syntax checks pass with `luac -p` on:
  - `Core.lua`
  - `Classes/Warrior.lua`
  - `Classes/Druid.lua`
  - `Classes/Paladin.lua`
  - `Classes/DeathKnight.lua`

## Current Status

- No in-game combat verification has been done in this session.
- The main risk area is warrior Protection behavior, since that path was simplified aggressively.
- If a regression shows up, restore the removed warrior-only code locally before pushing anything.
- Fixed a live regression where `Core.lua` `FindBestTankTarget()` was calling bare `Throttle` instead of `self:Throttle`.
