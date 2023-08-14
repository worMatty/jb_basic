#pragma semicolon 1




/**
 * Remove special characters from a parsed string.
 * 
 * @noreturn
 */
stock void CleanString(char[] buffer)
{
	// Get the length of the string
	int iLength = strlen(buffer);
	
	// For every character, if it's a special character replace it with whitespace
	for (int i = 0; i < iLength; i++)
	{
		switch (buffer[i])
		{
			case '\r': buffer[i] = ' ';
			case '\n': buffer[i] = ' ';		// New line
			case '\t': buffer[i] = ' ';
		}
	}

	// Remove whitespace from the beginning and end
	TrimString(buffer);
}




/**
 * Format class function. Displays plugin debug message in console when ConVar enabled.
 * Ex: Additionally displays to client.
 *
 * @param	int		Client index
 * @param	bool	Use sound
 * @param	string	Formatting rules
 * @param	...		Variable number of formatting arguments
 * @noreturn
 */
stock void ChatResponse(int client, bool useSound = false, const char[] string, any...)
{
	int len = strlen(string) + 255;
	char[] sBuffer = new char[len];
	VFormat(sBuffer, len, string, 4);
	
	PrintToChat(client, "%t %s", "prefix_reply", sBuffer);
	
	if (useSound)
	{
		char sSound[64];
		g_Sounds.GetString("chat_feedback", sSound, sizeof(sSound));
		EmitSoundToClient(client, sSound);
	}
}



/**
 * Format class function. Displays plugin debug message in console when ConVar enabled.
 *
 * @param string		Formatting rules
 * @param ...			Variable number of formatting arguments
 * @noreturn
 */
stock void Debug(const char[] string, any...)
{
	if (!g_ConVars[P_Debug].BoolValue)
		return;
	
	int len = strlen(string) + 255;
	char[] sBuffer = new char[len];
	VFormat(sBuffer, len, string, 2);
	
	PrintToServer("%s %s", PREFIX_DEBUG, sBuffer);
}



/**
 * Format class function. Displays plugin debug message in console when ConVar enabled.
 * Ex: Additionally displays to client.
 *
 * @param	int	Client index
 * @param	string	Formatting rules
 * @param	...	Variable number of formatting arguments
 * @noreturn
 */
stock void DebugEx(int client, const char[] string, any...)
{
	if (!g_ConVars[P_Debug].BoolValue)
		return;
	
	int len = strlen(string) + 255;
	char[] sBuffer = new char[len];
	VFormat(sBuffer, len, string, 3);
	
	PrintToChat(client, "%t %s", "prefix_error", sBuffer);
	char sSound[64];
	g_Sounds.GetString("chat_debug", sSound, sizeof(sSound));
	EmitSoundToClient(client, sSound);
	PrintToServer("%s %s", PREFIX_DEBUG, sBuffer);
}



/**
 * Send a message to all clients except the one specified.
 *
 * @param	int		Client index
 * @param	string	Formatting rules
 * @param	...		Variable number of formatting arguments
 * @noreturn
 */
stock void PrintToChatAllEx(int client, const char[] string, any...)
{
	int len = strlen(string) + 255;
	char[] sBuffer = new char[len];
	VFormat(sBuffer, len, string, 3);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || i == client)
			continue;
		
		PrintToChat(i, sBuffer);
	}
}



/**
 * Send a message to all admins.
 *
 * @param	int		Client index
 * @param	string	Formatting rules
 * @param	...		Variable number of formatting arguments
 * @noreturn
 */
stock void PrintToChatAdmins(int client, const char[] string, any...)
{
	int len = strlen(string) + 255;
	char[] sBuffer = new char[len];
	VFormat(sBuffer, len, string, 3);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetUserAdmin(i) != INVALID_ADMIN_ID)
			PrintToChat(i, sBuffer);
	}
}



/**
 * Send a message to all admins except the one specified.
 *
 * @param	int		Client index
 * @param	string	Formatting rules
 * @param	...		Variable number of formatting arguments
 * @noreturn
 */
stock void PrintToChatAdminsEx(int client, const char[] string, any...)
{
	int len = strlen(string) + 255;
	char[] sBuffer = new char[len];
	VFormat(sBuffer, len, string, 3);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetUserAdmin(i) != INVALID_ADMIN_ID && i != client)
			PrintToChat(i, sBuffer);
	}
}



/**
 * Get your crosshair's aim target position.
 *
 * @param	int	Client index
 * @return	float	Position of aim target
 */
