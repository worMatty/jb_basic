#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#undef REQUIRE_PLUGIN
#tryinclude <basecomm>

#undef REQUIRE_EXTENSIONS
#tryinclude <steamtools>	// server game description
#tryinclude <tf2_stocks>

#define PLUGIN_VERSION		"0.2"
#define PLUGIN_NAME			"Jailbreak Basic"
#define PREFIX_SERVER		"[JB Basic]"
#define PREFIX_DEBUG		"[JB Basic] [Debug]"
#define STRING_YOUR_MOD		"Source Game Server"
#define PRE_ROUND_TIME		20
#define MAXPLAYERS_TF2		34

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = "worMatty",
	description = "Basic Jailbreak game mode functions",
	version = PLUGIN_VERSION,
	url = ""
};

// ConVars
enum {
	P_Version = 0,
	P_Enabled,
	P_AutoEnable,
	P_UseTimer,
	P_RemoteRange,
	P_RoundTime,
	P_OfficerCap,
	P_Debug,
	
	S_Unbalance,
	S_AutoBalance,
	S_Scramble,
	S_Queue,
	S_FirstBlood,	// Not supported by OF
	S_Pushaway,
	S_FreezeTime,
	
	ConVars_Max
}

// Timers
enum {
	Timer_Direction = 0,
	Timer_Glow,
	Timer_HUD,
	Timer_NameText,
	Timer_QueuePoints,
	Timer_Max
}

// Warden Ability Cooldowns
enum {
	CD_Directions = 0,
	CD_CellDoors,
	CD_Repeat,
	CD_ArrayMax
}

// Round State
enum {
	Round_Waiting = 0,
	Round_Freeze,
	Round_Active,
	Round_Win
}



/**
 * Bit Masks
 * ----------------------------------------------------------------------------------------------------
 */

// Player Preferences
#define FLAG_PREFERENCE				( 1 << 0 )
#define FLAG_FULLPOINTS				( 1 << 1 )
#define FLAG_ENGLISH				( 1 << 2 )

// Session Flags
#define FLAG_WELCOMED				( 1 << 16 )
#define FLAG_OFFICER				( 1 << 17 )
#define FLAG_WARDEN					( 1 << 18 )
#define FLAG_PRISONER				( 1 << 19 )
#define FLAG_WARDEN_LARGE			( 1 << 20 )
#define FLAG_WANTS_WARDEN			( 1 << 21 )

// Game State Flags
#define FLAG_HAVE_WARDEN			( 1 << 0 )
#define FLAG_PRISONERS_MUTED		( 1 << 1 )
#define FLAG_REDISTRIBUTING			( 1 << 2 )
#define FLAG_LOADED_LATE			( 1 << 3 )

// Games or Source Mods
#define FLAG_TF						( 1 << 0 )
#define FLAG_OF						( 1 << 1 ) 
#define FLAG_TF2C					( 1 << 2 )

// Flag Masks
#define MASK_DEFAULT_FLAGS			( FLAG_PREFERENCE | FLAG_FULLPOINTS )
#define MASK_STORED_FLAGS			( FLAG_PREFERENCE | FLAG_FULLPOINTS | FLAG_ENGLISH )
#define MASK_SESSION_FLAGS			( 0xFFFF0000 )
#define MASK_RESET_ROLES			( FLAG_OFFICER | FLAG_WARDEN | FLAG_PRISONER | FLAG_WARDEN_LARGE )
// Note: Only store specific bits to db. Session flags are 16-31




/**
 * Variables
 * ----------------------------------------------------------------------------------------------------
 */

// Libraries present
bool g_bSteamTools;
bool g_bBasecomm;

ConVar g_ConVars[ConVars_Max];

Handle g_Timers[Timer_Max];
Handle g_hRadialText;
Handle g_hHUDText;
Handle g_hNameText;

int g_iGame;
int g_iState;
int g_iRoundState;
int g_iPlayers[MAXPLAYERS_TF2][Player_ArrayMax];
int g_iCooldowns[CD_ArrayMax];

ButtonList g_Buttons;
DoorList g_CellDoors;
StringMap g_Sounds;

