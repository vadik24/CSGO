/**
* File: War3Source_CombineGrunt.sp
* Description: Combine Grunt race for War3Source
* Author(s): Revan
*/
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include "sdkhooks"
#include "W3SIncs/War3Source_Interface"
#define WEAPONNAME "energyball"
#define DISSOLVECLASSNAME "removed_entity"
#define LAUNCHERNAME "grenade launcher"
#define ROCKETWEAPON "weapon_ak47" //should be a primary weapon!
#define EXPLOSIONFLAGS TE_EXPLFLAG_ROTATE
#define NUKENAME "nuke"
#define SLOT 0 //primary weapon slot (in css 0)
#define SHOWNUKE 15.0
#define	DAMAGE_NO				0
#define	DAMAGE_YES				2
new bool:chargingenergyball[MAXPLAYERS + 1];
new bool:nukecharge[MAXPLAYERS];
new kills[MAXPLAYERS];
//new bool:swep[2048];
new bool:ar2[MAXPLAYERS];
//new oldweapon[MAXPLAYERS];
new energyballtouchcount[2048];
new bool:playingenergyballsound[2048];
new bool:playingrocketsound[2048];
new bool:pressdelay[MAXPLAYERS];

new thisRaceID, SKILL_HP, SKILL_AR2, SKILL_NUKE, ULT_BALL;
new PlasmaBeam, PlasmaHalo, Explosion, GlowSprite, Smoke;
new String:loop[] = "weapons/physcannon/energy_sing_loop4.mp3";
new String:detonade[] = "weapons/physcannon/energy_sing_explosion2.mp3";
new String:bouncey0[] = "weapons/physcannon/energy_bounce1.mp3";
new String:bouncey1[] = "weapons/physcannon/energy_bounce2.mp3";
new String:disintegrate0[] = "weapons/physcannon/energy_disintegrate4.mp3";
new String:disintegrate1[] = "weapons/physcannon/energy_disintegrate5.mp3";
new String:charge[] = "weapons/cguard/charging.mp3";
new String:fire[] = "weapons/irifle/irifle_fire2.mp3";
new String:nuke[] = "weapons/c4/c4_explode1.mp3";
new String:nukefire[] = "weapons/rpg/rocketfire1.mp3";
new String:grenade[] = "weapons/grenade_launcher1.mp3";
new String:explode[] = "weapons/explode3.mp3";
new Handle:chargeTimeCvar = INVALID_HANDLE;
new Handle:ultCooldownCvar = INVALID_HANDLE;
new Handle:lifeTimeCvar = INVALID_HANDLE;
new Handle:projectileSpeedCvar = INVALID_HANDLE;
new Handle:touchLimitCvar = INVALID_HANDLE;
new Handle:nukeSpeedCvar = INVALID_HANDLE;
//new Handle:grenadeSpeedCvar = INVALID_HANDLE;
new Handle:enableLauncherCvar = INVALID_HANDLE;
new EnergyBall[6]={0,75,80,90,100,120};
new hpadd[6]={0,2,4,6,8,10};
//new Float:firearmor[6]={0.0,45.0,50.0,65.0,77.0,85.0};
new Min[6]={0,70,91,100,150,200};
new Max[6]={0,90,100,150,200,250};
new killstreak[6]={0,15,13,11,10,8};
new Float:nadespeed[6]={250.0,280.0,350.0,500.0,650.0,870.0}; //my game crashed if i use zero so lets start with 100
new itemmdl;
enum{
	
	EF_BONEMERGE			= 0x001,	// Performs bone merge on client side
	EF_BRIGHTLIGHT 			= 0x002,	// DLIGHT centered at entity origin
	EF_DIMLIGHT 			= 0x004,	// player flashlight
	EF_NOINTERP				= 0x008,	// don't interpolate the next frame
	EF_NOSHADOW				= 0x010,	// Don't cast no shadow
	EF_NODRAW				= 0x020,	// don't draw entity
	EF_NORECEIVESHADOW		= 0x040,	// Don't receive no shadow
	EF_BONEMERGE_FASTCULL	= 0x080,	// For use with EF_BONEMERGE. If this is set, then it places this ent's origin at its
										// parent and uses the parent's bbox + the max extents of the aiment.
										// Otherwise, it sets up the parent's bones every frame to figure out where to place
										// the aiment, which is inefficient because it'll setup the parent's bones even if
										// the parent is not in the PVS.
	EF_ITEM_BLINK			= 0x100,	// blink an item so that the user notices it.
	EF_PARENT_ANIMATES		= 0x200,	// always assume that the parent entity is animating
	EF_MAX_BITS = 10
	
};
// Big Thanks to :
// javalia - TacticlaGunMod2
public Plugin:myinfo = 
{
	name = "War3Source - Combine Elite",
	author = "Revan",
	description = "Combine Elite Race for War3Source",
	version = "0.9.1.0",
	url = "www.wcs-lagerhaus.de"
};

