/*
* War3Source Addon - Give Gold
* 
* File: War3Source_Addon_GiveGold.sp
* Description: The Give Gold Addon for War3Source. Allows a player to share his gold with another one.
* Author: M.A.C.A.B.R.A 
* 
* Changelog:
*
* v1.2.2
* - modified messages and translation files
* 
* v1.2.1
* - modified help instructions 
* 
* v1.2.0
* - adjustment messages to translate
* - added translations (en, pl)
* 
* v1.1.1
* - added shortcuts
* - modified messages
* - modified help instructions
* 
* v1.1.0
* - added in-game plugin advertisement
* - added advertisement cvar
* - fixed messages bugs
* 
* v1.0.0
* - initial release
*/

#include <sourcemod>
#include <sdktools>
#include "W3SIncs/War3Source_Interface"

#define PLUGIN_VERSION "1.2.2"

#define SPEC_GREY "\x07CCCCCC" 
#define T_RED "\x07FF4040" 
#define CT_BLUE "\x0799CCFF" 

public Plugin:myinfo = 
{
	name = "War3Source Addon - Give Gold",
	author = "M.A.C.A.B.R.A",
	description = "The Give Gold Addon for War3Source. Allows a player to share his gold with another one.",
	version = PLUGIN_VERSION,
	url = "http://strefagier.com.pl/"
};

new Handle:GiveGoldPluginON = INVALID_HANDLE;
new Handle:GiveGoldAdvertisement = INVALID_HANDLE;
new Handle:GiveGoldMin = INVALID_HANDLE;
new Handle:GiveGoldMax = INVALID_HANDLE;

/* *********************** OnPluginStart *********************** */
public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("war3.givegold.phrases");
	
	CreateConVar("war3_givegold_version", PLUGIN_VERSION, "Give Gold plugin version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	GiveGoldPluginON = CreateConVar("war3_givegold_on", "1", "Enables/Disables Give Gold plugin.", 0, true, 0.0, true, 1.0);
	GiveGoldAdvertisement = CreateConVar("war3_givegold_advertisement", "1", "Enables/Disables Give Gold advertisement on chat.", 0, true, 0.0, true, 1.0);
	GiveGoldMin = CreateConVar("war3_givegold_min", "1", "Minimum amount of gold that player can donate to another one.", 0, true, 1.0, false);
	GiveGoldMax = CreateConVar("war3_givegold_max", "500", "Maximum amount of gold that player can donate to another one.", 0, true, 2.0, false);
	
	RegConsoleCmd("givegold", GiveGold, "Allows you to give a part of your gold to another player.");
	RegConsoleCmd("gg", GiveGold, "Allows you to give a part of your gold to another player.");
	RegConsoleCmd("givegoldhelp", GiveGoldHelp, "Shows Give Gold help instructions.");
	RegConsoleCmd("gghelp", GiveGoldHelp, "Shows Give Gold help instructions.");
	
	CreateTimer(150.0, BroadcastAdvertisement,_,TIMER_REPEAT);
}

/* *********************** BroadcastAdvertisement *********************** */
public Action:BroadcastAdvertisement(Handle:timer, any:userid)
{
	if(GetConVarBool(GiveGoldAdvertisement))
	{
		CPrintToChatAll("{green}[{lightgreen}Give Gold{green}]{default} %t ", "Advertisement1");
		CPrintToChatAll("{green}[{lightgreen}Give Gold{green}]{default} %t ", "Advertisement2");
	}
}