StringMap BuildSoundList()
{
	StringMap sounds = new StringMap();
	sounds.SetString("direction_cooldown", 	"player/recharged.wav");
	sounds.SetString("direction_goto", 		"coach/coach_go_here.wav");
	sounds.SetString("direction_lookat", 	"coach/coach_look_here.wav");
	sounds.SetString("direction_kill", 		"coach/coach_defend_here.wav");
	sounds.SetString("warden_instruction",	"buttons/button17.wav");
	sounds.SetString("chat_debug", 			"common/warning.wav");
	sounds.SetString("chat_feedback", (FileExists("sound/ui/chat_display_text.wav", true)) ? "ui/chat_display_text.wav" : "ui/buttonclickrelease.wav");
	sounds.SetString("repeat_1", 			"vo/k_lab/ba_guh.wav");
	sounds.SetString("repeat_2", 			"vo/k_lab/ba_whoops.wav");
	sounds.SetString("repeat_3", 			"vo/k_lab/ba_whatthehell.wav");
	sounds.SetString("repeat_4", 			"vo/npc/male01/whoops01.wav");
	sounds.SetString("repeat_5", 			"vo/npc/male01/pardonme02.wav");
	sounds.SetString("repeat_6", 			"vo/npc/male01/sorry01.wav");
	sounds.SetString("repeat_7", 			"vo/npc/male01/sorry03.wav");
	sounds.SetString("repeat_8", 			"vo/k_lab/kl_ohdear.wav");
	sounds.SetString("repeat_9", 			"vo/npc/male01/pardonme01.wav");
	sounds.SetString("repeat_10", 			"vo/npc/male01/excuseme01.wav");
	sounds.SetString("repeat_11", 			"vo/npc/male01/excuseme02.wav");
	sounds.SetString("repeat_12", 			"vo/k_lab/kl_interference.wav");
	sounds.SetString("repeat_13", 			"vo/k_lab2/kl_cantleavelamarr.wav"); 	
	
	return sounds;
}




/**
 * Plugin Includes
 * ----------------------------------------------------------------------------------------------------
 */

#include "jb_basic/methodmaps.sp"
#include "jb_basic/commands.sp"
#include "jb_basic/hud.sp"
#include "jb_basic/events.sp"
#include "jb_basic/menus.sp"
#include "jb_basic/stocks.sp"
#include "jb_basic/teams.sp"
#include "jb_basic/timers.sp"
#include "jb_basic/world_control.sp"



/**
 * SourceMod Forwards
 * ----------------------------------------------------------------------------------------------------
 */

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	char sGame[32];
	GetGameFolderName(sGame, sizeof(sGame));
	
	if			(StrEqual(sGame, "tf"))					g_iGame |= FLAG_TF;
	else if		(StrEqual(sGame, "open_fortress"))		g_iGame |= FLAG_OF;
	else if 	(StrEqual(sGame, "tf2classic"))			g_iGame |= FLAG_TF2C;
	else		LogError("Plugin currently only supported on TF2, OF and TF2C. Some things may not work");
	
	MarkNativeAsOptional("Steam_SetGameDescription");
	
	if (late) g_iState |= FLAG_LOADED_LATE;
	
	return APLRes_Success;
}



