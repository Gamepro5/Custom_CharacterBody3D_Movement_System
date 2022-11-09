# Custom_CharacterBody_Movement_System
A fully custom made replacement for Godot 4's broken and useless "move_and_slide()" function. Was designed to imitate the source engine's character controller as closely as possible, with a few of my own tweaks and improvements.

To-do:
- Await Godot to fix bad collision percision, especially above y=250 and why convex meshes corners can sometimes act like walls to the bottom most part of a capsule. (This can be fixed by using a float=64 build of the engine)
- Climbing (ladders)
- Fix platform bugs
