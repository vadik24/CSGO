#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>
#include <sdktools_functions>
#include <cstrike>

public Plugin:myinfo = 
{
	name = "War3Source Race - Elven Scout",
	author = "M.A.C.A.B.R.A",
	description = "The Elven Scout race for War3Source.",
	version = "1.0.1",
};

new thisRaceID;
new SKILL_SENSE, SKILL_ACCURACY, SKILL_CUTLER,  ULT_RETURN;

// Sense
new Float:SenseRange[]={0.0, 1000.0, 1500.0, 2000.0, 2500.0};
new bool:WeaponZoomed[MAXPLAYERS+1];
new g_iScope[MAXPLAYERS + 1];
new ammo[MAXPLAYERS +1];
new GlowSprite,GlowSprite2,BeamSprite,HaloSprite,BloodSpray,BloodDrop;
// Accuracy Buffs
new Float:AccuracyDmg[]={1.0,1.5,1.6,1.7,1.8};

// Cutler Buffs
new Float:CutlerSpeed[]={1.0,1.4,1.5,1.6,1.7};

// Return
new Float:ReturnSavedPos[MAXPLAYERS][3];
new bool:ReturnAnyPosSaved[MAXPLAYERS];
new Float:ReturnTeleportCooldown[]={0.0,40.0,30.0,20.0,10.0};



/* *********************** OnWar3PluginReady *********************** */
public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("VIP Elven Scout","elvenscout");
	
	SKILL_SENSE=War3_AddRaceSkill(thisRaceID,"Eagle Eye","You have an eagle sight while scoping. Range increases with level!",false,4); // [X]
	SKILL_ACCURACY=War3_AddRaceSkill(thisRaceID,"Accuracy","Your scout does 50-80% additional damage when you're not using the scope!",false,4); // [X]
	SKILL_CUTLER=War3_AddRaceSkill(thisRaceID,"Cutter","Gain 40-70% additional speed when using the knife!",false,4); // [X]
	ULT_RETURN=War3_AddRaceSkill(thisRaceID,"Return","Mark a location and return to it upon usage!",true,4); // [X]
	
	War3_CreateRaceEnd(thisRaceID);
}

/* *********************** OnPluginStart *********************** */
public OnPluginStart()
{
	CreateTimer( 0.1, Calculate, _, TIMER_REPEAT );
	
	HookEvent("weapon_zoom", OnPlayerZoom, EventHookMode_Post);
	HookEvent("weapon_reload", OnPlayerReload, EventHookMode_Post);
	HookEvent("weapon_fire", OnPlayerFire, EventHookMode_Post);
	
}

/* *********************** OnMapStart *********************** */
public OnMapStart()
{
	GlowSprite=PrecacheModel("effects/redflare.vmt");
	GlowSprite2=PrecacheModel("materials/effects/fluttercore.vmt");
	BeamSprite=War3_PrecacheBeamSprite();
	HaloSprite=War3_PrecacheHaloSprite();
	BloodSpray=PrecacheModel("sprites/bloodspray.vmt");
	BloodDrop=PrecacheModel("sprites/blood.vmt");
}

/* *********************** OnWar3EventSpawn *********************** */
public OnWar3EventSpawn(client)
{
	new race = War3_GetRace( client );
	if( race == thisRaceID )
	{
		ReturnAnyPosSaved[client] = false;
		WeaponZoomed[client] = false;
		g_iScope[client] = 0;
		ammo[client] = 10;
		GivePlayerItem( client, "weapon_ssg08" );
	}
}

public OnWar3EventDeath(client)
{
	new race = War3_GetRace( client );
	if( race == thisRaceID )
	{
		ReturnAnyPosSaved[client] = false;
		WeaponZoomed[client] = false;
		g_iScope[client] = 0;
	}
}

/* *********************** OnRaceChanged *********************** */
public OnRaceChanged(client,oldrace,newrace)
{
	if( oldrace == thisRaceID )
	{
		War3_WeaponRestrictTo( client, thisRaceID, "" );
		W3ResetAllBuffRace( client, thisRaceID );
		g_iScope[client] = 0;
		ReturnAnyPosSaved[client] = false;
		WeaponZoomed[client] = false;
	}
	if( newrace == thisRaceID )
	{
		War3_WeaponRestrictTo( client, thisRaceID, "weapon_knife,weapon_ssg08" );
		if( IsPlayerAlive( client ) )
		{
			GivePlayerItem( client, "weapon_ssg08" );
			g_iScope[client] = 0;
			ReturnAnyPosSaved[client] = false;
			WeaponZoomed[client] = false;
		}
	}
}

/* *************************************** Calculate *************************************** */
public Action:Calculate( Handle:timer, any:userid )
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(ValidPlayer(i))
		{
			if( War3_GetRace( i ) == thisRaceID )
			{
				Sense(i);
				Cutler(i);
				if(ReturnAnyPosSaved[i]) {
					TE_SetupGlowSprite(ReturnSavedPos[i],GlowSprite,0.2,1.5,200);
					TE_SendToClient(i);
				}
			}		
		}
	}
	
}