public void OnPluginStart()
{
	LoadTranslations("jb_basic.phrases");
	PrintToChatAll("%t %t", "prefix_important", "jb_plugin_loaded");
	
	// ConVars
	g_ConVars[P_Version]			= CreateConVar("jb_version", PLUGIN_VERSION);
	g_ConVars[P_Enabled]			= CreateConVar("jb_enabled", "0", "Enabled Jailbreak");
	g_ConVars[P_AutoEnable]		= CreateConVar("jb_auto_enable", "1", "Allow the plugin to enable and disable itself based on a map's prefix");
	g_ConVars[P_UseTimer] 		= CreateConVar("jb_round_timer", "0", "Create and use a round timer if one is not built into the map");
	g_ConVars[P_RoundTime] 		= CreateConVar("jb_round_time", "600", "Round time, if enabled");
	g_ConVars[P_OfficerCap] 		= CreateConVar("jb_officer_cap", "35.72", "Percentage of total active players that are allowed to be an officer. This sets the maximum officer count", _, true, 0.0, true, 100.0);
	g_ConVars[P_RemoteRange] 	= CreateConVar("jb_remote_range", "2600", "Range of the Warden's remote cell door ability when not in LOS");
	g_ConVars[P_Debug]			= CreateConVar("jb_debug", "1", "Enable plugin debugging messages showing in server and client consoles");
	
	g_ConVars[S_Unbalance]		= FindConVar("mp_teams_unbalance_limit");
	g_ConVars[S_AutoBalance]		= FindConVar("mp_autoteambalance");
	g_ConVars[S_Scramble]		= FindConVar("mp_scrambleteams_auto");
	g_ConVars[S_Queue]			= FindConVar("tf_arena_use_queue");
	g_ConVars[S_FreezeTime] 		= FindConVar("tf_arena_preround_time");
	
	if (!(g_iGame & FLAG_OF))			g_ConVars[S_FirstBlood]	= FindConVar("tf_arena_first_blood");
	if (g_iGame & FLAG_OF)				g_ConVars[S_Pushaway] 	= FindConVar("of_teamplay_collision");
	if (g_iGame & (FLAG_TF|FLAG_TF2C))	g_ConVars[S_Pushaway] 	= FindConVar("tf_avoidteammates_pushaway");
	
	// Increase the amount of pre-round freeze time possible
	SetConVarBounds(g_ConVars[S_FreezeTime], ConVarBound_Upper, true, PRE_ROUND_TIME.0);
	
	// Hook ConVars
	for (int i = 0; i < ConVars_Max; i++)
	{
		g_ConVars[i].AddChangeHook(ConVar_ChangeHook);
	}
	
	// Commands
	RegConsoleCmd("sm_jb", Command_Menu, "Open the Jailbreak menu");
	RegConsoleCmd("sm_wm", Command_Menu, "Open the Warden menu");
	RegConsoleCmd("sm_w", Command_CommonCommands, "Become the Warden");
	RegConsoleCmd("sm_jbhelp", Command_CommonCommands, "Jailbreak basic help");
	RegConsoleCmd("sm_r", Command_CommonCommands, "Ask the Warden to repeat their instruction");
	
	// Admin Commands
	RegAdminCmd("sm_addpoints", Command_AdminCommands, ADMFLAG_SLAY, "Give a player some queue points");
	RegAdminCmd("sm_setpoints", Command_AdminCommands, ADMFLAG_SLAY, "Set a player's queue points");
	
	// Debug Commands
	RegAdminCmd("sm_jbdata", Command_DebugCommands, ADMFLAG_SLAY, "Print the values of the player data array to your console");
	RegAdminCmd("sm_jbents", Command_DebugEntities, ADMFLAG_SLAY, "Print found Jailbreak entities in the map to console");
	RegAdminCmd("sm_stripslot", Command_DebugCommands, ADMFLAG_SLAY, "Strip one of your weapons of its ammo");
	RegAdminCmd("sm_redist", Command_DebugCommands, ADMFLAG_SLAY, "Redistribute players");
	RegAdminCmd("sm_jbtextdemo", Command_DebugCommands, ADMFLAG_SLAY, "Print example text strings to your chat box");
	RegConsoleCmd("sm_lflags", Command_DebugCommands, "Print your listen flags to chat for voice chat debugging");
	RegConsoleCmd("sm_clipvals", Command_DebugCommands, "Print your weapon clip values to console");
	
	// Build Sound List
	g_Sounds = BuildSoundList();
	
	// Late Loading
	if (g_iState & FLAG_LOADED_LATE)
	{
		// Initialise Player Data Array
		for (int i = 1; i <= MaxClients; i++)
		{
			Player player = new Player(i);
			if (player.InGame)
				player.CheckArray();
		}
	}
}



/**
 * Library Detection
 */
public void OnAllPluginsLoaded()
{
	if (!(g_bSteamTools = LibraryExists("SteamTools")))
		LogMessage("Library not found: SteamTools. Unable to change server game description");
	if (!(g_bBasecomm = LibraryExists("basecomm")))
		LogMessage("Library not found: SourceMod Basic Comms Control (basecomm)");
}

public void OnLibraryAdded(const char[] name)
{
	LibraryChanged(name, true);
}