public OnPluginStart()
{
	ultCooldownCvar=CreateConVar("war3_combinee_ult_cooldown","40.0","Combine Grunt's Ultimate cooldown.");
	chargeTimeCvar = CreateConVar("war3_combinee_ult_time", "1.0", "Combine Grunt's Ultimate chargetime");
	lifeTimeCvar = CreateConVar("war3_combinee_ult_duration", "8.0", "Combine Grunt's Ultimate lifetime");
	touchLimitCvar = CreateConVar("war3_combinee_ult_touch", "10", "Combine Grunt's Ultimate touchlimit");
	projectileSpeedCvar = CreateConVar("war3_combinee_ult_speed", "1600.0", "Combine Grunt's Ultimate energyball speed");
	nukeSpeedCvar = CreateConVar("war3_combinee_ability_speed", "450.0", "Combine Grunt's Ability nuke speed");
	enableLauncherCvar = CreateConVar("war3_combinee_grenadelauncher_enable", "1", "Enables/Disabled the grenade launcher for the race Combine Grunt");
	//grenadeSpeedCvar = CreateConVar("war3_combinee_grenadelauncher_speed", "400", "grenade laucher speed(combine grunt) if not leveled!");
	//itemmdl=FindSendPropOffs("CBaseViewModel","m_nViewModelIndex");  
	RegAdminCmd("kills", cmd, ADMFLAG_CUSTOM6, "testing command");
}

public OnMapStart(){
	GlowSprite = PrecacheModel("materials/sprites/orangeglow1.vmt");
	//ar2mdl = PrecacheModel("models/weapons/w_rocket_launcher.mdl",true); //PrecacheModel("models/weapons/w_IRifle.mdl",true); <- old model, but used rocket after trying much other models..
	Explosion = PrecacheModel("materials/sprites/floorfire4_.vmt", true);
	PlasmaBeam = PrecacheModel("materials/sprites/plasma.vmt", true);
	PlasmaHalo = PrecacheModel("materials/sprites/plasmahalo.vmt", true);
	Smoke = PrecacheModel("materials/sprites/smoke.vmt", true);
	PrecacheModel("models/effects/combineball.mdl", true);
	PrecacheModel("models/props_combine/headcrabcannister01a.mdl", true);
	PrecacheModel("models/Items/ar2_grenade.mdl", true);
	//War3_PrecacheSound( loop );
	//War3_PrecacheSound( detonade );
	//War3_PrecacheSound( bouncey0 );
	//War3_PrecacheSound( bouncey1 );
	//War3_PrecacheSound( disintegrate0 );
	//War3_PrecacheSound( disintegrate1 );
	//War3_PrecacheSound( charge );
	//War3_PrecacheSound( fire );
	//War3_PrecacheSound( nuke );
	//War3_PrecacheSound( nukefire );
	//War3_PrecacheSound( grenade );
	//War3_PrecacheSound( explode );
}

public OnClientPutInServer(client){
	chargingenergyball[client] = false;
	nukecharge[client] = false;
	kills[client] = false;
	pressdelay[client] = false;
	SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
	SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip);
	SDKHook(client, SDKHook_WeaponDrop, OnWeaponDrop);
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==267){
		thisRaceID = War3_CreateNewRace( "Vip Combine Guard", "combinee" );
		SKILL_HP = War3_AddRaceSkill( thisRaceID, "Armor Plates", "Equip yourself with special Armor Plates", false, 5 );	

		if (GetConVarBool(enableLauncherCvar))
		SKILL_AR2 = War3_AddRaceSkill( thisRaceID, "Assault-Launcher M2", "Gives you an Assault Launcher Mark2 on spawn use the alternativ fire button to launche a grenade", false, 5 );
		else
		SKILL_AR2 = War3_AddRaceSkill( thisRaceID, "Assault-Launcher M2", "Gives you an Assault Launcher Mark2 on spawn", false, 5 );	

		SKILL_NUKE = War3_AddRaceSkill( thisRaceID, "Orbital Strike", "Marks an area and sends down a bomb from the sky!", false, 5 );
		ULT_BALL = War3_AddRaceSkill( thisRaceID, "Energy Ball", "Launches an bouncy energy ball out of your weapon to dissolve enemies!", true, 5 );	
		War3_CreateRaceEnd( thisRaceID );
	}
}

public Action:cmd(client,args)
	kills[client]++;

public bool:OnlyWorld(entity, mask, any:data){
	if(entity == 0){
		return true;
	}
	else{
		return false;
	}
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client)){
		if(!Silenced(client)){
			new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_NUKE);
			if(skill_level>0){
				if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_NUKE,true)){
					if(kills[client] >= killstreak[skill_level])
					{
						kills[client] -= killstreak[skill_level];
						PrintHintText(client,"Orbital Strike\nKill Streak(%i/%i)",kills[client],killstreak[skill_level]);
						War3_CooldownMGR(client,8.0,thisRaceID,SKILL_NUKE,_,_);
						usenukeskill(client);
					}
					else
						PrintHintText(client,"Orbital Strike\nNot enough kills(%i/%i)",kills[client],killstreak[skill_level]);
				}
			}
			else
			{
				PrintHintText(client, "Orbital Strike\nNo Acess!");
			}
		}
		else
		{
			PrintHintText(client, "Silenced!");
		}
	}
}

public OnWar3EventDeath(client,victim)
{
	new race=War3_GetRace(client);
	new skill=War3_GetSkillLevel(client,thisRaceID,SKILL_NUKE);
	if(race==thisRaceID)
	{
		kills[client]++;
		PrintHintText(client,"Orbital Strike\nKill Streak(%i/%i)",kills[client],killstreak[skill]);
	}
	new race_victim=War3_GetRace(victim);
	if(race_victim==thisRaceID)
	{
		kills[client] = 0;
	}
}

