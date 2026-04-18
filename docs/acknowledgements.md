# Acknowledgements

SUCC exists because of decades of open-source FPS movement lineage and the work of several people who deserve direct credit.

## Direct lineage

**[Quake](https://github.com/id-software/quake)** - id Software released the Quake source code under GPL in 1999. The movement code in `sv_user.c` / `sv_move.c` defines the shape of FPS player physics: friction, ground/air acceleration, air strafing, bunnyhopping. Every controller that feels good at high speed traces back here.

**[Source SDK 2013](https://github.com/ValveSoftware/source-sdk-2013)** - Valve's open release of the Source engine's game code. SUCC's friction, air-accel, and mouse-look math derive directly from `game/shared/gamemovement.cpp`. The 0.022° mouse-unit and `sv_friction` / `sv_accelerate` defaults come from here.

## Godot ports

**[GoldGdt](https://github.com/ratmarrow/GoldGdt)** by **[ratmarrow](https://github.com/ratmarrow)** - a faithful GoldSrc/Source-style controller for Godot. SUCC began as a fork of GoldGdt inside the SurfsUp project.

## SurfsUp

**[SurfsUp](https://store.steampowered.com/app/3454830/SurfsUp/)** is a commercial surf/bhop game on Steam. Its character controller is the direct ancestor of SUCC.

- **[Mark Arneman](https://bearlikelion.com/)** - forked GoldGdt and rewrote the controller for SurfsUp's initial Steam release.
- **[Nerdiful](https://nerdiful.itch.io/)** - refactored the controller for SurfsUp 2.0.
- **Mark Arneman** - overhauled the SurfsUp controller into SUCC: decoupled from game singletons, added the `SUCCPawn` pattern, `SUCCConfig` resource, editor warnings, extension hooks, and documentation. Open-sourced under MIT.

## License & attribution

SUCC is MIT-licensed. Attribution is appreciated but not required. If you ship a game using SUCC, a mention in your credits would make the author smile.
