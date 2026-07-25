# Tutorial: your first SUCC character

By the end of this lesson you will have a character you can walk, jump, crouch and
bunnyhop around a test level, and you will have felt the difference between Quake
movement and Half-Life 2 movement by pressing a single key.

This is a lesson, not a reference. Follow it in order and don't worry yet about what
every value means. Later pages explain the details.

You need Godot 4.6 or newer and about ten minutes.

## Step 1: get the addon into your project

Copy the `addons/SUCC/` folder into your own project's `addons/` folder.

That's the whole install. SUCC's scripts declare a `class_name`, so Godot registers
them the moment it scans the folder. There is no plugin to enable in Project Settings.

## Step 2: teach your project the movement keys

SUCC reads named actions rather than raw keys, so you decide the bindings. Open
**Project → Project Settings → Input Map** and add these eight actions:

| Action name | Key |
|---|---|
| `forward` | W |
| `back` | S |
| `left` | A |
| `right` | D |
| `jump` | Space |
| `duck` | Ctrl |
| `crouch` | C |
| `sprint` | Shift |

Type the name exactly as written, press **Add**, then click the **+** beside it to
bind the key.

If you skip one, SUCC won't crash. It prints a warning naming the missing action and
disables just that movement, so you can start with `forward` and add the rest later.

## Step 3: put a character in your scene

Open any 3D scene with a floor in it. Drag `addons/SUCC/scenes/succ_character.tscn`
from the FileSystem panel into the scene tree.

Press **F6** to run the current scene. You can now walk with WASD, look with the
mouse, jump with Space and crouch with Ctrl. Press **Esc** to release the mouse.

That's a complete, working character. Everything from here is about understanding
what you have.

## Step 4: run the demo gym

SUCC ships with a test level built to exercise every movement feature. Open
`addons/SUCC/demo/test_level.tscn` and press **F6**.

![The demo gym seen from above the spawn pad](images/gym-overview.png)

You spawn on the yellow pad. Six lanes run away from you, each one built to test a
different thing. Spend a minute on each:

- **Stairs** (far left, tan), walk straight up. You should glide up the steps rather
  than bumping.
- **Slants** (green), three ramps at 15°, 30° and 44°. All three are walkable.
- **Bunnyhop blocks** (orange, centre), hold **Space** while running along them.
  Holding jump is enough; you don't need to tap it.
- **Crouch corridor** (purple), walk into it standing and you stop. Hold **Ctrl** and
  you fit.
- **Surf ramps** (blue), the steep V. Walk up the yellow ramp, drop in, and hold a
  strafe key into the slope.
- **Slide** (far right), a 40° chute you slide down.

The number under the crosshair is your speed, shown twice: engine units per second on
top, metres per second below. Speedrunners and Source players think in units; Godot
thinks in metres.

## Step 5: feel a different engine

Now the interesting part. While the demo is running, press the number keys **1** to
**5**. The label in the top-right corner changes each time.

Walk the same stretch of floor after each press:

1. **SurfsUp**, the fastest, 400 units per second.
2. **GoldSrc**, Half-Life. 320 u/s.
3. **Quake**, also 320 u/s, but a shorter character with a lower camera.
4. **Quake 2**, noticeably grippier when you stop, and you cannot gain speed by
   strafing in the air.
5. **Source**, Half-Life 2. Floaty jumps and slow on foot at 190 u/s, until you hold
   **Shift** to sprint and it jumps to 320.

Try the bunnyhop blocks on preset 5, then on preset 1. On Source you will fall short
on the later gaps; its jump is roughly a third as high.

You just swapped five complete movement models without touching code. Each is a
`.tres` resource file, and that is the main idea behind SUCC.

## What you built

- A character that walks, jumps, crouches and sprints.
- An understanding that movement feel lives in a **config resource**, not in the
  controller's code.
- A test level for checking any change you make later.

## Where to go next

- To ship one of those five feels in your game: [Use a movement preset](how-to/use-a-preset.md).
- To add health, weapons or anything game-specific: [Extend SUCC for your game](how-to/extend-succ.md).
- To invent your own feel: [Tune your own movement](how-to/tune-movement.md).
- To understand *why* holding jump makes you faster: [How the movement works](explanation/movement.md).
