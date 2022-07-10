/**
 * Library Includes
 * ----------------------------------------------------------------------------------------------------
 */

#include <sourcemod>
#include <sdktools>					// Used for GameRules stuff
#include <sdkhooks>					// Used for working with entities

#undef REQUIRE_PLUGIN
#tryinclude <basecomm>				// Don't affect the voice status of admin-muted clients
//#tryinclude <tf2attributes>		// Used to set player and weapon attributes
//#tryinclude <Source-Chat-Relay>	// Discord relay

#undef REQUIRE_EXTENSIONS
#tryinclude <steamtools>			// Used to set the game description
#tryinclude <tf2_stocks>			// TF2 wrapper functions. Also includes <tf2>, the extension natives




/**
 * Compile Preprocessor Directives
 * ----------------------------------------------------------------------------------------------------
 */

#pragma semicolon 1
#pragma newdecls required




/**
 * Definitions
 * ----------------------------------------------------------------------------------------------------
 */

#define DEBUG
#define PLUGIN_AUTHOR		"worMatty"
#define PLUGIN_VERSION		"0.1"
#define PLUGIN_NAME			"Jailbreak Basic"
#define PLUGIN_DESCRIPTION	"Basic Jailbreak game mode functions"
#define MAXPLAYERS_TF2		34		// Source TV + 1 for client index offset

#define PREFIX_DEBUG		"[JB Basic] [Debug]"
#define PREFIX_SERVER		"[JB Basic]"

#define STRING_YOUR_MOD		"Source Game Server"	// Default game description when using with unsupported games/mods
#define PRE_ROUND_TIME		20




/**
 * Enumerations
 * ----------------------------------------------------------------------------------------------------
 */

// Player Queue Points
enum {
	Points_Starting = 10,		// Queue points a player receives when connecting for the first time
	Points_FullAward = 10,		// Queue points awarded on round end
	Points_PartialAward = 5,	// Smaller amount of round end queue points awarded
	Points_Incremental = 1,		// Number of points awarded to live players by a timer
	Points_Consumed = 0,		// The points a selected player is left with
}

// ConVars
enum {
	P_Version = 0,
	P_Enabled,
	P_AutoEnable,
	P_UseTimer,
	P_RemoteRange,
	P_RoundTime,
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

// Entities to control
enum {
	Ent_CellButton = 0,
	Ent_CellDoors,
	Ent_Reticle,
	Ent_ArrayMax
}

// Player Data Array
enum {
	Player_Index = 0,
	Player_ID,
	Player_Points,
	Player_Flags,
	Player_ArrayMax
}

// Warden Ability Cooldowns
enum {
	CD_Directions = 0,
	CD_CellDoors,
	CD_Repeat,
	CD_ArrayMax
}