public void OnLibraryRemoved(const char[] name)
{
	LibraryChanged(name, false);
}

void LibraryChanged(const char[] name, bool loaded)
{
	if (StrEqual(name, "Steam Tools"))
		g_bSteamTools = loaded;
	if (StrEqual(name, "basecomm"))
		g_bBasecomm = loaded;
}



public void OnMapStart()
{
	// Reset the round state to WFP
	g_iRoundState = Round_Waiting;
}



/**
 * Called when SteamTools connects to Steam.
 * Used to set the game description when SteamTools loads late.
 */
public int Steam_FullyLoaded()
{
	if (g_ConVars[P_Enabled].BoolValue)
	{
		GameDescription(true);
	}
}



/**
 * OnConfigsExecuted
 *
 * Detect Jailbreak maps and enable the plugin
 * Execute config_jailbreak.cfg when all other configs have loaded.
 */
public void OnConfigsExecuted()
{
	if (g_ConVars[P_AutoEnable].BoolValue)
	{
		char sMapName[32];
		GetCurrentMap(sMapName, sizeof(sMapName));

		if (StrContains(sMapName, "jb_", false) != -1 || StrContains(sMapName, "ba_", false) != -1 || StrContains(sMapName, "jail_", false) != -1 || StrContains(sMapName, "jail_", false) != -1)
		{
			g_ConVars[P_Enabled].SetBool(true);
		}
	}
	
	if (g_ConVars[P_Enabled].BoolValue)
	{
		ServerCommand("exec config_jailbreak.cfg");
	}
}



/**
 * OnMapEnd
 *
 * Disable the plugin if it's enabled
 * NOT called when the plugin is unloaded.
 */
public void OnMapEnd()
{
	if (g_ConVars[P_Enabled].BoolValue)
	{
		g_ConVars[P_Enabled].SetBool(false);
	}
}



/**
 * OnPluginEnd
 *
 * Disable the plugin if it's enabled
 * Called when the plugin is unloaded.
 */
public void OnPluginEnd()
{
	if (g_ConVars[P_Enabled].BoolValue)
	{
		g_ConVars[P_Enabled].SetBool(false);
	}
}



public void OnClientAuthorized(int client, const char[] auth)
{
	Player player = new Player(client);
	player.CheckArray();
}



public void OnEntityCreated(int entity, const char[] classname)
{
	if (!g_ConVars[P_Enabled].BoolValue)
		return;
	
	if (StrEqual(classname, "tf_ammo_pack"))
		AcceptEntityInput(entity, "Kill");
	
	//if (StrEqual(classname, "team_round_timer"))
	//	RequestFrame(RequestFrame_RoundTimer, entity);
}

stock void RequestFrame_RoundTimer(int entity)
{
	if (!IsValidEdict(entity))
		return;
	
	char sTargetname[32];
	GetEntPropString(entity, Prop_Data, "m_iName", sTargetname, sizeof(sTargetname));
	
	Debug("team_round_timer %d detected with targetname \"%s\"", entity, sTargetname);
	
/*	if (sTargetname[0] == '\0')
	{
		Debug("Killing team_round_timer %d with no targetname", entity);
		AcceptEntityInput(entity, "Kill");
	}
*/
	if (!StrEqual(sTargetname, "JB_ROUND_TIMER"))
	{
		int iEnt = CreateEntityByName("team_round_timer");
		if (iEnt != -1)
		{
			char sSetup[3], sTime[5];
			IntToString(PRE_ROUND_TIME, sSetup, sizeof(sSetup));
			g_ConVars[P_RoundTime].GetString(sTime, sizeof(sTime));
			
			DispatchKeyValue(iEnt, "setup_length", sSetup);
			DispatchKeyValue(iEnt, "timer_length", sTime);
			DispatchKeyValue(iEnt, "targetname", "JB_ROUND_TIMER");
			if (DispatchSpawn(iEnt))
				Debug("Created a team_round_timer %d with targetname JB_ROUND_TIMER", iEnt);
			
			SetVariantString("1");
			AcceptEntityInput(iEnt, "ShowInHUD");
			AcceptEntityInput(iEnt, "Resume");
			
			if (g_ConVars[P_UseTimer].BoolValue)
			{
				SetVariantString("OnFinished JB_RED_WIN,RoundWin,,0.0,1");
				AcceptEntityInput(iEnt, "AddOutput");
				
				iEnt = CreateEntityByName("game_round_win");
				if (iEnt != -1)
				{
					DispatchKeyValue(iEnt, "targetname", "JB_RED_WIN");
					//DispatchKeyValue(iEnt, "TeamNum", "2");
					DispatchSpawn(iEnt);
					
					SetVariantString("2");
					AcceptEntityInput(iEnt, "SetTeam");

					Debug("Team value of game_round_win is %d", GetEntProp(iEnt, Prop_Data, "m_iTeamNum"));
				}
			}
			else
			{
				SetVariantString("OnSetupFinished !self,Kill,,0.0,1");
				AcceptEntityInput(iEnt, "AddOutput");
			}
		}
	}
}



