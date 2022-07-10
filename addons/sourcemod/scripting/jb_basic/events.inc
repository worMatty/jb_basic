/**
 * Events
 * ----------------------------------------------------------------------------------------------------
 */

stock void Event_RoundRestart(Event event, const char[] name, bool dontBroadcast)
{
	PrintToServer("%s Round Reset", PREFIX_SERVER);
	
	// Reset entity indexes
	for (int i = 0; i < Ent_ArrayMax; i++)
		g_iEnts[i] = 0;
	
	// Find map entities
	int iEnt = -1;
	
	// Find Cell Button
	// Alternative names: *model, opencells, button_cells, cb
	while ((iEnt = FindEntityByClassname(iEnt, "func_button")) != -1)
	{
		char sTargetname[11];
		GetEntPropString(iEnt, Prop_Data, "m_iName", sTargetname, sizeof(sTargetname));
		if (StrEqual(sTargetname, "open_cells", false) || StrEqual(sTargetname, "opencells", false) ||
			StrEqual(sTargetname, "button_cells", false) || StrEqual(sTargetname, "cb", false))
		{
			g_iEnts[Ent_CellButton] = iEnt;
			Debug("Found \"open_cells\" button at entity index %d", iEnt);
			break;
		}
	}
	if (!g_iEnts[Ent_CellButton])
		LogError("Couldn't find cell door button");
	
	// Find Cell Doors
	// Alternative names: cd, opencells, cells, Jaildoor, cell_door_1, prisondoor, jailcells
	while ((iEnt = FindEntityByClassname(iEnt, "func_door")) != -1)
	{
		char sTargetname[10];
		GetEntPropString(iEnt, Prop_Data, "m_iName", sTargetname, sizeof(sTargetname));
		if (StrEqual(sTargetname, "cell_door", false) || StrEqual(sTargetname, "opencells", false) ||
			StrEqual(sTargetname, "cells", false) || StrEqual(sTargetname, "jaildoor", false) ||
			StrEqual(sTargetname, "cell_door_1", false) || StrEqual(sTargetname, "prisondoor", false) ||
			StrEqual(sTargetname, "jailcells", false) || StrEqual(sTargetname, "cd", false))
		{
			g_iEnts[Ent_CellDoors] = iEnt;
			Debug("Found \"cell_door\" at entity index %d", iEnt);
			iEnt = -1;
			break;
		}
	}
	if (!g_iEnts[Ent_CellDoors])
		LogError("Couldn't find cell door");
	
	// Reset player and game state flags and cooldowns
	for (int i = 1; i <= MaxClients; i++)
	{
		Player player = new Player(i);
		if (player.InGame && player.IsWarden)
			player.MakeWarden(false);
		//player.Flags &= ~MASK_SESSION_FLAGS;
		player.RemoveFlag(MASK_RESET_ROLES);
	}
	g_iState = 0;
	g_iCooldowns[CD_Directions] = 0;
	g_iCooldowns[CD_CellDoors] = 0;
	g_iCooldowns[CD_Repeat] = 0;
	
	// Change round state here to work around player_spawn firing twice on reset
	g_iRoundState = Round_Freeze;
	
	// Do stuff one frame later
	RequestFrame(RequestFrame_RoundReset);
}

stock void RequestFrame_RoundReset()
{
	// Spawn Round Timer
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
				DispatchKeyValue(iEnt, "force_map_reset", "1");
				DispatchKeyValue(iEnt, "switch_teams", "0");
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




stock void Event_RoundActive(Event event, const char[] name, bool dontBroadcast)
{
	PrintToServer("%s Round Active", PREFIX_SERVER);
	g_iRoundState = Round_Active;
	
	// Select a Warden
	int iWarden;
	if (!(iWarden = SelectWarden()))
		PrintToChatAll("%t %t", "prefix", "jb_noone_opted_into_warden");
	else
	{
		Player player = new Player(iWarden);
		player.MakeWarden();
		player.RemoveFlag(FLAG_WANTS_WARDEN);
		player.SetPoints(Points_Consumed);
		ChatResponse(player.Index, true, "%t", "jb_name_taken_out_of_warden_pool");
	}
	
	// Redistribute Players
	Redistribute();
	
	// Give roles
	for (int i = 1; i <= MaxClients; i++)
	{
		Player player = new Player(i);
		if (player.InGame)
		{
			if (player.Team == Team_Red)
				player.MakePrisoner();
			else if (player.Team == Team_Blue && !player.IsWarden)
				player.MakeOfficer();
		}
	}
	
	// Start queue points award timer
	g_hTimers[Timer_QueuePoints] = CreateTimer(30.0, Timer_AwardPoints, _, TIMER_REPEAT);
}



stock void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	PrintToServer("%s Round Ended", PREFIX_SERVER);
	g_iRoundState = Round_Win;
	
	// Kill Queue Points Timer
	KillTimer(g_hTimers[Timer_QueuePoints]);
	
	// Unmute everyone
	for (int i = 1; i <= MaxClients; i++)
	{
		Player player = new Player(i);
		
		if (player.InGame)
			player.Mute(false);
	}
}



stock void Event_ChangeClass(Event event, const char[] name, bool dontBroadcast)
{
	Player player = new Player(GetClientOfUserId(event.GetInt("userid")));
	
	if (!(player.Flags & FLAG_WELCOMED))
	{
		char sName[32];
		GetClientName(player.Index, sName, sizeof(sName));
		PrintToChat(player.Index, "%t %t", "prefix_reply", "jb_welcome", sName);
		player.Flags |= FLAG_WELCOMED;
	}
}



stock void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	Player player = new Player(GetClientOfUserId(event.GetInt("userid")));
	player.Mute(false);
}



stock void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	Player player = new Player(GetClientOfUserId(event.GetInt("userid")));
	
	// Check if round state is active to prevent the last dying player on a team
	// being muted after everyone is unmuted when the round ends
	if (g_iRoundState == Round_Active)
	{
		player.Mute();
		if (player.IsWarden) player.MakeWarden(false);
		ShowHUD(player.Index);
	}
}