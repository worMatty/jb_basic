# jb_basic
A basic Jailbreak plugin

## Why?
Because I wanted to help my friends test Jailbreak maps on our servers but the existing plugins feel too complicated to get working, and aren't suitable for a multi-game mode environment. i also wanted to try some new things I'd never done before, and rewrite a lot of the code for my Deathrun plugin so it was cleaner. This plugin shares a lot of the same methods and actions as that one, which I will be able to transport when I go back to working on it. This has also been a good test and practicing of my abilities as a Source Pawn scripter, or indeed a 'programmer' in general.

## Not Complete
The plugin isn't ready to be deployed fully yet as it doesn't have some essential things like team restrictions, but it can be used to play a game because it can remove red player weapons and allow an admin to become a warden and grant themselves a couple of abilities like remotely pressing buttons or opening doors.

## Some Features
* Warden can cast a targeting reticle to direct players, similar to the beam circle seen on other plugins but uses a model that's easier to see and wider for more players. When targeting a door, func_brush or prop_dynamic, the brushes are tinted green and the models are given a green glow outline. Context-sensitive translation phrases are used in the accompanying training annotations (yes, translated training annotations). The direction system responds to the voicemenu command '0 2' which is "Go, go, go." The actual voice line has a 1/3 chance of being spoken to prevent nuisance.
* Searches for button and door entities with a common set of targetnames found in most maps, and lets the Warden trigger them from a menu. Does away with the need to edit a map config file so testing is easier.
* Added a radial menu for the Warden that uses on-screen 'hudsync'/'game_ui' text. Hold down +use and move the mouse to highlight an option, then release +use to select. Right click to reset. This is designed for quick and common actions and is faster and more comfortable than launching and navigating a menu.
* Wardens become twenty percent larger than everyone else to make them stand out amonst the crowd. This is a design technique I borrowed from World of Warcraft, where friendly NPCs are twice the size in raid encounters to allow the player to see and interact with them more easily. Ths should present no problems in most maps but the Warden can remove their size increase from the menu (/jb or /wm).
* Admin menu for testing functions (/jb).

## Design Brief
* Make something that allows a JB map to be tested with no configuration, all it needs is a map. Provides the basic functions for essential gameplay, doesn't overstep the mark or wander too much into complicated events like freedays, last requests and so on.
* Make something that keeps user information communication to a minimum to avoid spam.
* Make something that has consistency in its display of information to clients. I don't like text appearing all over the screen coming at me from lots of different sources (chat, hudsync, hudmsg, hints, training messages, training annotations, menus) with no apparent consistency of what that 'channel' or display area means. Important information such as voice mute status should be displayed to the user in a clear and static manner such as persistent hudsync text. Users should not be directed to look away from the action if they are alive.
* Make something that doesn't rely on SDK hooks or TF2 extension natives as much as possible, so the plugin will work on Open Fortress and TF2 Classic from the start (untested).
* Make something that sets itself up on detecting a JB map and closes itself down when the map is done, returning the server to its default state and NOT polluting every other game mode on the server. 
