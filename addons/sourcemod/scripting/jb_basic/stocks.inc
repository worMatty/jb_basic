

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
	if (b[1] == a[1])return 0;
	else if (b[1] > a[1])return 1;
	else return -1;
}



/**
 * Remove special characters from a parsed string.
 * 
 * @noreturn
 */
stock void CleanString(char[] buffer)
{
	// Get the length of the string
	int iLength = strlen(buffer);
	
	// For every character, if it's a special character replace it with whitespace
	for (int i = 0; i < iLength; i++)
	{
		switch (buffer[i])
		{
			case '\r': buffer[i] = ' ';
			case '\n': buffer[i] = ' ';		// New line
			case '\t': buffer[i] = ' ';
		}
	}

	// Remove whitespace from the beginning and end
	TrimString(buffer);
}



/**
 * Process a text string into a class number.
 * 
 * @param	char	Class name string.
 * @return	int	Class number.
 */
stock int ProcessClassString(const char[] string)
{
	if 		(strncmp(string, "scout", 3, false) == 0)		return 1;
	else if (strncmp(string, "sniper", 3, false) == 0)		return 2;
	else if (strncmp(string, "soldier", 3, false) == 0)		return 3;
	else if (strncmp(string, "demo", 3, false) == 0)		return 4;
	else if (strncmp(string, "medic", 3, false) == 0)		return 5;
	else if (strncmp(string, "heavy", 3, false) == 0)		return 6;
	else if (strncmp(string, "pyro", 3, false) == 0)		return 7;
	else if (strncmp(string, "spy", 3, false) == 0)			return 8;
	else if (strncmp(string, "engineer", 3, false) == 0)	return 9;
	return 0; // Class not recognised
}



/**
 * Format class function. Displays plugin debug message in console when ConVar enabled.
 * Ex: Additionally displays to client.
 *
 * @param	int		Client index
 * @param	bool	Use sound
 * @param	string	Formatting rules
 * @param	...		Variable number of formatting arguments
 * @noreturn
 */
stock void ChatResponse(int client, bool useSound = false, const char[] string, any...)
{
	int len = strlen(string) + 255;
	char[] sBuffer = new char[len];
	VFormat(sBuffer, len, string, 4);
	
	PrintToChat(client, "%t %s", "prefix_reply", sBuffer);
	
	if (useSound)
	{
		char sSound[64];
		g_hSound.GetString("chat_feedback", sSound, sizeof(sSound));
		EmitSoundToClient(client, sSound);
	}
}



/**
 * Format class function. Displays plugin debug message in console when ConVar enabled.
 *
 * @param string		Formatting rules
 * @param ...			Variable number of formatting arguments
 * @noreturn
 */
stock void Debug(const char[] string, any...)
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
stock void DebugEx(int client, const char[] string, any...)
{
	if (!g_ConVar[P_Debug].BoolValue)
		return;
	
	int len = strlen(string) + 255;
	char[] sBuffer = new char[len];
	VFormat(sBuffer, len, string, 3);
	
	PrintToChat(client, "%t %s", "prefix_error", sBuffer);
	char sSound[64];
	g_hSound.GetString("chat_debug", sSound, sizeof(sSound));
	EmitSoundToClient(client, sSound);
	PrintToServer("%s %s", PREFIX_DEBUG, sBuffer);
}



/**
 * Send a message to all clients except the one specified.
 *
 * @param	int		Client index
 * @param	string	Formatting rules
 * @param	...		Variable number of formatting arguments
 * @noreturn
 */
stock void PrintToChatAllEx(int client, const char[] string, any...)
{
	int len = strlen(string) + 255;
	char[] sBuffer = new char[len];
	VFormat(sBuffer, len, string, 3);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || i == client)
			continue;
		
		PrintToChat(i, sBuffer);
	}
}



