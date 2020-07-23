

/**
 * General Purpose
 * ----------------------------------------------------------------------------------------------------
 */

/**
 * Sorting function used by SortCustom2D. Sorts players by queue points.
 * 
 * @return	int	
 */
stock int SortByPoints(int[] a, int[] b, const int[][] array, Handle hndl)
{
	if 			(b[1] == a[1])		return 0;
	else if 	(b[1] > a[1])		return 1;
	else							return -1;
}



/**
 * Process a text string into a class number.
 * 
 * @param	char	Class name string.
 * @return	int	Class number.
 */
stock int ProcessClassString(const char[] string)
{
	if 			(strncmp(string, "scout", 3, false) == 0)		return 1;
	else if		(strncmp(string, "sniper", 3, false) == 0)		return 2;
	else if 	(strncmp(string, "soldier", 3, false) == 0)		return 3;
	else if 	(strncmp(string, "demo", 3, false) == 0)		return 4;
	else if 	(strncmp(string, "medic", 3, false) == 0)		return 5;
	else if 	(strncmp(string, "heavy", 3, false) == 0)		return 6;
	else if 	(strncmp(string, "pyro", 3, false) == 0)		return 7;
	else if 	(strncmp(string, "spy", 3, false) == 0)			return 8;	
	else if 	(strncmp(string, "engineer", 3, false) == 0)	return 9;
	return 0;	// Class not recognised
}



/**
 * Format class function. Displays plugin debug message in console when ConVar enabled.
 *
 * @param string		Formatting rules
 * @param ...			Variable number of formatting arguments
 * @noreturn
 */
stock void Debug(const char[] string, any ...)
{
	if (!g_ConVar[P_Debug].BoolValue)
		return;
	
	int len = strlen(string) + 255;
	char[] sBuffer = new char[len];
	VFormat(sBuffer, len, string, 2);
	
	PrintToServer("%s %s", PREFIX_DEBUG, sBuffer);
}




/**
 * Format class function. Displays plugin debug message in console when ConVar enabled.
 * Ex: Additionally displays to client.
 *
 * @param	int	Client index
 * @param	string	Formatting rules
 * @param	...	Variable number of formatting arguments
 * @noreturn
 */
stock void DebugEx(int client, const char[] string, any ...)
{
	if (!g_ConVar[P_Debug].BoolValue)
		return;
	
	int len = strlen(string) + 255;
	char[] sBuffer = new char[len];
	VFormat(sBuffer, len, string, 3);
	
	PrintToChat(client, "%t %s", "prefix_error", sBuffer);
	PrintToServer("%s %s", PREFIX_DEBUG, sBuffer);
}




/**
 * Server Environment
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
	PrintToServer("%s %s has been changed from '%s' to '%s'", PREFIX_SERVER, sName, oldValue, newValue);
	
	// Enable/Disable
	if (StrEqual(sName, "jb_enabled", false))
	{
		bool bEnabled = g_ConVar[P_Enabled].BoolValue;
		GameDescription(bEnabled);
		HookStuff(bEnabled);
	}
}




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
		g_ConVar[S_Unbalance].IntValue 		= 0;
		g_ConVar[S_AutoBalance].IntValue 	= 0;
		g_ConVar[S_Scramble].IntValue 		= 0;
		g_ConVar[S_Queue].IntValue 			= 0;
		g_ConVar[S_FirstBlood].IntValue 	= 0;
		//g_ConVar[S_FreezeTime]
		//g_ConVar[S_Pushaway]
		g_ConVar[S_AllTalk].IntValue 		= 0;
	}
	else
	{
		g_ConVar[S_Unbalance].RestoreDefault();
		g_ConVar[S_AutoBalance].RestoreDefault();
		g_ConVar[S_Scramble].RestoreDefault();
		g_ConVar[S_Queue].RestoreDefault();
		g_ConVar[S_FirstBlood].RestoreDefault();
		g_ConVar[S_FreezeTime].RestoreDefault();
		g_ConVar[S_AllTalk].RestoreDefault();
		//g_ConVar[S_Pushaway].RestoreDefault();
	}
	
	// Events
	if (enabled)
	{
		HookEvent("teamplay_round_start", Event_RoundRestart, EventHookMode_PostNoCopy);	// Round restart
		HookEvent("teamplay_round_active", Event_RoundActive, EventHookMode_PostNoCopy);	// Round has begun
		HookEvent("arena_round_start", Event_RoundActive, EventHookMode_PostNoCopy);		// Round has begun (Arena)
		HookEvent("player_changeclass", Event_ChangeClass);									// Player changes class
		HookEvent("player_spawn", Event_PlayerSpawn);										// Player spawns
		HookEvent("player_death", Event_PlayerDeath);										// Player dies
		
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
		AddCommandListener(Command_Listener, "build");
		AddCommandListener(Command_Listener, "voicemenu");
		
	}
	else
	{
		RemoveCommandListener(Command_Listener, "autoteam");
		RemoveCommandListener(Command_Listener, "build");
		RemoveCommandListener(Command_Listener, "voicemenu");
	}
}




/**
 * Set the server's game description.
 *
 * @noreturn
 */