public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	if (!g_ConVars[P_Enabled].BoolValue || g_iRoundState != Round_Active)
		return;
	
	static int iMouseMovement[MAXPLAYERS_TF2][3];

	// USE is being held
	if (buttons & IN_USE)
	{
		// Player is a Warden
		Player player = new Player(client);
		if (player.IsWarden)
		{
			// Store mouse movement while holding USE
			if (!(buttons & IN_ATTACK2))
			{
				iMouseMovement[client][0] += mouse[0];
				iMouseMovement[client][1] += mouse[1];
			}
			// Clear it if player right-clicks
			else
			{
				iMouseMovement[client][0] = 0;
				iMouseMovement[client][1] = 0;
				iMouseMovement[client][2] = 0;
			}
			
			char sTop[64];
			Format(sTop, sizeof(sTop), "  %t  ", "jb_radial_warden_menu");
			
			char sLeft[64];
			if (!g_Buttons.Empty)
				Format(sLeft, sizeof(sLeft), "  %64t  ", "jb_radial_cells_button");
			
			char sRight[64];
			Format(sRight, sizeof(sRight), "  %64s  ", "");
			
			char sBottom[64];
			Format(sBottom, sizeof(sBottom), "  %t  ", "jb_radial_direct_prisoners");
			
			if (iMouseMovement[client][1] < -30)
			{
				TrimString(sTop);
				Format(sTop, sizeof(sTop), "❱ %s ❰", sTop);
				iMouseMovement[client][2] = 1;
			}
			else if (iMouseMovement[client][0] < -100)
			{
				TrimString(sLeft);
				if (!g_Buttons.Empty) Format(sLeft, sizeof(sLeft), "❱ %s ❰", sLeft);
				iMouseMovement[client][2] = 2;
			}
			else if (iMouseMovement[client][0] > 90)
			{
				//TrimString(sRight);
				//Format(sRight, sizeof(sRight), "❱ %s ❰", sRight);
				iMouseMovement[client][2] = 3;
			}
			else if (iMouseMovement[client][1] > 30)
			{
				TrimString(sBottom);
				Format(sBottom, sizeof(sBottom), "❱ %s ❰", sBottom);
				iMouseMovement[client][2] = 4;
			}
			else
			{
				iMouseMovement[client][2] = 0;
			}
			
			if (!(buttons & IN_ATTACK2))	// Continue cycling HudSync if RMB not being held
			{
				if (g_hRadialText == INVALID_HANDLE) g_hRadialText = CreateHudSynchronizer();
				SetHudTextParamsEx(-1.0, -1.0, 0.1, {255, 255, 255, 255}, {255, 255, 255, 255}, 0, 0.0, 0.0);
				ShowSyncHudText(client, g_hRadialText, "%s\n\n%s%s\n\n%s", sTop, sLeft, sRight, sBottom);
			}
		}
	}
	// USE not being held
	else
	{
		iMouseMovement[client][0] = 0;
		iMouseMovement[client][1] = 0;
		
		// Run the command if there is one in the buffer
		if (iMouseMovement[client][2])
		{
			switch (iMouseMovement[client][2])
			{
				case 1: MenuFunction(client, "menu_warden");
				case 2: if (!g_Buttons.Empty) CellControlHandler(client);
				//case 3: DebugEx(client, "Right item chosen");
				case 4: ClientCommand(client, "voicemenu 0 2");
			}
			
			// Purge command buffer
			iMouseMovement[client][2] = 0;
		}
	}
}