/**
 * Send a message to all admins.
 *
 * @param	int		Client index
 * @param	string	Formatting rules
 * @param	...		Variable number of formatting arguments
 * @noreturn
 */
stock void PrintToChatAdmins(int client, const char[] string, any...)
{
	int len = strlen(string) + 255;
	char[] sBuffer = new char[len];
	VFormat(sBuffer, len, string, 3);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetUserAdmin(i) != INVALID_ADMIN_ID)
			PrintToChat(i, sBuffer);
	}
}



/**
 * Send a message to all admins except the one specified.
 *
 * @param	int		Client index
 * @param	string	Formatting rules
 * @param	...		Variable number of formatting arguments
 * @noreturn
 */
stock void PrintToChatAdminsEx(int client, const char[] string, any...)
{
	int len = strlen(string) + 255;
	char[] sBuffer = new char[len];
	VFormat(sBuffer, len, string, 3);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetUserAdmin(i) != INVALID_ADMIN_ID && i != client)
			PrintToChat(i, sBuffer);
	}
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

bool TraceFilter(int entity, int contentsMask, any data)
{
	Debug("TraceFilter called.  Entity: %d  contentsMask: %d  data: %d", entity, contentsMask, data);
	
	/*
		TraceFilter is called for each entity my ray hits!
	
		If my ray hits nothing, 'entity' is my player index.
		If my ray hits a player, 'entity' is that player's index.
		If my ray hits an entity_soldier_statue, 'entity' is its entity index.
	*/
	
	return (entity > MaxClients);
}



/**
 * Check if an entity is within range and/or in LOS.
 *
 * @param	int		Client index
 * @param	int		Entity index
 * @param	int		Use range check
 * @param	bool	Use LOS check
 * @return	bool	Entity is within range/LOS
 */
stock bool EntInRange(int client, int entity, float range = 0.0, bool useLOS = false)
{
	// Get Entity Coordindates
	float flClientPos[3], flEntPos[3];
	GetClientAbsOrigin(client, flClientPos);
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", flEntPos);
	
	// Check if Button is in LOS
	Handle hTrace = TR_TraceRayFilterEx(flClientPos, flEntPos, CONTENTS_SOLID, RayType_EndPoint, TraceFilter);
	
	bool bSuccess;

	if (useLOS && TR_GetEntityIndex(hTrace) == entity)
	{
		Debug("Entity %d is in line of sight of %N", entity, client);
		bSuccess = true;
	}
	else if (GetVectorDistance(flClientPos, flEntPos) <= range)
	{
		Debug("Entity %d is within range of %N", entity, client);
		bSuccess = true;
	}
	
	delete(hTrace);
	return bSuccess;
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
		
		// Remove player roles
		for (int i = 1; i <= MaxClients; i++)
		{
			Player player = new Player(i);
			player.Flags &= ~MASK_RESET_ROLES;
		}
		
		if (bEnabled)
		{
			// Begin HUD Timers
			g_hTimers[Timer_HUD] = CreateTimer(10.0, Timer_ShowHUD, _, TIMER_REPEAT);
			g_hTimers[Timer_NameText] = CreateTimer(0.25, Timer_ShowNameText, _, TIMER_REPEAT);
			TriggerTimer(g_hTimers[Timer_HUD]);
			
			// Prepare assets for download
			PrepareAssets();
		}
		else
		{
			// Decommission all timers
			for (int i = 0; i < Timer_Max; i++)
			{
				if (g_hTimers[i] != null)
				{
					//KillTimer(g_hTimers[i]);
					//g_hTimers[i] = null;
					delete g_hTimers[i];
				}
			}
		}
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
		g_ConVar[S_Unbalance].IntValue = 0;
		g_ConVar[S_AutoBalance].IntValue = 0;
		g_ConVar[S_Scramble].IntValue = 0;
		g_ConVar[S_Queue].IntValue = 0;
		g_ConVar[S_FreezeTime].IntValue = PRE_ROUND_TIME;
		//g_ConVar[S_Pushaway]
		if (!(g_iGame & FLAG_OF)) g_ConVar[S_FirstBlood].IntValue = 0;
	}
	else
	{
		g_ConVar[S_Unbalance].RestoreDefault();
		g_ConVar[S_AutoBalance].RestoreDefault();
		g_ConVar[S_Scramble].RestoreDefault();
		g_ConVar[S_Queue].RestoreDefault();
		g_ConVar[S_FreezeTime].RestoreDefault();
		//g_ConVar[S_Pushaway].RestoreDefault();
		if (!(g_iGame & FLAG_OF)) g_ConVar[S_FirstBlood].RestoreDefault();
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
stock void PrepareAssets()
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
	StringMapSnapshot hSnapshot = g_hSound.Snapshot();
	int iLength = hSnapshot.Length;
	char sKeyString[32];
	char sSound[64];
	
	Debug("%d sounds found in the string map", iLength);
	
	for (int i = 0; i < iLength; i++)
	{
		hSnapshot.GetKey(i, sKeyString, sizeof(sKeyString));
		g_hSound.GetString(sKeyString, sSound, sizeof(sSound));
		

		if (PrecacheSound(sSound, true))
			Debug("Successfully precached %s", sSound);
		else
			LogError("Failed to precache %s", sSound);
	}

	// Delete Handles
	delete hSnapshot;
	delete hFile;
}







