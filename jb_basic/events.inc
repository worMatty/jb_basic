/**
 * Events
 * ----------------------------------------------------------------------------------------------------
 */

stock void Event_RoundRestart(Event event, const char[] name, bool dontBroadcast)
{
	PrintToServer("%s Round Reset", PREFIX_SERVER);
	
	// Extend freeze time
	g_ConVar[S_FreezeTime].IntValue = 6;
	
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
	
	// Reset player flags and issue roles
	for (int i = 1; i <= MaxClients; i++)
	{
		Player player = new Player(i);
		
		if (player.InGame)
		{
			if (player.IsWarden)
				player.MakeWarden(false);

			if (player.Team == Team_Red)
				player.MakePrisoner();
			else
				player.MakePrisoner(false);
		}
	}
}



stock void Event_RoundActive(Event event, const char[] name, bool dontBroadcast)
{
	PrintToServer("%s Round Active", PREFIX_SERVER);
}



stock void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	PrintToServer("%s Round Ended", PREFIX_SERVER);
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
}



stock void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	Player player = new Player(GetClientOfUserId(event.GetInt("userid")));
	player.VoiceDead();
}