/**
 * Methodmaps
 * ----------------------------------------------------------------------------------------------------
 */



/**
 * Player
 * ----------------------------------------------------------------------------------------------------
 */
methodmap Player < Handle
{
	public Player(int player)
	{
		return view_as<Player>(player);
	}
	
	
	/**
	 * Properties
	 * --------------------------------------------------
	 * --------------------------------------------------
	 */
	
	// Client Index
	property int Index
	{
		public get()
		{
			return view_as<int>(this);
		}
	}
	
	// User ID
	property int UserID
	{
		public get()
		{
			if (IsClientConnected(this.Index))
				return GetClientUserId(this.Index);
			else
				return 0;
		}
	}
	
	// Steam Account ID
	property int SteamID
	{
		public get()
		{
			if (IsClientConnected(this.Index))
				return GetSteamAccountID(this.Index);
			else
				return 0;
		}
	}
	
	// Team Number
	property int Team
	{
		public get()
		{
			return GetClientTeam(this.Index);
		}
	}
	
	// Class Number
	property int Class
	{
		public get()
		{
			GetEntProp(this.Index, Prop_Send, "m_iClass");
		}
	}
	
	// Is Connected
	property bool IsConnected
	{
		public get()
		{
			return IsClientConnected(this.Index);
		}
	}
	
	// In Game
	property bool InGame
	{
		public get()
		{
			return IsClientInGame(this.Index);
		}
	}
	
	// Is Observer
	property bool IsObserver
	{
		public get()
		{
			return IsClientObserver(this.Index);
		}
	}
	
	// Alive
	property bool IsAlive
	{
		public get()
		{
			if (IsClientInGame(this.Index))
				return IsPlayerAlive(this.Index);
				//return (!IsClientObserver(this.Index));
			else
				return false;
		}
	}
	
	// Is Participating
	property bool IsParticipating
	{
		public get()
		{
			if (IsClientInGame(this.Index))
				return (GetClientTeam(this.Index) == Team_Red || GetClientTeam(this.Index) == Team_Blue);
			else
				return false;
		}
	}
	
	// Health
	property int Health
	{
		public get()
		{
			if (IsClientInGame(this.Index))
				return GetClientHealth(this.Index);
			else
				return 0;
		}
	}
	
	
	/**
	 * Functions
	 * --------------------------------------------------
	 * --------------------------------------------------
	 */
	
	// Set Health
	public void SetHealth(int health)
	{
		SetEntProp(this.Index, Prop_Send, "m_iHealth", health, 4);
	}
	
	// Set Team & Optionally Respawn
	public void SetTeam(int team, bool respawn=true)
	{
		if (!(g_iGame & FLAG_TF))	// TODO Get alternative for TF2 Tools respawn native
			respawn = false;
		
		if (respawn) SetEntProp(this.Index, Prop_Send, "m_lifeState", LifeState_Dead);
		ChangeClientTeam(this.Index, team);
		if (respawn) SetEntProp(this.Index, Prop_Send, "m_lifeState", LifeState_Alive);
		if (respawn) TF2_RespawnPlayer(this.Index);
		
		Debug("Moved %N to team %d %s", this.Index, team, (respawn) ? "and respawned them" : "");
		
		// If running in Open Fortress or TF2C, respawn all players
		if (g_iGame & (FLAG_OF|FLAG_TF2C)) // TODO Change to a check if the native is available
		{
			int iRespawn = CreateEntityByName("game_forcerespawn");
			if (iRespawn == -1)
				LogError("Unable to create game_forcerespawn");
			else
			{
				if (!DispatchSpawn(iRespawn))
					LogError("Unable to spawn game_forcerespawn");
				else
				{
					if (!AcceptEntityInput(iRespawn, "ForceRespawn"))
						LogError("game_forcerespawn wouldn't accept our ForceRespawn input");
					else
						Debug("Respawned all players by creating a game_forcerespawn");
				}
				RemoveEdict(iRespawn);
			}
		}
	}
	
	// Set Class
	public bool SetClass(int class, bool regenerate=true, bool persistent=false)
	{
		TF2_SetPlayerClass(this.Index, view_as<TFClassType>(class), _, persistent);
		
		// Don't regenerate a dead player because they'll go to Limbo
		if (regenerate && IsPlayerAlive(this.Index) && (GetFeatureStatus(FeatureType_Native, "TF2_RegeneratePlayer") == FeatureStatus_Available))
			TF2_RegeneratePlayer(this.Index);
	}
	

	// Get Weapon Index
	// BUG Use with RequestFrame after spawning or it might return -1
	public int GetWeapon(int slot=TFWeaponSlot_Primary)
	{
		if (IsClientInGame(this.Index))
			return GetPlayerWeaponSlot(this.Index, slot);
		else
			return -1;
	}
	
	// Switch to Slot
	public void SetSlot(int slot=TFWeaponSlot_Primary)
	{
		int iWeapon;
		
		if (IsClientInGame(this.Index))
			if ((iWeapon = GetPlayerWeaponSlot(this.Index, slot)) == -1)
			{
				LogError("Tried to get %N's weapon in slot %d but got -1. Can't switch to that slot", this.Index, slot);
				return;
			}
		
		if (GetFeatureStatus(FeatureType_Native, "TF2_RemoveCondition") == FeatureStatus_Available)
			TF2_RemoveCondition(this.Index, TFCond_Taunting);
		
		char sClassname[64];
		GetEntityClassname(iWeapon, sClassname, sizeof(sClassname));
		FakeClientCommandEx(this.Index, "use %s", sClassname);
		SetEntProp(this.Index, Prop_Send, "m_hActiveWeapon", iWeapon);
	}
	
	// Switch to Melee & Optionally Restrict
	// TODO Find out OF melee slot
	public void MeleeOnly(bool enable=true, bool remove_others=false)
	{
		bool bConds = (GetFeatureStatus(FeatureType_Native, "TF2_AddCondition") == FeatureStatus_Available);
		
		if (enable)
		{
			if (bConds)
			{
				TF2_AddCondition(this.Index, TFCond_RestrictToMelee, TFCondDuration_Infinite);
				remove_others = true;
			}
			
			this.SetSlot(TFWeaponSlot_Melee);
			
			if (remove_others)
			{
				TF2_RemoveWeaponSlot(this.Index, TFWeaponSlot_Primary);
				TF2_RemoveWeaponSlot(this.Index, TFWeaponSlot_Secondary);
			}
			
			Debug("Restricted %N to melee %s", this.Index, (remove_others) ? "and removed their other weapons" : "");
		}
		else
		{
			if (GetFeatureStatus(FeatureType_Native, "TF2_RegeneratePlayer") == FeatureStatus_Available &&
			(GetPlayerWeaponSlot(this.Index, TFWeaponSlot_Primary) == -1 || GetPlayerWeaponSlot(this.Index, TFWeaponSlot_Secondary) == -1))
			{
				int iHealth = this.Health;
				TF2_RegeneratePlayer(this.Index);
				this.SetHealth(iHealth);
			}
			
			if (GetFeatureStatus(FeatureType_Native, "TF2_RemoveCondition") == FeatureStatus_Available)
				TF2_RemoveCondition(this.Index, TFCond_RestrictToMelee);
			
			this.SetSlot();
			
			Debug("Removed %N's melee-only restriction %s", this.Index, (remove_others) ? "and respawned their other weapons" : "");
		}
	}
	
	// Strip Ammo
	public void StripAmmo(int slot)
	{
		int iWeapon = this.GetWeapon(slot);
		if (iWeapon != -1)
		{
			if (GetEntProp(iWeapon, Prop_Data, "m_iClip1") != -1)
			{
				DebugEx(this.Index, "Clip 1 of slot %d contains %d ammo", slot, GetEntProp(iWeapon, Prop_Data, "m_iClip1"));
				SetEntProp(iWeapon, Prop_Send, "m_iClip1", 0);
			}
			
			if (GetEntProp(iWeapon, Prop_Data, "m_iClip2") != -1)
			{
				DebugEx(this.Index, "Clip 2 of slot %d contains %d ammo", slot, GetEntProp(iWeapon, Prop_Data, "m_iClip2"));
				SetEntProp(iWeapon, Prop_Send, "m_iClip2", 0);
			}
			
			// Get the type of ammo the weapon uses
			int iAmmoType = GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType", 1);
			
			// Get the player's ammo store table offset
			int iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
			
			// Go to the position in the table for the ammo type and set it to 0
			SetEntData(this.Index, iAmmoTable + (iAmmoType * 4), 0, 4, true);
		}

		/*
			Get the weapon index
			Get its ammo type
			Set its clip values
			Set the client's ammo?
		*/
	}
	
	
	/**
	 * Plugin Stuff
	 * --------------------------------------------------
	 * --------------------------------------------------
	 */
	
	// Queue Points
	property int Points
	{
		public get()
		{
			return g_iPlayers[this.Index][Player_Points];
		}
		public set(int points)
		{
			g_iPlayers[this.Index][Player_Points] = points;
		}
	}
	
	// Plugin Flags
	property int Flags
	{
		public get()
		{
			return g_iPlayers[this.Index][Player_Flags];
		}
		public set(int flags)
		{
			g_iPlayers[this.Index][Player_Flags] = flags;
		}
	}
	
	// Is Warden
	property bool IsWarden
	{
		public get()
		{
			if (g_iPlayers[this.Index][Player_Flags] & FLAG_WARDEN)
				return true;
			else
				return false;
		}
	}
	
	// Is Prisoner
	property bool IsPrisoner
	{
		public get()
		{
			if (g_iPlayers[this.Index][Player_Flags] & FLAG_PRISONER)
				return true;
			else
				return false;
		}
	}
	
	// User ID from Player Array
	property int ArrayUserID
	{
		public get()
		{
			return g_iPlayers[this.Index][Player_ID];
		}
		public set(int userid)
		{
			g_iPlayers[this.Index][Player_ID] = userid;
		}
	}
	
	// Initialise a New Player's Data in the Array
	public void NewPlayer()
	{
		g_iPlayers[this.Index][Player_ID] = this.UserID;
		g_iPlayers[this.Index][Player_Points] = Points_Starting;
		g_iPlayers[this.Index][Player_Flags] = MASK_DEFAULT_FLAGS;
	}
	
	/**
	 * Set a player's queue points value in the data array.
	 * 
	 * @noreturn
	 */
	/*public void SetPoints(int points)
	{
		g_iPlayers[this.Index][Player_Points] = points;
	}*/
	
	// Add Queue Points
	public void AddPoints(int points)
	{
		g_iPlayers[this.Index][Player_Points] += points;
	}
	
	
	// Check Player On Connection TODO Rename
	public void CheckArray()
	{
		// If the player's User ID is not in our array
		if (GetClientUserId(this.Index) != g_iPlayers[this.Index][Player_ID])
		{
			this.NewPlayer();
		}
		
		// If the player wants SourceMod translations in English, set their language
		if (g_iPlayers[this.Index][Player_Flags] & FLAG_ENGLISH)
		{
			SetClientLanguage(this.Index, 0);
		}
	}
	
	// Make the Player a Warden
	public void MakeWarden(bool grant=true)
	{
		if (grant)
		{
			this.Flags |= FLAG_WARDEN;
			SetVariantString("1.2");
			AcceptEntityInput(this.Index, "SetModelScale");
			ShowAnnotation(this.Index, "jb_annotation_player_is_a_warden", this.Index, _, _, true);
			PrintToChat(this.Index, "%t %t", "prefix_personal", "jb_you_are_a_warden");
			
			for (int i = 1; i <= MaxClients; i++)
			{
				char sName[32];
				GetClientName(this.Index, sName, sizeof(sName));
				
				Player player = new Player(i);
				if (player.InGame && this.Index != player.Index)
					PrintToChat(player.Index, "%t %t", "prefix", "jb_name_became_warden", sName);
			}
		}
		else
		{
			this.Flags &= ~FLAG_WARDEN;
			SetVariantString("1.0");
			AcceptEntityInput(this.Index, "SetModelScale");
			Debug("Removed %N's warden status", this.Index);
		}
	}
	
	// Make the Player an Officer
	public void MakeOfficer(bool grant=true)
	{
		if (grant)
		{
			this.Flags |= FLAG_OFFICER;
			PrintToChat(this.Index, "%t %t", "prefix_personal", "jb_you_are_an_officer");
		}
		else
		{
			this.Flags &= ~FLAG_OFFICER;
		}
	}
	
	// Make the Player a Prisoner
	public void MakePrisoner(bool grant=true)
	{
		if (grant)
		{
			if (!this.IsPrisoner)
			{
				this.Flags |= FLAG_PRISONER;
				PrintToChat(this.Index, "%t %t", "prefix_personal", "jb_you_are_a_prisoner");
			}
			this.StripAmmo(Weapon_Primary);
			this.StripAmmo(Weapon_Secondary);
		}
		else
		{
			this.Flags &= ~FLAG_PRISONER;
		}
	}
	
	// Set 'Alive' Voice Flags
	public void VoiceAlive()
	{
		int iFlags = GetClientListeningFlags(this.Index);
		SetClientListeningFlags(this.Index, VOICE_SPEAKALL);
		// While alive, transmit to team mates both alive and dead.
		// Only receive from live team mates. Transmit to all players including enemy
		DebugEx(this.Index, "%N's listening flags were %06b, they are now %06b", this.Index, iFlags, GetClientListeningFlags(this.Index));
	}
	
	// Set 'Dead' Void Flags
	public void VoiceDead()
	{
		int iFlags = GetClientListeningFlags(this.Index);
		SetClientListeningFlags(this.Index, VOICE_LISTENALL);
		// Transmit to dead team mates. Hear all players including enemy live and dead
		DebugEx(this.Index, "%N's listening flags were %06b, they are now %06b", this.Index, iFlags, GetClientListeningFlags(this.Index));
	}
}