stock void GameDescription(bool enabled)
{
	if (!g_bSteamTools)
		return;
	
	char sGameDesc[32];
	
	if (!enabled)	// Plugin not enabled
	{
		if			(g_iGame & FLAG_TF)		Format(sGameDesc, sizeof(sGameDesc), "Team Fortress");
		else if		(g_iGame & FLAG_OF)		Format(sGameDesc, sizeof(sGameDesc), "Open Fortress");
		else if		(g_iGame & FLAG_TF2C)	Format(sGameDesc, sizeof(sGameDesc), "Team Fortress 2 Classic");
		else								Format(sGameDesc, sizeof(sGameDesc), STRING_YOUR_MOD);
	}
	else
		Format(sGameDesc, sizeof(sGameDesc), "%s | %s", PLUGIN_NAME, PLUGIN_VERSION);
	
	Steam_SetGameDescription(sGameDesc);
	PrintToServer("%s Set game description to \"%s\"", PREFIX_SERVER, sGameDesc);
}



/**
 * Get your crosshair's aim target position.
 *
 * @param	int	Client index
 * @return	float	Position of aim target
 */
void GetCrosshair(int client, float pos[3])
{
	float vEyePos[3], vEyeAngles[3];
	
	GetClientEyePosition(client, vEyePos);
	GetClientEyeAngles(client, vEyeAngles);
	
	Handle hTrace = TR_TraceRayFilterEx(vEyePos, vEyeAngles, MASK_PLAYERSOLID, RayType_Infinite, TraceFilter);
	
	if (TR_DidHit(hTrace))
		TR_GetEndPosition(pos, hTrace);
	
	CloseHandle(hTrace);
}

bool TraceFilter(int entity, int contentsMask)
{
	return entity > MaxClients;
}




/**
 * Show a translated annotation to all above a follow target.
 *
 * @param	int		Client index to use for name if used
 * @param	char	Translation phrase
 * @param	int		Entity to follow
 * @param	float	Vertical offset
 * @param	float	Lifetime
 * @param	bool	Exclude client from seeing it
 */
stock void ShowAnnotation(int client = 0, const char[] phrase, int entity, float offset = 0.0, float lifetime = 5.0, bool exclude = false)
{
	// TODO Provide initial coordinates to stop 'snapping' into place
	// TODO Get the height of a model, its origin and calculate the offset
	Event hAnnot = CreateEvent("show_annotation");
	if (hAnnot)
	{
		char sName[32];
		char sText[256];
		float vPos[3];
		
		GetClientName(client, sName, sizeof(sName));
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);
		
		hAnnot.SetFloat("worldPosX", vPos[0]);
		hAnnot.SetFloat("worldPosY", vPos[1]);
		hAnnot.SetFloat("worldPosZ", vPos[2] += offset);
		hAnnot.SetFloat("lifetime", lifetime);
		hAnnot.SetBool("show_effect", true);
		if (offset == 0.0) hAnnot.SetInt("follow_entindex", entity);
		
		for (int i = 1; i <= MaxClients; i++)
		{
			Player player = new Player(i);
			if (player.InGame)
			{
				if (!(exclude && player.Index == client))
				{
					SetGlobalTransTarget(i);
					Format(sText, sizeof(sText), "%t", phrase, sName);
					hAnnot.SetString("text", sText);
					hAnnot.FireToClient(i);
				}
			}
		}
		
		hAnnot.Cancel();
	}
}
