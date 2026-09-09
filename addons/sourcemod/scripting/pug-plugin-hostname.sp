#include <cstrike>
#include <sourcemod>

#include "include/pug-plugin.inc"
#include "pug-plugin/util.sp"

#pragma semicolon 1
#pragma newdecls required

#define MAX_HOST_LENGTH 256

ConVar g_hEnabled;
ConVar g_HostnameCvar;

bool g_GotHostName = false;	// keep track of it, so we only fetch it once
char g_HostName[MAX_HOST_LENGTH];	// stores the original hostname

// clang-format off
public Plugin myinfo =
{
	name = "Pug Plugin: hostname setter",
	author = "splewis, heapy",
	description = "Tweaks the server hostname according to the pug status",
	version = PLUGIN_VERSION,
	url = "https://github.com/csharmony/pug-plugin",
};
// clang-format on

public void OnPluginStart()
{
	LoadTranslations("pug-plugin.phrases");
	g_hEnabled = CreateConVar("sm_pp_hostname_enabled", "1", "Whether the plugin is enabled");
	AutoExecConfig(true, "pp_hostname", "sourcemod/pug-plugin");
	g_HostnameCvar = FindConVar("hostname");
	g_GotHostName = false;

	if(g_HostnameCvar == INVALID_HANDLE)
		SetFailState("Failed to find cvar \"hostname\"");

	HookEvent("round_start", Event_RoundStart);
}
public void OnConfigsExecuted()
{
	if(!g_GotHostName)
	{
		g_HostnameCvar.GetString(g_HostName, sizeof g_HostName);
		g_GotHostName = true;
	}
}
public void PugPlugin_OnReadyToStartCheck(int readyPlayers, int totalPlayers)
{
	if(g_hEnabled.IntValue == 0)
		return ;

	char hostname[MAX_HOST_LENGTH];
	int need = PugPlugin_GetPugMaxPlayers() - totalPlayers;

	if(need >= 1)
	{
		Format(hostname, sizeof hostname, "%s [NEED %d]", g_HostName, need);
	}
	else
	{
		Format(hostname, sizeof hostname, "%s", g_HostName);
	}

	g_HostnameCvar.SetString(hostname);
}
public void PugPlugin_OnGoingLive()
{
	if(g_hEnabled.IntValue == 0)
		return ;

	char hostname[MAX_HOST_LENGTH];
	Format(hostname, sizeof hostname, "%s [LIVE]", g_HostName);
	g_HostnameCvar.SetString(hostname);
}
public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if(g_hEnabled.IntValue == 0 || !PugPlugin_IsMatchLive())
		return Plugin_Continue;

	char hostname[MAX_HOST_LENGTH];
	Format(hostname, sizeof hostname, "%s [LIVE %d-%d]", g_HostName, CS_GetTeamScore(CS_TEAM_CT), CS_GetTeamScore(CS_TEAM_T));
	g_HostnameCvar.SetString(hostname);

	return Plugin_Continue;
}
public void PugPlugin_OnMatchOver()
{
	if(GetConVarInt(g_hEnabled) == 0)
		return ;

	g_HostnameCvar.SetString(g_HostName);
}
