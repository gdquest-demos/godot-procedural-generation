# Modular weapons design

## Projectile emitter configuration

Holds projectile emitters that create projectiles and sets the direction the projectile will begin its travel.

### Modifiable statistics

- How many
- Positions
- Facing direction
- Firing rate

## Projectile

Emitted by projectile emitters, and holds projectile motions. What it looks like or what visual and audio effect it causes when emitted.

### Modifiable statistics

- Audio-visual appearance
- Projectile lifetime
- Projectile speed
- Projectile motion(s)
- Collision

## Projectile motion

How the projectile moves (homing, curving, wavy pattern). Controls speed the projectile moves at. Stacks and projectile uses these to calculate final motion at any given moment

## Collision

What happens when projectile hits an obstacle, dissipates after time, or hits a target.

### Modifiable statistics

- Damage
- Audio-visual appearance
- Post-collision(s)
- Post-collision event(s)

## Post-collision event

An event for after the projectile collision has resolved.

## Example upgrades

- Laser: Projectile travels the intervening space between start to finish instantly. Shoots once per tick. Acts as a tracer to draw a continuous laser line.
- Homing: Projectile detects nearby targets and turns towards them in its motion, trying to hit them.
- Boom: Replaces projectile with a missile. Explodes when hitting an obstacle (but not dissipating.)
- Spread gun: Shoots 3-5 projectiles in an arc
- Rapid fire: Increases firing speed
- Impact shrapnel: Causes projectiles to shoot out in different directions after hitting a target
- Bigger boom: Causes explosions on impact, or increases explosion strength.
- Long shot: Projectile flies for longer.

## Procedural weapon icon

In an inventory or ship schematics view or otherwise, you can have an icon of a weapon and how it's modified by upgrades.

Each upgrade has an icon graphic that can attach to an attachment point somewhere on the icon.

The base icon itself can change based on the main projectile type (missile launcher, plasma caster, shotgun, rapid fire, etc.)
