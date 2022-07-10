
/**
 * Timers
 * ----------------------------------------------------------------------------------------------------
 */

// Remove Directions System Reticle Model
Action Timer_RemoveReticle(Handle timer, int model)
{
	if (model != INVALID_ENT_REFERENCE)
	{
		model = EntRefToEntIndex(model);
		RemoveEdict(model);
	}
	
	g_hTimers[Timer_Direction] = null;
	return Plugin_Handled;
}



// Remove Directions System Glow
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
	
	g_hTimers[Timer_Glow] = null;
	return Plugin_Handled;
}



// Remove Marked Inmate Glow
Action Timer_RemoveInmateGlow(Handle timer, int glow)
{
	if (glow != INVALID_ENT_REFERENCE)
	{
		glow = EntRefToEntIndex(glow);
		
		RemoveEdict(glow);
	}
	
	return Plugin_Handled;
}



// Add a Charge to Warden Ability Cooldowns
Action Timer_Cooldowns(Handle timer, int cooldown)
{
	if (g_iCooldowns[cooldown] > 0)
	{
		g_iCooldowns[cooldown] -= 1;
		//ShowCooldowns();
		ShowHUD();
		
		for (int i = 1; i <= MaxClients; i++)
		{
			Player player = new Player(i);
			
			// Warden Abilities
			if (player.InGame && player.IsWarden && cooldown == CD_Directions)
			{
				char sSound[64];
				g_hSound.GetString("direction_cooldown", sSound, sizeof(sSound));
				EmitSoundToClient(i, sSound, _, SNDCHAN_STATIC, _, SND_CHANGEPITCH|SND_CHANGEVOL, 0.2, SNDPITCH_HIGH);
			}
		}
	}
}



// Show the HUD
Action Timer_ShowHUD(Handle timer)
{
	ShowHUD();
}



// Show the HUD
Action Timer_ShowNameText(Handle timer)
{
	ShowNameText();
}



// Give Queue Points to Living Players
Action Timer_AwardPoints(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		Player player = new Player(i);
		
		if (player.InGame && player.IsAlive)
			player.AddPoints(Points_Incremental);
	}
}