void GetCrosshair(int client, float pos[3])
{
	float vEyePos[3], vEyeAngles[3];
	
	GetClientEyePosition(client, vEyePos);
	GetClientEyeAngles(client, vEyeAngles);
	
	Handle hTrace = TR_TraceRayFilterEx(vEyePos, vEyeAngles, MASK_PLAYERSOLID, RayType_Infinite, TraceFilter);
	
	if (TR_DidHit(hTrace))
		TR_GetEndPosition(pos, hTrace);
	
	CloseHandle(hTrace);
}

bool TraceFilter(int entity, int contentsMask, any data)
{
	Debug("TraceFilter called.  Entity: %d  contentsMask: %d  data: %d", entity, contentsMask, data);
	
	/*
		TraceFilter is called for each entity my ray hits!
	
		If my ray hits nothing, 'entity' is my player index.
		If my ray hits a player, 'entity' is that player's index.
		If my ray hits an entity_soldier_statue, 'entity' is its entity index.
	*/
	
	return (entity > MaxClients);
}



/**
 * Check if an entity is within range and/or in LOS.
 *
 * @param	int		Client index
 * @param	int		Entity index
 * @param	int		Use range check
 * @param	bool	Use LOS check
 * @return	bool	Entity is within range/LOS
 */
stock bool EntInRange(int client, int entity, float range = 0.0, bool useLOS = false)
{
	// Get Entity Coordindates
	float flClientPos[3], flEntPos[3];
	GetClientAbsOrigin(client, flClientPos);
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", flEntPos);
	
	// Check if Button is in LOS
	Handle hTrace = TR_TraceRayFilterEx(flClientPos, flEntPos, CONTENTS_SOLID, RayType_EndPoint, TraceFilter);
	
	bool bSuccess;

	if (useLOS && TR_GetEntityIndex(hTrace) == entity)
	{
		Debug("Entity %d is in line of sight of %N", entity, client);
		bSuccess = true;
	}
	else if (GetVectorDistance(flClientPos, flEntPos) <= range)
	{
		Debug("Entity %d is within range of %N", entity, client);
		bSuccess = true;
	}
	
	delete(hTrace);
	return bSuccess;
}




/**
 * Pick a random player from a team.
 * 
 * @param	int		Team number
 * @return	int		Client index. 0 if no players on that team
 */
stock int PickRandomTeamMember(int team)
{
	int[] table = new int[MaxClients];
	int index;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == team)
		{
			table[index] = i;
			index += 1;
		}
	}
	
	int result = table[GetRandomInt(0, index - 1)];
	return result;
}



/**
 * Get an entity's targetname
 *
 * @param	entity			Entity index
 * @param	targetname		Destination string buffer
 * @param	maxlength		Maximum length of output string buffer
 * @return					Number of non-null bytes written
 * @error					Invalid entity, offset out of reasonable bounds, or property is not a valid string
 */
stock int GetEntityTargetname(int entity, char[] targetname, int maxlength)
{
	int num_written = GetEntPropString(entity, Prop_Data, "m_iName", targetname, maxlength);
	return num_written;
}


/**
 * Set an entity's targetname
 *
 * @param	entity			Entity index
 * @param	targetname		String to set
 * @return					Number of non-null bytes written
 * @error					Invalid entity, offset out of reasonable bounds, or property is not a valid string
 */
stock int SetEntityTargetname(int entity, char[] targetname)
{
	int num_written = SetEntPropString(entity, Prop_Data, "m_iName", targetname);
	return num_written;
}





/**
 * Maths
 * ----------------------------------------------------------------------------------------------------
 */

/**
 * Clamp an integer between two ranges
 * Min must be lower than max and vice versa
 *
 * @param		int		By-reference variable to clamp
 * @param		int		Minimum clamp boundary
 * @param		int		Maximum clamp boundary
 * @noreturn
 */
stock void ClampInt(int &value, int min, int max)
{
	if (value <= min)
		value = min;
	else if (value >= max)
		value = max;
}



/**
 * Clamp an integer to a minimum value
 *
 * @param		int		By-reference variable to clamp
 * @param		int		Minimum clamp boundary
 * @noreturn
 */
stock void ClampIntMin(int &value, int min)
{
	value = ((value < min) ? min : value);
}



/**
 * Clamp an integer to a maximum value
 *
 * @param		int		By-reference variable to clamp
 * @param		int		Maximum clamp boundary
 * @noreturn
 */
stock void ClampIntMax(int &value, int max)
{
	value = ((value > max) ? max : value);
}



/**
 * Clamp a float
 *
 * @param		float		By-reference variable to clamp
 * @param		float		Minimum clamp boundary
 * @param		float		Maximum clamp boundary
 * @noreturn
 */
stock void ClampFloat(float &value, float min, float max)
{
	if (value < min)
		value = min;
	else if (value > max)
		value = max;
}