 enum {
	Team_None = 0,
	Team_Spec,
	Team_Red,
	Team_Blue,
	Team_Both = 254,
	Team_All = 255
}

// Player Property "m_lifeState" Values
enum {
	LifeState_Alive,		// alive
	LifeState_Dying,		// playing death animation or still falling off of a ledge waiting to hit ground
	LifeState_Dead,			// dead. lying still.
	LifeState_Respawnable,
	LifeState_DiscardBody
}

// Round State
enum {
	Round_Waiting = 0,
	Round_Freeze,
	Round_Active,
	Round_Win
}

// Weapon Slots
enum {
	Weapon_Primary = 0,
	Weapon_Secondary,
	Weapon_Melee,
	Weapon_Grenades,
	Weapon_Building,
	Weapon_PDA,
	Weapon_ArrayMax
}

// Ammo Types
enum {
	Ammo_Dummy = 0,
	Ammo_Primary,
	Ammo_Secondary,
	Ammo_Metal,
	Ammo_Grenades1,	// Thermal Thruster fuel
	Ammo_Grenades2
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

bool g_bSteamTools;
bool g_bBasecomm;

ConVar g_ConVar[ConVars_Max];

Handle g_hTimers[Timer_Max];
Handle g_hRadialText;
Handle g_hHUDText;
Handle g_hNameText;

int g_iGame;
int g_iState;
int g_iRoundState;
int g_iPlayers[MAXPLAYERS_TF2][Player_ArrayMax];
int g_iEnts[Ent_ArrayMax];
int g_iCooldowns[CD_ArrayMax];

StringMap g_hSound;

StringMap SoundList()
{
	StringMap hSound = new StringMap();
	hSound.SetString("direction_cooldown", 	"player/recharged.wav");
	hSound.SetString("direction_goto", 		"coach/coach_go_here.wav");
	hSound.SetString("direction_lookat", 	"coach/coach_look_here.wav");
	hSound.SetString("direction_kill", 		"coach/coach_defend_here.wav");
	hSound.SetString("warden_instruction",	"buttons/button17.wav");
	hSound.SetString("chat_debug", 			"common/warning.wav");
	hSound.SetString("chat_feedback", (FileExists("sound/ui/chat_display_text.wav", true)) ? "ui/chat_display_text.wav" : "ui/buttonclickrelease.wav");
	hSound.SetString("repeat_1", 			"vo/k_lab/ba_guh.wav");
	hSound.SetString("repeat_2", 			"vo/k_lab/ba_whoops.wav");
	hSound.SetString("repeat_3", 			"vo/k_lab/ba_whatthehell.wav");
	hSound.SetString("repeat_4", 			"vo/npc/male01/whoops01.wav");
	hSound.SetString("repeat_5", 			"vo/npc/male01/pardonme02.wav");
	hSound.SetString("repeat_6", 			"vo/npc/male01/sorry01.wav");
	hSound.SetString("repeat_7", 			"vo/npc/male01/sorry03.wav");
	hSound.SetString("repeat_8", 			"vo/k_lab/kl_ohdear.wav");
	hSound.SetString("repeat_9", 			"vo/npc/male01/pardonme01.wav");
	hSound.SetString("repeat_10", 			"vo/npc/male01/excuseme01.wav");
	hSound.SetString("repeat_11", 			"vo/npc/male01/excuseme02.wav");
	hSound.SetString("repeat_12", 			"vo/k_lab/kl_interference.wav");
	hSound.SetString("repeat_13", 			"vo/k_lab2/kl_cantleavelamarr.wav"); 	
	
	return hSound;
}




/**
 * Plugin Includes
 * ----------------------------------------------------------------------------------------------------
 */

#include "jb_basic/methodmaps"
#include "jb_basic/stocks"
#include "jb_basic/events"
#include "jb_basic/commands"
#include "jb_basic/menus"
#include "jb_basic/timers"




/**
 * Plugin Info
 * ----------------------------------------------------------------------------------------------------
 */

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = ""
};




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
	g_ConVar[P_Version]			= CreateConVar("jb_version", PLUGIN_VERSION);
	g_ConVar[P_Enabled]			= CreateConVar("jb_enabled", "0", "Enabled Jailbreak");
	g_ConVar[P_AutoEnable]		= CreateConVar("jb_auto_enable", "1", "Allow the plugin to enable and disable itself based on a map's prefix");
	g_ConVar[P_UseTimer] 		= CreateConVar("jb_round_timer", "0", "Create and use a round timer if one is not built into the map");
	g_ConVar[P_RoundTime] 		= CreateConVar("jb_round_time", "600", "Round time, if enabled");
	g_ConVar[P_RemoteRange] 	= CreateConVar("jb_remote_range", "2600", "Range of the Warden's remote cell door ability when not in LOS");
	g_ConVar[P_Debug]			= CreateConVar("jb_debug", "1", "Enable plugin debugging messages showing in server and client consoles");
	
	g_ConVar[S_Unbalance]		= FindConVar("mp_teams_unbalance_limit");
	g_ConVar[S_AutoBalance]		= FindConVar("mp_autoteambalance");
	g_ConVar[S_Scramble]		= FindConVar("mp_scrambleteams_auto");
	g_ConVar[S_Queue]			= FindConVar("tf_arena_use_queue");
	g_ConVar[S_FreezeTime] 		= FindConVar("tf_arena_preround_time");
	
	if (!(g_iGame & FLAG_OF))			g_ConVar[S_FirstBlood]	= FindConVar("tf_arena_first_blood");
	if (g_iGame & FLAG_OF)				g_ConVar[S_Pushaway] 	= FindConVar("of_teamplay_collision");
	if (g_iGame & (FLAG_TF|FLAG_TF2C))	g_ConVar[S_Pushaway] 	= FindConVar("tf_avoidteammates_pushaway");
	
	// Increase the amount of pre-round freeze time possible
	SetConVarBounds(g_ConVar[S_FreezeTime], ConVarBound_Upper, true, PRE_ROUND_TIME.0);
	
