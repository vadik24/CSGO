#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
	name = "War3Source Race - Paladin",
	author = "Ted Theodore Logan",
	description = "The Paladin race for War3Source.",
	version = "1.0",
};	

/* Notes:
 * Paladin only gains half of what the aura gives
 * While teammates are nearby you gain "holy energy", wich is needed to cast aura overdrive
 * Overdrive lasts 10 seconds
 * Overdrive can buff the minimum level of the current aura
 * 	Defensive Aura is level 2, Offensive and Healing 4, Overdrive level 3.
 * 	Defensive Aura is active, the Paladin casts Overdrive
 * 	For the duration of Overdrive he gets level 3 Defensive Aura but both Offensive and Healing are also level 3
 */

/* Defensive Aura: Increases Armor 5-10-15-20
 * Offensive Aura: Increases Damage 5-10-15-20
 * Regenerative Aura: Gives HP regeneration 1-2-3-4 (%)
 * Aura Overdrive: Activates the other 2 Auras and gives the Paladin the full benefit of all 3 auras
 */


new thisRaceID;
new SKILL_DEFENSIVE, SKILL_OFFENSIVE, SKILL_HEALING, ULT_OVERDRIVE;
new Handle:HudMessage;

// Effects
new BeamSprite,HaloSprite;

enum ACTIVEAURA{
	None,
	Defensive,
	Offensive,
	Regenerative,
}
/* Bugs:
 * 	Buff takes priority over Aura
 * 	no effects
 */

new PaladinsTeam;
 new ACTIVEAURA:CurrentAura[MAXPLAYERS]; // Wich aura does this Paladin currently have?
new overdriveCharge[MAXPLAYERS]; // How much holy energy a paladin has built up
new bool:bOnOverdrive[MAXPLAYERS]; // Is this Paladin in Overdrive mode?
new Float:fAuraRange = 500.0; // How far a Paladins aura stretches
new bool:bDidAlert[MAXPLAYERS][MAXPLAYERS]; // bDidAlert[paladin][client] Was this player alerted of being in an aura?
new highestPaladin; // Paladin with the highest skill level

// Defensive aura
new Float:DefArmorAura[5]={1.0,0.95,0.90,0.85,0.80};
new Float:DefArmorPala[5]={1.0,0.975,0.95,0.925,0.90};

// Offensive aura
new Float:OffDamageAura[5]={1.0,1.05,1.1,1.15,1.2};
new Float:OffDamagePala[5]={1.0,1.025,1.05,1.075,1.1};

// Regenerative aura
new Float:RegenAura[5]={0.0,0.01,0.02,0.03,0.04};
new Float:RegenPala[5]={0.0,0.005,0.01,0.015,0.02};

public OnWar3PluginReady(){
	thisRaceID=War3_CreateNewRaceT("paladin");
	SKILL_DEFENSIVE=War3_AddRaceSkillT(thisRaceID,"DefensiveAura",false,4);
	SKILL_OFFENSIVE=War3_AddRaceSkillT(thisRaceID,"OffensiveAura",false,4);
	SKILL_HEALING=War3_AddRaceSkillT(thisRaceID,"HealingAura",false,4);
	ULT_OVERDRIVE=War3_AddRaceSkillT(thisRaceID,"AuraOverdrive",true,4); 
	War3_CreateRaceEnd(thisRaceID);
}

public OnPluginStart()
{
	HudMessage = CreateHudSynchronizer();
	CreateTimer(1.0,HealingAuraTimer,_,TIMER_REPEAT);
	CreateTimer(1.0,HolyPointsTimer,_,TIMER_REPEAT);
	CreateTimer(0.1,UpdateInfoTimer,_,TIMER_REPEAT);
	CreateTimer(0.1,UpdateAuraNotification,_,TIMER_REPEAT);
	
	LoadTranslations("w3s.race.paladin.phrases");
}

// ################## THE LITTLE STUFF ###############

public OnWar3EventSpawn(client)
{	
	bOnOverdrive[client] = false;
	overdriveCharge[client] = 0;
	// "Unnotify" this client of all auras he's currently getting so he can get renotified
	for(new i=1;i<=MaxClients;i++)
	{
		// Found a paladin?
		if((ValidPlayer(i))&&(War3_GetRace(i)==thisRaceID))
		{
			// Well our client isn't notified anymore...
			if(i!=client)
			{
				bDidAlert[i][client] = false;
			}
		}
	}
}

