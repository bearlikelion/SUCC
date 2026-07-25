# How the movement works

This page explains why SUCC feels the way it does. You don't need any of it to use the
addon, but it helps enormously when you're deciding which values to change.

## Why holding jump makes you faster

In most games, your speed is clamped: the game works out how fast you should be going and
won't let you exceed it. Quake didn't do that, and the bug became a genre.

Quake caps how much speed it can *add* each frame, not how fast you can *be*. On the
ground that distinction doesn't matter, because friction removes speed as fast as
acceleration adds it. The moment you leave the ground, friction stops, and the cap starts
behaving oddly.

Air acceleration works like this:

1. Take the direction you're asking for.
2. Measure how much of your current speed already points that way.
3. If that's less than the cap, add the difference. Otherwise add nothing.

The catch is step 2. It measures speed *along the direction you asked for*. Turn the
mouse slightly and hold a strafe key, and the direction you're asking for is nearly
sideways to where you're travelling, so your speed along it is almost zero, so the
game happily gives you the full allowance again. Repeat every frame and you accumulate
speed indefinitely.

That is bunnyhopping and strafe-jumping. It is not a feature anyone designed; it's what
falls out of these two config values:

- `air_acceleration`, how hard the game pushes
- `max_air_speed`, the per-frame allowance, 0.762 m (30 units) in every Valve and id
  engine

The allowance being *small* is the whole point. It's small enough that you can't just
accelerate forward in mid-air, but non-zero, so the sideways trick works. Raise it and
you break bunnyhopping by making forward air acceleration too easy.

## Why surfing works

A slope steeper than the character can stand on leaves them permanently airborne. They
slide, gravity keeps pulling, and because they're airborne, air acceleration is running.

So a surf ramp is just bunnyhopping against a wall. You hold a strafe key into the slope
and the same accumulation happens, except the ramp keeps you from falling. All SUCC needs
for this is a surface steeper than `max_floor_angle` (50° by default). The demo's ramps
are 55°.

`enable_surf` is a separate, non-authentic addition: it makes jumping off a ramp push you
along the slope's normal rather than straight up. Real engines always jump straight up.
Turn it off if you want accuracy.

## Why stairs need special handling

Godot's `move_and_slide()` treats a 20 cm step like a wall, you stop dead against it.
Every Quake-lineage engine solves this the same way, and SUCC copies it.

Rather than detecting steps and teleporting the body upward, the engines **do the move
twice**:

1. Move normally. Remember where that got you.
2. Go back to the start, lift up by one step height, move again, then drop back down.
3. Keep whichever attempt covered more ground.

This is Source's `StepMove` and Quake's `SV_WalkMove`. It matters that the second attempt
is a *real move* rather than a position fix, because the move itself produces the
velocity. An earlier version of SUCC teleported the body and then re-applied speed by
hand, which turned every ramp into a catapult, the synthesised speed never decayed.

The step attempt only runs when the normal move was blocked. Running it every frame lifts
and drops the character constantly, which stalls ordinary walking.

`step_height` decides the tallest ledge you can walk up. All four engines use 18 units
(0.457 m).

## Why the camera lags behind on stairs

When you climb a step, the body jumps upward instantly. If the camera followed exactly,
every step would be a visible jolt.

So the camera doesn't follow. SUCC records the height the body gained and applies it as a
downward offset to the camera, cancelling the jump, your view stays level while your
feet climb. The offset then closes at a constant 3.81 m/s (Source's 150 units/s).

The constant rate matters. A percentage-based approach is framerate-dependent and jitters
when you climb several steps in quick succession.

## Why crouching moves the body differently in the air

On the ground, crouching keeps your feet planted and lowers your head. That's what you'd
expect.

In the air, Source does the opposite: it **raises the origin** by the full height
difference, so your head stays where it was and your feet tuck up underneath you. That's
why crouch-jumping gets you onto ledges you couldn't otherwise reach, the jump gains you
height, and the duck gains you the hull difference on top.

SUCC copies this, including the detail that the origin raise and the camera drop cancel
out, so the view doesn't move at all during an air duck. Landing absorbs the raise, and
standing up afterwards checks for room *below* rather than overhead, because the legs are
extending downward.

Surf ramps count as air for this purpose, so boarding a ramp while ducking tucks the same
way.

## Why friction uses only horizontal speed

Friction slows you along the ground. If it measured your full 3D speed, falling fast
would make ground friction stronger, so landing at speed would brake harder than
landing gently, for no reason a player could understand.

Every engine measures horizontal speed only. SUCC had this wrong at one point and it made
deceleration feel inconsistent after a fall.

## Where to look next

- [Preset values](../reference/presets.md) for the numbers.
- [How accurate are the presets?](engine-accuracy.md) for where the engines surprise you.
- [Tune your own movement](../how-to/tune-movement.md) to start changing things.