	// Cycle through and hook each ConVar
	for (int i = 0; i < ConVars_Max; i++)
	{
		if (g_ConVar[i] != null)
		{
			g_ConVar[i].AddChangeHook(ConVar_ChangeHook);
			char sName[64];
			g_ConVar[i].GetName(sName, sizeof(sName));
			Debug("Hooked convar %s", sName);
		}
		else
			LogError("Unable to hook ConVar number %d", i);
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
	RegAdminCmd("sm_stripslot", Command_DebugCommands, ADMFLAG_SLAY, "Strip one of your weapons of its ammo");
	RegAdminCmd("sm_redist", Command_DebugCommands, ADMFLAG_SLAY, "Redistribute players");
	RegAdminCmd("sm_jbtextdemo", Command_DebugCommands, ADMFLAG_SLAY, "Print example text strings to your chat box");
	RegConsoleCmd("sm_lflags", Command_DebugCommands, "Print your listen flags to chat for voice chat debugging");
	RegConsoleCmd("sm_clipvals", Command_DebugCommands, "Print your weapon clip values to console");
	
	// Build Sound List
	g_hSound = SoundList();
	
	// Late Loading
	if (g_iState & FLAG_LOADED_LATE)
	{
		// Initialise Player Data Array
		LogMessage("Plugin loaded late. Initialising the player data array");
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
	
/*	// Add assets to the download table and precache them
	PrepareAssets();
	
	// Auto Enable
	if (g_ConVar[P_AutoEnable].BoolValue)
	{
		char sMapName[32];
		GetCurrentMap(sMapName, sizeof(sMapName));
		
		if (StrContains(sMapName, "jb_", false) != -1 || StrContains(sMapName, "ba_", false) != -1)
		{
			LogMessage("Detected a Jailbreak map. Enabling game mode functions");
			g_ConVar[P_Enabled].SetBool(true);
		}
	}*/
}



/**
 * Called when SteamTools connects to Steam.
 * Used to set the game description when SteamTools loads late.
 */
public int Steam_FullyLoaded()
{
	if (g_ConVar[P_Enabled].BoolValue)
		GameDescription(true);
}



/**
 * OnConfigsExecuted
 *
 * Execute config_jailbreak.cfg when all other configs have loaded.
 */
public void OnConfigsExecuted()
{
	// Add assets to the download table and precache them
	//PrepareAssets();
	
	// Auto Enable
	if (g_ConVar[P_AutoEnable].BoolValue)
	{
		char sMapName[32];
		GetCurrentMap(sMapName, sizeof(sMapName));
		
		if (StrContains(sMapName, "jb_", false) != -1 || StrContains(sMapName, "ba_", false) != -1 ||
			StrContains(sMapName, "jail_", false) != -1 || StrContains(sMapName, "jail_", false) != -1)
		// TODO Ask Berke if 'jail_' was the right prefix
		{
			LogMessage("Detected a Jailbreak map. Enabling game mode functions");
			g_ConVar[P_Enabled].SetBool(true);
		}
	}
	
	// Set required ConVar values in case the server reversed them
	//SetConVars();
	
	if (g_ConVar[P_Enabled].BoolValue)
		ServerCommand("exec config_jailbreak.cfg");
}



/**
 * OnMapEnd
 *
 * NOT called when the plugin is unloaded.
 */
public void OnMapEnd()
{
	if (g_ConVar[P_Enabled].BoolValue)
	{
		g_ConVar[P_Enabled].SetBool(false);
		LogMessage("The map has come to an end. Restoring server ConVars to defaults and unhooking things");
	}
}



public void OnPluginEnd()
{
	if (g_ConVar[P_Enabled].BoolValue)
	{
		g_ConVar[P_Enabled].SetBool(false);
		PrintToChatAll("%t %t", "prefix_important", "jb_plugin_unloaded");
		LogMessage("Plugin has been unloaded. Restoring server ConVars to defaults and unhooking things");
	}
}



public void OnClientAuthorized(int client, const char[] auth)
{
	Player player = new Player(client);
	player.CheckArray();
}



public void OnEntityCreated(int entity, const char[] classname)
{
	if (!g_ConVar[P_Enabled].BoolValue)
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
			g_ConVar[P_RoundTime].GetString(sTime, sizeof(sTime));
			
			DispatchKeyValue(iEnt, "setup_length", sSetup);
			DispatchKeyValue(iEnt, "timer_length", sTime);
			DispatchKeyValue(iEnt, "targetname", "JB_ROUND_TIMER");
			if (DispatchSpawn(iEnt))
				Debug("Created a team_round_timer %d with targetname JB_ROUND_TIMER", iEnt);
			
			SetVariantString("1");
			AcceptEntityInput(iEnt, "ShowInHUD");
			AcceptEntityInput(iEnt, "Resume");
			
			if (g_ConVar[P_UseTimer].BoolValue)
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
	if (!g_ConVar[P_Enabled].BoolValue || g_iRoundState != Round_Active)
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
			if (g_iEnts[Ent_CellButton])
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
				if (g_iEnts[Ent_CellButton]) Format(sLeft, sizeof(sLeft), "❱ %s ❰", sLeft);
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
				case 2: if (g_iEnts[Ent_CellButton]) ToggleCells(client);
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
