# jb_basic

## About
This is a SourceMod plugin that lets you host Jailbreak maps on your TF2/TF2 Classic server.

As the name suggests this is a basic implementation of Jailbreak that does not have things like last requests, free days and all that stuff. I made it because I run a Deathrun design Discord community, and we occasionally also work on and test Jailbreak maps, but I found existing plugins too complicated with poor support for multi-game mode servers. This was also a great SourceMod programming exercise.

## Installation and Usage

1. Upload the files to your game server. The directories in this repo are in the same structure as a Source dedicated server with SourceMod installation. You don't have to upload the scripting directory.
2. If you use a FastDL server, upload the contents of the materials and models dir to that. They are so small, it's not worth compressing them into .bz2 files, but you can do that if you wish.
3. Change map to a Jailbreak map!

To get a list of ConVars in server console, do `sm cvars jb_basic`. To get a list of commands, do `sm cmds jb_basic`. Use the */jbhelp* command in-game to view the [help page](https://steamcommunity.com/groups/death_experiments/discussions/3/2791620699996372350/).

## Features

### In brief
* Team balancing
* Weapon restrictions
* Voice mute system + HUD text mute status
* Command cooldown system + HUD text status
* Warden role + commands + remote control
* A radial warden menu
* Fancy effects
* No need for config files

### At length
* Instead of a beam circle, the warden target is a model that's much easier to see, looks better and can accommodate more players.
* When the warden targets a func_door or func_brush brush entity, or a prop_dynamic model, brushes are tinted green and models are given a green glow outline.
* Training annotations attached to targeted objects use translation phrases
* The direction system responds to the voicemenu command "Go, go, go." (0, 2). The actual voice line now has a 1/3 chance of being spoken so it doesn't get spammy.
* The plugin looks for buttons and doors that have a targetname matching a list of commonly-used targetnames in existing maps, and adds them to the Warden list, without needing to create a config file for the map.
* The warden radial menu is opened by holding +use. Options are selected by moving the mouse and releasing +use. Right mouse cancels the menu.
* Wardens become twenty percent larger than everyone else to make them stand out from the crowd. Ths should present no problems in most maps but the Warden can remove their size increase in the menu (/jb or /wm).
* Admin menu for testing functions (/jb).
* Debug convar which adds extra messages in server console and chat.

### The future
* When a player uses a command which emits a training_annotation from themselves, put them into thirdperson temporarily.

## Design Notes

### Brief
* Enable the playing of a JB map with no configuration other than running the map. Provide the essential functions for gameplay, don't add bloat or wander too much into complicated events like freedays, last requests and so on.
* Use specific text display channels for certain types of message content. e.g. HUD text for abilities, training annotations for 'speech' emitted from/by players (warden commands, repeat requests), menus for options.
* Keep the amount of text information displayed to players at a minimum so we don't distract or overwhelm them. Avoid flooding chat.
* Avoid using dependencies that only work on TF2 servers, so it can be used on TF2 Classic and Open Fortress servers.
* The plugin should enable itself when it detects a Jailbreak map, and disable itself when the map finishes. The plugin should not affect anything on non-Jailbreak maps. This includes precaching and downloading files.

## Philosophy
* The warden is scaled by 20% because it makes them stand out from the crowd so prisoners and guards can find them more easily. This was the best option at the time, as it is quick to implement, compared with using a custom model or special effects. I don't like visual clutter, and I don't want to impose a class choice on the warden, or mess with their appearance too much, and I liked how in World of Warcraft, important NPCs are scaled up in size during raid encounters to make them easier to see when there is a lot of action. 