public OnMapStart()
{
	BeamSprite=War3_PrecacheBeamSprite();
	HaloSprite=War3_PrecacheHaloSprite();
}

/* Retrieve the highest skill level that a paladin next to client has
 * I tried to make it somewhat smart to give the player the best buff
 * even when multiple Paladins are around but it turned into a brainfuck
 * and I said "FUCK THIS SHIT I'M GOING HOME" and then /ragequit Eclipse.
 */

public HighestAuraLevel(client, ACTIVEAURA:aura)
{
	new paladin;
	new Float:range = fAuraRange;
	new highest_skill = 0;
	new skill = 0;
	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true))
		{
			// Found a paladin
			if(War3_GetRace(i)==thisRaceID)
			{
				paladin = i;
				// Same team?
				PaladinsTeam = GetClientTeam(paladin);
				new ClientTeam = GetClientTeam(client);
				if(PaladinsTeam==ClientTeam)
				{
					new Float:PaladinPos[3];
					new Float:ClientPos[3];
					GetClientAbsOrigin(paladin,PaladinPos);
					GetClientAbsOrigin(client,ClientPos);
					// In range?
					if(GetVectorDistance(PaladinPos,ClientPos)<=range)
					{
						// Does he have the aura we're looking for active?
						if(CurrentAura[paladin]==aura)
						{
							// Get the skill level of the aura we're looking for and compare it to the
							// previous highest we found, so low level skills don't override high level
							switch(CurrentAura[paladin])
							{
								case(Defensive):
								{
									skill = War3_GetSkillLevel(paladin,thisRaceID,SKILL_DEFENSIVE);
									if(skill>highest_skill)
									{
										highestPaladin = paladin;
										highest_skill = skill;
									}
									// Prefer other Paladins so we get their aura instead of using our own buff
									else if((skill==highest_skill)&&(paladin!=client))
									{
										highestPaladin = paladin;
									}
								}
								case(Offensive):
								{
									skill = War3_GetSkillLevel(paladin,thisRaceID,SKILL_OFFENSIVE);
									if(skill>highest_skill)
									{
										highestPaladin = paladin;
										highest_skill = skill;
									}
									else if((skill==highest_skill)&&(paladin!=client))
									{
										highestPaladin = paladin;
									}
								}
								case(Regenerative):
								{
									skill = War3_GetSkillLevel(paladin,thisRaceID,SKILL_HEALING);
									if(skill>highest_skill)
									{
										highestPaladin = paladin;
										highest_skill = skill;
									}
									else if((skill==highest_skill)&&(paladin!=client))
									{
										highestPaladin = paladin;
									}
								}
							}
						}
						// If he doesn't have the aura select; does he have atleast have overdrive?
						else if(bOnOverdrive[paladin]==true)
						{
							// Is his overdrive level higher than the skill levels we got before?
							skill = War3_GetSkillLevel(paladin,thisRaceID,ULT_OVERDRIVE);
							if(skill>highest_skill)
							{
								highestPaladin = paladin;
								highest_skill = skill;
							}
						}
					}
				}
			}
		}
	}
	return highest_skill;
}

// ################## NOTIFICATION ###############

// For when the Paladin switches Auras and everyone needs to be notified of this switch
public NotAlertedAnymore(paladin)
{
	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i))
		{
			bDidAlert[paladin][i] = false;
		}
	}
}

// Old
/*
// Notify clients of the aura they're getting
public Action:UpdateAuraNotification(Handle:timer)
{
	new paladin;
	new client;
	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true))
		{
			if(War3_GetRace(i)==thisRaceID)
			{
				paladin = i;
				new Float:range = fAuraRange;
				new PaladinTeam = GetClientTeam(paladin);
				new Float:PaladinPos[3];
				GetClientAbsOrigin(paladin,PaladinPos);
				new Float:ClientPos[3];
				for(new j=1;j<=MaxClients;j++)
				{
					if(ValidPlayer(j,true)&&GetClientTeam(j)==PaladinTeam)
					{
						client = j;
						GetClientAbsOrigin(client,ClientPos);
						
						// In range?
						if((GetVectorDistance(PaladinPos,ClientPos)<=range)&&(!bDidAlert[paladin][client]))
						{
							if(CurrentAura[paladin]==Defensive)
							{
								if(client==paladin)
								{
									PrintHintText(client, "Activated defensive aura!");
								}
								else
								{
									PrintHintText(client, "You are getting a defensive aura!");
								}
								bDidAlert[paladin][client] = true;
							}
							else if(CurrentAura[paladin]==Offensive)
							{
								if(client==paladin)
								{
									PrintHintText(client, "Activated offensive aura!");
								}
								else
								{
									PrintHintText(client, "You are getting a offensive aura!");
								}
								bDidAlert[paladin][client] = true;
							}
							else if(CurrentAura[paladin]==Regenerative)
							{
								if(client==paladin)
								{
									PrintHintText(client, "Activated healing aura!");
								}
								else
								{
									PrintHintText(client, "You are getting a healing aura!");
								}
								bDidAlert[paladin][client] = true;
							}
						}
					}
				}
			}
		}
	}
}
*/

