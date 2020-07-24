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
	
	while ((iEnt = FindEntityByClassname(iEnt, "func_button")) != -1)
	{
		char sTargetname[11];
		GetEntPropString(iEnt, Prop_Data, "m_iName", sTargetname, sizeof(sTargetname));
		if (StrEqual(sTargetname, "open_cells", false))
		{
			g_iEnts[Ent_CellButton] = iEnt;
			Debug("Found \"open_cells\" button at entity index %d", iEnt);
			break;
		}
	}
	if (!g_iEnts[Ent_CellButton])
		LogError("Couldn't find cell door button");
	
	while ((iEnt = FindEntityByClassname(iEnt, "func_door")) != -1)
	{
		char sTargetname[10];
		GetEntPropString(iEnt, Prop_Data, "m_iName", sTargetname, sizeof(sTargetname));
		if (StrEqual(sTargetname, "cell_door", false))
		{
			g_iEnts[Ent_CellDoors] = iEnt;
			Debug("Found \"cell_door\" at entity index %d", iEnt);
			iEnt = -1;
			break;
		}
	}
	if (!g_iEnts[Ent_CellDoors])
		LogError("Couldn't find cell door");
	
	// Reset player and game state flags
	for (int i = 1; i <= MaxClients; i++)
	{
		Player player = new Player(i);
		if (player.InGame && player.IsWarden)
			player.MakeWarden(false);
		player.Flags &= ~MASK_SESSION_FLAGS;
	}
	g_iState = 0;
	
	// Change round state here to work around player_spawn firing twice on reset
	g_iRoundState = Round_Freeze;
}




stock void Event_RoundActive(Event event, const char[] name, bool dontBroadcast)
{
	PrintToServer("%s Round Active", PREFIX_SERVER);
	g_iRoundState = Round_Active;
	
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
}



stock void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	PrintToServer("%s Round Ended", PREFIX_SERVER);
	g_iRoundState = Round_Win;
}



stock void Event_ChangeClass(Event event, const char[] name, bool dontBroadcast)
{
	Player player = new Player(GetClientOfUserId(event.GetInt("userid")));
	
	if (!(player.Flags & FLAG_WELCOMED))
	{
		char sName[32];
		GetClientName(player.Index, sName, sizeof(sName));
		PrintToChat(player.Index, "%t %t", "prefix_personal", "jb_welcome", sName);
		player.Flags |= FLAG_WELCOMED;
	}
}



stock void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	Player player = new Player(GetClientOfUserId(event.GetInt("userid")));
	player.VoiceAlive();
	
	if (g_iRoundState == Round_Freeze && player.Team == Team_Blue && !(g_iState & FLAG_HAVE_WARDEN))
	{
		PrintCenterText(player.Index, "%t", "jb_someone_must_assume_warden_role");
		DebugEx(player.Index, "Sent hint text to %N", player.Index);
	}
}



stock void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	Player player = new Player(GetClientOfUserId(event.GetInt("userid")));
	player.VoiceDead();
}