/**
* goldbets.sp
* Adds team betting. After dying, a player can bet on which team will win. 
*/
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "Team Bets(Gold)",
	author = "GrimReaper - Original by ferret - heavily altered by Necavi, With Teh Suq/ShadowCouncil Fixing ",
	description = "Bet on Team to Win",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=85914"
};

#define BET_AMOUNT 0
#define BET_WIN 1
#define BET_TEAM 2

new g_bEnabled = false;

new g_iPlayerBetData[MAXPLAYERS + 1][3];
new bool:g_bPlayerBet[MAXPLAYERS + 1] = {false, ...};

new g_iTotalPot = 0;
new g_iBetTeam2;
new g_iBetTeam3;

new Handle:g_hSmBet = INVALID_HANDLE;
new Handle:g_hMaximumBet = INVALID_HANDLE;
new Handle:g_hMinimumBet = INVALID_HANDLE;
new Handle:g_hBetRatio = INVALID_HANDLE;

public OnPluginStart()
{
	LoadTranslations("w3s.addon.goldbets.phrases");	
	
	CreateConVar("sm_goldbets_version", PLUGIN_VERSION, "GoldBets Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_hSmBet = CreateConVar("sm_goldbet_enable","1","Enables or disables the goldbet War3Source plugin",_,true,0.0,true,1.0);
	g_hMaximumBet = CreateConVar("sm_goldbets_maximum","50","Maximum bet value");
	g_hMinimumBet = CreateConVar("sm_goldbets_minimum","2","Minimum bet value");
	g_hBetRatio = CreateConVar("sm_goldbets_betratio","2","Defines the amount you can win per gold you bet");
	HookConVarChange(g_hSmBet, ConVarChange_SmBet);
	
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);	
	
	g_bEnabled = true;
	
	CreateTimer(5.0, Timer_DelayedHooks);
	
	AutoExecConfig(true, "teambets");
	
	CreateTimer(60.0,Timer_Advertise,_,TIMER_REPEAT);
}

public ConVarChange_SmBet(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_bEnabled = StringToInt(newValue);
}

public Action:Timer_DelayedHooks(Handle:timer)
{
	if (g_bEnabled)
	{
		if(War3_GetGame()==Game_TF)
		{
			HookEvent("teamplay_round_win", Event_RoundEnd,EventHookMode_Post);
		}
		else
		{
			HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
		}
		
		PrintToServer("[GoldBets] - Loaded");
	}
}