// New
public Action:UpdateAuraNotification(Handle:timer)
{
	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true))
		{
			new skill_offensive = HighestAuraLevel(i, Offensive);
			new skill_defensive = HighestAuraLevel(i, Defensive);
			new skill_healing = HighestAuraLevel(i, Regenerative);
			new Float:effect_vec[3];
			GetClientAbsOrigin(i,effect_vec);
			
			effect_vec[2]+=10.0;
			if(skill_offensive>0)
			{
				TE_SetupBeamRingPoint(effect_vec,45.0,44.0,BeamSprite,HaloSprite,0,15,0.1,float(skill_offensive),0.0,{255,0,0,255},10,0);
				// TE_SendToAll();
				new tmp3 = 0;//, team = 2;
				decl sendarray[32];
				for (new x = 1; x <= MaxClients; x++)
				{
					if(IsClientInGame(x) && !IsFakeClient(x))
					{
						new XTeam = GetClientTeam(x);
						if (XTeam == PaladinsTeam)
						{
							sendarray[tmp3++] = x;
						}
					}
				}
				TE_Send(sendarray, tmp3);
			}
			effect_vec[2]+=5.0;
			if(skill_defensive>0)
			{
				TE_SetupBeamRingPoint(effect_vec,45.0,44.0,BeamSprite,HaloSprite,0,15,0.1,float(skill_defensive),0.0,{0,0,255,255},10,0);
				// TE_SendToAll();
				new tmp3 = 0;//, team = 2;
				decl sendarray[32];
				for (new x = 1; x <= MaxClients; x++)
				{
					if(IsClientInGame(x) && !IsFakeClient(x))
					{
						new XTeam = GetClientTeam(x);
						if (XTeam == PaladinsTeam)
						{
							sendarray[tmp3++] = x;
						}
					}
				}
				TE_Send(sendarray, tmp3);
			}
			effect_vec[2]+=5.0;
			if(skill_healing>0)
			{
				TE_SetupBeamRingPoint(effect_vec,45.0,44.0,BeamSprite,HaloSprite,0,15,0.1,float(skill_healing),0.0,{0,255,0,255},10,0);
				// TE_SendToAll();
				new tmp3 = 0;//, team = 2;
				decl sendarray[32];
				for (new x = 1; x <= MaxClients; x++)
				{
					if(IsClientInGame(x) && !IsFakeClient(x))
					{
						new XTeam = GetClientTeam(x);
						if (XTeam == PaladinsTeam)
						{
							sendarray[tmp3++] = x;
						}
					}
				}
				TE_Send(sendarray, tmp3);
			}
		}
	}
}

// ################## HOLY POINTS ###############

// Award Holy Points for being in range of teammates
public Action:HolyPointsTimer(Handle:timer)
{
	new paladin;
	new client;
	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true))
		{
			if(War3_GetRace(i)==thisRaceID)
			{
				paladin = i;
				// Not in overdrive?
				if(!bOnOverdrive[paladin])
				{ 
					new Float:range = fAuraRange;
					new PaladinTeam = GetClientTeam(paladin);
					new Float:PaladinPos[3];
					GetClientAbsOrigin(paladin,PaladinPos);
					new Float:ClientPos[3];
					for(new j=1;j<=MaxClients;j++)
					{
						if(ValidPlayer(j,true)&&GetClientTeam(j)==PaladinTeam)
						{
							client = j;
							GetClientAbsOrigin(client,ClientPos);
							
							// In range?
							if(GetVectorDistance(PaladinPos,ClientPos)<=range)
							{
								if(client!=paladin)
								{
									if(overdriveCharge[paladin]<100)
									{
										// Give charge
										overdriveCharge[paladin]++;
									}
								}
							}
						}
					}
				}
			}
		}
	}
}