/**
 * Display Elements
 * ----------------------------------------------------------------------------------------------------
 */

/**
 * Show a translated annotation to all above a follow target.
 *
 * @param	int		Client index to use for name if used
 * @param	char	Translation phrase
 * @param	int		Entity to follow
 * @param	float	Vertical offset
 * @param	float	Lifetime
 * @param	bool	Exclude client from seeing it
 * @param	int		Sound from the global set to use
 * @noreturn
 */
stock void ShowAnnotation(int client = 0, const char[] phrase, int entity, float offset = 0.0, float lifetime = 5.0, bool exclude = false, const char[] sound = "")
{
	// TODO Provide initial coordinates to stop 'snapping' into place
	// TODO Get the height of a model, its origin and calculate the offset
	Event hAnnot = CreateEvent("show_annotation");
	if (hAnnot)
	{
		char sName[32], sText[256], sSound[64];
		float vPos[3];
		
		GetClientName(client, sName, sizeof(sName));
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);
		g_hSound.GetString(sound, sSound, sizeof(sSound));
		
		hAnnot.SetFloat("worldPosX", vPos[0]);
		hAnnot.SetFloat("worldPosY", vPos[1]);
		hAnnot.SetFloat("worldPosZ", vPos[2] += offset);
		hAnnot.SetFloat("lifetime", lifetime);
		hAnnot.SetString("play_sound", sSound);
		hAnnot.SetBool("show_effect", false);
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



/**
 * Refresh the HUD for all players or just a specific one.
 *
 * @param	int		Client index
 * @noreturn
 */
stock void ShowHUD(int client = 0)
{
	char sString[128];
	
	if (g_hHUDText == INVALID_HANDLE) g_hHUDText = CreateHudSynchronizer();
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (client)
			i = client;
		
		Player player = new Player(i);
		
		if (!player.InGame)
			continue;
		
		if (player.IsWarden)
		{
			char sDirections[16], sCells[16];
			
			switch (g_iCooldowns[CD_Directions])
			{
				case 0: sDirections = "☞ ∎∎∎";
				case 1: sDirections = "☞ ∎∎";
				case 2: sDirections = "☞ ∎";
				case 3: sDirections = "☞ ";
			}
			
			switch (g_iCooldowns[CD_CellDoors])
			{
				case 0: sCells = "⚿  ∎∎∎";
				case 1: sCells = "⚿  ∎∎";
				case 2: sCells = "⚿  ∎";
				case 3: sCells = "⚿ ";
			}
			
			Format(sString, sizeof(sString), "%s\n%s", sDirections, sCells);
		}
		else if (player.Team == Team_Red || !player.IsAlive)
		{
			switch (player.IsMuted)
			{
				case 0: Format(sString, sizeof(sString), "⯈ %t", "jb_hud_not_muted");
				case 1: Format(sString, sizeof(sString), "■ %t", "jb_hud_muted");
				case 2: Format(sString, sizeof(sString), "■ %t", "jb_hud_muted_by_admin");
			}
			
			char sRepeat[16];
			
			if (player.Team == Team_Red && player.IsAlive)
			{
				switch (g_iCooldowns[CD_Repeat])
				{
					case 0: sRepeat = "⭯ ∎∎∎";
					case 1: sRepeat = "⭯ ∎∎";
					case 2: sRepeat = "⭯ ∎";
					case 3: sRepeat = "⭯ ";
				}
			}
			Format(sString, sizeof(sString), "%s\n%s", sString, sRepeat);
		}
		
		SetHudTextParamsEx(0.20, 0.85, 10.0, { 255, 255, 255, 255 }, { 255, 255, 255, 255 }, 0, 0.0, 0.0);
		ShowSyncHudText(i, g_hHUDText, sString);
		
		if (client)
			break;
	}
}
// Work: 👉 ⛳ ⚐ ⚿ ▦ ■ █ ∎ ⯈ ⯀ (Unicode Misc Symbols)
// Don't work: 🔑 🚩 🔐 🚪 🏠 🔓 (presumably Unicode Emoji? Graphical represenations of symbols?)



