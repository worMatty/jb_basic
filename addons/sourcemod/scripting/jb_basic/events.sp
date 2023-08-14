#pragma semicolon 1


/**
 * Events
 * ----------------------------------------------------------------------------------------------------
 */

stock void Event_RoundRestart(Event event, const char[] name, bool dontBroadcast)
{
	PrintToServer("%s Round Restart", PREFIX_SERVER);
	
	// Find map entities
	delete g_Buttons;
	delete g_CellDoors;
	g_Buttons = FindCellButtons();
	g_CellDoors = FindCellDoors();
	
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
	// Create a team_round_timer used for the setup time and optionally the round time
	int timer = CreateEntityByName("team_round_timer");

	if (timer != -1)
	{
		char setup_length[3], timer_length[5];

		IntToString(PRE_ROUND_TIME, setup_length, sizeof(setup_length));
		g_ConVars[P_RoundTime].GetString(timer_length, sizeof(timer_length));
		
		DispatchKeyValue(timer, "setup_length", setup_length);
		DispatchKeyValue(timer, "timer_length", timer_length);
		DispatchKeyValue(timer, "targetname", "JB_ROUND_TIMER");
		DispatchSpawn(timer);

		SetVariantString("1");
		AcceptEntityInput(timer, "ShowInHUD");
		AcceptEntityInput(timer, "Resume");
		
		// If we're using the plugin's round timer, set it to call a red win on end
		if (g_ConVars[P_UseTimer].BoolValue)
		{
			SetVariantString("OnFinished JB_RED_WIN,RoundWin,,0.0,1");
			AcceptEntityInput(timer, "AddOutput");
			
			int round_win = CreateEntityByName("game_round_win");
			if (round_win != -1)
			{
				DispatchKeyValue(round_win, "targetname", "JB_RED_WIN");
				DispatchKeyValue(round_win, "force_map_reset", "1");
				DispatchKeyValue(round_win, "switch_teams", "0");
				//DispatchKeyValue(round_win, "TeamNum", "2");
				DispatchSpawn(round_win);
				
				SetVariantString("2");
				AcceptEntityInput(round_win, "SetTeam");

				Debug("Team value of game_round_win is %d", GetEntProp(round_win, Prop_Data, "m_iTeamNum"));
			}
		}
		else
		{
			SetVariantString("OnSetupFinished !self,Kill,,0.0,1");
			AcceptEntityInput(timer, "AddOutput");
		}
	}
}



/**
 * Event: Round Active
 *
 * Will not fire if either team has no players
 */
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
			if (player.Team == Team_Inmates)
				player.MakePrisoner();
			else if (player.Team == Team_Officers && !player.IsWarden)
				player.MakeOfficer();
		}
	}
	
	// Start queue points award timer
	g_Timers[Timer_QueuePoints] = CreateTimer(30.0, Timer_AwardPoints, _, TIMER_REPEAT);
}



stock void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	PrintToServer("%s Round Ended", PREFIX_SERVER);
	g_iRoundState = Round_Win;
	
	// Kill Queue Points Timer
	KillTimer(g_Timers[Timer_QueuePoints]);
	
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