public Action:UpdateInfoTimer(Handle:timer) 
{
	for(new i=1;i<=MaxClients;i++) 
	{
		if (ValidPlayer(i,true) && !IsFakeClient(i) && (War3_GetRace(i)==thisRaceID)) 
		{
			SetHudTextParams(0.04, 0.05, 5.0, 0, 255, 0, 255);
			new String:message[] = "[          ]";
			// Pretty explicit way eh
			switch(overdriveCharge[i] / 10)
			{
				case(1):
				{
					message = "[#         ]";
				}
				case(2):
				{
					message = "[##        ]";
				}
				case(3):
				{
					message = "[###       ]";
				}
				case(4):
				{
					message = "[####      ]";
				}
				case(5):
				{
					message = "[#####     ]";
				}
				case(6):
				{
					message = "[######    ]";
				}
				case(7):
				{
					message = "[#######   ]";
				}
				case(8):
				{
					message = "[########  ]";
				}
				case(9):
				{
					message = "[######### ]";
				}
				case(10):
				{
					message = "[##########]";
				}
			}
			ShowSyncHudText(i, HudMessage, "%T", "Holy Points {message}", i, message);
		}
	}
}

// ################## MENU ###############

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
	{
		new skill_defensive = War3_GetSkillLevel(client,thisRaceID,SKILL_DEFENSIVE);
		new skill_offensive = War3_GetSkillLevel(client,thisRaceID,SKILL_OFFENSIVE);
		new skill_healing = War3_GetSkillLevel(client,thisRaceID,SKILL_HEALING);
		
		// No auras yet? Don't bother...
		if((skill_defensive==0)&&(skill_offensive==0)&&(skill_healing==0))
		{
			PrintHintText(client, "%T", "You first need a aura!", client);
		}
		else
		{
			new Handle:menu = CreateMenu(SelectAura);
			
			new String:auramenu[64];
			new String:defensive[64];
			new String:offensive[64];
			new String:healing[64];
			Format(auramenu,sizeof(auramenu),"%T","Wich aura do you want to select?",client);
			Format(defensive,sizeof(defensive),"%T","Defensive Aura",client);
			Format(offensive,sizeof(offensive),"%T","Offensive Aura",client);
			Format(healing,sizeof(healing),"%T","Healing Aura",client);
			
			SetMenuTitle(menu, auramenu);
			// Only add those auras that have skillpoints
			if(skill_defensive>0)
			{
				AddMenuItem(menu, "defensive", defensive);
			}
			if(skill_offensive>0)
			{
				AddMenuItem(menu, "offensive", offensive);
			}
			if(skill_healing>0)
			{
				AddMenuItem(menu, "healing", healing);
			}
			
			SetMenuExitButton(menu, false);
			DisplayMenu(menu, client, 20);
		}
	}
}

public SelectAura(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		if(StrEqual(info,"defensive"))
		{
			if(CurrentAura[param1] != Defensive)
			{
				NotAlertedAnymore(param1);
				CurrentAura[param1] = Defensive;
			}
		}
		else if(StrEqual(info,"offensive"))
		{
			if(CurrentAura[param1] != Offensive)
			{
				NotAlertedAnymore(param1);
				CurrentAura[param1] = Offensive;
			}
		}
		else if(StrEqual(info,"healing"))
		{
			if(CurrentAura[param1] != Regenerative)
			{
				NotAlertedAnymore(param1);
				CurrentAura[param1] = Regenerative;
			}
		}
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

// ################## OVERDRIVE ###############

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && IsPlayerAlive(client))
	{
		new skill = War3_GetSkillLevel(client,thisRaceID,ULT_OVERDRIVE);
		if((overdriveCharge[client]>=100)&&(skill>0))
		{
			PrintHintText(client, "%T", "You went into overdrive!", client);
			bOnOverdrive[client] = true;
			overdriveCharge[client] = 100; // just in case the client has more than 100 points for some odd reason
			CreateTimer(1.0,ReduceOverdrive,client);
		}
		else
		{
			PrintHintText(client, "%T", "Overdrive is not ready. Charge - (1)", client, overdriveCharge[client]);
		}
	}
}

