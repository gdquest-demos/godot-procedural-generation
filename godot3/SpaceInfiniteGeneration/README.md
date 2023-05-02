# Infinite procedural worlds

This demo shows four stages of the creation of an infinite procedural world. The first two show the use of white versus blue noise to produce respectively chaotic and fairly natural distributions of entities in the world. The third demo shows how to use multiple layers of world generation to enrich the output. And the fourth adds the ability to make persistent changes like adding and removing planets with the mouse.

## Controls

- WASD To move the player ship
- In the persistent world demo, left click in an empty space to add a new planet and right click on an existing planet to destroy it.

## How it works

All four demo scenes in this folder extend the `Shared/WorldGenerator.gd` class.

`WorldGenerator` is a virtual base class. It defines a `_generate_sector()` function we use to generate areas of the world around the player.

The key aspects of the generation process are:

1. At the start of the game, we generate a number of sectors around the player in a gridlike pattern.
1. As the player moves through the world, we destroy sectors that are far away from them and generate new ones in the direction they are moving.
1. We use a function to generate a unique seed for every sector in any world, `make_seed_for()`. This function creates a text string using the sectors coordinates and the world's name, and it outputs a number using a hash algorithm.

The last point allows us to make the generation deterministic. If the player moves back or loads the game from any position in the universe, the world will always generate the same way.
