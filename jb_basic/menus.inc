
/**
* Menu Function
*/
stock void MenuFunction(int client, const char[] sMenu)
{
	Player player = new Player(client);
	Menu menu = new Menu(MenuHandler, MenuAction_DisplayItem);
	
	
	
	/**
	 * Main Menu
	 */
	if (StrEqual(sMenu, "menu_main"))
	{
		menu.SetTitle("%s %s\n ", PLUGIN_NAME, PLUGIN_VERSION);

		if (player.Flags & FLAG_WARDEN)
			menu.AddItem("menu_warden", "jb_menu_warden_title");
		
		if (GetAdminFlags(GetUserAdmin(client), Access_Effective))
			menu.AddItem("menu_admin", "jb_menu_admin_title");
	}
	
	
	
	/**
	 * Warden Menu
	 */
	if (StrEqual(sMenu, "menu_warden"))
	{
		menu.SetTitle("%t\n ", "jb_menu_warden_title");
		menu.ExitBackButton = true;
		
		if (g_iEnts[Ent_CellButton])
		{
			menu.AddItem("warden_press_cell_button", "jb_menu_warden_press_cell_button");
		}
		else if (g_iEnts[Ent_CellDoors])
		{
			menu.AddItem("warden_open_cells", "jb_menu_warden_open_cells");
			menu.AddItem("warden_close_cells", "jb_menu_warden_close_cells");
		}
		else
		{
			menu.AddItem("", "jb_menu_warden_no_ents", ITEMDRAW_DISABLED);
		}
		
		menu.AddItem("warden_normal_size", "jb_menu_warden_normal_size");
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


public int MenuHandler(Menu menu, MenuAction action, int param1, int param2)
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
		 * Warden Menu
		 */
		else if (StrContains(sSelection, "warden_") == 0)
		{
			if (StrEqual(sSelection, "warden_press_cell_button"))
			{
				AcceptEntityInput(g_iEnts[Ent_CellButton], "PressIn");
				PrintToChatAll("%t %t", "prefix", "jb_cells_warden_pressed_button");
			}
			if (StrEqual(sSelection, "warden_open_cells"))
			{
				AcceptEntityInput(g_iEnts[Ent_CellDoors], "Open");
				PrintToChatAll("%t %t", "prefix", "jb_cells_warden_opened");
			}
			if (StrEqual(sSelection, "warden_close_cells"))
			{
				AcceptEntityInput(g_iEnts[Ent_CellDoors], "Close");				
				PrintToChatAll("%t %t", "prefix", "jb_cells_warden_closed");
			}
			if (StrEqual(sSelection, "warden_normal_size"))
			{
				SetVariantString("1");
				AcceptEntityInput(player.Index, "SetModelScale");
			}
			
			MenuFunction(param1, "menu_warden");
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

		if (sDisplay[0] != '\0' && !StrEqual(sSelection, "points_item"))
		{
			char buffer[256];
			Format(buffer, sizeof(buffer), "%T", sDisplay, param1);
			
			return RedrawMenuItem(buffer);
		}
    }
	
	return 0;
}
