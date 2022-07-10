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
		PrintToChat(client, "%t %t", "prefix_reply", "jb_engineer_buildings_not_allowed");
		return Plugin_Handled;
	}
	
	// Block Autoteam (bypasses balancing)
	if (StrEqual(command, "autoteam", false))
	{
		PrintToChat(client, "%t %t", "prefix_reply", "jb_command_autoteam_disallowed");
		return Plugin_Handled;
	}
	
	// Block Team Joins When Redistributing
	if (StrEqual(command, "jointeam", false))
	{
		if (player.IsWarden)
		{
			PrintToChat(player.Index, "%t %t", "prefix_reply", "jb_warden_cant_change_team");
			return Plugin_Handled;
		}
	}

	// Warden Voice Commands
	if (StrEqual(command, "voicemenu", false) && player.IsWarden && g_iRoundState == Round_Active)
	{
		char sArgs[4];
		GetCmdArgString(sArgs, sizeof(sArgs));
		
		// Reticle ("Go go go!")
		if (StrEqual(sArgs, "0 2"))
		{
			if (g_iCooldowns[CD_Directions] > 2)
			{
				PrintToChat(player.Index, "%t %t", "prefix_reply", "jb_reticle_on_cooldown");
				return Plugin_Handled;
			}
			else
			{
				g_iCooldowns[CD_Directions] += 1;
				CreateTimer(10.0, Timer_Cooldowns, CD_Directions);
				//ShowCooldowns();
				ShowHUD();
			}
			
			if (g_hTimers[Timer_Direction] != null)
				TriggerTimer(g_hTimers[Timer_Direction]);
				
			if (g_hTimers[Timer_Glow] != null)
				TriggerTimer(g_hTimers[Timer_Glow]);

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
					ShowAnnotation(player.Index, "jb_annotation_enter_here", iEnt, _, 10.0, _, "direction_goto");
				}
				else if (StrEqual(sClassname, "func_brush") || StrEqual(sClassname, "prop_dynamic"))
				{
					bEntityTargeted = true;
					DebugEx(player.Index, "You targeted a %s", sClassname);
					
					// Is it a brush or a prop?
					if (StrContains(sClassname, "prop") == -1)
					{
						bColor = true;
						ShowAnnotation(player.Index, "jb_annotation_move_here", iEnt, _, 10.0, _, "direction_goto");
					}
					else
						ShowAnnotation(player.Index, "jb_annotation_investigate_this", iEnt, _, 10.0, _, "direction_lookat");
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
						g_hTimers[Timer_Glow] = CreateTimer(10.0, Timer_RemoveGlow, EntIndexToEntRef(iGlow));
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
					ShowAnnotation(player.Index, "jb_annotation_move_here", iEnt, 96.0, _, _, "direction_goto");
					g_hTimers[Timer_Direction] = CreateTimer(10.0, Timer_RemoveReticle, EntIndexToEntRef(iEnt));
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
		
		// Highlight Inmate for Elimination ("Battle Cry")
		else if (StrEqual(sArgs, "2 1"))
		{
			int iTarget = GetClientAimTarget(player.Index, true);
			Player iPlayer = new Player(iTarget);
			
			if (iPlayer.IsValid && iPlayer.Team == Team_Red)
			{
				char sName[32];
				GetClientName(iPlayer.Index, sName, sizeof(sName));
				
				ReplyToCommand(player.Index, "%t %t", "prefix_reply", "jb_marked_target_for_death", sName);
				ShowAnnotation(iPlayer.Index, "jb_annotation_marked_target_for_death", iPlayer.Index, _, 5.0, _, "direction_kill");
				
				// Back-up their targetname and change it
				char sTargetname[256];
				GetEntPropString(iPlayer.Index, Prop_Data, "m_iName", sTargetname, sizeof(sTargetname));
				SetEntPropString(iPlayer.Index, Prop_Data, "m_iName", "JB_GLOWING_PLAYER");
				
				// Create a glow entity
				int iGlow = CreateEntityByName("tf_glow");
				if (iGlow != -1)
				{
					//char sParent[5];
					//IntToString(iPlayer.Index, sParent, sizeof(sParent));
					//SetEntPropString(iGlow, Prop_Data, "m_iParent", sParent);
					
					DispatchKeyValue(iGlow, "target", "JB_GLOWING_PLAYER");
					DispatchKeyValue(iGlow, "GlowColor", "255 0 0 200");
					DispatchKeyValue(iGlow, "targetname", "JB_GLOW");
					DispatchSpawn(iGlow);
					CreateTimer(5.0, Timer_RemoveInmateGlow, EntIndexToEntRef(iGlow));
				}
				
				// Restore their targetname
				SetEntPropString(iPlayer.Index, Prop_Data, "m_iName", sTargetname);
			}
		}
	}
	
	// Prevent Suicide During Freeze Time
	if (StrEqual(command, "kill", false) || StrEqual(command, "explode", false))
	{
		if (g_iRoundState == Round_Freeze)
			return Plugin_Handled;
		
		if (player.IsWarden && g_iRoundState == Round_Active)
		{
			PrintToChat(player.Index, "%t %t", "prefix_reply", "jb_warden_cant_change_team");
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}



Action Command_CommonCommands(int client, int args)
{
	if (!g_ConVar[P_Enabled].BoolValue)
		return Plugin_Handled;
	
	char sCommand[16];
	GetCmdArg(0, sCommand, sizeof(sCommand));
	Player player = new Player(client);

	// Add your name to the Warden pool
	if (StrEqual(sCommand, "sm_w", false))
	{
		if (player.HasFlag(FLAG_WANTS_WARDEN))
		{
			player.RemoveFlag(FLAG_WANTS_WARDEN);
			ReplyToCommand(player.Index, "%t %t", "prefix_reply", "jb_removed_yourself_from_warden_pool");
		}
		else
		{
			player.AddFlag(FLAG_WANTS_WARDEN);
			ReplyToCommand(player.Index, "%t %t", "prefix_reply", "jb_added_yourself_to_warden_pool");
			
			if (player.Team != Team_Blue)
				ReplyToCommand(player.Index, "%t %t", "prefix_reply", "jb_must_be_blue_to_be_warden");
		}
	}
	
	// Ask for a repeat
	else if (StrEqual(sCommand, "sm_r", false))
	{
		// If the ability is on cooldown
		if (g_iCooldowns[CD_Repeat] > 2 && g_iRoundState == Round_Active && player.Team == Team_Red && player.IsAlive)
		{
			ChatResponse(client, _, "%t", "jb_repeat_on_cooldown");
		}
		else if (g_iRoundState == Round_Active && player.Team == Team_Red && player.IsAlive)
		{
			// Select translation phrase
			static int iNumberOfPhrases;
			char sPhrase[32];
			
			if (!iNumberOfPhrases)
			{
				do
				{
					iNumberOfPhrases++;
					Format(sPhrase, sizeof(sPhrase), "jb_annotation_repeat_%d", iNumberOfPhrases);
				}
				while (TranslationPhraseExists(sPhrase));
			}
			
			// Display Annotation
			Format(sPhrase, sizeof(sPhrase), "jb_annotation_repeat_%d", GetRandomInt(1, iNumberOfPhrases - 1));
			ShowAnnotation(player.Index, sPhrase, player.Index, _, 3.0, true, _);
			ChatResponse(player.Index, true, "%t", "jb_you_asked_for_repeat");
			g_iCooldowns[CD_Repeat] += 1;
			CreateTimer(30.0, Timer_Cooldowns, CD_Repeat);
			ShowHUD();
			
			// Play Sound from Player
			static int iMaxSounds;
			
			// Get Sound List Bounds
			if (!iMaxSounds)
			{
				StringMapSnapshot hSnapshot = g_hSound.Snapshot();
				int iLength = hSnapshot.Length;
				
				char sKeyString[32];
				
				for (int i = 0; i < iLength; i++)
				{
					hSnapshot.GetKey(i, sKeyString, sizeof(sKeyString));
					if (StrContains(sKeyString, "repeat_") == 0)
						iMaxSounds++;
				}
				
				delete hSnapshot;
				Debug("hSnapshot contains %d sounds with a key beginning with \"repeat_\"", iMaxSounds);
			}
			
			// Pick a Sound
			if (iMaxSounds)
			{
				char sKeyString[32], sSound[128];
				Format(sKeyString, sizeof(sKeyString), "repeat_%d", GetRandomInt(1, iMaxSounds));
				g_hSound.GetString(sKeyString, sSound, sizeof(sSound));
				if (IsSoundPrecached(sSound))
					EmitSoundToAll(sSound, player.Index);
			}
		}
	}
	
	// Help
	else if (StrEqual(sCommand, "sm_jbhelp", false))
	{
		KeyValues kv = CreateKeyValues("data");
		kv.SetString("msg", "https://steamcommunity.com/groups/death_experiments/discussions/3/2791620699996372350/");
		kv.SetNum("customsvr", 1);
		kv.SetNum("type", MOTDPANEL_TYPE_URL);	// MOTDPANEL_TYPE_URL displays a web page. MOTDPANEL_TYPE_TEXT displays text. MOTDPANEL_TYPE_FILE shows a blank MOTD panel. MOTDPANEL_TYPE_INDEX shows a blank panel with title.
		ShowVGUIPanel(client, "info", kv, true);
		kv.Close();
	}
	
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




Action Command_AdminCommands(int client, int args)
{
	if (!g_ConVar[P_Enabled].BoolValue)
		return Plugin_Handled;
	
	char sCommand[32];
	GetCmdArg(0, sCommand, sizeof(sCommand));
	//Player player = new Player(client);
	
	// Add / Set Queue Points
	bool bSet;
	if (StrEqual(sCommand, "sm_addpoints", false) || (bSet = (StrEqual(sCommand, "sm_setpoints", false))))
	{
		if (args != 2)
		{
			// Command needs two arguments
			ReplyToCommand(client, "%t %t", "prefix_reply", (bSet) ? "jb_command_set_points_usage" : "jb_command_add_points_usage");
		}
		else
		{
			// Get the command arguments
			char sArg1[32], sArg2[6];
			GetCmdArg(1, sArg1, sizeof(sArg1));		// Player name
			GetCmdArg(2, sArg2, sizeof(sArg2));		// Points string
			int iPoints = StringToInt(sArg2);		// Points integer
			
			// Find the player's client index
			int iTarget = FindTarget(client, sArg1, false, false);
			if (iTarget == -1)
			{
				// Don't recognise that player string
				ReplyToTargetError(client, COMMAND_TARGET_AMBIGUOUS);
				return Plugin_Handled;
			}
			else
			{
				// Grant the points
				Player target = new Player(iTarget);
				(bSet) ? target.SetPoints(iPoints) : target.AddPoints(iPoints);
				
				char sName[32];
				GetClientName(client, sName, sizeof(sName));
				
				if (bSet)
				{
					PrintToChat(iTarget, "%t %t", "prefix_reply", "jb_admin_set_your_queue_points", sName, iPoints);
					ReplyToCommand(client, "%t %t", "prefix_reply", "jb_admin_you_set_queue_points", iTarget, iPoints);
					PrintToChatAdminsEx(client, "%t %t", "prefix_error", "jb_admin_set_someone_queue_points", client, iTarget, iPoints);
					LogMessage("%L set %L queue points to %d", client, iTarget, iPoints);
				}
				else
				{
					PrintToChat(iTarget, "%t %t", "prefix_reply", "jb_admin_granted_you_queue_points", sName, iPoints, target.Points);
					ReplyToCommand(client, "%t %t", "prefix_reply", "jb_admin_you_granted_queue_points", iTarget, iPoints, target.Points);
					PrintToChatAdminsEx(client, "%t %t", "prefix_error", "jb_admin_granted_someone_queue_points", client, iTarget, iPoints, target.Points);
					LogMessage("%L awarded %L %d queue points", client, iTarget, iPoints);
				}
			}
		}
	}

	return Plugin_Handled;
}



Action Command_DebugCommands(int client, int args)
{
	//if (!g_ConVar[P_Enabled].BoolValue)
	//	return Plugin_Handled;
	
	char sCommand[16];
	GetCmdArg(0, sCommand, sizeof(sCommand));
	
	// Check Listening Flags
	if (StrEqual(sCommand, "sm_lflags", false))
	{
		int iFlags = GetClientListeningFlags(client);
		ReplyToCommand(client, "%t Your listening flags are: %05b (%d)", "prefix_error", iFlags, iFlags);
	}
	
	// Print example text to chat
	if (StrEqual(sCommand, "sm_jbtextdemo", false))
	{
		ReplyToCommand(client, "%t This is an example of a message sent to all clients", "prefix");
		ReplyToCommand(client, "%t I am a message sent to a client in response to a command", "prefix_reply");
		ReplyToCommand(client, "%t This is an important public message", "prefix_important");
		ReplyToCommand(client, "%t Debugging messages and plugin errors use this colour", "prefix_error");
	}
	
	// Check Weapon Clip Values
	if (StrEqual(sCommand, "sm_clipvals", false))
	{
		Player player = new Player(client);
		int iWeapon;
		int iClips[Weapon_ArrayMax][2];
		for (int i = 0; i < Weapon_ArrayMax; i++)
		{
			iWeapon = player.GetWeapon(i);
			if (iWeapon != -1)
			{
				iClips[i][0] = GetEntProp(iWeapon, Prop_Data, "m_iClip1");
				iClips[i][1] = GetEntProp(iWeapon, Prop_Data, "m_iClip2");
			}
		}
		
		ReplyToCommand(client, "%t %t", "prefix_error", "jb_check_console");
		
		PrintToConsole(client, "\n");
		PrintToConsole(client, " Slot | Clip #1 | Clip #2");
		PrintToConsole(client, " ------------------------");
		
		for (int i = 0; i < Weapon_ArrayMax; i++)
			PrintToConsole(client, " %4d   %7d   %7d", i, iClips[i][0], iClips[i][1]);
		
		PrintToConsole(client, " ------------------------\n");
	}
	
	// ADMIN ONLY - Strip a Weapon's Ammo
	if (StrEqual(sCommand, "sm_stripslot", false))
	{
		if (args != 1)
		{
			ReplyToCommand(client, "%t You have to specify a weapon slot", "prefix_error");
			return Plugin_Handled;
		}
		
		char sArg1[3];
		GetCmdArg(1, sArg1, sizeof(sArg1));
		int iSlot = StringToInt(sArg1);
		Player player = new Player(client);
		if (iSlot >= Weapon_Primary && iSlot < Weapon_ArrayMax)
		{
			if (player.GetWeapon(iSlot) == -1)
			{
				ReplyToCommand(client, "%t No weapon found in slot %d", "prefix_error", iSlot);
			}
			else
			{
				player.StripAmmo(iSlot);
				ReplyToCommand(client, "%t Stripped ammo from weapon in slot %d", "prefix_error", iSlot);
			}
		}
		else
			ReplyToCommand(client, "%t %d is not a valid weapon slot (0-5)", "prefix_error", iSlot);
	}
	
	// ADMIN ONLY - Print Player Data to Console
	if (StrEqual(sCommand, "sm_jbdata", false))
	{
		PrintToConsole(client, "\n %s Player points and preference flags\n  Please note: The table will show values for unoccupied slots. These are from\n  previous players and are reset when someone new takes the slot.\n", PREFIX_SERVER);
		PrintToConsole(client, " Index | User ID | Steam ID   | Name                             | Points | Flags");
		PrintToConsole(client, " ----------------------------------------------------------------------------------------");
		
		for (int i = 1; i <= MaxClients; i++)
		{
			Player player = new Player(i);
			char sName[32] = "<no player>";
			if (player.InGame)
				Format(sName, sizeof(sName), "%N", player.Index);
			PrintToConsole(client, " %5d | %7d | %10d | %32s | %6d | %06b %06b", player.Index, player.ArrayUserID, player.SteamID, sName, player.Points, ((player.Flags & MASK_SESSION_FLAGS) >> 16), (player.Flags & MASK_STORED_FLAGS));
				// This bit shift operation should take the resulting bits and shift them all down to the 'stored' range for display purposes
		}
		
		PrintToConsole(client, " ----------------------------------------------------------------------------------------");
		PrintToConsole(client, " Game State Flags: %06b  Round State: %d\n\n", g_iState, g_iRoundState);
		ReplyToCommand(client, "%t %t", "prefix_error", "jb_check_console");
	}
	
	// ADMIN ONLY - Redistribute Players
	if (StrEqual(sCommand, "sm_redist", false))
	{
		ReplyToCommand(client, "%t Redistributing players", "prefix_error");
		Redistribute();
	}
	
	return Plugin_Handled;
}