/* *************************************** Sense *************************************** */
public Sense(client)
{
	new skill_sense = War3_GetSkillLevel( client, thisRaceID, SKILL_SENSE );
	if( skill_sense > 0 && !Hexed( client, false ) )
	{
		new ElfTeam = GetClientTeam( client );
		new Float:ElfPos[3];
		new Float:VictimPos[3];
		
		GetClientAbsOrigin( client, ElfPos );
		
		ElfPos[2] += 50.0;
		
		for( new i = 1; i <= MaxClients; i++ )
		{
			if( ValidPlayer( i, true ) && GetClientTeam( i ) != ElfTeam && !W3HasImmunity( i, Immunity_Skills ) )
			{
				GetClientAbsOrigin( i, VictimPos );
				VictimPos[2] += 50.0;
				
				if(GetVectorDistance( ElfPos, VictimPos ) <= SenseRange[skill_sense])
				{
					decl String:weapon[64];
					GetClientWeapon(client, weapon, sizeof(weapon));
					if(StrEqual(weapon, "weapon_ssg08"))
					{
						new VictimTeam = GetClientTeam( i );
						if(WeaponZoomed[client] == true)
						{
							if(VictimTeam == 2) // TT
							{
								TE_SetupGlowSprite(VictimPos,GlowSprite,0.1,0.6,80);
								TE_SendToClient(client);
								TE_SetupBeamPoints(ElfPos, VictimPos, BeamSprite, HaloSprite, 0, 8, 0.1, 1.0, 10.0, 10, 10.0, {255,0,0,155}, 70); // czerwony
								TE_SendToClient(client);
							}
							else // CT
							{
								TE_SetupGlowSprite(VictimPos,GlowSprite2,0.1,0.1,150);
								TE_SendToClient(client);
								TE_SetupBeamPoints(ElfPos, VictimPos, BeamSprite, HaloSprite, 0, 8, 0.1, 1.0, 10.0, 10, 10.0, {30,144,255,155}, 70); // niebieski
								TE_SendToClient(client);
							}	
						}
					}
					else
					{
						g_iScope[client] = 0;
						WeaponZoomed[client] = false;						
					}						
				}
			}
		}
	}
}



/* *************************************** OnPlayerZoom *************************************** */
public Action:OnPlayerZoom(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	g_iScope[client]++;
	if(g_iScope[client] >= 3)
	{
		g_iScope[client] = 0;
	}
	
	decl String:weapon[64];
	GetClientWeapon(client, weapon, sizeof(weapon));
	if(StrEqual(weapon, "weapon_ssg08"))
	{
		if(g_iScope[client] == 2)
		{
			WeaponZoomed[client] = true;
		}
		else
		{
			WeaponZoomed[client] = false;
		}
	}
	else
	{
		g_iScope[client] = 0;
		WeaponZoomed[client] = false;
	}
}

/* *************************************** OnPlayerReload *************************************** */
public Action:OnPlayerReload(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_iScope[client] = 0;
	WeaponZoomed[client] = false;
	ammo[client] = 10;
}

/* *************************************** OnPlayerFire *************************************** */
public Action:OnPlayerFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	decl String:weapon[64];
	GetClientWeapon(client, weapon, sizeof(weapon));
	if(StrEqual(weapon, "weapon_ssg08"))
	{
		ammo[client]--;
		if(ammo[client] == 0)
		{
			g_iScope[client] = 0;
			WeaponZoomed[client] = false;
			ammo[client] = 10;
		}
	}
}

/* *************************************** Cutler *************************************** */
public Cutler(client)
{
	new skill_cutler = War3_GetSkillLevel( client, thisRaceID, SKILL_CUTLER );
	if( skill_cutler > 0)
	{
		decl String:weapon[64];
		GetClientWeapon(client, weapon, sizeof(weapon));
		if(StrEqual(weapon, "weapon_knife"))
		{
			War3_SetBuff(client,fMaxSpeed,thisRaceID,CutlerSpeed[skill_cutler]);
		}
		else
		{
			W3ResetAllBuffRace( client, thisRaceID );
		}
		
	}
}



/* *************************************** OnW3TakeDmgBulletPre *************************************** */
public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim,true)&&ValidPlayer(attacker,false)&&GetClientTeam(victim)!=GetClientTeam(attacker))
	{
		if(War3_GetRace(attacker)==thisRaceID)
		{
			if(g_iScope[attacker] == 0)
			{
				decl Float:Position[3],Float:Angles[3], skill_ult;
				skill_ult = War3_GetSkillLevel(attacker,thisRaceID,SKILL_ACCURACY);
				War3_DamageModPercent(AccuracyDmg[skill_ult]);
				GetClientAbsOrigin(victim,Position);
				GetClientAbsAngles(attacker,Angles);
				TE_SetupBloodSprite(Position, Angles, {220, 20, 20, 255}, GetRandomInt(8,12), BloodSpray, BloodDrop);
				TE_SendToAll();
			}
		}
	}
}

/* *************************************** OnUltimateCommand *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
		new skill_ult = War3_GetSkillLevel(client,thisRaceID,ULT_RETURN);
		if(skill_ult > 0)
		{
			if(!Silenced(client) && War3_SkillNotInCooldown(client,thisRaceID,ULT_RETURN,true ))
			{
				if(ReturnAnyPosSaved[client] == false)
				{
					PrintHintText( client, "Location Marked" );
					War3_CooldownMGR(client,10.0,thisRaceID,ULT_RETURN,false,true);
					GetClientAbsOrigin( client, ReturnSavedPos[client] );
					ReturnAnyPosSaved[client] = true;
				}
				else
				{
					PrintHintText( client, "Returned to marked location" );
					War3_CooldownMGR(client,ReturnTeleportCooldown[skill_ult],thisRaceID,ULT_RETURN,false,true);
					TeleportEntity(client, ReturnSavedPos[client], NULL_VECTOR, NULL_VECTOR);
					ReturnAnyPosSaved[client] = false;
				}
				TE_SetupBeamRingPoint(ReturnSavedPos[client], 1.0, 300.0, BeamSprite, HaloSprite, 0, 10, 0.8, 20.0, 1.5, {120,255,120,255}, 1600, FBEAM_SINENOISE);
				TE_SendToAll();
			}
		}
		else
		{
			PrintHintText(client, "Level Skill Return first");
		}
	}
}