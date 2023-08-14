#pragma semicolon 1


/**
 * Player
 * ----------------------------------------------------------------------------------------------------
 */

enum {
	Player_Index = 0,
	Player_ID,
	Player_Points,
	Player_Flags,
	Player_ArrayMax
}

enum {
	Team_None = 0,
	Team_Spec,
	Team_Inmates,
	Team_Officers,
	Team_Both = 254,
	Team_All = 255
}

// Weapon Slots
enum {
	Weapon_Primary = 0,
	Weapon_Secondary,
	Weapon_Melee,
	Weapon_Grenades,
	Weapon_Building,
	Weapon_PDA,
	Weapon_ArrayMax
}

// Ammo Types
enum {
	Ammo_Dummy = 0,
	Ammo_Primary,
	Ammo_Secondary,
	Ammo_Metal,
	Ammo_Grenades1,	// Thermal Thruster fuel
	Ammo_Grenades2
}

enum {
	LifeState_Alive,
	LifeState_Dying,
	LifeState_Dead,
	LifeState_Respawnable,
	LifeState_DiscardBody
}

enum {
	Points_Starting = 10,		// Queue points a player receives when connecting for the first time
	Points_FullAward = 10,		// Queue points awarded on round end
	Points_PartialAward = 5,	// Smaller amount of round end queue points awarded
	Points_Incremental = 1,		// Number of points awarded to live players by a timer
	Points_Consumed = 0,		// The points a selected player is left with
}

