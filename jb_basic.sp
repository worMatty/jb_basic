/**
 * Library Includes
 * ----------------------------------------------------------------------------------------------------
 */

#include <sourcemod>
//#include <sdktools>					// Used for GameRules stuff
//#include <sdkhooks>					// Used for hooking entities

//#undef REQUIRE_PLUGIN
//#tryinclude <tf2attributes>		// Used to set player and weapon attributes
//#tryinclude <Source-Chat-Relay>	// Discord relay

#undef REQUIRE_EXTENSIONS
#tryinclude <steamtools>		// Used to set the game description
#tryinclude <tf2_stocks>		// TF2 wrapper functions. Also includes <tf2>, the extension natives




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
#define PLUGIN_NAME			"Secret Sauce"
#define PLUGIN_DESCRIPTION	"Basic Jailbreak game mode functions"
#define MAXPLAYERS_TF2		34		// Source TV + 1 for client index offset

#define PREFIX_DEBUG		"[JB Basic] [Debug]"
#define PREFIX_SERVER		"[JB Basic]"

#define STRING_YOUR_MOD		"Source Game Server"	// Default game description when using with unsupported games/mods




/**
 * Enumerations
 * ----------------------------------------------------------------------------------------------------
 */

// Player Queue Points
enum {
	Points_Starting = 10,		// Queue points a player receives when connecting for the first time
	Points_FullAward = 10,		// Queue ponts awarded on round end
	Points_PartialAward = 5,	// Smaller amount of round end queue points awarded
	Points_Consumed = 0,		// The points a selected activator is left with
}

// ConVars
enum {
	P_Version = 0,
	P_Enabled,
	P_AutoEnable,
	P_Debug,
	S_Unbalance,
	S_AutoBalance,
	S_Scramble,
	S_Queue,
	S_FirstBlood,
	S_Pushaway,
	S_FreezeTime,
	S_AllTalk,
	ConVars_Max
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

 enum {
	Team_None,
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

// Weapon Slots
enum {
	Weapon_Primary = 0,
	Weapon_Secondary,
	Weapon_Melee,
	Weapon_Grenades,
	Weapon_Building,
	Weapon_PDA
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
#define FLAG_GUARD					( 1 << 17 )
#define FLAG_WARDEN					( 1 << 18 )
#define FLAG_PRISONER				( 1 << 19 )

// Games or Source Mods
#define FLAG_TF						( 1 << 0 )
#define FLAG_OF						( 1 << 1 ) 
#define FLAG_TF2C					( 1 << 2 )

// Flag Masks
#define MASK_DEFAULT_FLAGS			( FLAG_PREFERENCE | FLAG_FULLPOINTS )
#define MASK_STORED_FLAGS			( FLAG_PREFERENCE | FLAG_FULLPOINTS | FLAG_ENGLISH )
#define MASK_SESSION_FLAGS			( 0xFFFF0000 )
// Note: Only store specific bits to db. Session flags are 15-31




/**
 * Variables
 * ----------------------------------------------------------------------------------------------------
 */

bool g_bSteamTools;

ConVar g_ConVar[ConVars_Max];

Handle g_hReticleTimer;
Handle g_hGlowTimer;
Handle g_hRadialText;

int g_iGame;
int g_iPlayers[MAXPLAYERS_TF2][Player_ArrayMax];
int g_iEnts[Ent_ArrayMax];




/**
 * Plugin Includes
 * ----------------------------------------------------------------------------------------------------
 */

#include "jb_basic/methodmaps"
#include "jb_basic/stocks"
#include "jb_basic/events"
#include "jb_basic/commands"
#include "jb_basic/menus"




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
	g_ConVar[P_Debug]			= CreateConVar("jb_debug", "1", "Enable plugin debugging messages showing in server and client consoles");
	
