#pragma semicolon 1

/**
 * Redistribute players.
 * 
 * @noreturn
 */
void Redistribute()
{
	int inmates = GetTeamClientCount(Team_Inmates);
	int officers = GetTeamClientCount(Team_Officers);
	
	int participants = (inmates + officers);
	int officer_cap = RoundFloat(participants * (g_ConVars[P_OfficerCap].FloatValue / 100));
	ClampInt(officer_cap, 1, participants - 1);
	
	int deficit = officer_cap - officers;
	
	Debug("Redistribute -- %d officers  %d inmates  %d total", inmates, officers, participants);
	Debug("Redistribute -- %d officers needed  Deficit %d  Transferring %d %s", officer_cap, deficit, (0 - deficit), (deficit > 0) ? "inmates" : "officers");
	
	// We have no officers
	if (deficit == officer_cap)
	{
		// Pick a random inmate
		Player player = new Player(PickRandomTeamMember(Team_Inmates));
		
		if (!player.Index)
		{
			ThrowError("Couldn't find a player on the inmate team");
		}
		
		Debug("Redistribute -- Making inmate %N an officer", player.Index);
		player.SetTeam(Team_Officers);
	}
	
	// We have too many officers
	else if (deficit < 0)
	{
		// Get number of non-Warden officers
		int non_wardens;
		for (int i = 1; i <= MaxClients; i++)
		{
			Player player = new Player(i);
			if (player.InGame && player.Team == Team_Officers && !player.IsWarden)
				non_wardens += 1;
		}
		
		if (non_wardens)
		{
			while (non_wardens > 0 && deficit != 0)
			{
				Debug("Redistribute -- Finding an officer to change to an inmate");
				Player player = new Player(PickRandomTeamMember(Team_Officers));
				if (!player.IsWarden)
				{
					if (!player.Index)
					{
						ThrowError("Couldn't find a player on the Blue team");
					}
					Debug("Redistribute -- Making officer %N an inmate", player.Index);
					player.SetTeam(Team_Inmates);
					deficit += 1;
					non_wardens -= 0;
				}
			}
		}
	}
	
	// If running in Open Fortress or TF2C, respawn all players
	if (g_iGame & (FLAG_OF|FLAG_TF2C)) // TODO Change to a check if the native is available
	{
		int respawn_ent = CreateEntityByName("game_forcerespawn");
		if (respawn_ent == -1)
		{
			LogError("Unable to create game_forcerespawn");
		}
		else
		{
			if (!DispatchSpawn(respawn_ent))
			{
				LogError("Unable to spawn game_forcerespawn");
			}
			else
			{
				if (!AcceptEntityInput(respawn_ent, "ForceRespawn"))
				{
					LogError("game_forcerespawn wouldn't accept our ForceRespawn input");
				}
				else
				{
					Debug("Respawned all players by creating a game_forcerespawn");
				}
			}
			
			AcceptEntityInput(respawn_ent, "Kill");
		}
	}
}


/**
 * Redistribute players.
 * 
 * @noreturn
 */
/* Old function where we balance the teams to have a minimum officer count
void Redistribute()
{
	//Check player numbers on each team.
	//Count clients on each and do a division thing. Do we need to rebalance? Is there a tolerance?
	//Look at queue points. Take the blue players with the fewest points and move them to red.
	//Drag in some reds if we need them. Should we take away their points?
	//Take away the points from blues who were still remaining.
	//
	//Do we need a separate set of points for Wardenship?
	
	int iReds = GetTeamClientCount(Team_Inmates);
	int iBlues = GetTeamClientCount(Team_Officers);
	
	int iTotal = (iReds + iBlues);
	int iBluesNeeded = RoundFloat(iTotal * g_ConVars[P_OfficerCap].FloatValue); // Old values 3.6 or 0.3571428571428571
	
	int iDeficit = iBluesNeeded - iBlues;
	
	Debug("Players on Red: %d  Players on Blue: %d  Total Players: %d", iReds, iBlues, iTotal);
	Debug("Blues Needed: %d  Deficit: %d  We need to move %d players from %s", iBluesNeeded, iDeficit, (0 - iDeficit), (iDeficit > 0) ? "RED" : "BLUE");
	
	// We have too many Reds
	if (iDeficit > 0)
	{
		while (iDeficit > 0)
		{
			// Pick a random Red
			Player player = new Player(PickRandomTeamMember(Team_Inmates));
			if (!player.Index)
				ThrowError("Couldn't find a player on the Red team");
			Debug("Moving %N from Red to Blue", player.Index);
			player.SetTeam(Team_Officers);
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
			if (player.InGame && player.Team == Team_Officers && !player.IsWarden)
				iNonWardens += 1;
		}
		
		if (iNonWardens)
		{
			while (iNonWardens > 0 && iDeficit != 0)
			{
				Debug("Finding a Blue player to move to Red");
				Player player = new Player(PickRandomTeamMember(Team_Officers));
				if (!player.IsWarden)
				{
					if (!player.Index)
						ThrowError("Couldn't find a player on the Blue team");
					Debug("Moving %N from Blue to Red", player.Index);
					player.SetTeam(Team_Inmates);
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
*/



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
		
		if (player.InGame && player.Team == Team_Officers && player.HasFlag(FLAG_WANTS_WARDEN))
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