public Action:Command_Say(client, args)
{
	if (!g_bEnabled)
		return Plugin_Continue;
	
	
	new String:szText[192];
	GetCmdArgString(szText, sizeof(szText));
	
	new startarg = 0;
	if (szText[0] == '"')
	{
		startarg = 1;
		/* Strip the ending quote, if there is one */
		new szTextlen = strlen(szText);
		if (szText[szTextlen-1] == '"')
		{
			szText[szTextlen-1] = '\0';
		}
	}
	
	new String:szParts[3][16];
	ExplodeString(szText[startarg], " ", szParts, 3, 16);
	if(g_bPlayerBet[client])
	{
		if (strcmp(szParts[0],"bet",false) == 0)
		{
			PrintToChat(client, "\x04[Goldbets]\x01 %t", "Already_Bet");
			return Plugin_Handled;
		}
	}
	if (strcmp(szParts[0],"bet",false) == 0)
	{
		
		if (GetClientTeam(client) <= 1)
		{
			PrintToChat(client, "\x04[GoldBets]\x01 %t", "Must_Be_On_A_Team_To_Vote");
			return Plugin_Handled;
		}
		
		if (ValidPlayer(client,true))
		{
			PrintToChat(client, "\x04[GoldBets]\x01 %t", "Must_Be_Dead_To_Vote");
			return Plugin_Handled;
		}
		
		if (strcmp(szParts[1],"ct",false) != 0 && strcmp(szParts[1],"t", false) != 0 && strcmp(szParts[1],"blu",false) != 0 && strcmp(szParts[1],"red", false))
		{
			if(War3_GetGame()==Game_CS){
				PrintToChat(client, "\x04[GoldBets]\x01 %t", "Invalid_Team_for_Bet_CSS");
			}
			else if(War3_GetGame()==Game_TF){
				PrintToChat(client, "\x04[GoldBets]\x01 %t", "Invalid_Team_for_Bet_TF2");
			}
			return Plugin_Handled;
		}
		
		if (strcmp(szParts[1],"ct",false) == 0 || strcmp(szParts[1],"t", false) == 0 || strcmp(szParts[1],"blu",false) != 0 || strcmp(szParts[1],"red", false))
		{
			
			new iAmount = 0;
			new iBank = GetMoney(client);
			
			if (IsCharNumeric(szParts[2][0]))
			{
				iAmount = StringToInt(szParts[2]);
			}
			else if (strcmp(szParts[2],"all",false) == 0)
			{
				iAmount = iBank;
			}
			else if (strcmp(szParts[2],"half", false) == 0)
			{
				iAmount = (iBank / 2) + 1;
			}
			else if (strcmp(szParts[2],"third", false) == 0)
			{
				iAmount = (iBank / 3) + 1;
			}
			
			new iMaxBet = 50;
			
			if(iAmount > iMaxBet)
			{
				iAmount = iMaxBet;
				PrintToChat(client, "\x04[GoldBets]\x01 %t","Above_Max_Bet",iMaxBet);
			}
			
			new iMinBet = 2;
			
			if(iAmount < iMinBet)
			{
				PrintToChat(client, "\x04[GoldBets]\x01 %t","Below_Min_Bet",iMinBet);
				return Plugin_Handled;
			}
			
			if (iAmount < 1)
			{
				PrintToChat(client, "\x04[GoldBets]\x01 %t", "Invalid_Bet_Amount");
				return Plugin_Handled;
			}		
			
			if (iAmount > iBank || iBank < 1)
			{
				PrintToChat(client, "\x04[GoldBets]\x01 %t", "Not_Enough_Gold");
				return Plugin_Handled;
			}
			
			
			
			
			g_iPlayerBetData[client][BET_AMOUNT] = iAmount;
			g_iTotalPot += iAmount;
			new team;
			if(strcmp(szParts[1],"t",false) == 0 || strcmp(szParts[1],"red",false) == 0){
				team = 2;				
			} 
			else {
				team = 3;
			}
			g_iPlayerBetData[client][BET_TEAM] = team;
			
			if (g_iPlayerBetData[client][BET_TEAM] == 2) // 2 = t, 3 = ct
			{
				g_iBetTeam2 += iAmount;
			}
			else
			{
				g_iBetTeam3 += iAmount;
			}
			PrintToChat(client,"\x04[GoldBets]\x01 %t","Bet_Made",g_iTotalPot);
			
			g_bPlayerBet[client] = true;
			
			SetMoney(client, iBank - iAmount);
			
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public OnClientConnected(client)
{
	if (g_bEnabled)
		return true;	
	
	g_iPlayerBetData[client][BET_AMOUNT] = 0;
	g_iPlayerBetData[client][BET_TEAM] = 0;
	g_iPlayerBetData[client][BET_WIN] = 0;
	g_bPlayerBet[client] = false;
	
	return true;	
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bEnabled)
		return;		
	new iCount = 0;
	new iCountPot = 0;
	new iMaxClients = GetMaxClients();
	new iWinner;
    new PercentageAsInt = 0;
	new CurrentPlayerBet = 0;
	new AmountWon = 0;
	if(War3_GetGame()==Game_TF)
	{
		iWinner=GetEventInt(event,"team");
	}
	else
	{
		iWinner=GetEventInt(event,"winner");
	}
	
	new WinAmount;
	if(iWinner == 2)
	{
		WinAmount = g_iBetTeam2;
	} else {
		WinAmount = g_iBetTeam3;
	}
	for (new i = 1; i <= iMaxClients; i++)
	{
		if (IsClientInGame(i) && g_bPlayerBet[i])
		{
			CurrentPlayerBet = g_iPlayerBetData[i][BET_AMOUNT];
			AmountWon = RoundToFloor(float(g_iTotalPot) * (float(g_iPlayerBetData[i][BET_AMOUNT]) / float(WinAmount)));

			if (iWinner == g_iPlayerBetData[i][BET_TEAM])
			{
				//Please ignore.
				if(CurrentPlayerBet < 5)
				{
					PercentageAsInt = 1;
				}	
				if(CurrentPlayerBet >= 5 && CurrentPlayerBet < 12)
				{
					PercentageAsInt = 2;
				}
				if(CurrentPlayerBet >= 12 && CurrentPlayerBet < 20)
				{
					PercentageAsInt = 3;
				}
				if(CurrentPlayerBet >= 20 && CurrentPlayerBet < 28)
				{
					PercentageAsInt = 4;
				}
				if(CurrentPlayerBet >= 28 && CurrentPlayerBet < 36)
				{
					PercentageAsInt = 5;
				}
				if(CurrentPlayerBet >= 37 && CurrentPlayerBet < 40)
				{
					PercentageAsInt = 6;
				}
					if(CurrentPlayerBet >= 40 && CurrentPlayerBet < 45)
				{
					PercentageAsInt = 7;
				}
				if(CurrentPlayerBet >= 45)
				{
					PercentageAsInt = 8;
				}	
				if(CurrentPlayerBet >= 50)
				{
					PercentageAsInt = 10;
				}		
				new MinimumReturn = CurrentPlayerBet + PercentageAsInt;
				new Payout = AmountWon;
				if (Payout < MinimumReturn)
				{
						Payout = MinimumReturn;
						
				}
				new BetRatio = 2;
				if(Payout > (BetRatio * CurrentPlayerBet))
				{
					Payout = BetRatio * CurrentPlayerBet;
				}
				if (Payout < CurrentPlayerBet)
				{
						Payout = CurrentPlayerBet;
				}
				g_iTotalPot -= AmountWon;
				SetMoney(i,GetMoney(i) + Payout);
				PrintToChat(i, "\x04[GoldBets]\x01 %t", "Bet_Won", Payout, CurrentPlayerBet ,g_iTotalPot);
			}
			else
			{
				PrintToChat(i, "\x04[GoldBets]\x01 %t", "Bet_Lost",CurrentPlayerBet);
			}

		}
		if (IsClientInGame(i))
		{
			iCount++;
		}
		g_bPlayerBet[i] = false;		
	}
	if(iCount < 32)
	{
		iCount = 32;
	}
	if(iCount >= 2 && iCount < 5)
	{
		iCountPot = 5;
	}
	if(iCount >= 5 && iCount < 10)
	{
		iCountPot = 7;
	}	
	if(iCount >= 10 && iCount < 15)
	{
		iCountPot = 12;
	}
	if(iCount >= 15 && iCount < 20)
	{
		iCountPot = 14;
	} 
	if(iCount >= 20 && iCount < 25)
	{
		iCountPot = 20;
	}
	if(iCount >= 25 && iCount < 30)
	{
		iCountPot = 25;
	}
	if(iCount >= 30 && iCount < 33)
	{
		iCountPot = 30;
	}
	g_iBetTeam2 = 0;
	g_iBetTeam3 = 0;
	if(g_iTotalPot < 0)
	{
		g_iTotalPot = 0;
	}
	g_iTotalPot =  g_iTotalPot + iCountPot;
}

public Action:Timer_Advertise(Handle:timer, any:data)
{
	if(!g_bEnabled)
		return;
	for(new i = 1;i <MAXPLAYERS+1;i++)
	{
		if (ValidPlayer(i))
		{
			PrintToChat(i, "\x04[GoldBets]\x01 %t", "Advertise_Bets", g_iTotalPot);
		}
	}
}

public SetMoney(client, amount)
{
	War3_SetGold(client,amount);
}

public GetMoney(client)
{
	return War3_GetGold(client);
}