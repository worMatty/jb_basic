#pragma semicolon 1


/**
 * Return a ButtonList of func_button and func_rot_button matching common Jailbreak button names.
 * Looks for: open_cells, opencells, button_cells, cb, close_cells, closecells.
 *
 * @return	An array of entity references for found buttons
 */
ButtonList FindCellButtons()
{
	ButtonList buttonlist = new ButtonList();
	ArrayList found_buttons = new ArrayList();
	int entity = -1;
	
	while ((entity = FindEntityByClassname(entity, "func_button")) != -1)
	{
		found_buttons.Push(entity);
	}
	
	while ((entity = FindEntityByClassname(entity, "func_rot_button")) != -1)
	{
		found_buttons.Push(entity);
	}
	
	for (int i; i < found_buttons.Length; i++)
	{
		int button = found_buttons.Get(i);
		char targetname[32];
		GetEntityTargetname(button, targetname, 32);
		
		if (StrEqual(targetname, "open_cells", false)
		|| StrEqual(targetname, "opencells", false)
		|| StrEqual(targetname, "button_cells", false)
		|| StrEqual(targetname, "cb", false))
		{
			int index = buttonlist.Push(EntIndexToEntRef(button));
			buttonlist.Set(index, ButtonType_Open, 1);
		}
		else if (StrEqual(targetname, "close_cells", false)
		|| StrEqual(targetname, "closecells", false))
		{
			int index = buttonlist.Push(EntIndexToEntRef(button));
			buttonlist.Set(index, ButtonType_Close, 1);
		}
	}
	
	return buttonlist;
}


/**
 * Return a DoorList of func_doors matching common Jailbreak cell door targetnames.
 * Looks for: cell_door, opencells, cells, jaildoor, cell_door_1, prisondoor, jailcells, cd.
 *
 * @return	An array of entity references for found doors
 */
DoorList FindCellDoors()
{
	DoorList doorlist = new DoorList();
	int entity = -1;
	
	while ((entity = FindEntityByClassname(entity, "func_door")) != -1)
	{
		char targetname[32];
		GetEntityTargetname(entity, targetname, 32);
		
		if (StrEqual(targetname, "cell_door", false)
			|| StrEqual(targetname, "opencells", false)
			|| StrEqual(targetname, "cells", false)
			|| StrEqual(targetname, "jaildoor", false)
			|| StrEqual(targetname, "cell_door_1", false)
			|| StrEqual(targetname, "prisondoor", false)
			|| StrEqual(targetname, "jailcells", false)
			|| StrEqual(targetname, "cd", false))
		{
			doorlist.Push(EntIndexToEntRef(entity));
		}
	}
	
	return doorlist;
}


/**
 * Open or close cell doors, either via buttons or directly.
 * 
 * @param	int		Client index
 * @param	bool	True to open or toggle, false to close
 * @error			Cell door or button list does not exist
 */
void CellControlHandler(int client, bool open = true)
{
	if (g_CellDoors.Empty && g_Buttons.Empty)
	{
		ChatResponse(client, _, "%t", "jb_response_unable_toggle_cells");
		return;
	}
	
	// On cooldown
	if (g_iCooldowns[CD_CellDoors] > 2)
	{
		ChatResponse(client, _, "%t", "jb_remote_cells_on_cooldown");
		return;
	}
	
	bool success;
	
	if (!g_Buttons.Empty)
	{
		if (g_Buttons.AnyInRange(client))
		{
			if (g_Buttons.IsPair)
			{
				if (open)
				{
					g_Buttons.PressOpen();
					ChatResponse(client, true, "%t", "jb_cells_you_opened");
					PrintToChatAllEx(client, "%t %t", "prefix", "jb_cells_warden_opened");
					Debug("%N opened the cell doors remotely via the Open button", client);
				}
				else
				{
					g_Buttons.PressClose();
					PrintToChatAll("%t %t", "prefix", "jb_cells_warden_closed");
					Debug("%N closed the cell doors remotely via the Close button", client);
				}
			}
			
			if (g_Buttons.IsToggle)
			{
				g_Buttons.Press();
				ChatResponse(client, true, "%t", "jb_cells_you_pressed_button");
				PrintToChatAllEx(client, "%t %t", "prefix", "jb_cells_warden_pressed_button");
				Debug("%N toggled the cell doors remotely via the button", client);
			}
			
			success = true;
		}
		else
		{
			ChatResponse(client, _, "%t", "jb_out_of_range_of_button");
		}
	}
	
	else if (!g_CellDoors.Empty)
	{
		if (g_CellDoors.AnyInRange(client))
		{
			if (open)
			{
				g_CellDoors.OpenAll();
				ChatResponse(client, true, "%t", "jb_cells_you_opened");
				PrintToChatAllEx(client, "%t %t", "prefix", "jb_cells_warden_opened");
				Debug("%N opened the cell doors remotely and directly", client);
			}
			else
			{
				g_CellDoors.CloseAll();
				PrintToChatAll("%t %t", "prefix", "jb_cells_warden_closed");
				Debug("%N closed the cell doors remotely and directly", client);
			}
			
			success = true;
		}
		else
		{
			ChatResponse(client, _, "%t", "jb_out_of_range_of_cell_doors");
		}
	}
	
	if (success)
	{
		g_iCooldowns[CD_CellDoors] += 1;
		CreateTimer(30.0, Timer_Cooldowns, CD_CellDoors);
		ShowHUD();
	}
}