/**
 * Name Text
 *
 * @noreturn
 */
stock void ShowNameText()
{	
	if (g_hNameText == INVALID_HANDLE) g_hNameText = CreateHudSynchronizer();
	
	for (int i = 1; i <= MaxClients; i++)
	{
		Player player = new Player(i);
		
		if (player.InGame && (player.IsWarden || player.IsOfficer))
		{
			int iTarget = GetClientAimTarget(player.Index, true);
			if (iTarget > 0)
			{
				Player target = new Player(iTarget);
				if (target.Team == Team_Red)
				{
					char sName[32];
					GetClientName(target.Index, sName, sizeof(sName));
					SetHudTextParamsEx(-1.0, 0.52, 0.3, { 255, 255, 255, 255 }, { 255, 255, 255, 255 }, 0, 0.0, 0.0);
					ShowSyncHudText(player.Index, g_hNameText, sName);
				}
			}
		}
	}
}





/**
 * Game Mechanics
 * ----------------------------------------------------------------------------------------------------
 */

/**
 * Toggle cell doors. Uses the func_button first and falls back
 * to the func_doors if a button wasn't found.
 * Adds '1' to the charge tally for cooldown.
 * 
 * @param	int		Client index of the person using the function, used for responses
 * @param	bool	Set to false to close the doors if the button wasn't found
 * @return	bool	The entity accepted the input
 */
