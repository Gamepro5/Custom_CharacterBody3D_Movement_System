# Custom_CharacterBody_Movement_System
A fully custom made replacement for Godot 4's primitive "move_and_slide()" function. Was designed to imitate the source engine's character controller as closely as possible, with a few of my own tweaks and improvements.

Features:
- Moving up slopes that are within your max-slope-angle will have zero effect on your x/z trajectory. This is different from move_and_slide(), and keeps it in-line with every other game engine.
- Air jumps (similar to scout from TF2, but can be set to any value)
- Swimming and water (uses Area3D). This can also be configured to add wind tunnels and other physics distorting volumes
- Advanced stair stepping (a-la Quake)
- Configurable acceleration and deceleration
- Moving platforms (buggy right now)
- Respects physics materials for floors (for instance, you can have icy surfaces for the player to walk on that change the acceleration and deceleration while on them)
- Complex air strafing


To-do:
- Await Godot to fix bad collision precision, especially above y=250 and why convex meshes corners can sometimes act like walls to the bottom most part of a capsule. (This can be fixed by using a float=64 build of the engine)
- Fix platform bugs
