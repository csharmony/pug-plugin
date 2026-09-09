// See include/pug-plugin.inc for documentation.

#define CHECK_CLIENT(%1) \
  if (!IsValidClient(%1)) \
  ThrowNativeError(SP_ERROR_PARAM, "Client %d is not connected", %1)
#define CHECK_CAPTAIN(%1) \
  if (%1 != 1 && %1 != 2) \
  ThrowNativeError(SP_ERROR_PARAM, "Captain number %d is not valid", %1)
#define CHECK_COMMAND(%1) \
  if (!PugPlugin_IsValidCommand(%1)) \
  ThrowNativeError(SP_ERROR_PARAM, "Pug-plugin command %s is not valid", %1)

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_ChatAliases = new ArrayList(ALIAS_LENGTH);
	g_ChatAliasesCommands = new ArrayList(COMMAND_LENGTH);
	g_ChatAliasesModes = new ArrayList();

	g_MapList = new ArrayList(PLATFORM_MAX_PATH);
	g_PermissionsMap = new StringMap();

	CreateNative("PugPlugin_SetupGame", Native_SetupGame);
	CreateNative("PugPlugin_SetSetupOptions", Native_SetSetupOptions);
	CreateNative("PugPlugin_GetSetupOptions", Native_GetSetupOptions);
	CreateNative("PugPlugin_ReadyPlayer", Native_ReadyPlayer);
	CreateNative("PugPlugin_UnreadyPlayer", Native_UnreadyPlayer);
	CreateNative("PugPlugin_IsReady", Native_IsReady);
	CreateNative("PugPlugin_IsSetup", Native_IsSetup);
	CreateNative("PugPlugin_GetTeamType", Native_GetTeamType);
	CreateNative("PugPlugin_GetMapType", Native_GetMapType);
	CreateNative("PugPlugin_GetGameState", Native_GetGameState);
	CreateNative("PugPlugin_IsMatchLive", Native_IsMatchLive);
	CreateNative("PugPlugin_IsPendingStart", Native_IsPendingStart);
	CreateNative("PugPlugin_SetLeader", Native_SetLeader);
	CreateNative("PugPlugin_GetLeader", Native_GetLeader);
	CreateNative("PugPlugin_GetCaptain", Native_GetCaptain);
	CreateNative("PugPlugin_SetCaptain", Native_SetCaptain);
	CreateNative("PugPlugin_Message", Native_Message);
	CreateNative("PugPlugin_MessageToAll", Native_MessageToAll);
	CreateNative("PugPlugin_GetPugMaxPlayers", Native_GetPugMaxPlayers);
	CreateNative("PugPlugin_PlayerAtStart", Native_PlayerAtStart);
	CreateNative("PugPlugin_IsPugAdmin", Native_IsPugAdmin);
	CreateNative("PugPlugin_HasPermissions", Native_HasPermissions);
	CreateNative("PugPlugin_SetRandomCaptains", Native_SetRandomCaptains);
	CreateNative("PugPlugin_AddChatAlias", Native_AddChatAlias);
	CreateNative("PugPlugin_GiveSetupMenu", Native_GiveSetupMenu);
	CreateNative("PugPlugin_GiveMapChangeMenu", Native_GiveMapChangeMenu);
	CreateNative("PugPlugin_IsValidCommand", Native_IsValidCommand);
	CreateNative("PugPlugin_GetPermissions", Native_GetPermissions);
	CreateNative("PugPlugin_SetPermissions", Native_SetPermissions);
	RegPluginLibrary("pug-plugin");
	return APLRes_Success;
}
public int Native_SetupGame(Handle plugin, int numParams)
{
	g_TeamType = view_as<TeamType>(GetNativeCell(1));
	g_MapType = view_as<MapType>(GetNativeCell(2));
	g_PlayersPerTeam = GetNativeCell(3);

	// optional parameters added, checking is they were
	// passed for backwards compatibility
	if(numParams >= 4)
	{
		g_RecordGameOption = GetNativeCell(4);
	}

	if(numParams >= 5)
	{
		g_DoKnifeRound = GetNativeCell(5);
	}

	if(numParams >= 6)
	{
		g_AutoLive = GetNativeCell(6);
	}

	SetupFinished();
	return 0;
}
public int Native_GetSetupOptions(Handle plugin, int numParams)
{
	if(!PugPlugin_IsSetup())
	{
		ThrowNativeError(SP_ERROR_ABORTED, "Cannot get setup options when a match is not setup.");
	}

	SetNativeCellRef(1, g_TeamType);
	SetNativeCellRef(2, g_MapType);
	SetNativeCellRef(3, g_PlayersPerTeam);
	SetNativeCellRef(4, g_RecordGameOption);
	SetNativeCellRef(5, g_DoKnifeRound);
	SetNativeCellRef(6, g_AutoLive);

	return 0;
}
public int Native_SetSetupOptions(Handle plugin, int numParams)
{
	g_TeamType = view_as<TeamType>(GetNativeCell(1));
	g_MapType = view_as<MapType>(GetNativeCell(2));
	g_PlayersPerTeam = GetNativeCell(3);
	g_RecordGameOption = GetNativeCell(4);
	g_DoKnifeRound = GetNativeCell(5);
	g_AutoLive = GetNativeCell(6);
}
public int Native_ReadyPlayer(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	CHECK_CLIENT(client);

	bool replyMessages = true;
	// Backwards compatability check.
	if(numParams >= 2)
	{
		replyMessages = GetNativeCell(2);
	}

	if(g_GameState != GameState_Warmup || !IsPlayer(client))
		return false;

	if(g_ExcludeSpectatorsCvar.IntValue != 0 && GetClientTeam(client) == CS_TEAM_SPECTATOR)
	{
		if(replyMessages)
			PugPlugin_Message(client, "%t", "SpecCantReady");
		return false;
	}

	// already ready
	if(g_Ready[client])
	{
		return false;
	}

	Call_StartForward(g_hOnReady);
	Call_PushCell(client);
	Call_Finish();

	g_Ready[client] = true;
	UpdateClanTag(client);

	if(g_EchoReadyMessagesCvar.IntValue != 0 && replyMessages)
	{
		if(g_AllowCustomReadyMessageCvar.IntValue != 0)
		{
			char message[256];
			GetClientCookie(client, g_ReadyMessageCookie, message, sizeof message);
			if(!StrEqual(message, ""))
			{
				PugPlugin_MessageToAll("%N %s", client, message);
			}
			else
			{
				PugPlugin_MessageToAll("%t", "IsNowReady", client);
			}
		}
		else
		{
			PugPlugin_MessageToAll("%t", "IsNowReady", client);
		}
	}

	return true;
}
public int Native_UnreadyPlayer(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	CHECK_CLIENT(client);

	if(g_GameState != GameState_Warmup || !IsPlayer(client))
		return false;

	// already un-ready
	if(!g_Ready[client])
	{
		return false;
	}

	Call_StartForward(g_hOnUnready);
	Call_PushCell(client);
	Call_Finish();

	g_Ready[client] = false;
	UpdateClanTag(client);

	if(g_EchoReadyMessagesCvar.IntValue != 0)
	{
		PugPlugin_MessageToAll("%t", "IsNoLongerReady", client);
	}

	return true;
}
public int Native_IsReady(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	CHECK_CLIENT(client);
	if(!IsClientInGame(client) || IsFakeClient(client))
		return false;

	if(g_ExcludeSpectatorsCvar.IntValue != 0)
	{
		return g_Ready[client] && OnActiveTeam(client);
	}
	else
	{
		return g_Ready[client];
	}
}
public int Native_IsSetup(Handle plugin, int numParams)
{
	return g_GameState >= GameState_Warmup;
}
public int Native_GetMapType(Handle plugin, int numParams)
{
	return view_as<int>(g_MapType);
}
public int Native_GetTeamType(Handle plugin, int numParams)
{
	return view_as<int>(g_TeamType);
}
public int Native_GetGameState(Handle plugin, int numParams)
{
	return view_as<int>(g_GameState);
}
public int Native_IsMatchLive(Handle plugin, int numParams)
{
	return g_GameState == GameState_Live;
}
public int Native_IsPendingStart(Handle plugin, int numParams)
{
	return g_GameState >= GameState_PickingPlayers && g_GameState <= GameState_GoingLive;
}
public int Native_SetLeader(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	CHECK_CLIENT(client);

	if(IsPlayer(client))
	{
		PugPlugin_MessageToAll("%t", "NewLeader", client);
		g_Leader = client;
	}
}
public int Native_GetLeader(Handle plugin, int numParams)
{
// first check if our "leader" is still connected
	if(g_Leader > 0 && IsClientConnected(g_Leader) && !IsFakeClient(g_Leader))
		return g_Leader;

	if(numParams >= 1)
	{
		bool doReassign = GetNativeCell(1);
		if(!doReassign)
			return -1;
	}

	// then check if we have someone with admin permissions
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsPlayer(i) && PugPlugin_IsPugAdmin(i))
		{
			g_Leader = i;
			return i;
		}
	}

	// otherwise fall back to a random player
	int r = RandomPlayer();
	if(IsPlayer(r))
		g_Leader = r;

	return r;
}
public int Native_SetCaptain(Handle plugin, int numParams)
{
	int captainNumber = GetNativeCell(1);
	CHECK_CAPTAIN(captainNumber);

	int client = GetNativeCell(2);
	CHECK_CLIENT(client);

	bool printIfSame = false;
	// backwards compatability
	if(numParams >= 3)
	{
		printIfSame = GetNativeCell(3);
	}

	if(IsPlayer(client))
	{
		int originalCaptain = -1;
		if(captainNumber == 1)
		{
			originalCaptain = g_capt1;
			g_capt1 = client;
		}
		else
		{
			originalCaptain = g_capt2;
			g_capt2 = client;
		}

		// Only printout if it's a different captain
		if(printIfSame || client != originalCaptain)
		{
			char buffer[64];
			FormatPlayerName(client, client, buffer);
			PugPlugin_MessageToAll("%t", "CaptMessage", captainNumber, buffer);
		}
	}

	return 0;
}
public int Native_GetCaptain(Handle plugin, int numParams)
{
	int captainNumber = GetNativeCell(1);
	CHECK_CAPTAIN(captainNumber);

	int capt = (captainNumber == 1) ? g_capt1 : g_capt2;

	if(IsValidClient(capt) && !IsFakeClient(capt))
		return capt;
	else
		return -1;
}
public int Native_Message(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(client != 0 && (!IsClientConnected(client) || !IsClientInGame(client)))
		return 0;

	char buffer[1024];
	int bytesWritten = 0;
	SetGlobalTransTarget(client);
	FormatNativeString(0, 2, 3, sizeof buffer, bytesWritten, buffer);

	char prefix[64];
	g_MessagePrefixCvar.GetString(prefix, sizeof prefix);

	char finalMsg[1024];
	if(StrEqual(prefix, ""))
		Format(finalMsg, sizeof finalMsg, " %s", buffer);
	else
		Format(finalMsg, sizeof finalMsg, "%s %s", prefix, buffer);

	if(client == 0)
	{
		Colorize(finalMsg, sizeof finalMsg, false);
		PrintToConsole(client, finalMsg);
	}
	else if(IsClientInGame(client))
	{
		Colorize(finalMsg, sizeof finalMsg);
		PrintToChat(client, finalMsg);
	}

	return 0;
}
public int Native_MessageToAll(Handle plugin, int numParams)
{
	char prefix[64];
	g_MessagePrefixCvar.GetString(prefix, sizeof prefix);
	char buffer[1024];
	int bytesWritten = 0;

	for(int i = 0; i <= MaxClients; i++)
	{
		if(i != 0 && (!IsClientConnected(i) || !IsClientInGame(i)))
			continue;

		SetGlobalTransTarget(i);
		FormatNativeString(0, 1, 2, sizeof buffer, bytesWritten, buffer);

		char finalMsg[1024];
		if(StrEqual(prefix, ""))
			Format(finalMsg, sizeof finalMsg, " %s", buffer);
		else
			Format(finalMsg, sizeof finalMsg, "%s %s", prefix, buffer);

		if(i != 0)
		{
			Colorize(finalMsg, sizeof finalMsg);
			PrintToChat(i, finalMsg);
		}
		else
		{
			Colorize(finalMsg, sizeof finalMsg, false);
			PrintToConsole(i, finalMsg);
		}
	}
}
public int Native_GetPugMaxPlayers(Handle plugin, int numParams)
{
	return 2 * g_PlayersPerTeam;
}
public int Native_PlayerAtStart(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return IsPlayer(client) && g_PlayerAtStart[client];
}
public int Native_IsPugAdmin(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	CHECK_CLIENT(client);

	AdminId admin = GetUserAdmin(client);
	if(admin != INVALID_ADMIN_ID)
	{
		char flags[8];
		AdminFlag flag;
		g_AdminFlagCvar.GetString(flags, sizeof flags);
		if(!FindFlagByChar(flags[0], flag))
		{
			LogError("Invalid immunity flag: %s", flags[0]);
			return false;
		}
		else
		{
			return GetAdminFlag(admin, flag);
		}
	}

	return false;
}
public int Native_HasPermissions(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(client == 0)
		return true;

	CHECK_CLIENT(client);

	bool allowLeaderReassignment = true;
	if(numParams >= 3)
		allowLeaderReassignment = GetNativeCell(3);

	Permission p = view_as<Permission>(GetNativeCell(2));
	bool isAdmin = PugPlugin_IsPugAdmin(client);
	bool isLeader = PugPlugin_GetLeader(allowLeaderReassignment) == client;
	bool isCapt = (client == g_capt1) || (client == g_capt2);

	if(p == Permission_Admin)
		return isAdmin;
	else if(p == Permission_Leader)
		return isLeader || isAdmin;
	else if(p == Permission_Captains)
		return isCapt || isLeader || isAdmin;
	else if(p == Permission_All)
		return true;
	else if(p == Permission_None)
		return false;
	else
		ThrowNativeError(SP_ERROR_PARAM, "Unknown permission value: %d", p);

	return false;
}
public int Native_SetRandomCaptains(Handle plugin, int numParams)
{
	int c1 = -1;
	int c2 = -1;

	c1 = RandomPlayer();
	while(!IsPlayer(c2) || c1 == c2)
	{
		if(GetRealClientCount() < 2)
			break;

		c2 = RandomPlayer();
	}

	if(IsPlayer(c1))
		PugPlugin_SetCaptain(1, c1, true);

	if(IsPlayer(c2))
		PugPlugin_SetCaptain(2, c2, true);

	return 0;
}
public int Native_AddChatAlias(Handle plugin, int numParams)
{
	char alias[ALIAS_LENGTH];
	char command[COMMAND_LENGTH];
	GetNativeString(1, alias, sizeof alias);
	GetNativeString(2, command, sizeof command);

	ChatAliasMode mode = ChatAlias_Always;
	if(numParams >= 3)
	{
		mode = GetNativeCell(3);
	}

	// don't allow duplicate aliases to be added
	if(g_ChatAliases.FindString(alias) == -1)
	{
		g_ChatAliases.PushString(alias);
		g_ChatAliasesCommands.PushString(command);
		g_ChatAliasesModes.Push(mode);
	}

	return 0;
}
public int Native_GiveSetupMenu(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	CHECK_CLIENT(client);
	bool displayOnly = GetNativeCell(2);

	// backwards compatability
	int menuPosition = -1;
	if(numParams >= 3)
	{
		menuPosition = GetNativeCell(3);
	}

	SetupMenu(client, displayOnly, menuPosition);

	return 0;
}
public int Native_GiveMapChangeMenu(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	CHECK_CLIENT(client);
	ChangeMapMenu(client);
}
public int Native_IsValidCommand(Handle plugin, int numParams)
{
	char command[COMMAND_LENGTH];
	GetNativeString(1, command, sizeof command);
	return g_Commands.FindString(command) != -1;
}
public int Native_GetPermissions(Handle plugin, int numParams)
{
	char command[COMMAND_LENGTH];
	GetNativeString(1, command, sizeof command);
	CHECK_COMMAND(command);

	Permission p;
	g_PermissionsMap.GetValue(command, p);
	return view_as<int>(p);
}
public int Native_SetPermissions(Handle plugin, int numParams)
{
	char command[COMMAND_LENGTH];
	GetNativeString(1, command, sizeof command);
	CHECK_COMMAND(command);

	Permission p = GetNativeCell(2);
	return g_PermissionsMap.SetValue(command, p);
}