/* *********************** GiveGold *********************** */
public Action:GiveGold(client, args)
{
	if(client == 0)
	{
		return Plugin_Handled;	
	}
	
	if(!GetConVarBool(GiveGoldPluginON))
	{
		CPrintToChat(client, "{green}[{lightgreen}Give Gold{green}]{default} %t ", "Error - Plugin Disabled", T_RED);
		return Plugin_Handled;	
	}
	
	if(args != 2)
	{
		CPrintToChat(client, "{green}[{lightgreen}Give Gold{green}]{default} %t ", "Error - Arguments");
		CPrintToChat(client, "{green}[{lightgreen}Give Gold{green}]{default} %t ", "Help Advertisement");
		return Plugin_Handled;	
	}
	else
	{
		new String:name[64];
		GetCmdArg(1, name, sizeof(name));
		new receiver = FindTarget(client, name, false, false);
		
		if(receiver < 1)
		{
			CPrintToChat(client, "{green}[{lightgreen}Give Gold{green}]{default} %t ", "Error - Player");
			CPrintToChat(client, "{green}[{lightgreen}Give Gold{green}]{default} %t ", "Help Advertisement");
			return Plugin_Handled;
		}
		
		new String:strGold[15];
		GetCmdArg(2, strGold, sizeof(strGold));
		new Gold = StringToInt(strGold);
		
		GiveGoldTransaction(client, receiver, Gold);
	}
	
	return Plugin_Handled;
}

/* *********************** GiveGoldTransaction *********************** */
public Action:GiveGoldTransaction(client, receiver, Gold)
{
	if(client == receiver)
	{
		CPrintToChat(client, "{green}[{lightgreen}Give Gold{green}]{default} %t ", "Error - Self");
		return Plugin_Handled; 
	}
	
	new GiveGoldMinAmount = GetConVarInt(GiveGoldMin);
	new GiveGoldMaxAmount = GetConVarInt(GiveGoldMax);
	
	if(Gold < GiveGoldMinAmount || Gold > GiveGoldMaxAmount)
	{
		CPrintToChat(client, "{green}[{lightgreen}Give Gold{green}]{default} %t ", "Error - Gold");
		CPrintToChat(client, "{green}[{lightgreen}Give Gold{green}]{default} %t ", "Help Advertisement");
		return Plugin_Handled;
	}
	
	new DonatorGold = War3_GetGold(client);
	new ReceiverGold = War3_GetGold(receiver);
	
	if(DonatorGold < Gold)
	{
		CPrintToChat(client, "{green}[{lightgreen}Give Gold{green}]{default} %t ", "Transaction - No Gold");
		return Plugin_Handled;
	}
	
	new DonatorTeam = GetClientTeam(client);
	new ReceiverTeam = GetClientTeam(receiver);
	new MaxGoldAmount = W3GetMaxGold();
	
	new String:DonatorName[32];
	GetClientName(client, DonatorName, sizeof(DonatorName));
	new String:ReceiverName[32];
	GetClientName(receiver, ReceiverName, sizeof(ReceiverName));
	
	if(ReceiverGold + Gold > MaxGoldAmount)
	{
		Gold = MaxGoldAmount-ReceiverGold;
		if(Gold == 0)
		{
			switch(ReceiverTeam)
			{
				case 1: // spec
				{
					CPrintToChat(client, "{green}[{lightgreen}Give Gold{green}]{default} %t ", "Transaction - No Place", SPEC_GREY, ReceiverName);			
				}
				case 2: // t
				{
					CPrintToChat(client, "{green}[{lightgreen}Give Gold{green}]{default} %t ", "Transaction - No Place", T_RED, ReceiverName);
				}
				case 3: // ct
				{
					CPrintToChat(client, "{green}[{lightgreen}Give Gold{green}]{default} %t ", "Transaction - No Place", CT_BLUE, ReceiverName);
				}			
			}
			return Plugin_Handled;
		}
	}
	
	if(DonatorTeam == ReceiverTeam)
	{
		switch(DonatorTeam)
		{
			case 1: // spec
			{
				CPrintToChatAll("{green}[{lightgreen}Give Gold{green}]{default} %t ", "Transaction - Succesfull", SPEC_GREY, DonatorName, SPEC_GREY, ReceiverName, Gold);
			}
			case 2: // t
			{
				CPrintToChatAll("{green}[{lightgreen}Give Gold{green}]{default} %t ", "Transaction - Succesfull", T_RED, DonatorName, T_RED, ReceiverName, Gold);
			}
			case 3: // ct
			{
				CPrintToChatAll("{green}[{lightgreen}Give Gold{green}]{default} %t ", "Transaction - Succesfull", CT_BLUE, DonatorName, CT_BLUE, ReceiverName, Gold);
			}			
		}		
	}
	else
	{
		switch(DonatorTeam)
		{
			case 1: // spec
			{
				switch(ReceiverTeam)
				{
					case 2: // t
					{
						CPrintToChatAll("{green}[{lightgreen}Give Gold{green}]{default} %t ", "Transaction - Succesfull", SPEC_GREY, DonatorName, T_RED, ReceiverName, Gold);
					}
					case 3: // ct
					{
						CPrintToChatAll("{green}[{lightgreen}Give Gold{green}]{default} %t ", "Transaction - Succesfull", SPEC_GREY, DonatorName, CT_BLUE, ReceiverName, Gold);
					}			
				}
			}
			case 2: // t
			{
				switch(ReceiverTeam)
				{
					case 1: // spec
					{
						CPrintToChatAll("{green}[{lightgreen}Give Gold{green}]{default} %t ", "Transaction - Succesfull", T_RED, DonatorName, SPEC_GREY, ReceiverName, Gold);
					}
					case 3: // ct
					{
						CPrintToChatAll("{green}[{lightgreen}Give Gold{green}]{default} %t ", "Transaction - Succesfull", T_RED, DonatorName, CT_BLUE, ReceiverName, Gold);
					}			
				}
			}
			case 3: // ct
			{
				switch(ReceiverTeam)
				{
					case 1: // spec
					{
						CPrintToChatAll("{green}[{lightgreen}Give Gold{green}]{default} %t ", "Transaction - Succesfull", CT_BLUE, DonatorName, SPEC_GREY, ReceiverName, Gold);
					}
					case 2: // t
					{
						CPrintToChatAll("{green}[{lightgreen}Give Gold{green}]{default} %t ", "Transaction - Succesfull", CT_BLUE, DonatorName, T_RED, ReceiverName, Gold);
					}			
				}
				
			}			
		}		
	}
	
	War3_SetGold(client,DonatorGold - Gold);
	War3_SetGold(receiver,ReceiverGold + Gold);
	return Plugin_Handled;
}