public void BaseComm_OnClientMute(int client, bool muteState)
{
	ShowHUD(client);
}




/**
 * ConVar Change Hook
 * ----------------------------------------------------------------------------------------------------
 */


/**
 * Print to server console when values are changed and trigger some functions
 * depending on the convar being changed.
 * 
 * @param	ConVar	ConVar handle.
 * @param	char	Old ConVar value.
 * @param	char	New ConVar value.
 * @noreturn
 */
stock void ConVar_ChangeHook(ConVar convar, const char[] oldValue, const char[] newValue)
{
	char sName[64];
	convar.GetName(sName, sizeof(sName));
	
	if (StrContains(sName, "jb_") != -1)
	{
		ShowActivity(0, "%s changed from %s to %s", sName, oldValue, newValue);
	}
	
	// Enable/Disable
	if (StrEqual(sName, "jb_enabled", false))
	{
		bool bEnabled = g_ConVars[P_Enabled].BoolValue;
		GameDescription(bEnabled);
		HookStuff(bEnabled);
		
		// Remove player roles
		for (int i = 1; i <= MaxClients; i++)
		{
			Player player = new Player(i);
			player.Flags &= ~MASK_RESET_ROLES;
		}
		
		if (bEnabled)
		{
			// Begin HUD Timers
			g_Timers[Timer_HUD] = CreateTimer(10.0, Timer_ShowHUD, _, TIMER_REPEAT);
			g_Timers[Timer_NameText] = CreateTimer(0.25, Timer_ShowNameText, _, TIMER_REPEAT);
			TriggerTimer(g_Timers[Timer_HUD]);
			
			// Prepare assets for download
			PrepareAssets();
		}
		else
		{
			// Decommission all timers
			for (int i = 0; i < Timer_Max; i++)
			{
				if (g_Timers[i] != null)
				{
					//KillTimer(g_hTimers[i]);
					//g_hTimers[i] = null;
					delete g_Timers[i];
				}
			}
		}
	}
}



/**
 * Enable Plugin
 * ----------------------------------------------------------------------------------------------------
 */

/**
 * Set server ConVars and un/hook events.
 * 
 * @param	bool	Plugin 'enabled'?
 * @noreturn
 */
stock void HookStuff(bool enabled)
{
	// ConVars
	if (enabled)
	{
		g_ConVars[S_Unbalance].IntValue = 0;
		g_ConVars[S_AutoBalance].IntValue = 0;
		g_ConVars[S_Scramble].IntValue = 0;
		g_ConVars[S_Queue].IntValue = 0;
		g_ConVars[S_FreezeTime].IntValue = PRE_ROUND_TIME;
		//g_ConVars[S_Pushaway]
		if (!(g_iGame & FLAG_OF)) g_ConVars[S_FirstBlood].IntValue = 0;
	}
	else
	{
		g_ConVars[S_Unbalance].RestoreDefault();
		g_ConVars[S_AutoBalance].RestoreDefault();
		g_ConVars[S_Scramble].RestoreDefault();
		g_ConVars[S_Queue].RestoreDefault();
		g_ConVars[S_FreezeTime].RestoreDefault();
		//g_ConVars[S_Pushaway].RestoreDefault();
		if (!(g_iGame & FLAG_OF)) g_ConVars[S_FirstBlood].RestoreDefault();
	}
	
	// Events
	if (enabled)
	{
		HookEvent("teamplay_round_start", Event_RoundRestart, EventHookMode_PostNoCopy); // Round restart
		HookEvent("teamplay_round_active", Event_RoundActive, EventHookMode_PostNoCopy); // Round has begun
		HookEvent("arena_round_start", Event_RoundActive, EventHookMode_PostNoCopy); // Round has begun (Arena)
		HookEvent("player_changeclass", Event_ChangeClass); // Player changes class
		HookEvent("player_spawn", Event_PlayerSpawn); // Player spawns
		HookEvent("player_death", Event_PlayerDeath); // Player dies
		
	}
	else
	{
		UnhookEvent("teamplay_round_start", Event_RoundRestart, EventHookMode_PostNoCopy);
		UnhookEvent("teamplay_round_active", Event_RoundActive, EventHookMode_PostNoCopy);
		UnhookEvent("arena_round_start", Event_RoundActive, EventHookMode_PostNoCopy);
		UnhookEvent("player_changeclass", Event_ChangeClass);
		UnhookEvent("player_spawn", Event_PlayerSpawn);
		UnhookEvent("player_death", Event_PlayerDeath);
	}
	
	// Commands
	if (enabled)
	{
		AddCommandListener(Command_Listener, "autoteam");
		AddCommandListener(Command_Listener, "jointeam");
		AddCommandListener(Command_Listener, "build");
		AddCommandListener(Command_Listener, "voicemenu");
		AddCommandListener(Command_Listener, "kill");
		AddCommandListener(Command_Listener, "explode");
	}
	else
	{
		RemoveCommandListener(Command_Listener, "autoteam");
		RemoveCommandListener(Command_Listener, "jointeam");
		RemoveCommandListener(Command_Listener, "build");
		RemoveCommandListener(Command_Listener, "voicemenu");
		RemoveCommandListener(Command_Listener, "kill");
		RemoveCommandListener(Command_Listener, "explode");
	}
	
	// Arrays
	if (!enabled)
	{
		delete g_CellDoors;
		delete g_Buttons;
	}
}



