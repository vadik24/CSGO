/**
* File: War3Source_Pistoleer.sp
* Description: The Pistoleer race for War3Source.
* Author(s): Invalid & Frenzzy
*/

#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <cstrike>

#define CS_SLOT_KNIFE 2 // Melee weapon slot

new thisRaceID;
new SKILL_GUNS, SKILL_SPEED, SKILL_CRITICAL, SKILL_BOUNTY, SKILL_CHWEAPON;

// Globals
new Handle:g_hTriehandle = INVALID_HANDLE;
new bool:g_bAutoRepick[MAXPLAYERS];

// Skill Data Arrays
new Float:g_fRushSpeed[7] = {1.00, 1.05, 1.10, 1.15, 1.20, 1.25, 1.30};
new Float:g_fCritChance[7] = {0.0, 0.03, 0.06, 0.09, 0.12, 0.15, 0.20};
new Float:g_fBountyChance[7] = {0.0, 0.03, 0.06, 0.09, 0.12, 0.15, 0.20};
new g_iBountyMoney[7] = {0, 50, 100, 200, 400, 800, 1600};
new g_iBountyGold[7] = {0, 1, 1, 1, 2, 2, 2};

// Convars
new Handle:cvUltCooldown = INVALID_HANDLE;
new Handle:cvBountyMoney = INVALID_HANDLE;

public Plugin:myinfo = {
	name = "War3Source Race - Pistoleer",
	author = "Invalid & Frenzzy",
	description = "The Pistoleer race for War3Source.",
	version = "1.1",
	url = "http://www.war3source.com"
};

public OnMapStart()
{
	if (g_hTriehandle != INVALID_HANDLE)
		ClearTrie(g_hTriehandle);
}

public OnPluginStart()
{
	LoadTranslations("w3s.race.pistoleer.phrases");
	cvUltCooldown = CreateConVar("war3_pistoleer_ult_cooldown", "5.0", "Cooldown for Exclusive Suppliers");
	cvBountyMoney = CreateConVar("war3_pistoleer_bounty_money", "1", "What will be gain a player for killing enemy. 0 - Gold, 1 - CS Money", _, true, 0.0, true, 1.0);
	g_hTriehandle = CreateTrie();
}

public OnWar3PluginReady()
{
	thisRaceID     = War3_CreateNewRaceT("pistoleer");
	SKILL_GUNS     = War3_AddRaceSkillT(thisRaceID, "GunCollector", false, 5);
	SKILL_SPEED    = War3_AddRaceSkillT(thisRaceID, "RushOfBattle", false, 6);
	SKILL_CRITICAL = War3_AddRaceSkillT(thisRaceID, "LuckyShot", false, 6);
	SKILL_BOUNTY   = War3_AddRaceSkillT(thisRaceID, "BountyHunter", false, 6);
	SKILL_CHWEAPON = War3_AddRaceSkillT(thisRaceID, "ExclusiveSuppliers", true, 1); 
	W3SkillCooldownOnSpawn(thisRaceID, SKILL_CHWEAPON, 7.0, false);
	War3_CreateRaceEnd(thisRaceID);
}

public OnRaceChanged(client,oldrace,newrace)
{
	if (newrace!=thisRaceID)
	{
		War3_WeaponRestrictTo(client, thisRaceID, "");
		W3ResetAllBuffRace(client,thisRaceID);
		
		decl String:sClient[16];
		IntToString(client, sClient, sizeof(sClient));
		SetTrieString(g_hTriehandle, sClient, "0");
		g_bAutoRepick[client] = false;
	}
	else
	{
		if (IsPlayerAlive(client))
		{
			InitPassiveSkills(client);
			War3_WeaponRestrictTo(client, thisRaceID, "weapon_knife,weapon_flashbang,weapon_hegrenade,weapon_smokegrenade", 1);
			
			new iWeapon;
			iWeapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
			if (iWeapon != -1)
				RemovePlayerItem(client, iWeapon);
			iWeapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
			if (iWeapon != -1)
				RemovePlayerItem(client, iWeapon);
			iWeapon = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
			if (iWeapon == -1)
				GivePlayerItem(client, "weapon_knife");
			FakeClientCommand(client, "use weapon_knife");
			
			if (!g_bAutoRepick[client])
				DoPistolMenu(client);
			else
				if (!DoAutoChoice(client))
					DoPistolMenu(client);
		}
	}
}

