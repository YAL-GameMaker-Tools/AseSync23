# AseSync23

This tool automatically updates sprites in your GameMaker Studio 2.3+ project when the matching Aseprite file is changed on disk!

In some way it can be seen as successor to [lazyload](https://lazyeye.itch.io/lazyload),
except without Topher's tasteful UI or much other polish.

**Update:** There's [a frontend](https://sahaun.itch.io/asesync) for the tool now that you can use.

## Requirements

*	GameMaker Studio 2.3 or higher (tested with 2.3.4)
*	Aseprite (this tool uses Aseprite CLI to get frame data)
*	Adequate backups/version control (in case something breaks)

## Basic use

*	Create a sprite called `spr_asebase`.  
	This will be used as the template for newly added sprites.  
	If you don't want to use frame delays from Aseprite, set the animation type to "frame per game frame".
*	Arrange your `Aseprite` sprites into a directory.  
	If there are subdirectories, these will become as resource tree folders.
*	Run the tool, give it your project path and aseprite directory path.  
	(on Windows, just run the `exe`, on Mac/Linux install [Neko VM](https://nekovm.org/download/) runtime and run the tool from terminal via `neko AseSync.n`)
*	Edit some \[ase]sprites!  
	The tool will automatically update the frames in existing sprites and add new ones as necessary.

## Advanced use

The tool can be ran from CLI with additional parameters, like so:
```
AseSync <YYP path> <sprites directory> [...additional parameters]
```
Supported parameters:

*	`--folder <path>`:
	Allows to specify the resource tree folder to dump new sprites in.  
	Defaults to `Sprites`, but can be `Sprites/subfolder`, etc.
*	`--base <name>`:
	Specifies the sprite to use as a template.  
	Defaults to `spr_asebase`, failing that will pick the first sprite in project.
*	`--sync`: Goes over all of the sprites in directory on startup.  
	This is good if you've received a bunch of new sprites and would rather not open-save each of them.
*	`--once`: Goes over all of the sprites in directory and then quits.  
	(without watching for changes)
*	`--consent`: Forces backup/source control consent without waiting for input.  
	(so you can run this tool completely automated, but still, use source control)
*	`--aseprite <path>`: Overrides Aseprite path for a session.

## Compiling

Initial setup:
```
haxelib git yyjson https://github.com/YAL-Haxe/yyjson
haxelib install haxe-files
haxelib install format
```
Neko build:
```
haxe -lib yyjson -lib haxe-files -lib format -cp . -neko bin/AseSync.n -main AseSync
```
C# build:
```
haxe -debug -lib yyjson -lib haxe-files -lib format -cp . -cs bin/cs -main AseSync
copy /Y bin\cs\bin\AseSync-Debug.exe bin\AseSync.exe
```
