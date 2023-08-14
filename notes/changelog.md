# Changelog

## Version 0.2

### Bug fixes

All cell doors sharing the same targetname are accounted for and can be remotely-controlled. Previously, only the first cell door found would be controllable.

### Minor changes

* Your server console is no longer spammed when we hook native console variables while in debug mode
* Support has been added for cell door buttons using `func_rot_button`

### Major changes

There has been a change to how team player numbers are balanced. Previously, the plugin sought a hard ratio of officers to inmates and would disallow deviation. However according to feedback, this is unwanted behaviour as having a minimum number of officers to guard against them being overwhelmed is not a concern. Players are free to join whichever team they choose, but there is instead now a percentage cap on the number of officers and a minimum of 1. The new console variable for this is `jb_officer_cap`.

### Technical stuff

* A new admin command for debugging cell doors and buttons, `sm_jbents`. It prints data on the entities found and enables you to `open` and `close` all doors for testing.
* SourceMod 1.11 compile warnings addressed.

### Code changes

Greatly improved the management of entities like doors and buttons. We now have custom types based on ArrayLists, with custom methods for validation, button configuration testing, range-checking and activation. A lot of code to do with remote activation has been moved from menu and command functions into these methods so it can be accessed from anywhere. It's much nicer.


## Version 0.1 - Release

### Bug fixes

* The `game_round_win` entity spawned for the round timer now resets the round. Previously it did not, resulting in a new round where the map was in the same state as the last one

### Minor changes

* By default, the round timer console variable is now disabled

I don't want to force map designers to deal with a round timer imposed on them by a plugin so I have disabled this cvar. I want map authors to choose their own time and round end effects, just like in deathrun. If a map author wanted to keep entities the same as they were in the previous rounds they could set their `game_round_win` to not reset entities on round restart to simulate a live environment where changes are permanent.