stock bool ToggleCells(int client, bool open = true)
{
	// If no ents were found
	if (!(g_iEnts[Ent_CellDoors] + g_iEnts[Ent_CellButton]))
	{
		ChatResponse(client, _, "%t", "jb_response_unable_toggle_cells");
		return false;
	}
	
	// If the ability is on cooldown
	if (g_iCooldowns[CD_CellDoors] > 2)
	{
		ChatResponse(client, _, "%t", "jb_remote_cells_on_cooldown");
		return false;
	}
	
	bool bSuccess;
	
	// If the button was found
	if (g_iEnts[Ent_CellButton])
	{
		if (EntInRange(client, g_iEnts[Ent_CellButton], g_ConVar[P_RemoteRange].FloatValue, true))
		{
			if (AcceptEntityInput(g_iEnts[Ent_CellButton], "PressIn", client, client))
			{
				ChatResponse(client, true, "%t", "jb_cells_you_pressed_button");
				PrintToChatAllEx(client, "%t %t", "prefix", "jb_cells_warden_pressed_button");
				bSuccess = true;
			}
			else
			{
				ChatResponse(client, _, "%t", "jb_problem_accepting_input");
			}
		}
		else
		{
			ChatResponse(client, _, "%t", "jb_out_of_range_of_button");
		}
	}
	// Else use the doors
	else if (g_iEnts[Ent_CellDoors])
	{
		if (EntInRange(client, g_iEnts[Ent_CellDoors], g_ConVar[P_RemoteRange].FloatValue, true))
		{
			if (open)
			{
				if (AcceptEntityInput(g_iEnts[Ent_CellDoors], "Open", client, client))
				{
					ChatResponse(client, true, "%t", "jb_cells_you_opened");
					PrintToChatAllEx(client, "%t %t", "prefix", "jb_cells_warden_opened");
					bSuccess = true;
				}
				else
				{
					ChatResponse(client, _, "%t", "jb_problem_accepting_input");
				}
			}
			else
			{
				if (AcceptEntityInput(g_iEnts[Ent_CellDoors], "Close", client, client))
				{
					PrintToChatAll("%t %t", "prefix", "jb_cells_warden_closed");
					bSuccess = true;
				}
				else
				{
					ChatResponse(client, _, "%t", "jb_problem_accepting_input");
				}
			}
		}
		else
		{
			ChatResponse(client, _, "%t", "jb_out_of_range_of_cell_doors");
		}
	}
	
	if (bSuccess)
	{
		g_iCooldowns[CD_CellDoors] += 1;
		CreateTimer(30.0, Timer_Cooldowns, CD_CellDoors);
		//ShowCooldowns();
		ShowHUD();
	}
	
	return bSuccess;
}



/**
 * Redistribute players.
 * 
 * @noreturn
 */
stock void Redistribute()
{
	/*
		Check player numbers on each team.
		Count clients on each and do a division thing. Do we need to rebalance? Is there a tolerance?
		Look at queue points. Take the blue players with the fewest points and move them to red.
		Drag in some reds if we need them. Should we take away their points?
		Take away the points from blues who were still remaining.
		
		Do we need a separate set of points for Wardenship?
	*/
	
	int iReds = GetTeamClientCount(Team_Red);
	int iBlues = GetTeamClientCount(Team_Blue);
	
	int iTotal = (iReds + iBlues);
	int iBluesNeeded = RoundFloat(iTotal * 0.3572); // Old values 3.6 or 0.3571428571428571
	
	int iDeficit = iBluesNeeded - iBlues;
	
	Debug("Players on Red: %d  Players on Blue: %d  Total Players: %d", iReds, iBlues, iTotal);
	Debug("Blues Needed: %d  Deficit: %d  We need to move %d players from %s", iBluesNeeded, iDeficit, (0 - iDeficit), (iDeficit > 0) ? "RED" : "BLUE");
	
	// We have too many Reds
	if (iDeficit > 0)
	{
		while (iDeficit > 0)
		{
			// Pick a random Red
			Player player = new Player(PickRandomParticipant(Team_Red));
			if (!player.Index)
				ThrowError("Couldn't find a player on the Red team");
			Debug("Moving %N from Red to Blue", player.Index);
			player.SetTeam(Team_Blue);
			iDeficit -= 1;
		}
	}
	
	// We have too many Blues
	else if (iDeficit < 0)
	{
		// Get number of non-Warden blues
		int iNonWardens;
		for (int i = 1; i <= MaxClients; i++)
		{
			Player player = new Player(i);
			if (player.InGame && player.Team == Team_Blue && !player.IsWarden)
				iNonWardens += 1;
		}
		
		if (iNonWardens)
		{
			while (iNonWardens > 0 && iDeficit != 0)
			{
				Debug("Finding a Blue player to move to Red");
				Player player = new Player(PickRandomParticipant(Team_Blue));
				if (!player.IsWarden)
				{
					if (!player.Index)
						ThrowError("Couldn't find a player on the Blue team");
					Debug("Moving %N from Blue to Red", player.Index);
					player.SetTeam(Team_Red);
					iDeficit += 1;
					iNonWardens -= 0;
				}
			}
		}
	}
	
	// If running in Open Fortress or TF2C, respawn all players
	if (g_iGame & (FLAG_OF|FLAG_TF2C)) // TODO Change to a check if the native is available
	{
		int iRespawn = CreateEntityByName("game_forcerespawn");
		if (iRespawn == -1)
		{
			LogError("Unable to create game_forcerespawn");
		}
		else
		{
			if (!DispatchSpawn(iRespawn))
			{
				LogError("Unable to spawn game_forcerespawn");
			}
			else
			{
				if (!AcceptEntityInput(iRespawn, "ForceRespawn"))
				{
					LogError("game_forcerespawn wouldn't accept our ForceRespawn input");
				}
				else
				{
					Debug("Respawned all players by creating a game_forcerespawn");
				}
			}
			
			AcceptEntityInput(iRespawn, "Kill");
			//RemoveEdict(iRespawn);
		}
	}
}



