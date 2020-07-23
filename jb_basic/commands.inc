/**
 * Client Commands
 * ----------------------------------------------------------------------------------------------------
 */

Action Command_Listener(int client, const char[] command, int args)
{
	Player player = new Player(client);

	// Block Engineer Builds
	if (StrEqual(command, "build", false))
	{
		ReplyToCommand(client, "%t %t", "prefix_personal", "jb_engineer_buildings_not_allowed");
		return Plugin_Handled;
	}
	
	// Block Autoteam (bypasses balancing)
	if (StrEqual(command, "autoteam", false))
	{
		ReplyToCommand(client, "%t %t", "prefix_personal", "jb_command_autoteam_disallowed");
		return Plugin_Handled;
	}

	// Warden Voice Commands
	if (StrEqual(command, "voicemenu", false) && player.IsWarden)
	{
		char sArgs[4];
		GetCmdArgString(sArgs, sizeof(sArgs));
		
		// Reticle ("Go go go!")
		if (StrEqual(sArgs, "0 2"))
		{
			if (g_hReticleTimer != null)
				TriggerTimer(g_hReticleTimer);
				
			if (g_hGlowTimer != null)
				TriggerTimer(g_hGlowTimer);

			// Is it a door or func_brush?
			bool bEntityTargeted;
			bool bColor;
			int iEnt = GetClientAimTarget(player.Index, false);
			if (iEnt > MaxClients)
			{
				char sClassname[64];
				GetEntityClassname(iEnt, sClassname, sizeof(sClassname));
				
				if (StrContains(sClassname, "door") != -1)
				{
					bEntityTargeted = true;
					DebugEx(player.Index, "You targeted a door (%s)", sClassname);
					bColor = (StrContains(sClassname, "prop") == -1);
					ShowAnnotation(player.Index, "jb_annotation_enter_here", iEnt, 64.0, 10.0);
				}
				else if (StrEqual(sClassname, "func_brush") || StrEqual(sClassname, "prop_dynamic"))
				{
					bEntityTargeted = true;
					DebugEx(player.Index, "You targeted a %s", sClassname);
					
					// Is it a brush or a prop?
					if (StrContains(sClassname, "prop") == -1)
					{
						bColor = true;
						ShowAnnotation(player.Index, "jb_annotation_move_here", iEnt, 64.0, 10.0);
					}
					else
						ShowAnnotation(player.Index, "jb_annotation_investigate_this", iEnt, _, 10.0);
				}
				
				// We targeted an entity
				if (bEntityTargeted)
				{
					// Back-up its targetname and change it
					char sTargetname[256];
					GetEntPropString(iEnt, Prop_Data, "m_iName", sTargetname, sizeof(sTargetname));
					SetEntPropString(iEnt, Prop_Data, "m_iName", "JB_GLOWING_ENTITY");
					
					// Create a glow entity which will glow any models
					int iGlow = CreateEntityByName("tf_glow");
					if (iGlow != -1)
					{
						// Parent field is used to store the entity's index so the timer can restore its colour
						char sParent[5];
						IntToString(iEnt, sParent, sizeof(sParent));
						SetEntPropString(iGlow, Prop_Data, "m_iParent", sParent);
						
						DispatchKeyValue(iGlow, "target", "JB_GLOWING_ENTITY");
						DispatchKeyValue(iGlow, "GlowColor", "0 255 0 255");
						DispatchKeyValue(iGlow, "targetname", "JB_GLOW");
						DispatchSpawn(iGlow);
						g_hGlowTimer = CreateTimer(10.0, Timer_RemoveGlow, EntIndexToEntRef(iGlow));
					}
					
					// Restore its targetname
					SetEntPropString(iEnt, Prop_Data, "m_iName", sTargetname);
					
					// Colour the entity
					if (bColor)
					{
						int iColor[4];
						GetEntityRenderColor(iEnt, iColor[0], iColor[1], iColor[2], iColor[3]);
						if ((iColor[0] + iColor[1] + iColor[2] + iColor[3]) == 1020)
							SetEntityRenderColor(iEnt, 0, 255, 0, 255);
					}
				}
			}

			// If a func_brush or door was not targeted create a reticle
			iEnt = CreateEntityByName("prop_dynamic");
			if (!bEntityTargeted && iEnt != -1)
			{
				DispatchKeyValue(iEnt, "model", "models/wormatty/test/jb_reticle1.mdl");
				DispatchKeyValue(iEnt, "DisableBoneFollowers", "1");
				DispatchKeyValue(iEnt, "DisableReceiveShadows", "1");
				DispatchKeyValue(iEnt, "DisableShadows", "1");
				DispatchKeyValue(iEnt, "targetname", "WORMATTYS_JB_RETICLE");
				if (DispatchSpawn(iEnt))
				{
					float vDest[3];
					GetCrosshair(player.Index, vDest);
					TeleportEntity(iEnt, vDest, NULL_VECTOR, NULL_VECTOR);
					ShowAnnotation(player.Index, "jb_annotation_move_here", iEnt, 96.0);
					g_hReticleTimer = CreateTimer(10.0, Timer_RemoveReticle, EntIndexToEntRef(iEnt));
				}
				else
				{
					LogError("Failed to spawn a Warden reticle for %N", player.Index);
					RemoveEdict(iEnt);
				}
			}
			else if (!bEntityTargeted)
			{
				LogError("Failed to create a Warden reticle for %N", player.Index);
				RemoveEdict(iEnt);
			}
			
			// Only play the voice line a third of the time to reduce spam
			if (GetRandomInt(0, 3))
				return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

Action Timer_RemoveReticle(Handle timer, int model)
{
	if (model != INVALID_ENT_REFERENCE)
	{
		model = EntRefToEntIndex(model);
		RemoveEdict(model);
	}
	
	g_hReticleTimer = null;
	return Plugin_Handled;
}

Action Timer_RemoveGlow(Handle timer, int glow)
{
	if (glow != INVALID_ENT_REFERENCE)
	{
		glow = EntRefToEntIndex(glow);
		
		char sParent[5];
		GetEntPropString(glow, Prop_Data, "m_iParent", sParent, sizeof(sParent));
		int iEnt = StringToInt(sParent);
		
		if (iEnt)
		{
			int iColor[4];
			GetEntityRenderColor(iEnt, iColor[0], iColor[1], iColor[2], iColor[3]);
			
			//Debug("Entity colours: %d %d %d %d (%d)", iColor[0], iColor[1], iColor[2], iColor[3], (iColor[0] + iColor[1] + iColor[2] + iColor[3]));
			if ((iColor[0] + iColor[1] + iColor[2] + iColor[3]) == 510)
			{
				SetEntityRenderColor(iEnt, 255, 255, 255, 255);
			}
		}
		
		RemoveEdict(glow);
	}
	
	g_hGlowTimer = null;
	return Plugin_Handled;
}




Action Command_Menu(int client, int args)
{
	if (!g_ConVar[P_Enabled].BoolValue)
		return Plugin_Handled;
	
	char sCommand[32];
	GetCmdArg(0, sCommand, sizeof(sCommand));
	Player player = new Player(client);
	
	if (StrEqual(sCommand, "sm_jb", false))
		MenuFunction(client, "menu_main");
	
	if (StrEqual(sCommand, "sm_wm", false))
		if (player.Flags & FLAG_WARDEN)
			MenuFunction(client, "menu_warden");
	
	return Plugin_Handled;
}




Action AdminCommand_PlayerData(int client, int args)
{
	PrintToConsole(client, "\n %s Player points and preference flags\n  Please note: The table will show values for unoccupied slots. These are from\n  previous players and are reset when someone new takes the slot.\n", PREFIX_SERVER);
	PrintToConsole(client, " Index | User ID | Steam ID   | Name                             | Points | Flags");
	PrintToConsole(client, " ----------------------------------------------------------------------------------------");
	
	for (int i = 1; i <= MaxClients; i++)
	{
		Player player = new Player(i);
		char sName[MAX_NAME_LENGTH] = "<no player>";
		if (player.InGame)
			Format(sName, MAX_NAME_LENGTH, "%N", player.Index);
		PrintToConsole(client, " %5d | %7d | %10d | %32s | %6d | %06b %06b", player.Index, player.ArrayUserID, player.SteamID, sName, player.Points, ((player.Flags & MASK_SESSION_FLAGS) >> 16), (player.Flags & MASK_STORED_FLAGS));
			// This bit shift operation should take the resulting bits and shift them all down to the 'stored' range for display purposes
	}
	
	PrintToConsole(client, " ----------------------------------------------------------------------------------------");
	ReplyToCommand(client, "%t %t", "prefix_personal", "jb_check_console");
	
	return Plugin_Handled;
}