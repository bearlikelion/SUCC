# SUCC - SurfsUp Character Controller

A Godot 4 character controller that feels like Quake, Half-Life, Quake 2, Half-Life 2 or SurfsUp, by swapping one resource file. It covers bunnyhopping, surfing, air strafing, momentum-preserving stair stepping and Source-style crouch jumping.

This is the controller from [SurfsUp](https://store.steampowered.com/app/3454830/SurfsUp/), open-sourced under the MIT License.

## Getting started

1. Copy `addons/SUCC/` into your project's `addons/` folder.
2. Add the input actions: `forward`, `back`, `left`, `right`, `jump`, `crouch`, `sprint`.
3. Duplicate `addons/SUCC/scenes/succ_character.tscn` into your project and run scene
4. Copy and edit an engine preset from `addons/SUCC/resources/` to your charcter's `config` property, or open `addons/SUCC/demo/test_level.tscn` and press 1 to 5 while playing to see what feels best.

## Links

- Documentation: https://bearlikelion.github.io/SUCC/
- Source and issues: https://github.com/bearlikelion/SUCC
- Browser demo: https://bearlikelion.com/succ

## License

MIT, see [LICENSE](LICENSE). Use it in commercial or non-commercial projects. Attribution appreciated but not required.