public Action:OnWeaponSwitch(client, weapon)
{
	//if(oldweapon[client] == GetPlayerWeaponSlot(client, SLOT))
	//CreateTimer(0.1, setmodel, oldweapon[client]);
	if(ar2[client])
	{
		//oldweapon[client] = weapon;
		//CreateTimer(0.1, setmodel, weapon);
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

public Action:OnWeaponDrop(client, weapon)
{
	if(ar2[client])
	{
		//CreateTimer(0.1, setmodel, weapon);
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

public Action:OnWeaponEquip(client, weapon)
{
	if(ar2[client])
	{
		//CreateTimer(0.1, setmodel, weapon);
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

usenukeskill(client){
	
	decl String:clientname[32];
	GetClientName(client, clientname, 32);

	decl Float:cleyepos[3], Float:cleyeangle[3];
			
	GetClientEyePosition(client, cleyepos);
	GetClientEyeAngles(client, cleyeangle);
	
	new Handle:traceresulthandle = INVALID_HANDLE;
	decl Float:traceresultposition[3], Float:resultnormal[3];
	traceresulthandle = TR_TraceRayFilterEx(cleyepos, cleyeangle, MASK_SOLID, RayType_Infinite, OnlyWorld, 0);
						
	if(TR_DidHit(traceresulthandle)){
		
		TR_GetEndPosition(traceresultposition, traceresulthandle);
		TR_GetPlaneNormal(traceresulthandle, resultnormal);
		

		AddVectors(traceresultposition, resultnormal, traceresultposition);
		

		new Float:upangle[3] = {-90.0, 0.0, 0.0};
		
		new Handle:traceresulthandle2 = INVALID_HANDLE;
		decl Float:skyposition[3];
		traceresulthandle2 = TR_TraceRayFilterEx(traceresultposition, upangle, MASK_SOLID, RayType_Infinite, OnlyWorld, 0);
		
		if(TR_DidHit(traceresulthandle2)){
		
			TR_GetEndPosition(skyposition, traceresulthandle2);
			

			new Float:downangle[3] = {90.0, 0.0, 0.0};
		
			new Handle:traceresulthandle3 = INVALID_HANDLE;
			decl Float:groundposition[3];
			traceresulthandle3 = TR_TraceRayFilterEx(skyposition, downangle, MASK_SOLID, RayType_Infinite, OnlyWorld, 0);
			
			if(TR_DidHit(traceresulthandle3)){
				TR_GetEndPosition(groundposition, traceresulthandle3);
				if(GetVectorDistance(groundposition, skyposition) >= 200.0){

					skyposition[2] = skyposition[2] - 100.0;
					
					new Handle:datapack = CreateDataPack();
					WritePackCell(datapack, GetClientUserId(client));
					WritePackFloat(datapack, skyposition[0]);
					WritePackFloat(datapack, skyposition[1]);
					WritePackFloat(datapack, skyposition[2]);
					
					CreateTimer(SHOWNUKE, firenuke, datapack, TIMER_FLAG_NO_MAPCHANGE & TIMER_DATA_HNDL_CLOSE);
					
				}else{
					new Handle:datapack = CreateDataPack();
					WritePackCell(datapack, GetClientUserId(client));
					WritePackFloat(datapack, groundposition[0]);
					WritePackFloat(datapack, groundposition[1]);
					WritePackFloat(datapack, groundposition[2]);
					
					CreateTimer(SHOWNUKE, justboomnuke, datapack, TIMER_FLAG_NO_MAPCHANGE & TIMER_DATA_HNDL_CLOSE);
				}
			}
			
			if(traceresulthandle3 != INVALID_HANDLE)
				CloseHandle(traceresulthandle3);
		}
		if(traceresulthandle2 != INVALID_HANDLE)
			CloseHandle(traceresulthandle2);
	}
	
	if(traceresulthandle != INVALID_HANDLE)
		CloseHandle(traceresulthandle);	
}

public Action:firenuke(Handle:timer, Handle:datapack){
	ResetPack(datapack);
	new client = GetClientOfUserId(ReadPackCell(datapack));
	
	decl Float:position[3];
	position[0] = ReadPackFloat(datapack);
	position[1] = ReadPackFloat(datapack);
	position[2] = ReadPackFloat(datapack);
	
	new entity = CreateEntityByName("hegrenade_projectile");
	DispatchKeyValue(entity, "classname", NUKENAME);
	SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
	SetEntityTakeDamage(entity, DAMAGE_NO);
	DispatchSpawn(entity);
	SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
	SetEntityModel(entity, "models/props_combine/headcrabcannister01a.mdl");
	SetEntityMoveType(entity, MOVETYPE_FLY);
	//SetEntProp(entity, Prop_Send, "m_CollisionGroup", 9);
	decl Float:angle[3], Float:anglevector[3];
	angle[0] = 90.0;
	angle[1] = 0.0;
	angle[2] = 0.0;

	GetAngleVectors(angle, anglevector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(anglevector, anglevector);
	ScaleVector(anglevector, GetConVarFloat(nukeSpeedCvar));

	angle[0] = 90.0;
	angle[1] = 0.0;
	angle[2] = 0.0;

	TeleportEntity(entity, position, angle, anglevector);
	EmitSoundToAll(nukefire, entity, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, position, NULL_VECTOR, true, 0.0);
	playingrocketsound[entity] = true;

	SetEntityTakeDamage(entity, DAMAGE_YES);

	SDKHook(entity, SDKHook_StartTouch, NukeTouchHook);
	SDKHook(entity, SDKHook_OnTakeDamage, NukeDamageHook);

	return Plugin_Handled;
}

public Action:NukeTouchHook(entity, other){
	
	if(other != 0){
		if(other == GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")){
			
			return Plugin_Continue;
			
		}else{
				return Plugin_Continue;
			}
			
		}
	NukeActive(entity);

	return Plugin_Continue;
}

public Action:NukeDamageHook(entity, &attacker, &inflictor, &Float:damage, &damagetype){
	SetEntProp(entity, Prop_Data, "m_iHealth", GetEntProp(entity, Prop_Data, "m_iHealth") + RoundToNearest(damage));
	if(GetEntProp(entity, Prop_Data, "m_iHealth") >= 200){
		NukeActive(entity);
	}
	return Plugin_Handled;
}



stock NukeActive(entity){
	SDKUnhook(entity, SDKHook_StartTouch, NukeTouchHook);
	SDKUnhook(entity, SDKHook_OnTakeDamage, NukeDamageHook);
	
	if(GetEntProp(entity, Prop_Data, "m_takedamage") == DAMAGE_YES){
	
		SetEntityTakeDamage(entity, DAMAGE_NO);
		decl Float:entityposition[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityposition);
		new client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		AcceptEntityInput(entity, "Kill");
		entityposition[2] = entityposition[2] + 15.0;
		//nukekill(isClientConnectedIngame(client) ? client : 0, entityposition);

		if(War3_GetRace(client)==thisRaceID)
		{
			new skill_level = War3_GetSkillLevel(client,thisRaceID,SKILL_NUKE);
			decl String:explosiondmg[256];
			IntToString(GetRandomInt(Min[skill_level],Max[skill_level]), explosiondmg, sizeof(explosiondmg));
			new explosion = CreateEntityByName("env_explosion");
			SetEntPropEnt(explosion, Prop_Send, "m_hOwnerEntity", client);
			DispatchKeyValue(explosion, "classname", NUKENAME);
			DispatchKeyValue(explosion, "iRadiusOverride", "500");
			DispatchKeyValue(explosion, "iMagnitude", explosiondmg);
			DispatchSpawn(explosion);
			TeleportEntity(explosion, entityposition, NULL_VECTOR, NULL_VECTOR);
			AcceptEntityInput(explosion, "Explode");
			RemoveEdict(explosion);
		}
		
		nukeeffect(entityposition);
	}
	
}

public Action:justboomnuke(Handle:timer, Handle:datapack){
	
	ResetPack(datapack);
	new client = GetClientOfUserId(ReadPackCell(datapack));

	decl Float:position[3];
	position[0] = ReadPackFloat(datapack);
	position[1] = ReadPackFloat(datapack);
	position[2] = ReadPackFloat(datapack);
	//nukekill(isClientConnectedIngame(client) ? client : 0, position);
	if(War3_GetRace(client)==thisRaceID)
	{
		new skill_level = War3_GetSkillLevel(client,thisRaceID,SKILL_NUKE);
		decl String:explosiondmg[256];
		IntToString(GetRandomInt(Min[skill_level],Max[skill_level]), explosiondmg, sizeof(explosiondmg));
		new explosion = CreateEntityByName("env_explosion");
		SetEntPropEnt(explosion, Prop_Send, "m_hOwnerEntity", client);
		DispatchKeyValue(explosion, "classname", NUKENAME);
		DispatchKeyValue(explosion, "iRadiusOverride", "500");
		DispatchKeyValue(explosion, "iMagnitude", explosiondmg);
		DispatchSpawn(explosion);
		TeleportEntity(explosion, position, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(explosion, "Explode");
		RemoveEdict(explosion);
	}
	nukeeffect(position);
}

nukeeffect(const Float:position[3]){
	EmitSoundToAll(nuke, SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, position, NULL_VECTOR, true, 0.0);
	new particle = CreateEntityByName("info_particle_system");
	new String:output[128];
	if(particle != -1){
		DispatchKeyValueVector(particle, "Origin", position);
		
		DispatchKeyValue(particle, "effect_name", "bomb_explosion_huge");
            
		DispatchSpawn(particle);

		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		
		Format(output, 512, "OnUser1 !self:stop:justkill:20.0:1");
		SetVariantString(output);
		AcceptEntityInput(particle, "AddOutput");
		
		Format(output, 512, "OnUser1 !self:kill:justkill:60.0:1");
		SetVariantString(output);
		AcceptEntityInput(particle, "AddOutput");
		
		AcceptEntityInput(particle, "FireUser1");
	}
	
	new hurt = CreateEntityByName("point_hurt");    
	if(hurt != -1){
		DispatchKeyValueFloat(hurt, "DamageRadius", 360.0);
		DispatchKeyValue(hurt, "classname", NUKENAME);
		DispatchKeyValue(hurt, "Damage", "15");
		DispatchKeyValue(hurt, "DamageDelay", "1.5");
		DispatchSpawn(hurt);
		AcceptEntityInput(hurt, "TurnOn");
		TeleportEntity(hurt, position, NULL_VECTOR, NULL_VECTOR);
		CreateTimer( 20.0, Timer_RemoveEntity, hurt );
	}
	TE_SetupGlowSprite(position, GlowSprite, 2.0, 3.0, 255);
	TE_SendToAll();
}

public Action:OnPlayerRunCmd(client, &buttons)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		if(ValidPlayer(client,true))
		{
			new skill_level = War3_GetSkillLevel(client,thisRaceID,SKILL_AR2);
			//if(skill_level>0)
			//{
			if (GetConVarBool(enableLauncherCvar))
			{
				if ((buttons & IN_ATTACK2))
				{
					new ent = W3GetCurrentWeaponEnt(client);
					//if(swep[ent])
					if(ar2[client])
					{
						if (!IsFakeClient(client))
						{
							if (client != -1)
							{
								if (!pressdelay[client])
								{
									pressdelay[client] = true;
									CreateTimer(5.0, ResetPressDelay, client);
									grenadeattack(client,ent,skill_level);
								}
							}
						}
					}
				}
			}
			//}
		}
	}
}

stock grenadeattack(client,item,skill){
	if(item != -1){
		new ammo = GetEntProp(item, Prop_Data, "m_iClip1");
		if(ammo >= 6)
		{
			SetEntProp(item, Prop_Data, "m_iClip1", ammo - 6);
			decl Float:clienteyeangle[3], Float:anglevector[3], Float:clienteyeposition[3], Float:resultposition[3], entity;
			//new skill=War3_GetSkillLevel(client,thisRaceID,SKILL_AR2);
			GetClientEyeAngles(client, clienteyeangle);
			GetClientEyePosition(client, clienteyeposition);
			GetAngleVectors(clienteyeangle, anglevector, NULL_VECTOR, NULL_VECTOR);
			NormalizeVector(anglevector, anglevector);
			AddVectors(clienteyeposition, anglevector, resultposition);
			NormalizeVector(anglevector, anglevector);
			//ScaleVector(anglevector, GetConVarFloat(grenadeSpeedCvar));
			ScaleVector(anglevector, nadespeed[skill]);
			decl Float:playerspeed[3];
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", playerspeed);
			AddVectors(anglevector, playerspeed, anglevector);

			entity = CreateEntityByName("hegrenade_projectile");
			DispatchKeyValue(entity, "classname", LAUNCHERNAME);
			SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
			SetEntityTakeDamage(entity, DAMAGE_NO);
			DispatchSpawn(entity);
			SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
			SetEntityModel(entity, "models/Items/ar2_grenade.mdl");
			SetEntProp(entity, Prop_Send, "m_CollisionGroup", 9);
			EmitSoundToAll(grenade, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, clienteyeposition, NULL_VECTOR, true, 0.0);
			SDKHook(entity, SDKHook_StartTouch, GrenadeTouchHook);
			SDKHook(entity, SDKHook_OnTakeDamage, GrenadeDamageHook);
			SetEntityTakeDamage(entity, DAMAGE_YES);
			TeleportEntity(entity, resultposition, clienteyeangle, anglevector);

			new gascloud = CreateEntityByName("env_smoketrail");
			DispatchKeyValueVector(gascloud,"Origin", resultposition);
			DispatchKeyValueVector(gascloud,"Angles", clienteyeangle);
			new Float:smokecolor[3] = {1.0, 1.0, 1.0};
			new Float:endcolor[3] = {0.0, 0.0, 0.0};
			SetEntPropVector(gascloud, Prop_Send, "m_StartColor", smokecolor);
			SetEntPropVector(gascloud, Prop_Send, "m_EndColor", endcolor);
			SetEntPropFloat(gascloud, Prop_Send, "m_Opacity", 0.2);
			SetEntPropFloat(gascloud, Prop_Send, "m_SpawnRate", 48.0);
			SetEntPropFloat(gascloud, Prop_Send, "m_ParticleLifetime", 1.0);
			SetEntPropFloat(gascloud, Prop_Send, "m_StartSize", 5.0);
			SetEntPropFloat(gascloud, Prop_Send, "m_EndSize", 30.0);
			SetEntPropFloat(gascloud, Prop_Send, "m_SpawnRadius", 0.0);
			SetEntPropFloat(gascloud, Prop_Send, "m_MinSpeed", 0.0);
			SetEntPropFloat(gascloud, Prop_Send, "m_MaxSpeed", 10.0);
			DispatchSpawn(gascloud);
			SetVariantString("!activator");
			AcceptEntityInput(gascloud, "SetParent", entity);
			SetEntPropEnt(entity, Prop_Send, "m_hEffectEntity", gascloud);
			new Float:angle[3] = {0.0, 0.0, 0.0};
			angle[2] = GetRandomFloat(0.0, 45.0);
			fakerecoil(client,angle);
		}
	}
}

public Action:GrenadeTouchHook(entity, other){
	if(other != 0){
		if(other == GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")){
			return Plugin_Continue;
		}
		else{
			if(!IsEntityCollidable(other, true, true, true)){
				return Plugin_Continue;
			}
		}
	}
	GrenadeActive(entity);
	return Plugin_Continue;
}

public Action:GrenadeDamageHook(entity, &attacker, &inflictor, &Float:damage, &damagetype){
	if(GetEntProp(entity, Prop_Data, "m_takedamage") == DAMAGE_YES){
		GrenadeActive(entity);
	}
	return Plugin_Continue;
}

stock GrenadeActive(entity){
	SDKUnhook(entity, SDKHook_StartTouch, GrenadeTouchHook);
	SDKUnhook(entity, SDKHook_OnTakeDamage, GrenadeDamageHook);
	
	if(GetEntProp(entity, Prop_Data, "m_takedamage") == DAMAGE_YES){
	
		SetEntityTakeDamage(entity, DAMAGE_NO);
		decl Float:entityposition[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityposition);
		new client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");

		new gasentity = GetEntPropEnt(entity, Prop_Send, "m_hEffectEntity");
		AcceptEntityInput(gasentity, "Kill");
		AcceptEntityInput(entity, "Kill");
		entityposition[2] = entityposition[2] + 15.0;
		
		if(War3_GetRace(client)==thisRaceID)
		{
			new skill=War3_GetSkillLevel(client,thisRaceID,SKILL_AR2);
			if(skill>0)
			{
				decl String:explosiondmg[99];
				IntToString(GetRandomInt(Min[skill],Max[skill]), explosiondmg, sizeof(explosiondmg));
				new explosion = CreateEntityByName("env_explosion");
				SetEntPropEnt(explosion, Prop_Send, "m_hOwnerEntity", client);
				DispatchKeyValue(explosion, "classname", LAUNCHERNAME);
				DispatchKeyValue(explosion, "iMagnitude", explosiondmg);
				DispatchKeyValue(explosion, "spawnflags", "128");
				DispatchSpawn(explosion);
				TeleportEntity(explosion, entityposition, NULL_VECTOR, NULL_VECTOR);
				AcceptEntityInput(explosion, "Explode");
				RemoveEdict(explosion);
			}
		}
		EmitSoundToAll(explode, SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, entityposition, NULL_VECTOR, true, 0.0);
	}
}

public Action:ResetPressDelay(Handle:timer, any:index)
{
	if (index != -1)
		pressdelay[index] = false;
}

public OnWar3EventSpawn( client )
{
	new race = War3_GetRace( client );
	if( race == thisRaceID )
	{
		chargingenergyball[client] = false;
		nukecharge[client] = false;
		AR2(client,race);
		Armor(client,race);
	}
}

stock Armor(client,this_race)
{
	new skill=War3_GetSkillLevel(client,this_race,SKILL_HP);
	if(skill>0)
	{
		new health = hpadd[skill];
		SetEntityHealth(client,GetClientHealth(client)+health);
		PrintToChat(client,"\x04[Armor Plates]\x03Gained addintional %i health",health);
		W3SetPlayerColor(client,thisRaceID,200,200,255,230,1);
	}
}

stock AR2(client,this_race)
{
	new skill=War3_GetSkillLevel(client,this_race,SKILL_AR2);
	if(skill>0)
	{
		//new primweapon = GetPlayerWeaponSlot(client, SLOT);
		//RemoveEdict(primweapon);
		//new ent = GivePlayerItem(client,ROCKETWEAPON);
		//ar2[client] = true;
		CreateTimer(0.2, giveweapon, client);
		//CreateTimer(0.4, setmodel, ent);
		PrintToChat(client,"\x03You gained an Assault Launcher M2");
		//CreateTimer(0.2, giveweapon, client);
	}
}

public Action:giveweapon(Handle:timer, any:client)
{
	if(client != -1)
	{
		new ent = GivePlayerItem(client,ROCKETWEAPON);
		ar2[client] = true;
		//CreateTimer(0.2, setmodel, ent);
		PrintToChat(client,"\x03You gained an Assault Launcher M2");
	}
}

//public Action:setmodel(Handle:timer, any:ent)
//{
//	if(ent != -1 && IsValidEdict(ent))
//	{
//		SetEntData( ent, itemmdl, ar2mdl, 4);
//		SetEntProp( ent, Prop_Send, "m_nModelIndex", ar2mdl);
//		SetEntProp( ent, Prop_Send, "m_iWorldModelIndex", ar2mdl);
//		//if(!swep[ent])
//	}
//}

public OnRaceChanged(client,oldrace,newrace)
{
	if( newrace != thisRaceID )
	{
		W3ResetPlayerColor(client,thisRaceID);
		W3ResetAllBuffRace(client,thisRaceID);
	}
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && IsPlayerAlive(client))
	{
		new skill=War3_GetSkillLevel(client,race,ULT_BALL);
		if(skill>0)
		{
			if(War3_SkillNotInCooldown(client,thisRaceID,ULT_BALL,true)&&!Silenced(client))
			{
				Energyball(client);
				new Float:ult_cooldown=GetConVarFloat(ultCooldownCvar);
				War3_CooldownMGR(client,ult_cooldown,thisRaceID,ULT_BALL,_,_);
			}
		}
		else
		{
			W3MsgUltNotLeveled(client);
		}
	}
}

stock Energyball(client)
{
	chargingenergyball[client] = true;
	decl Float:clienteyeposition[3];
	GetClientEyePosition(client, clienteyeposition);
	EmitSoundToAll(charge, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, clienteyeposition, NULL_VECTOR, true, 0.0);
	CreateTimer(GetConVarFloat(chargeTimeCvar)+0.2, BallSleep, client);
}

public Action:BallSleep(Handle:timer, any:client)
{
	if( ValidPlayer( client, true ) && IsPlayerAlive( client ) && chargingenergyball[client])
		Launch(client);
}

stock Launch(client){
	decl Float:clienteyeangle[3], Float:anglevector[3], Float:clienteyeposition[3], Float:resultposition[3], entity;
	GetClientEyeAngles(client, clienteyeangle);
	GetClientEyePosition(client, clienteyeposition);
	GetAngleVectors(clienteyeangle, anglevector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(anglevector, anglevector);
	ScaleVector(anglevector, 10.0);
	AddVectors(clienteyeposition, anglevector, resultposition);
	NormalizeVector(anglevector, anglevector);
	ScaleVector(anglevector, GetConVarFloat(projectileSpeedCvar));
	decl Float:playerspeed[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", playerspeed);
	AddVectors(anglevector, playerspeed, anglevector);
	entity = CreateEntityByName("hegrenade_projectile");
	DispatchKeyValue(entity, "classname", WEAPONNAME);
	SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
	chargingenergyball[client] = false;
	SDKHook(entity, SDKHook_OnTakeDamage, EnergyBallDamageHook);
	SDKHook(entity, SDKHook_StartTouch, EnergyBallTouchHook);
	SDKHook(entity, SDKHook_Touch, EnergyBallTouchHook2);
	SetEntPropFloat(entity, Prop_Send, "m_flElasticity", 9999.0);
	SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
	//SetEntProp(entity, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_NPC);
	SetEntProp(entity, Prop_Send, "m_CollisionGroup", 9);
	energyballtouchcount[entity] = 0;
	SetEntityTakeDamage(entity, DAMAGE_NO);
	DispatchSpawn(entity);
	SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
	SetEntityRenderMode(entity, RENDER_GLOW);
	SetEntityModel(entity, "models/effects/combineball.mdl");
	new Float:vecmax[3] = {8.0, 8.0, 8.0};
	new Float:vecmin[3] = {-8.0, -8.0, -8.0};
	SetEntPropVector(entity, Prop_Send, "m_vecMins", vecmin);
	SetEntPropVector(entity, Prop_Send, "m_vecMaxs", vecmax);
	SetEntProp(entity, Prop_Send, "m_fEffects", GetEntProp(entity, Prop_Send, "m_fEffects") | EF_NOSHADOW);
	SetEntityMoveType(entity, MOVETYPE_FLY);
	TeleportEntity(entity, resultposition, clienteyeangle, anglevector);
	TE_SetupBeamFollow(entity,Smoke,0,2.1,2.0,3.0,20,{255,255,255,255});
	TE_SendToAll();
	playingenergyballsound[entity] = true;
	EmitSoundToAll(fire, entity, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, clienteyeposition, NULL_VECTOR, true, 0.0);
	EmitSoundToAll(loop, entity, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, clienteyeposition, NULL_VECTOR, true, 0.0);
	CreateTimer(GetConVarFloat(lifeTimeCvar), energyballtimer, EntIndexToEntRef(entity));
	SetEntityTakeDamage(entity, DAMAGE_YES);
	new Float:angle[3] = {0.0, 0.0, 0.0};
	angle[0] = -3.0;
	angle[1] = GetRandomFloat(-7.0, 7.0);
	angle[2] = GetRandomFloat(-28.0, 28.0);
	fakerecoil(client,angle);
}

public OnEntityDestroyed(entity)
{
	if(playingrocketsound[entity])
	{
		StopSound(entity, SNDCHAN_AUTO,nukefire);
		playingrocketsound[entity] = false;
		
	}
	if(playingenergyballsound[entity])
	{
		//stopentitysound(entity, SOUNDENERGYBALLLOOP);
		StopSound(entity, SNDCHAN_AUTO,loop);
		playingenergyballsound[entity] = false;
	}
}

public Action:EnergyBallDamageHook(entity, &attacker, &inflictor, &Float:damage, &damagetype){
	return Plugin_Handled;
}

stock bool:isClientConnectedIngame(client){
	if(client > 0 && client <= MaxClients){
		if(IsClientInGame(client) == true){
			return true;
		}else{
			return false;	
		}
	}else{
		return false;
	}
}

stock W3DissolveClassname( const String:target[] )
{
	new dissolver = CreateEntityByName("env_entity_dissolver");
	if(dissolver != 0)
	{
		new String:SName[128];
		Format(SName, sizeof(SName), "dissolver_%i", target);
		DispatchKeyValue(dissolver,"magnitude", "50");
		DispatchKeyValue(dissolver,"dissolvetype", "1");
		DispatchKeyValue(dissolver,"target", target);
		DispatchSpawn(dissolver);
		AcceptEntityInput(dissolver, "Dissolve");
		CreateTimer( 1.20, Timer_RemoveEntity, dissolver );
	}
}

stock remove_hostage(other)
{
	DispatchKeyValue(other, "classname", DISSOLVECLASSNAME);
	W3DissolveClassname(DISSOLVECLASSNAME);
}

public Action:Timer_RemoveEntity( Handle:timer, any:ent )
{
	if (IsValidEntity(ent))
	   AcceptEntityInput(ent,"Kill");
}

public Action:EnergyBallTouchHook(entity, other){
	decl Float:entityposition[3], Float:entityspeed[3], Float:entityangle[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityposition);
	GetEntPropVector(entity, Prop_Send, "m_vecVelocity", entityspeed);
	GetEntPropVector(entity, Prop_Send, "m_angRotation", entityangle);
	
	TE_SetupEnergySplash(entityposition, entityangle, true); 
	TE_SendToAll();
	new client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(other != 0){
		if(other == client){
			return Plugin_Continue;
		}
		else{
			if(!IsEntityCollidable(other, true, true, true)){
				return Plugin_Continue;
			}
		}
		new dice = GetRandomInt(0,1);
		if(dice==1)
		{
			EmitSoundToAll(disintegrate1, SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, entityposition, NULL_VECTOR, true, 0.0);
		}
		else
		{
			EmitSoundToAll(disintegrate0, SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, entityposition, NULL_VECTOR, true, 0.0);
		}
		if(isClientConnectedIngame(client))
		{
			PrintToConsole(client,"[debug] energyball found target");
			decl String:classname[64];
			GetEdictClassname(other, classname, 64);
			if(StrEqual(classname, "hostage_entity", false))
			{
				remove_hostage(other);
			}
			else
			{
				new user_race = War3_GetRace(client);
				if (user_race == thisRaceID)
				{
					new skill=War3_GetSkillLevel(client,thisRaceID,ULT_BALL);
					if(skill)
					   War3_DealDamage(other,EnergyBall[skill],client,DMG_DISSOLVE,WEAPONNAME,W3DMGORIGIN_SKILL,W3DMGTYPE_MAGIC);
				}
			}
		}
	}
	else{
		new bouncer = GetRandomInt(0,1);
		if(bouncer==1)
		{
			EmitSoundToAll(bouncey1, SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, entityposition, NULL_VECTOR, true, 0.0);
		}
		else
		{
			EmitSoundToAll(bouncey0, SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, entityposition, NULL_VECTOR, true, 0.0);
		}
	}
	
	energyballtouchcount[entity]++;
		
	if(energyballtouchcount[entity] >= GetConVarInt(touchLimitCvar) && GetConVarInt(touchLimitCvar) > 0){
		
		energyballtimer(INVALID_HANDLE, EntIndexToEntRef(entity));
		
	}
	else{
		if(GetVectorLength(entityspeed) <= 1.0){
			
			entityspeed[0] = GetRandomFloat();
			entityspeed[1] = GetRandomFloat();
			entityspeed[2] = GetRandomFloat();
			
		}
		NormalizeVector(entityspeed, entityspeed);
		ScaleVector(entityspeed, GetConVarFloat(projectileSpeedCvar));
		decl Float:angle[3];
		GetVectorAngles(entityspeed, angle);
		TeleportEntity(entity, NULL_VECTOR, angle, entityspeed);
	}
	return Plugin_Continue;
}

public Action:EnergyBallTouchHook2(entity, other){
	decl Float:entityposition[3], Float:entityspeed[3], Float:entityangle[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityposition);
	GetEntPropVector(entity, Prop_Send, "m_vecVelocity", entityspeed);
	GetEntPropVector(entity, Prop_Send, "m_angRotation", entityangle);
	if(GetVectorLength(entityspeed) <= 1.0){
		
		entityspeed[0] = GetRandomFloat();
		entityspeed[1] = GetRandomFloat();
		entityspeed[2] = GetRandomFloat();
		
	}
	
	NormalizeVector(entityspeed, entityspeed);
	ScaleVector(entityspeed, GetConVarFloat(projectileSpeedCvar));
	decl Float:angle[3];
	GetVectorAngles(entityspeed, angle);
	TeleportEntity(entity, NULL_VECTOR, angle, entityspeed);
	
	return Plugin_Continue;
	
}

public Action:energyballtimer(Handle:timer, any:entref){
	new entity = EntRefToEntIndex(entref);
	if(entity != -1){
		decl Float:entityposition[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityposition);
		AcceptEntityInput(entity, "Kill");
		EmitSoundToAll(detonade, SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, entityposition, NULL_VECTOR, true, 0.0);
		TE_SetupBeamRingPoint(entityposition, 1.0, 300.0, PlasmaBeam, PlasmaHalo, 0, 10, 0.8, 20.0, 1.5, {255,255,255,255}, 1600, FBEAM_SINENOISE);
		TE_SendToAll();
		new Float:dirangle[3] = {-90.0, 0.0, 0.0};
		new Float:dir[3];
		GetAngleVectors(dirangle, dir, NULL_VECTOR, NULL_VECTOR);
		TE_SetupSparks(entityposition, dir, 200, 200);
		TE_SendToAll();
		TE_SetupExplosion(entityposition, Explosion, 0.5, 50, EXPLOSIONFLAGS, 0, 0);
		TE_SendToAll();
	}
}

stock fakerecoil(client, Float:angle[3]){
	decl Float:oldangle[3];
	GetEntPropVector(client, Prop_Send, "m_vecPunchAngle", oldangle);
	oldangle[0] = oldangle[0] + angle[0];
	oldangle[1] = oldangle[1] + angle[1];
	oldangle[2] = oldangle[2] + angle[2];
	SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", oldangle);
	SetEntPropVector(client, Prop_Send, "m_vecPunchAngleVel", angle);
}

stock SetEntityTakeDamage(entity, type){
	SetEntProp(entity, Prop_Data, "m_takedamage", type);
}

stock bool:IsEntityCollidable(entity, bool:includeplayer = true, bool:includehostage = true, bool:includeprojectile = true){
	
	decl String:classname[64];
	GetEdictClassname(entity, classname, 64);
	if((StrEqual(classname, "player", false) && includeplayer) || (StrEqual(classname, "hostage_entity", false) && includehostage)
		||StrContains(classname, "physics", false) != -1 || StrContains(classname, "prop", false) != -1
		|| StrContains(classname, "door", false)  != -1 || StrContains(classname, "weapon", false)  != -1
		|| StrContains(classname, "break", false)  != -1 || ((StrContains(classname, "projectile", false)  != -1) && includeprojectile)
		|| StrContains(classname, "brush", false)  != -1 || StrContains(classname, "button", false)  != -1
		|| StrContains(classname, "physbox", false)  != -1 || StrContains(classname, "plat", false)  != -1
		|| StrEqual(classname, "func_conveyor", false) || StrEqual(classname, "func_fish_pool", false)
		|| StrEqual(classname, "func_guntarget", false) || StrEqual(classname, "func_lod", false)
		|| StrEqual(classname, "func_monitor", false) || StrEqual(classname, "func_movelinear", false)
		|| StrEqual(classname, "func_reflective_glass", false) || StrEqual(classname, "func_rotating", false)
		|| StrEqual(classname, "func_tanktrain", false) || StrEqual(classname, "func_trackautochange", false)
		|| StrEqual(classname, "func_trackchange", false) || StrEqual(classname, "func_tracktrain", false)
		|| StrEqual(classname, "func_train", false) || StrEqual(classname, "func_traincontrols", false)
		|| StrEqual(classname, "func_vehicleclip", false) || StrEqual(classname, "func_traincontrols", false)
		|| StrEqual(classname, "func_water", false) || StrEqual(classname, "func_water_analog", false)){
		return true;
	}
	return false;
}