/**
 * Server Environment (game description & download table)
 * ----------------------------------------------------------------------------------------------------
 */

/**
 * Set the server's game description.
 *
 * @noreturn
 */
void GameDescription(bool enabled)
{
	if (!g_bSteamTools)
		return;
	
	char sGameDesc[32];
	
	if (!enabled) // Plugin not enabled
	{
		if (g_iGame & FLAG_TF)Format(sGameDesc, sizeof(sGameDesc), "Team Fortress");
		else if (g_iGame & FLAG_OF)Format(sGameDesc, sizeof(sGameDesc), "Open Fortress");
		else if (g_iGame & FLAG_TF2C)Format(sGameDesc, sizeof(sGameDesc), "Team Fortress 2 Classic");
		else Format(sGameDesc, sizeof(sGameDesc), STRING_YOUR_MOD);
	}
	else
		Format(sGameDesc, sizeof(sGameDesc), "%s | %s", PLUGIN_NAME, PLUGIN_VERSION);
	
	Steam_SetGameDescription(sGameDesc);
	PrintToServer("%s Set game description to \"%s\"", PREFIX_SERVER, sGameDesc);
}



// Add the Reticle Model to the Download Table
void PrepareAssets()
{
	// Read Reticle Model File
	Handle hFile = OpenFile("models/jb_basic_reticle.txt", "rt", true);
	
	if (hFile == null)
	{
		LogError("Unable to find jb_basic_reticle.txt");
		delete hFile;
		return;
	}
	
	char sLine[256];
	
	while (!IsEndOfFile(hFile))
	{
		ReadFileLine(hFile, sLine, sizeof(sLine));
		CleanString(sLine);
		
		if (!FileExists(sLine, true))
		{
			LogError("File listed in jb_basic_reticle.txt does not exist: %s", sLine);
			continue;
		}
		
		Debug("Adding to the download table: %s", sLine);
		AddFileToDownloadsTable(sLine);
		
		if (StrContains(sLine, ".mdl", false) != -1)
		{
			if (PrecacheModel(sLine, true))
				Debug("Successfully precached %s", sLine);
			else
				LogError("Failed to precache %s", sLine);
		}
	}
	
	// Precache Sounds
	StringMapSnapshot hSnapshot = g_Sounds.Snapshot();
	int iLength = hSnapshot.Length;
	char sKeyString[32];
	char sSound[64];
	
	Debug("%d sounds found in the string map", iLength);
	
	for (int i = 0; i < iLength; i++)
	{
		hSnapshot.GetKey(i, sKeyString, sizeof(sKeyString));
		g_Sounds.GetString(sKeyString, sSound, sizeof(sSound));
		

		if (PrecacheSound(sSound, true))
			Debug("Successfully precached %s", sSound);
		else
			LogError("Failed to precache %s", sSound);
	}

	// Delete Handles
	delete hSnapshot;
	delete hFile;
}