public OnWar3EventSpawn(client)
{
	if (War3_GetRace(client) == thisRaceID)
	{
		InitPassiveSkills(client);
		War3_WeaponRestrictTo(client, thisRaceID, "weapon_knife,weapon_flashbang,weapon_hegrenade,weapon_smokegrenade", 1);
		
		new iWeapon;
		iWeapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
		if (iWeapon != -1)
			RemovePlayerItem(client, iWeapon);
		iWeapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
		if (iWeapon != -1)
			RemovePlayerItem(client, iWeapon);
		iWeapon = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
		if (iWeapon == -1)
			GivePlayerItem(client, "weapon_knife");
		FakeClientCommand(client, "use weapon_knife");
		
		if (!g_bAutoRepick[client])
				CreateTimer(0.5, PistolMenuTimer, client);
			else
				if (!DoAutoChoice(client))
					CreateTimer(0.5, PistolMenuTimer, client);
	}
}

public Action:PistolMenuTimer(Handle:plugin, any:client)
{
	if (ValidPlayer(client, true))
	{
		DoPistolMenu(client);
	}
}

// Opens pistol menu
public DoPistolMenu(client)
{
	new Handle:hPistolMenu = CreateMenu(War3Source_PistolMenu_Selected);
	new iGunLevel = War3_GetSkillLevel(client, thisRaceID, SKILL_GUNS);
	decl String:sPistolMenu[128], String:sGlock[128], String:sUSP[128], String:sP228[128], String:sFiveseven[128], String:sDeagle[128], String:sElite[128], String:sAutoRepick[128];
	
	Format(sPistolMenu, sizeof(sPistolMenu), "%T", "Pistol Menu", client);
	Format(sGlock, sizeof(sGlock), "%T", "Glock", client);
	Format(sUSP, sizeof(sUSP), "%T", "Usp", client);
	Format(sP228, sizeof(sP228), "%T", "P228", client);
	Format(sFiveseven, sizeof(sFiveseven), "%T", "Fiveseven", client);
	Format(sDeagle, sizeof(sDeagle), "%T", "Deagle", client);
	Format(sElite, sizeof(sElite), "%T", "Duel Elites", client);
	Format(sAutoRepick, sizeof(sAutoRepick), "%T", "Save Choice", client);
	
	SetMenuExitButton(hPistolMenu, false);
	SetMenuPagination(hPistolMenu, MENU_NO_PAGINATION);
	
	SetMenuTitle(hPistolMenu, sPistolMenu);
	AddMenuItem(hPistolMenu, "weapon_glock", sGlock);
	AddMenuItem(hPistolMenu, "weapon_tec9", sUSP, (iGunLevel > 0)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	AddMenuItem(hPistolMenu, "weapon_p250", sP228, (iGunLevel > 1)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	AddMenuItem(hPistolMenu, "weapon_fiveseven", sFiveseven, (iGunLevel > 2)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	AddMenuItem(hPistolMenu, "weapon_deagle", sDeagle, (iGunLevel > 3)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	AddMenuItem(hPistolMenu, "weapon_elite", sElite, (iGunLevel > 4)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	AddMenuItem(hPistolMenu, "nothing", "", ITEMDRAW_NOTEXT);
	AddMenuItem(hPistolMenu, "nothing", " ", ITEMDRAW_SPACER);
	AddMenuItem(hPistolMenu, "autorepick", sAutoRepick, (g_bAutoRepick[client])?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	DisplayMenu(hPistolMenu, client, MENU_TIME_FOREVER);
}

// Pistol menu functionality
public War3Source_PistolMenu_Selected(Handle:menu, MenuAction:action, client, selection)
{
	if (action == MenuAction_Select)
	{
		if (War3_GetRace(client) == thisRaceID && ValidPlayer(client, true))
		{
			decl String:sNewRestrict[256];
			decl String:sWeaponName[32];
			decl String:sSelectionDispText[256];
			new iSelectionStyle;
			
			GetMenuItem(menu, selection, sWeaponName, sizeof(sWeaponName), iSelectionStyle, sSelectionDispText, sizeof(sSelectionDispText));
			
			if (StrEqual(sWeaponName, "autorepick", true))
			{
				g_bAutoRepick[client] = true;
				DoPistolMenu(client);
				PrintHintText(client, "%T", "Pistol auto choice is now enabled", client);
			}
			else
			{
				Format(sNewRestrict, sizeof(sNewRestrict), "weapon_knife,weapon_flashbang,weapon_hegrenade,weapon_smokegrenade,%s", sWeaponName);
				War3_WeaponRestrictTo(client, thisRaceID, sNewRestrict, 2);
				
				new iWeapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
				if (iWeapon != -1)
					RemovePlayerItem(client, iWeapon);
				
				new iWeaponEquip = GivePlayerItem(client, sWeaponName);
				if ((iWeaponEquip != -1) && IsValidEntity(iWeaponEquip))
					FakeClientCommand(client, "use %s", sWeaponName);
				else
					FakeClientCommand(client, "use weapon_knife");
				
				decl String:sClient[16];
				IntToString(client, sClient, sizeof(sClient));
				SetTrieString(g_hTriehandle, sClient, sWeaponName);
			}
		}
	}
	if (action == MenuAction_Cancel)
	{
		if (War3_GetRace(client) == thisRaceID && ValidPlayer(client, true))
		{
			War3_WeaponRestrictTo(client, thisRaceID, "weapon_knife,weapon_flashbang,weapon_hegrenade,weapon_smokegrenade,weapon_glock", 2);
			
			new iWeapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
			if (iWeapon != -1)
				RemovePlayerItem(client, iWeapon);
			
			new iWeaponEquip = GivePlayerItem(client, "weapon_glock");
			if ((iWeaponEquip != -1) && IsValidEntity(iWeaponEquip))
				FakeClientCommand(client, "use weapon_glock");
			else
				FakeClientCommand(client, "use weapon_knife");
		}
	}
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

// Do bounty collection on player death
public OnWar3EventDeath(victim, attacker)
{
	if (ValidPlayer(victim) && ValidPlayer(attacker, true) && GetClientTeam(victim) != GetClientTeam(attacker))
	{
		if (War3_GetRace(attacker) == thisRaceID && !Hexed(attacker))
		{
			new iSkillLevel = War3_GetSkillLevel(attacker, thisRaceID, SKILL_BOUNTY);
			if (iSkillLevel)
			{
				if (GetConVarBool(cvBountyMoney))
				{
					new iMoney = GetCSMoney(attacker);
					iMoney += g_iBountyMoney[iSkillLevel];
					SetCSMoney(attacker, iMoney);
					W3FlashScreen(attacker, RGBA_COLOR_GREEN);
					War3_ChatMessage(attacker, "%T", "Collected a ${amount} bounty", attacker, g_iBountyMoney[iSkillLevel]);
				}
				else
				{
					if (GetRandomFloat(0.0, 1.0) <= g_fBountyChance[iSkillLevel])
					{
						new iGold = War3_GetGold(attacker);
						iGold += g_iBountyGold[iSkillLevel];
						War3_SetGold(attacker,iGold);
						W3FlashScreen(attacker, RGBA_COLOR_GREEN);
						War3_ChatMessage(attacker, "%T", "Collected a {amount} gold bounty", attacker, g_iBountyGold[iSkillLevel]);
					}
				}
			}
		}
	}
}

// Do critical hit calculation for lucky shot
public OnW3TakeDmgBullet(victim, attacker, Float:damage)
{
	if (ValidPlayer(victim, true) && ValidPlayer(attacker, true) && GetClientTeam(victim) != GetClientTeam(attacker))
	{
		new iSkillLevel = War3_GetSkillLevel(attacker, thisRaceID, SKILL_CRITICAL);
		if (War3_GetRace(attacker) == thisRaceID && iSkillLevel > 0 && !Hexed(attacker, false) && !W3HasImmunity(victim, Immunity_Skills))
		{
			// Will not factor in skill immunity
			if (GetRandomFloat(0.0, 1.0) <= g_fCritChance[iSkillLevel])
			{
				if (War3_DealDamage(victim, 30, attacker, DMG_BULLET, "luckyshot", W3DMGORIGIN_SKILL, W3DMGTYPE_PHYSICAL))
				{
					W3PrintSkillDmgHintConsole(victim, attacker, 30, SKILL_CRITICAL);
					W3FlashScreen(victim, RGBA_COLOR_RED);
				}
			}
		}
	}
}

public OnSkillLevelChanged(client, race, skill, newskilllevel)
{
	if (race == thisRaceID)
	{
		InitPassiveSkills(client);
	}
}

public InitPassiveSkills(client)
{
	new iSkillLevel = War3_GetSkillLevel(client, thisRaceID, SKILL_SPEED);
	new Float:fSpeed = g_fRushSpeed[iSkillLevel];
	War3_SetBuff(client, fMaxSpeed, thisRaceID, fSpeed);
}

public OnUltimateCommand(client, race, bool:pressed)
{
	if (race == thisRaceID && pressed && IsPlayerAlive(client))
	{
		new iSkillLevel = War3_GetSkillLevel(client, race, SKILL_CHWEAPON);
		if (iSkillLevel)
		{
			if (War3_SkillNotInCooldown(client, thisRaceID, SKILL_CHWEAPON, true))
			{
				if (!g_bAutoRepick[client])
					DoPistolMenu(client);
				else
					if (!DoAutoChoice(client))
						DoPistolMenu(client);
				new Float:fCoolDown = GetConVarFloat(cvUltCooldown);
				War3_CooldownMGR(client, fCoolDown, thisRaceID, SKILL_CHWEAPON, _, false);
			}
		}
		else
		{
			W3MsgUltNotLeveled(client);
		}
	}
}

public OnAbilityCommand(client, ability, bool:pressed)
{
	if (War3_GetRace(client) == thisRaceID && ability == 0 && pressed)
	{
		if (g_bAutoRepick[client])
		{
			g_bAutoRepick[client] = false;
			PrintHintText(client, "%T", "Pistol auto choice is now disabled", client);
		}
	}
}

public OnClientPutInServer(client)
{
	decl String:sClient[16];
	IntToString(client, sClient, sizeof(sClient));
	SetTrieString(g_hTriehandle, sClient, "0");
	g_bAutoRepick[client] = false;
}

public OnClientDisconnect(client)
{
	decl String:sClient[16];
	IntToString(client, sClient, sizeof(sClient));
	SetTrieString(g_hTriehandle, sClient, "0");
	g_bAutoRepick[client] = false;
}

stock bool:DoAutoChoice(client)
{
	decl String:sTempWeaponName[32];
	decl String:sClient[16];
	IntToString(client, sClient, sizeof(sClient));
	if (GetTrieString(g_hTriehandle, sClient, sTempWeaponName, sizeof(sTempWeaponName)))
	{
		if (strlen(sTempWeaponName) < 5)
			return false;
		else
		{
			if (!CanUseWeapon(client, sTempWeaponName))
				return false;
			decl String:sNewRestrict[256];
			Format(sNewRestrict, sizeof(sNewRestrict), "weapon_knife,weapon_flashbang,weapon_hegrenade,weapon_smokegrenade,%s", sTempWeaponName);
			War3_WeaponRestrictTo(client, thisRaceID, sNewRestrict, 2);
			
			new iWeapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
			if (iWeapon != -1)
				RemovePlayerItem(client, iWeapon);
			
			new iWeaponEquip = GivePlayerItem(client, sTempWeaponName);
			if ((iWeaponEquip != -1) && IsValidEntity(iWeaponEquip))
				FakeClientCommand(client, "use %s", sTempWeaponName);
			else
				FakeClientCommand(client, "use weapon_knife");
			
			PrintHintText(client, "%T", "To disable pistol auto choice, use +ability", client);
			return true;
		}
	}
	else // if for some reason g_bAutoRepick[client] will return true while it should be false
		return false;
}

stock bool:CanUseWeapon(client, String:sWeaponName[32])
{
	new iGunLevel = War3_GetSkillLevel(client, thisRaceID, SKILL_GUNS);
	if (StrEqual(sWeaponName, "weapon_elite", true) && iGunLevel < 5)
	{
		DoPistolMenu(client);
		return false;
	}
	if (StrEqual(sWeaponName, "weapon_deagle", true) && iGunLevel < 4)
	{
		DoPistolMenu(client);
		return false;
	}
	if (StrEqual(sWeaponName, "weapon_fiveseven", true) && iGunLevel < 3)
	{
		DoPistolMenu(client);
		return false;
	}
	if (StrEqual(sWeaponName, "weapon_p228", true) && iGunLevel < 2)
	{
		DoPistolMenu(client);
		return false;
	}
	if (StrEqual(sWeaponName, "weapon_usp", true) && iGunLevel < 1)
	{
		DoPistolMenu(client);
		return false;
	}
	return true;
}
