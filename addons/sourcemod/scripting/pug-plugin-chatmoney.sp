#include <cstrike>
#include <sourcemod>

#include "include/pug-plugin.inc"
#include "pug-plugin/util.sp"

#pragma semicolon 1
#pragma newdecls required

ConVar g_hEnabled;

public Plugin myinfo =
{
	name = "Pug Plugin: write team money to chat",
	author = "Versatile_BFG/jkroepke, heapy",
	description = "Write the team members' money to the chat (like WarMod)",
	version = PLUGIN_VERSION,
	url = "https://github.com/csharmony/pug-plugin",
};
public void OnPluginStart()
{
	LoadTranslations("pug-plugin.phrases");
	g_hEnabled = CreateConVar("sm_pp_chatmoney_enabled", "1", "Whether the plugin is enabled");
	AutoExecConfig(true, "pp_chatmoney", "sourcemod/pug-plugin");
	HookEvent("round_start", Event_Round_Start);
}
public Action Event_Round_Start(Event event, const char[] name, bool dontBroadcast)
{
	if(!PugPlugin_IsMatchLive() || g_hEnabled.IntValue == 0)
		return Plugin_Continue;

	ArrayList players = new ArrayList();

	// sort by money
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsPlayer(i) && OnActiveTeam(i))
		{
			players.Push(i);
		}
	}

	SortADTArrayCustom(players, SortMoneyFunction);

	char player_money[16];
	char has_weapon[4];
	int pri_weapon;

	int numPlayers = players.Length;

	// display team players money
	for(int i = 0; i < numPlayers; i++)
	{
		for(int j = 0; j < numPlayers; j++)
		{
			int displayClient = players.Get(i);
			int moneyClient = players.Get(j);

			if(GetClientTeam(displayClient) == GetClientTeam(moneyClient))
			{
				pri_weapon = GetPlayerWeaponSlot(moneyClient, 0);
				if(pri_weapon == -1)
				{
					has_weapon = ">";
				}
				else
				{
					has_weapon = "\0";
				}
				IntToMoney(GetClientMoney(moneyClient), player_money, sizeof player_money);
				PugPlugin_Message(displayClient, "\x01$%s \x04%s> \x03%N", player_money, has_weapon, moneyClient);
			}
		}
	}

	delete players;
	return Plugin_Continue;
}
public int SortMoneyFunction(int index1, int index2, Handle array, Handle hnd)
{
	int client1 = GetArrayCell(array, index1);
	int client2 = GetArrayCell(array, index2);
	int money1 = GetClientMoney(client1);
	int money2 = GetClientMoney(client2);

	if(money1 > money2)
	{
		return -1;
	}
	else if(money1 == money2)
	{
		return 0;
	}
	else
	{
		return 1;
	}
}
public int GetClientMoney(int client)
{
	int offset = FindSendPropInfo("CCSPlayer", "m_iAccount");
	return GetEntData(client, offset);
}
public void IntToMoney(int OldMoney, char[] NewMoney, int size)
{
	char Temp[32];
	char OldMoneyStr[32];
	char tempChar;
	int RealLen = 0;

	IntToString(OldMoney, OldMoneyStr, sizeof OldMoneyStr);

	for(int i = strlen(OldMoneyStr) - 1; i >= 0; i--)
	{
		if(RealLen % 3 == 0 && RealLen != strlen(OldMoneyStr) && i != strlen(OldMoneyStr) - 1)
		{
			tempChar = OldMoneyStr[i];
			Format(Temp, sizeof Temp, "%s,%s", tempChar, Temp);
		}
		else
		{
			tempChar = OldMoneyStr[i];
			Format(Temp, sizeof Temp, "%s%s", tempChar, Temp);
		}
		RealLen++;
	}
	Format(NewMoney, size, "%s", Temp);
}