/**
 * Pick a random player from a team.
 * 
 * @param	int		Team number
 * @return	int		Client index
 */
stock int PickRandomParticipant(int team)
{
	int iTable[MAXPLAYERS_TF2];
	int iIndex;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		Player player = new Player(i);
		
		if (player.InGame && player.Team == team)
		{
			iTable[iIndex] = player.Index;
			Debug("Storing player %d (%N) in iTable cell %d", player.Index, player.Index, iIndex);
			iIndex += 1;
		}
	}
	
	int iSelection = iTable[GetRandomInt(0, iIndex - 1)];
	Debug("PickRandomParticipant selected %d (%N)", iSelection, iSelection);
	return iSelection;
}



/**
 * Select a Warden
 * 
 * @return	int		Client index
 */
stock int SelectWarden()
{
	/*
		Make a list of people opted into Warden on Blue team.
		Find who has the most queue points.
		Make them Warden.
		
		If no one on Blue has opted in, select a Blue player at random.
		If there are no players on Blue, select a Red player at random and move them.
		Make them Warden, reset their queue points and take their name out of the pool.
	*/
	
	// Create an array of Blue players wanting to become Warden
	int iTable[MAXPLAYERS_TF2];
	int iIndex;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		Player player = new Player(i);
		
		if (player.InGame)
			Debug("%N does %s have the flag FLAG_WANTS_WARDEN", player.Index, (player.HasFlag(FLAG_WANTS_WARDEN)) ? "" : "not");
		
		if (player.InGame && player.Team == Team_Blue && player.HasFlag(FLAG_WANTS_WARDEN))
		{
			iTable[iIndex] = player.Index;
			Debug("Storing player %d (%N) in iTable cell %d", player.Index, player.Index, iIndex);
			iIndex += 1;
		}
	}
	
	// Cycle through the array and select the player with the most points
	int iSelection, iPoints;
	
	for (int i = 0; iTable[i]; i++)					// iTable[i] is the player index
	{
		Player player = new Player(iTable[i]);		// Turn the client index stored in the cell to a Player
		Debug("SelectWarden is checking points for iTable[%d] (%N)", i, player.Index);
		if (player.Points > iPoints)
		{
			iPoints = player.Points;
			iSelection = player.Index;
		}
	}
	
	Debug("SelectWarden selected %d (%N)", iSelection, iSelection);
	return iSelection;
}



/*
	Warden Pool
	
	Opt in using a command or by setting a permanent option.
	When using a command, player gets a new flag that marks them as wanting to be a warden.
	Permanent option players get a stored flag.
	
	When a round becomes active, the pool of Wardens is checked. Most points gets selected.
*/