/* *********************** GiveGoldHelp *********************** */
public Action:GiveGoldHelp(client, args)
{
	if(client == 0)
	{
		return Plugin_Handled;	
	}
	else
	{
		GiveGoldHelpMainMenu(client);
	}
	return Plugin_Handled;
}

/* *********************** GiveGoldHelpMainMenu *********************** */
GiveGoldHelpMainMenu(client)
{
	new String:HelpMainCommandsTxt[512];
	Format(HelpMainCommandsTxt,sizeof(HelpMainCommandsTxt),"%T", "Help - Main Commands",client);
	new String:HelpMainShortCutsTxt[128];
	Format(HelpMainShortCutsTxt,sizeof(HelpMainShortCutsTxt),"%T", "Help - Main Shortcuts",client);
	new String:HelpMainCreditsTxt[256];
	Format(HelpMainCreditsTxt,sizeof(HelpMainCreditsTxt),"%T", "Help - Main Credits",client);
	new String:HelpMainSendTxt[128];
	Format(HelpMainSendTxt,sizeof(HelpMainSendTxt),"%T", "Help - Main Send To Console",client);
	
	new Handle:HelpMainMenu = CreateMenu(HelpMainMenuSelect);
	SetMenuTitle(HelpMainMenu, "%T", "Help  - Main Menu Title",client);
	AddMenuItem(HelpMainMenu, "commands", HelpMainCommandsTxt);
	AddMenuItem(HelpMainMenu, "shortcuts", HelpMainShortCutsTxt);
	AddMenuItem(HelpMainMenu, "credits", HelpMainCreditsTxt);
	AddMenuItem(HelpMainMenu, "sendtoconsole", HelpMainSendTxt);
	SetMenuExitButton(HelpMainMenu, true);
	DisplayMenu(HelpMainMenu, client, MENU_TIME_FOREVER);	
}

