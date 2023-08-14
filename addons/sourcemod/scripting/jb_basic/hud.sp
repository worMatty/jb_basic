#pragma semicolon 1


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
		g_Sounds.GetString(sound, sSound, sizeof(sSound));
		
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
		else if (player.Team == Team_Inmates || !player.IsAlive)
		{
			switch (player.IsMuted)
			{
				case 0: Format(sString, sizeof(sString), "⯈ %t", "jb_hud_not_muted");
				case 1: Format(sString, sizeof(sString), "■ %t", "jb_hud_muted");
				case 2: Format(sString, sizeof(sString), "■ %t", "jb_hud_muted_by_admin");
			}
			
			char sRepeat[16];
			
			if (player.Team == Team_Inmates && player.IsAlive)
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
				if (target.Team == Team_Inmates)
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