methodmap Player < Handle
{
	public Player(int player) {
		return view_as<Player>(player);
	}
	
	property int Index {
		public get() {
			return view_as<int>(this);
		}
	}
	
	property int UserID {
		public get() {
			if (IsClientConnected(this.Index))	// necessary?
			{
				return GetClientUserId(this.Index);
			}

			return 0;
		}
	}
	
	property int SteamID {
		public get() {
			if (IsClientConnected(this.Index))	// necessary?
			{
				return GetSteamAccountID(this.Index);
			}

			return 0;
		}
	}
	
	property int Team {
		public get() {
			return GetClientTeam(this.Index);
		}
	}
	
	property int Class {
		public get() {
			GetEntProp(this.Index, Prop_Send, "m_iClass");	// TF2 class number
		}
	}
	
	property bool IsConnected {
		public get() {
			return IsClientConnected(this.Index);
		}
	}
	
	property bool InGame {
		public get() {
			return IsClientInGame(this.Index);
		}
	}
	
	property bool IsValid {
		public get() {
			return (this.Index > 0 && this.Index <= MaxClients);
		}
	}
	
	property bool IsObserver {
		public get() {
			return IsClientObserver(this.Index);
		}
	}
	
	property bool IsAlive {
		public get() {
			if (IsClientInGame(this.Index))	// necessary?
			{
				return IsPlayerAlive(this.Index);
			}

			return false;
		}
	}
	
	property bool IsParticipating {
		public get() {
			if (IsClientInGame(this.Index))
			{
				return (GetClientTeam(this.Index) == Team_Inmates || GetClientTeam(this.Index) == Team_Officers);
			}

			return false;
		}
	}
	
	property bool IsAdmin {
		public get() {
			return (GetUserAdmin(this.Index) != INVALID_ADMIN_ID);
		}
	}
	
	property int IsMuted {
		public get() {
			if (g_bBasecomm && BaseComm_IsClientMuted(this.Index))
			{
				return 2;
			}
			else if (GetClientListeningFlags(this.Index) == VOICE_MUTED)
			{
				return 1;
			}
			else
			{
				return 0;
			}
		}
	}
	
	property int Health {
		public get() {
			if (IsClientInGame(this.Index))
			{
				return GetClientHealth(this.Index);
			}

			return 0;
		}
	}
	
	
	/**
	 * Functions
	 * --------------------------------------------------
	 */
	
	public void SetHealth(int health)
	{
		SetEntProp(this.Index, Prop_Send, "m_iHealth", health, 4);
	}
	
	public void SetTeam(int team, bool respawn = true)
	{
		if (!(g_iGame & FLAG_TF))	// TODO Get alternative for TF2 Tools respawn native
		{
			respawn = false;
		}
		
		if (respawn)
		{
			SetEntProp(this.Index, Prop_Send, "m_lifeState", LifeState_Dead);
		}

		ChangeClientTeam(this.Index, team);
		
		if (respawn)
		{
			SetEntProp(this.Index, Prop_Send, "m_lifeState", LifeState_Alive);
		}
		
		if (respawn)
		{
			TF2_RespawnPlayer(this.Index);
		}

		Debug("Moved %N to team %d %s", this.Index, team, (respawn) ? "and respawned them" : "");
	}
	
	public bool SetClass(int class, bool regenerate = true, bool persistent = false)
	{
		TF2_SetPlayerClass(this.Index, view_as<TFClassType>(class), _, persistent);
		
		// Don't regenerate a dead player because they'll go to Limbo
		if (regenerate && IsPlayerAlive(this.Index) && (GetFeatureStatus(FeatureType_Native, "TF2_RegeneratePlayer") == FeatureStatus_Available))
		{
			TF2_RegeneratePlayer(this.Index);
		}
	}

	// Get Weapon Index
	// BUG Use with RequestFrame after spawning or it might return -1
	public int GetWeapon(int slot = Weapon_Primary)
	{
		if (IsClientInGame(this.Index))
		{
			return GetPlayerWeaponSlot(this.Index, slot);
		}

		return -1;
	}
	
	public void SetSlot(int slot = Weapon_Primary)
	{
		int iWeapon;
		
		if (IsClientInGame(this.Index))
		{
			if ((iWeapon = GetPlayerWeaponSlot(this.Index, slot)) == -1)
			{
				LogError("Tried to get %N's weapon in slot %d but got -1. Can't switch to that slot", this.Index, slot);
				return;
			}
		}
		
		if (GetFeatureStatus(FeatureType_Native, "TF2_RemoveCondition") == FeatureStatus_Available)
		{
			TF2_RemoveCondition(this.Index, TFCond_Taunting);
		}
		
		char sClassname[64];
		GetEntityClassname(iWeapon, sClassname, sizeof(sClassname));
		FakeClientCommandEx(this.Index, "use %s", sClassname);
		SetEntProp(this.Index, Prop_Send, "m_hActiveWeapon", iWeapon);
	}
	
	// Switch to Melee & Optionally Restrict
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
	
	public void StripAmmo(int slot)
	{
		int iWeapon = this.GetWeapon(slot);

		if (iWeapon != -1)
		{
			if (GetEntProp(iWeapon, Prop_Data, "m_iClip1") != -1)	// Formerly -1
			{
				//DebugEx(this.Index, "Slot %d weapon had %d ammo", slot, GetEntProp(iWeapon, Prop_Data, "m_iClip1"));
				SetEntProp(iWeapon, Prop_Send, "m_iClip1", 0);
			}
			
			if (GetEntProp(iWeapon, Prop_Data, "m_iClip2") != -1)	// Formerly -1
			{
				//DebugEx(this.Index, "Slot %d weapon had %d ammo", slot, GetEntProp(iWeapon, Prop_Data, "m_iClip2"));
				SetEntProp(iWeapon, Prop_Send, "m_iClip2", 0);
			}
			
			// Weapon's ammo type
			int iAmmoType = GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType", 1);
			
			// Player ammo table offset
			int iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
			
			// Set quantity of that ammo type in table to 0
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
	 * Plugin Properties
	 * --------------------------------------------------
	 */
	
	// Queue Points
	property int Points {
		public get() {
			return g_iPlayers[this.Index][Player_Points];
		}
		public set(int points) {
			g_iPlayers[this.Index][Player_Points] = points;
		}
	}
	
	property int Flags {
		public get() {
			return g_iPlayers[this.Index][Player_Flags];
		}
		public set(int flags) {
			g_iPlayers[this.Index][Player_Flags] = flags;
		}
	}
	
	property bool IsWarden {
		public get() {
			return !!(g_iPlayers[this.Index][Player_Flags] & FLAG_WARDEN);
		}
	}
	
	property bool IsOfficer {
		public get() {
			return !!(g_iPlayers[this.Index][Player_Flags] & FLAG_OFFICER);
		}
	}
	
	property bool IsPrisoner {
		public get() {
			return !!(g_iPlayers[this.Index][Player_Flags] & FLAG_PRISONER);
		}
	}
	
	// User ID from Player Array
	property int ArrayUserID {
		public get() {
			return g_iPlayers[this.Index][Player_ID];
		}
		public set(int userid) {
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
	 * Plugin Functions
	 * --------------------------------------------------
	 */
	
	public void AddPoints(int points)
	{
		g_iPlayers[this.Index][Player_Points] += points;
	}
	
	public void SetPoints(int points)
	{
		g_iPlayers[this.Index][Player_Points] = points;
	}
	
	// Check Player On Connection
	public void CheckArray()
	{
		if (GetClientUserId(this.Index) != g_iPlayers[this.Index][Player_ID])	// not found in array
		{
			this.NewPlayer();	// set them up
		}
		
		if (g_iPlayers[this.Index][Player_Flags] & FLAG_ENGLISH)	// wants English SM translations
		{
			SetClientLanguage(this.Index, 0);
		}
	}
	
	public bool HasFlag(int flag)
	{
		return !!(g_iPlayers[this.Index][Player_Flags] & flag);	// https://forums.alliedmods.net/showthread.php?t=319928
	}
	
	public void AddFlag(int flag)
	{
		g_iPlayers[this.Index][Player_Flags] |= flag;
	}
	
	public void RemoveFlag(int flag)
	{
		g_iPlayers[this.Index][Player_Flags] &= ~flag;
	}
	
	public void MakeWarden(bool grant = true)
	{
		if (grant)
		{
			this.Flags |= FLAG_WARDEN;
			g_iState |= FLAG_HAVE_WARDEN;

			// Scale up model by 20%			
			SetVariantString("1.2");
			if (AcceptEntityInput(this.Index, "SetModelScale"))
			{
				this.Flags |= FLAG_WARDEN_LARGE;
			}
			
			ShowAnnotation(this.Index, "jb_annotation_player_is_a_warden", this.Index, _, _, true);
			
			char sName[32];
			GetClientName(this.Index, sName, sizeof(sName));
			PrintToChatAllEx(this.Index, "%t %t", "prefix", "jb_name_became_warden", sName);
			ChatResponse(this.Index, true, "%t", "jb_you_are_a_warden");
			ShowHUD(this.Index);
		}
		else
		{
			this.Flags &= ~FLAG_WARDEN|FLAG_WARDEN_LARGE;
			SetVariantString("1.0");
			AcceptEntityInput(this.Index, "SetModelScale");
			Debug("Removed %N's warden status", this.Index);
			ShowHUD(this.Index);
		}
	}
	
	public void MakeOfficer(bool grant = true)
	{
		if (grant)
		{
			this.Flags |= FLAG_OFFICER;
			PrintToChat(this.Index, "%t %t", "prefix_reply", "jb_you_are_an_officer");
		}
		else
		{
			this.Flags &= ~FLAG_OFFICER;
		}
	}
	
	public void MakePrisoner(bool grant = true)
	{
		if (grant)
		{
			if (!this.IsPrisoner)
			{
				this.Flags |= FLAG_PRISONER;
				PrintToChat(this.Index, "%t %t", "prefix_reply", "jb_you_are_a_prisoner");
			}

			this.StripAmmo(Weapon_Primary);
			this.StripAmmo(Weapon_Secondary);
		}
		else
		{
			this.Flags &= ~FLAG_PRISONER;
		}

		SetEntProp(this.Index, Prop_Send, "m_bIsMiniBoss", grant, 1);	// TODO Does this get reset on death?
	}
	
	public bool Mute(bool mute = true)
	{
		if (g_bBasecomm && BaseComm_IsClientMuted(this.Index))
		{
			return false;
		}
		
		if (mute)
		{
			SetClientListeningFlags(this.Index, VOICE_MUTED);
			ShowHUD(this.Index);
		}
		else
		{
			SetClientListeningFlags(this.Index, VOICE_SPEAKALL);
			ShowHUD(this.Index);
		}
		
		return true;
	}
}




methodmap EntityList < ArrayList
{
	public EntityList(int blocksize = 1)
	{
		return view_as<EntityList>(new ArrayList(blocksize));
	}
	
	property bool Empty {
		public get() {
			this.Validate();
			return !this.Length;
		}
	}
	
	public void Validate() 
	{
		for (int i; i < this.Length;)
		{
			if (IsValidEntity(this.Get(i)))
			{
				i++;
			}
			else
			{
				this.Erase(i);
			}
		}
	}
	
	public bool AnyInRange(int client)
	{
		bool in_range;
		
		for (int i; i < this.Length; i++)
		{
			int entity = this.Get(i);
			
			if (IsValidEntity(entity))
			{
				if (EntInRange(client, entity, g_ConVars[P_RemoteRange].FloatValue, true))
				{
					in_range = true;
					break;
				}
			}
		}
		
		return in_range;
	}
}



methodmap DoorList < EntityList
{
	public DoorList()
	{
		return view_as<DoorList>(new EntityList());
	}

	public int OpenAll()
	{
		int opened;
		
		for (int i; i < this.Length; i++)
		{
			int door = this.Get(i);
			
			if (IsValidEntity(door))
			{
				if (AcceptEntityInput(door, "Open"))
				{
					opened += 1;
				}
			}
		}
		
		return opened;
	}
	
	public int CloseAll()
	{
		int closed;
		
		for (int i; i < this.Length; i++)
		{
			int door = this.Get(i);
			
			if (IsValidEntity(door))
			{
				if (AcceptEntityInput(door, "Close"))
				{
					closed += 1;
				}
			}
		}
		
		return closed;
	}
}


enum {
	ButtonType_Open,
	ButtonType_Close,
}

methodmap ButtonList < EntityList
{
	public ButtonList()
	{
		return view_as<ButtonList>(new EntityList(2));
	}
	
	public void GetTypeCounts(int &open_count, int &close_count)
	{
		this.Validate();
		
		int open, close;
		
		for (int i; i < this.Length; i++)
		{
			int type = this.Get(i, 1);
			
			if (type == ButtonType_Open)
			{
				open++;
			}
			
			if (type == ButtonType_Close)
			{
				close++;
			}
		}
		
		open_count = open;
		close_count = close;
	}
	
	property bool IsToggle
	{
		public get()
		{
			int open_count, close_count;
			this.GetTypeCounts(open_count, close_count);
			
			if (close_count == 0 && open_count > 0)
			{
				return true;
			}
			
			return false;
		}
	}
	
	property bool IsPair
	{
		public get()
		{
			int open_count, close_count;
			this.GetTypeCounts(open_count, close_count);
			
			if (close_count > 0 && open_count > 0)
			{
				return true;
			}
			
			return false;
		}
	}
	
	public int Press()
	{
		int pressed;
		
		for (int i; i < this.Length; i++)
		{
			int button = this.Get(i);
			
			if (IsValidEntity(button))
			{
				if (AcceptEntityInput(button, "Press"))
				{
					pressed += 1;
				}
			}
		}
		
		return pressed;
	}
	
	public int PressOpen()
	{
		int pressed;
		
		for (int i; i < this.Length; i++)
		{
			int button = this.Get(i);
			int buttontype = this.Get(i, 1);
			
			if (IsValidEntity(button) && buttontype == ButtonType_Open)
			{
				if (AcceptEntityInput(button, "Press"))
				{
					pressed += 1;
				}
			}
		}
		
		return pressed;
	}
	
	public int PressClose()
	{
		int pressed;
		
		for (int i; i < this.Length; i++)
		{
			int button = this.Get(i);
			int buttontype = this.Get(i, 1);
			
			if (IsValidEntity(button) && buttontype == ButtonType_Close)
			{
				if (AcceptEntityInput(button, "Press"))
				{
					pressed += 1;
				}
			}
		}
		
		return pressed;
	}
}