/* *********************** HelpMainMenuSelect *********************** */
public HelpMainMenuSelect(Handle:HelpMainMenu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
    {
		new GiveGoldMinAmount = GetConVarInt(GiveGoldMin);
		new GiveGoldMaxAmount = GetConVarInt(GiveGoldMax);
		new ExampleAmount = GetRandomInt(GiveGoldMinAmount, GiveGoldMaxAmount);
		new String:Name[32];
		GetClientName(client, Name, sizeof(Name));
		new String:HelpBackToMain[32];
		Format(HelpBackToMain,sizeof(HelpBackToMain),"%T", "Help - Back To Main",client);
		
		new String:info[32];
		GetMenuItem(HelpMainMenu, param2, info, sizeof(info));
		if(StrEqual(info,"commands"))
        {
			new Handle:HelpMenuCommands = CreateMenu(HelpMenuOptionSelect);
			SetMenuTitle(HelpMenuCommands, "%T", "Help - Commands Menu Title",client, GiveGoldMinAmount, GiveGoldMaxAmount, Name, ExampleAmount);
			AddMenuItem(HelpMenuCommands, "backtomainhelp", HelpBackToMain);
			SetMenuExitButton(HelpMenuCommands, true);
			DisplayMenu(HelpMenuCommands, client, MENU_TIME_FOREVER);	
        }
		else if(StrEqual(info,"shortcuts"))
        {
			new Handle:HelpMenuShortcuts = CreateMenu(HelpMenuOptionSelect);
			SetMenuTitle(HelpMenuShortcuts, "%T", "Help - Shortcuts Menu Title",client);
			AddMenuItem(HelpMenuShortcuts, "backtomainhelp", HelpBackToMain);
			SetMenuExitButton(HelpMenuShortcuts, true);
			DisplayMenu(HelpMenuShortcuts, client, MENU_TIME_FOREVER);
        }
		else if(StrEqual(info,"credits"))
        {
			new Handle:HelpMenuCredits = CreateMenu(HelpMenuOptionSelect);
			SetMenuTitle(HelpMenuCredits, "%T", "Help - Credits Menu Title",client, PLUGIN_VERSION);
			AddMenuItem(HelpMenuCredits, "backtomainhelp", HelpBackToMain);
			SetMenuExitButton(HelpMenuCredits, true);
			DisplayMenu(HelpMenuCredits, client, MENU_TIME_FOREVER);
        }
		else if(StrEqual(info,"sendtoconsole"))
        {
			PrintToConsole(client, "%T", "Help Console Text", client, GiveGoldMinAmount, GiveGoldMaxAmount, Name, ExampleAmount, PLUGIN_VERSION);
			
			new Handle:HelpMenuSend = CreateMenu(HelpMenuOptionSelect);
			SetMenuTitle(HelpMenuSend, "%T", "Help - Send Menu Title",client);
			AddMenuItem(HelpMenuSend, "backtomainhelp", HelpBackToMain);
			SetMenuExitButton(HelpMenuSend, true);
			DisplayMenu(HelpMenuSend, client, MENU_TIME_FOREVER);
        }
	}
	else if(action == MenuAction_End)
	{
        CloseHandle(HelpMainMenu);
    }
}

/* *********************** HelpMenuOptionSelect *********************** */
public HelpMenuOptionSelect(Handle:menu, MenuAction:action, client, param2)
{
	if(action==MenuAction_Select)
	{
		GiveGoldHelpMainMenu(client);
	}
	if(action==MenuAction_End)
	{
		CloseHandle(menu);
	}	
}