public Action:ReduceOverdrive(Handle:timer,any:client)
{
	if(overdriveCharge[client]<=10)
	{
		overdriveCharge[client] = 0;
		bOnOverdrive[client] = false;
		PrintHintText(client, "%T", "Finished overdrive", client);
	}
	else
	{
		overdriveCharge[client] -= 10;
		CreateTimer(1.0,ReduceOverdrive,client);
	}
}

// ################## HEALING AURA ###############

// Note that this is the only aura that actually stacks.
public Action:HealingAuraTimer(Handle:timer,any:userid)
{
	new paladin;
	new client;
	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true))
		{
			if(War3_GetRace(i)==thisRaceID)
			{
				paladin = i;
				new skill_healing = War3_GetSkillLevel(paladin,thisRaceID,SKILL_HEALING);
				new skill_overdrive = War3_GetSkillLevel(paladin,thisRaceID,ULT_OVERDRIVE);
				new skill;
				// Paladin has healing aura skilled and it activated or he's in overdrive mode
				if(((skill_healing>0)&&(CurrentAura[paladin]==Regenerative)) || (skill_overdrive>0)&&(bOnOverdrive[paladin]==true))
				{ 
					new Float:range = fAuraRange;
					new PaladinTeam = GetClientTeam(paladin);
					new Float:PaladinPos[3];
					GetClientAbsOrigin(paladin,PaladinPos);
					new Float:ClientPos[3];
					for(new j=1;j<=MaxClients;j++)
					{
						if(ValidPlayer(j,true)&&GetClientTeam(j)==PaladinTeam)
						{
							client = j;
							GetClientAbsOrigin(client,ClientPos);
							
							// In range?
							if(GetVectorDistance(PaladinPos,ClientPos)<=range)
							{
								// Paladin in overdrive mode?
								if(bOnOverdrive[paladin])
								{
									// Healing aura selected?
									if(CurrentAura[paladin]==Regenerative)
									{
										if(skill_healing>skill_overdrive)
										{
											skill = skill_healing;
										}
										else
										{
											skill = skill_overdrive;
										}
										// Apply the buff based on the level of healing aura
										War3_HealToMaxHP(client,RoundToCeil(War3_GetMaxHP(client) * RegenAura[skill]));
									}
									else
									{
										// Apply the buff based on the level of overdrive
										War3_HealToMaxHP(client,RoundToCeil(War3_GetMaxHP(client) * RegenAura[skill_overdrive]));	
									}
								}
								// If he's not in overdrive mode
								else
								{
									// Not the paladin and below max HP?
									if((client!=paladin)&&(GetClientHealth(client)<War3_GetMaxHP(client)))
									{
										// Heal!
										War3_HealToMaxHP(client,RoundToCeil(War3_GetMaxHP(client) * RegenAura[skill_healing]));
									}
									// Paladin and below max HP?
									else if ((client==paladin)&&(GetClientHealth(client)<War3_GetMaxHP(client)))
									{
										// Only give him the (weaker) Paladin regen
										War3_HealToMaxHP(client,RoundToCeil(War3_GetMaxHP(client) * RegenPala[skill_healing]));
									}
								}
							}
						}
					}
				}
			}
		}
	}
}

// ################## OFFENSIVE/DEFENSIVE AURA ###############

public OnW3TakeDmgBulletPre(victim,attacker,Float:damage){
	if(ValidPlayer(victim,true)&&ValidPlayer(attacker,false)&&GetClientTeam(victim)!=GetClientTeam(attacker))
	{
		// Victim calculations
		new skill_def = HighestAuraLevel(victim, Defensive);
		if(skill_def>0)
		{
			if((victim==highestPaladin)&&(!bOnOverdrive[victim]))
			{
				War3_DamageModPercent(DefArmorPala[skill_def]);
			}
			else
			{
				War3_DamageModPercent(DefArmorAura[skill_def]);
			}
		}
		// Attacker calculations
		new skill_off = HighestAuraLevel(attacker, Offensive);
		if(skill_off>0)
		{
			if((attacker==highestPaladin)&&(!bOnOverdrive[attacker]))
			{
				War3_DamageModPercent(OffDamagePala[skill_off]);
			}
			else
			{
				War3_DamageModPercent(OffDamageAura[skill_off]);
			}
		}
	}
}