	g_ConVar[S_Unbalance]		= FindConVar("mp_teams_unbalance_limit");
	g_ConVar[S_AutoBalance]		= FindConVar("mp_autoteambalance");
	g_ConVar[S_Scramble]		= FindConVar("mp_scrambleteams_auto");
	g_ConVar[S_Queue]			= FindConVar("tf_arena_use_queue");
	g_ConVar[S_FirstBlood]		= FindConVar("tf_arena_first_blood");
	g_ConVar[S_FreezeTime]		= FindConVar("mp_enableroundwaittime");
	g_ConVar[S_AllTalk] 		= FindConVar("sv_alltalk");
	if (g_iGame & FLAG_OF)				g_ConVar[S_Pushaway] = FindConVar("of_teamplay_collision");
	if (g_iGame & (FLAG_TF|FLAG_TF2C))	g_ConVar[S_Pushaway] = FindConVar("tf_avoidteammates_pushaway");
	
	// TODO Test this
	for (int i = 0; i < ConVars_Max; i++)
	{
		g_ConVar[i].AddChangeHook(ConVar_ChangeHook);
		char sName[64];
		g_ConVar[i].GetName(sName, sizeof(sName));
		Debug("Hooked convar %s", sName);
	}
	
	// Commands
	RegAdminCmd("sm_jbdata", AdminCommand_PlayerData, ADMFLAG_SLAY, "Print the values of the player data array to your console");
	RegConsoleCmd("sm_jb", Command_Menu, "Open the Jailbreak menu");
	RegConsoleCmd("sm_wm", Command_Menu, "Open the Warden menu");
}



/**
 * Library Detection
 */
public void OnAllPluginsLoaded()
{
	if (!(g_bSteamTools = LibraryExists("SteamTools")))
		LogMessage("Library not found: SteamTools. Unable to change server game description");
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
}



public void OnMapStart()
{
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
	}
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
	if (g_ConVar[P_Enabled].BoolValue)
		ServerCommand("exec config_jailbreak.cfg");
}



/**
 * OnMapEnd
 *
 * NOT called when the plugn is unloaded.
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
	if (g_ConVar[P_Enabled].BoolValue)
		if (StrEqual(classname, "tf_ammo_pack"))
			AcceptEntityInput(entity, "Kill");
}



public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	static int iMouseMovement[MAXPLAYERS_TF2][3];

	// Detected mouse movement while holding USE
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
			
			char sTop[64] = "  Top Item  ";
			char sLeft[64] = "  Left Item  ";
			char sRight[64] = "  Right Item  ";
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
				Format(sLeft, sizeof(sLeft), "❱ %s ❰", sLeft);
				iMouseMovement[client][2] = 2;
			}
			else if (iMouseMovement[client][0] > 90)
			{
				TrimString(sRight);
				Format(sRight, sizeof(sRight), "❱ %s ❰", sRight);
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
			
			//if (mouse[0] != 0 || mouse[1] != 0 || !(buttons & IN_ATTACK2))
			if (!(buttons & IN_ATTACK2))	// Right mouse button not being clicked
			{
				if (g_hRadialText == INVALID_HANDLE) g_hRadialText = CreateHudSynchronizer();
				SetHudTextParamsEx(-1.0, -1.0, 0.1, {255, 255, 255, 255}, {255, 255, 255, 255}, 0, 0.0, 0.0);
				ShowSyncHudText(client, g_hRadialText, "%s\n\n%s                    %s\n\n%s", sTop, sLeft, sRight, sBottom);
			}
		}
	}
	else
	{
		iMouseMovement[client][0] = 0;
		iMouseMovement[client][1] = 0;
		
		// Run the command
		if (iMouseMovement[client][2])
		{
			switch (iMouseMovement[client][2])
			{
				case 1: DebugEx(client, "Top item chosen");
				case 2: DebugEx(client, "Left item chosen");
				case 3: DebugEx(client, "Right item chosen");
				case 4: ClientCommand(client, "voicemenu 0 2");
			}
			iMouseMovement[client][2] = 0;
		}
	}
}