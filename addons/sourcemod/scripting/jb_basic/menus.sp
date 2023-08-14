#pragma semicolon 1


/**
* Menu Function
*/
stock void MenuFunction(int client, const char[] sMenu)
{
	Player player = new Player(client);
	Menu menu = new Menu(Menu_Handler, MenuAction_DisplayItem);
	
	
	
	/**
	 * Main Menu
	 */
	if (StrEqual(sMenu, "menu_main"))
	{
		menu.SetTitle("%s %s\n ", PLUGIN_NAME, PLUGIN_VERSION);

		if (g_iRoundState == Round_Freeze && !(g_iState & FLAG_HAVE_WARDEN) && player.Team == Team_Officers)
			menu.AddItem("item_become_warden", "jb_menu_item_become_warden");

		if (player.Flags & FLAG_WARDEN)
			menu.AddItem("menu_warden", "jb_menu_warden_title", (g_iRoundState == Round_Active) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		
		if (player.IsAdmin)
			menu.AddItem("menu_admin", "jb_menu_admin_title");
		
		menu.AddItem("item_help", "jb_menu_item_help");
	}
	
	
	
	/**
	 * Warden Menu
	 */
	if (StrEqual(sMenu, "menu_warden"))
	{
		menu.SetTitle("%t\n ", "jb_menu_warden_title");
		menu.ExitBackButton = true;
		
		if (!g_Buttons.Empty)
		{
			if (g_Buttons.IsPair)
			{
				menu.AddItem("warden_cells_open", "jb_menu_warden_open_cells", (g_iRoundState == Round_Active) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
				menu.AddItem("warden_cells_close", "jb_menu_warden_close_cells", (g_iRoundState == Round_Active) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
			}
			else if (g_Buttons.IsToggle)
			{
				menu.AddItem("warden_cells_button", "jb_menu_warden_press_cell_button", (g_iRoundState == Round_Active) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
			}
		}
		else if (!g_CellDoors.Empty)
		{
			menu.AddItem("warden_cells_open", "jb_menu_warden_open_cells", (g_iRoundState == Round_Active) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
			menu.AddItem("warden_cells_close", "jb_menu_warden_close_cells", (g_iRoundState == Round_Active) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		}
		else
		{
			menu.AddItem("", "jb_menu_warden_no_ents", ITEMDRAW_DISABLED);
		}
		
		menu.AddItem("warden_direct", "jb_menu_warden_direct");
		menu.AddItem("warden_instructions", "jb_menu_warden_instructions");
		menu.AddItem("warden_mark_for_death", "jb_menu_warden_mark_for_death");
		
		//if (g_iState & FLAG_PRISONERS_MUTED)
		menu.AddItem("warden_mute_prisoners", (g_iState & FLAG_PRISONERS_MUTED) ? "jb_menu_warden_unmute_prisoners" : "jb_menu_warden_mute_prisoners");
		//else
		//	menu.AddItem("warden_mute_prisoners", "jb_menu_warden_mute_prisoners");
		menu.AddItem("menu_mutes", "jb_menu_warden_mute_individual_prisoners");
		menu.AddItem("warden_normal_size", "jb_menu_warden_normal_size", (!(player.Flags & FLAG_WARDEN_LARGE)) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	}
	
	
	
	/**
	 * Warden Common Instructions Menu
	 */
	if (StrEqual(sMenu, "menu_instructions"))
	{
		menu.SetTitle("%t\n ", "jb_menu_mute_title");
		menu.ExitBackButton = true;
		
		menu.AddItem("instruction_yellow_line", "jb_menu_instructions_yellow_line");
		menu.AddItem("instruction_red_line", "jb_menu_instructions_red_line");
		menu.AddItem("instruction_dont_move", "jb_menu_instructions_dont_move");
		menu.AddItem("instruction_stand_inline", "jb_menu_instructions_stand_inline");
		menu.AddItem("instruction_choose_act", "jb_menu_instructions_choose_activity");
		menu.AddItem("instruction_follow_tar", "jb_menu_instructions_follow_targets");
		menu.AddItem("instruction_escapee", "jb_menu_instructions_escapee");
		menu.AddItem("instruction_miscount", "jb_menu_instructions_miscount");
	}
	
	
	
	/**
	 * Mute Prisoners Menu
	 */
	if (StrEqual(sMenu, "menu_mutes"))
	{
		menu.SetTitle("%t\n ", "jb_menu_mute_title");
		menu.ExitBackButton = true;
		
		for (int i = 1; i <= MaxClients; i++)
		{
			Player iPlayer = new Player(i);
			if (iPlayer.InGame && iPlayer.Team == Team_Inmates && iPlayer.IsAlive)
			{
				char sItem[17], sName[32], sDisplay[32];
				Format(sItem, sizeof(sItem), "mute_prisoner_%d", i);
				GetClientName(i, sName, sizeof(sName));
				
				bool bAdminMuted;
				switch (iPlayer.IsMuted)
				{
					case 0:	Format(sDisplay, sizeof(sDisplay), "%t", "jb_menu_mute_mute_prisoner", sName);
					case 1:	Format(sDisplay, sizeof(sDisplay), "%t", "jb_menu_mute_unmute_prisoner", sName);
					case 2:
					{
						Format(sDisplay, sizeof(sDisplay), "%t", "jb_menu_mute_admin_muted", sName);
						bAdminMuted = true;
					}
				}
				
				menu.AddItem(sItem, sDisplay, (bAdminMuted) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			}
		}
	}
	
	
	
	/**
	 * Admin Commands
	 */
	if (StrEqual(sMenu, "menu_admin"))
	{
		menu.SetTitle("%t\n ", "jb_menu_admin_title");
		menu.ExitBackButton = true;
		
		if (player.Flags & FLAG_WARDEN)
			menu.AddItem("admin_remove_your_warden", "jb_menu_admin_remove_warden_from_yourself");
		else
			menu.AddItem("admin_make_yourself_warden", "jb_menu_admin_make_yourself_warden");
		
		menu.AddItem("admin_strip_your_ammo", "jb_menu_admin_strip_your_ammo");
		
	}
	
	
	menu.Display(client, MENU_TIME_FOREVER);
}




/**
 * Menu Handler
 * ----------------------------------------------------------------------------------------------------
 */


public int Menu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char sSelection[32];
		menu.GetItem(param2, sSelection, sizeof(sSelection));
		Player player = new Player(param1);
		
		
		
		/**
		 * Go to a Menu
		 */
		if (StrContains(sSelection, "menu_") == 0)
		{
			MenuFunction(param1, sSelection);
		}
		
		
		
		/**
		 * Loose Items
		 */
		else if (StrContains(sSelection, "item_") == 0)
		{
			if (StrEqual(sSelection, "item_become_warden"))
			{
				ClientCommand(player.Index, "sm_w");
			}
			else if (StrEqual(sSelection, "item_help"))
			{
				ClientCommand(player.Index, "sm_jbhelp");
			}
			
			MenuFunction(param1, sSelection);
		}
		
		
		
		
		/**
		 * Warden Menu
		 */
		else if (StrContains(sSelection, "warden_") == 0)
		{
			
			if (StrContains(sSelection, "warden_cells_") == 0)
			{
				if (StrEqual(sSelection, "warden_cells_open") || StrEqual(sSelection, "warden_cells_button"))
				{
					CellControlHandler(player.Index, true);
				}
				else
				{
					CellControlHandler(player.Index, false);
				}
			}
			else if (StrEqual(sSelection, "warden_direct"))
			{
				ClientCommand(player.Index, "voicemenu 0 2");
			}
			else if (StrEqual(sSelection, "warden_instructions"))
			{
				MenuFunction(param1, "menu_instructions");
				return 0;	// TODO Is this working?
			}
			else if (StrEqual(sSelection, "warden_mark_for_death"))
			{
				ClientCommand(player.Index, "voicemenu 2 1");
			}
			else if (StrEqual(sSelection, "warden_mute_prisoners"))
			{
				bool mute = (!(g_iState & FLAG_PRISONERS_MUTED));
				
				for (int i = 1; i <= MaxClients; i++)
				{
					Player iPlayer = new Player(i);
					if (iPlayer.InGame && iPlayer.Team == Team_Inmates && iPlayer.IsAlive)
						iPlayer.Mute(mute);
				}
				
				if (mute)
					g_iState |= FLAG_PRISONERS_MUTED;
				else
					g_iState &= ~FLAG_PRISONERS_MUTED;
				
			}
			else if (StrEqual(sSelection, "warden_normal_size"))
			{
				SetVariantString("1");
				if (AcceptEntityInput(player.Index, "SetModelScale"))
					player.Flags &= ~FLAG_WARDEN_LARGE;
			}
			
			MenuFunction(param1, "menu_warden");
		}
		
		
		
		/**
		 * Warden Common Instructions Menu
		 */
		else if (StrContains(sSelection, "instruction_") == 0)
		{
			char sDisplay[64];
			menu.GetItem(param2, sSelection, sizeof(sSelection), _, sDisplay, sizeof(sDisplay));
			
			ShowAnnotation(player.Index, sDisplay, player.Index, _, _, true, "warden_instruction");
			ChatResponse(player.Index, false, "%t", sDisplay);
			
			MenuFunction(param1, "menu_instructions");
		}
		
		
		
		/**
		 * Mutes Menu
		 */
		else if (StrContains(sSelection, "mute_prisoner_") == 0)
		{
			ReplaceString(sSelection, sizeof(sSelection), "mute_prisoner_", "");
			int iClient = StringToInt(sSelection);
			Player iPlayer = new Player(iClient);
			
			if (!iPlayer.Mute(!iPlayer.IsMuted))
			{
				char sName[32];
				GetClientName(iPlayer.Index, sName, sizeof(sName));
				ReplyToCommand(player.Index, "%t %t", "prefix_reply", "jb_unable_to_affect_mute", sName);
			}
			//ShowVoiceStatus();
			ShowHUD(iPlayer.Index);
			
			MenuFunction(param1, "menu_mutes");
		}
		


		/**
		 * Admin Menu
		 */
		else if (StrContains(sSelection, "admin_") == 0)
		{
			if (StrEqual(sSelection, "admin_make_yourself_warden"))
			{
				player.MakeWarden();
			}
			else if (StrEqual(sSelection, "admin_remove_your_warden"))
			{
				player.MakeWarden(false);
			}
			else if (StrEqual(sSelection, "admin_strip_your_ammo"))
			{
				player.StripAmmo(Weapon_Primary);
				player.StripAmmo(Weapon_Secondary);
			}
			
			MenuFunction(param1, "menu_main");
		}
		
		
		// Go back to the main menu
		else MenuFunction(param1, "menu_main");
	}
	
	else if (param2 == MenuCancel_ExitBack)
	{
		MenuFunction(param1, "menu_main");
	}
	
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	
	else if (action == MenuAction_DisplayItem)
    {
		char sDisplay[64];
		char sSelection[32];
		menu.GetItem(param2, sSelection, sizeof(sSelection), _, sDisplay, sizeof(sDisplay));
		
		// If the phrase is not a mute individual prisoner item, redraw it
		if (StrContains(sSelection, "mute_prisoner_") == -1)
		{
			char buffer[256];
			Format(buffer, sizeof(buffer), "%T", sDisplay, param1);
			
			return RedrawMenuItem(buffer);
		}
    }
	
	return 0;
}
