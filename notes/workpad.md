# JB Basic Workpad

Out of date notes are present.

## Ideas/todo

* Key combinations for special warden actions
* Trace mask should go through glass (???)
* OnPickup ammo pack check if player had their ammo stripped and switch to their primary for convenience?
* If warden tool range cvar is 0, disable check
* Make dead text chat semi transparent?
* Don't display annotations on yourself if you are in thirdperson (why not?)

### Not basic!

* A random guard gets some special sidekick ability like being able to tranq (slow/stun) three times.
* Warden remote control dropped on death
* Guard ability: Intimidate. AoE/conal humil stun. Cooldown and crowd control diminishing return
* Some kind of plugin support?
* Prisoner run speed is slower on round start and slowly increases


## Another todo list

* Replace some weapons?
* Follow a brush if it has a relative origin (???)
* Cooldown refill sound effects (think Overwatch)
* Grant a form of prisoner glow ability to Officers?
* Prefix warden name in text chat with rank
* Glow warden when they are voice chatting or put a speaker sprite above them (if it doesn't clip)
* See prisoner health (Who? Warden? Needed?)
* "A prisoner has rebelled" warning when a prisoner damages a guard. On cooldown after X seconds of no combat
* Warden grace period at start of round
* Utilise sesson flag for perma-Warden pref (???)
* Prevent people firing during freeze time (optionally. Off by default)
* "Warden has been killed?" warning
* Offer to the warden to mute all reds for the first twenty or thirty seconds
* First round post map change could be a mess-around round lasting two minutes with auto respawning
* Add a vote to keep people off a certain team?
* Warden has a key combination to mute guards when they are speaking, or auto-duck if possible (client cvars?)
* Warden HUD panel shops when out of range/not in LOS of buttons
* Perhaps check if the cell door button is locked and fail the attempt/don't consume a cooldown?
* Use text chat when training annotation is not available due to no mod support. Optionally disable using cvar
* Take spies out of cloak when their weapons are removed
* Handle double round restart when blue team becomes empty (TF2 Arena behaviour - see DTK)
* Check if round 'is valid' (has players on both teams and is pre-round or running) for some restart functions
* Consider using VScript for attribute modification instead of TF2 Attributes
* Consider using GetRoundState and rely on OF Tools/TF2C Tools for its natives, making it a requirement


## To do list since 0.2

* Debug convar level?
* Player array methods for muting
* Admin debug commands for buttons and doors. List (DONE), status, open, close, press
* Support for rotating buttons (done?)
* Support for prop doors? (Done?)
* Add model check from m_playtest to highlight system in place of checking classnames
* Cooldown cvars
* Warden size cvar
* Optionally put a player into TP when they cause a TA above them. Add preference. Use PrintToChat otherwise/in addition
* Use priority system combining points and ban status for queue sorting?
* close_cells button support (done?)
* Cvar to toggle warden remote control
* Prevent spies from cloaking or disguising
* Information to people about how they can become a warden
* Information on the current officer cap during pre-round
* Always show mute status when on a team? Check most recent playtest video
* Why could player Toad talk when dead? Check playtest video
* Remove radial menu as no-one is likely to use it
* HUD hints for binds?
* Show warden pool status during pre-round (people in the pool. In a menu panel? HUD hint?)
* Auto open WM on round start for warden
* Button m_toggle_state (I don't remember what this means)
* Button presses should take an activator? (Does this mean always pass activator index to prevent crashes?)
* Can point_worldtext be used for warden talking notification? Billboard support?

### Possible additions from gleaning chat about JB on forums
* Highlight warden text chat
* Ammo re-enables ammoless weapons (mad milk, jarate, pompson, mangler etc., charging)
* "Heavy can use lunchbox items to delay"
* "Eternal reward can disguise..."


## Voice notes

AllTalk needs to be disabled if you want to do any of this.
Update: No it doesn't. It just changes the behaviour of NORMAL so both teams can talk.

VOICE_NORMAL
	
#define VOICE_NORMAL 		0 	000000	/**< Allow the client to listen and speak normally. */
#define VOICE_MUTED 		1 	000001	/**< Mutes the client from speaking to everyone. */
#define VOICE_SPEAKALL 		2 	000010	/**< Allow the client to speak to everyone. */
#define VOICE_LISTENALL 	4 	000100	/**< Allow the client to listen to everyone. */
#define VOICE_TEAM 			8 	001000	/**< Allow the client to always speak to team, even when dead. */
#define VOICE_LISTENTEAM 	16	010000	/**< Allow the client to always hear teammates, including dead ones. */

Flags of 000100 (4 - LISTENALL) while live let me talk to live Berke on my team.
Flags of 000010 (2 - SPEAKALL) while dead, allowed me to talk to alive players on both teams.

Flags of 000100 (4 - LISTENALL) allowed dead Berke to hear live me on same team.
Flags of 000100 (4 - LISTENALL) allowed dead Berke to hear dead me on same team.

Listening flags by default are 0.


## Bugs

* Annotations on parented entities are going to origin. Could be absolute origin? (Ignore for now)
* My weapons didn't have their ammo stripped on the first round. Did the server not fire a restart event?
* Can't trigger buttons in TF2C or set my model scale. AcceptEntityInput not working?
* TF2 particles on training annot? show_effect
* Player queue points were not reset when chosen as Warden (???)
* Does m_bIsMiniBoss get reset on death or round restart? Do I need to remove it? What am I using it for, again?
* Setting convar bounds OnPluginStart could override other plugins. Do this on enable instead

L 07/31/2020 - 18:48:25: [SM] Exception reported: Property "m_bIsMiniBoss" not found (entity 1/player)
L 07/31/2020 - 18:48:25: [SM] Blaming: open_fortress/jb_basic.smx
L 07/31/2020 - 18:48:25: [SM] Call stack trace:
L 07/31/2020 - 18:48:25: [SM]   [0] SetEntProp
L 07/31/2020 - 18:48:25: [SM]   [1] Line 552, jb_basic/methodmaps.inc::Player.MakePrisoner
L 07/31/2020 - 18:48:25: [SM]   [2] Line 151, jb_basic/events.inc::Event_RoundActive

In TF2C
	Commands not working: r, w, setpoints, addpoints



## Weapon restriction & ammo stripping findings

m_iClip1 is the current clip of weapons like the shotgun.
I don't know what m_iClip2 is used for (if at all?)
Flamethrower does not use m_iClip1. Perhaps because it's not a clip. Nor does minigun or SR (what is SR?).
m_iClip2 does *not* contain Hype.
Emptying m_iClip1 breaks Cow Mangler. Can't fire.

Net prop clip values are 255, while data map values are -1.

m_iClip1 == 255:
	Mad Milk,
	Cleaver,
	Buff Banner

Setting clips that normally have a value of 255 to *any other number* prevents them being used.

Cow Mangler clip1 is 20!?



## Weapon restriction notes

A simple approach. If it confers an advantage, remove the item.
Disable healing.
Create a spreadsheet/table of all TF2 weapons. Include: IDI, classname, iswearable, heals, self-damage, minor speed, major speed, minor jump, major jump, 
Taunts

## JB map design notes

Not meant for the plugin, just stuff that occurred to me while I was here.

* Guards drop key caads that grant access to the armory? (map mechanic)
* Some guards can be medics that can heal prisoners
* Footsteps giving away inmate location
* Security systems that detect rebellers. Lazer grids, motion detection, microphones, DSP to make things echo
