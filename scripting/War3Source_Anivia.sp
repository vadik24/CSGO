/**
* File: War3Source_Anivia.sp
* Description: blah blah blah
* Author(s): Revan
*/
#pragma semicolon 1
#include <sourcemod>
#undef REQUIRE_EXTENSIONS
//#include "W3SIncs/mana"
#define REQUIRE_EXTENSIONS
#include <sdktools>
#include "sdkhooks"
#include "W3SIncs/War3Source_Interface"
public W3ONLY(){}

// Cryophoenix Anivia
new thisRaceID;
new SKILL_1, SKILL_2, SKILL_3, ULT;
new Handle:ultCooldownCvar=INVALID_HANDLE;
new Handle:shardSpeedCvar=INVALID_HANDLE;
new PlasmaBeam,Glow,LaserSprite,BeamSprite,HaloSprite;
new Handle:hUltimateEndTimer[MAXPLAYERS]=INVALID_HANDLE;
new iManaValue[MAXPLAYERS]=0;
new iGlacialEntity[MAXPLAYERS]=-1;
new iFlashFrostEnt[MAXPLAYERS]=-1;
new bool:bUltActive[MAXPLAYERS]=false;
new bool:bChilled[MAXPLAYERS]=false;
new bool:bFrosted[MAXPLAYERS]=false;//same as chilled but this is used for the ultimate(to avoid overwrite)
new bool:bOverlayed[MAXPLAYERS]=false;
new bool:bExtension=false;
new FlashFrostDmg[5] = {0,3,5,7,9};
new Float:FlashFrostLifetime[5] = {0.0,5.0,8.0,10.0,12.0};
new Float:CondenseDuration[5] = {0.0,4.0,6.0,8.0,8.0};//{0.0,2.0,4.0,6.0,8.0};
new Float:BiteChanceArr[5]={0.0,0.20,0.35,0.40,0.45};
new BiteDamageArray[5]={0,2,3,4,5};
new Float:GlacialMaxDistance[5] = {0.0,650.0,800.0,850.0,900.0};
new Float:GlacialMaxRadius[5] = {0.0,250.0,300.0,350.0,360.0};//{0.0,320.0,360.0,420.0,460.0};
new Float:GlacialMaxTime[5] = {0.0,10.0,12.0,14.0,16.0};
new Float:GlacialSlowdown[5] = {1.0,0.90,0.85,0.80,0.78};
new GlacialDamagePerTick[5] = {0,2,4,6,6};
//Defines from SourceEngine
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
//new String:explode[] = "ambient/explosions/explode_2.mp3";
new String:flash1[] = "physics/glass/glass_largesheet_break1.mp3";
new String:flash2[] = "physics/glass/glass_largesheet_break2.mp3";
new String:flash3[] = "physics/glass/glass_largesheet_break3.mp3";
new String:crystallize[] = "physics/concrete/boulder_impact_hard1.mp3";//"ui/freeze_cam.mp3";
new String:glacial[] = "ambient/levels/canals/windmill_wind_loop1.mp3";

public Plugin:myinfo = {
	name = "War3Source Race - Anivia",
	author = "Revan",
	description = "Anivia(from LoL) for the Source Engine's war3source",
	version = "1.1",
	url = "www.wcs-lagerhaus.de"
};

public APLRes:AskPluginLoad2Custom(Handle:myself,bool:late,String:error[],err_max)
{
	MarkNativeAsOptional("W3GetMana");
	MarkNativeAsOptional("W3SetMana");
	MarkNativeAsOptional("W3ToggleMana");
	MarkNativeAsOptional("W3SetManaRegen");
	return APLRes_Success;
}

public OnPluginStart()
{
	if(War3_GetGame()!=Game_CS){
		//the entities used by this race are only avaible in css..
		//someone needs to make a engine that uses predcrabs CEntity framework to add a similar entity to the game xD
		SetFailState("This game is not supported by this Race - Sorry!");
	}
	if(GetExtensionFileStatus("w3mana.ext") == 1) {
		PrintToServer("[Anivia] Extension found, using w3mana system");
		bExtension=true;
	}
	RegServerCmd("war3_anivia_whichmode",Command_GetMode);
	LoadTranslations("w3s.race.anivia.phrases");
	ultCooldownCvar=CreateConVar("war3_anivia_ult_cooldown","6.0","The ultimate cooldown for Anivia's Ultimate");
	shardSpeedCvar=CreateConVar("war3_anivia_shard_speed","380.0","How fast should the shard travel?");
	CreateTimer(1.0,UpdateMana,_,TIMER_REPEAT);
}

public Action:Command_GetMode(args){
	if(bExtension==false) {
		PrintToServer("[Anivia] W3Mana ext. not found using standalone mana system instead...");
	}
	else {
		PrintToServer("[Anivia] Using W3Mana extension.");
	}
}

public OnWar3PluginReady(){
	/*
	Cryophoenix Anivia
	Skills:
	==================================================F L A S H - F R O S T=======================================================================
	--Original--
	Anivia summons a shard of ice that flies on a line.
	The shard will deal magic damage and slow by 20% for 3 seconds to anyone in its path.
	The shard will detonate when reaching its max range or if the ability is activated again.
	When the shard explodes it will deal magic damage to all enemies nearby, stunning them for 1 second.
	The magic damage done by both the shard and the detonation is the same, and both will apply the "chilled" debuff on enemies hit for 3 seconds. 
	--War3Source-- (ability0)
	Throws shard of ice that flies on a line.
	The Shard will apply damage and slows anyone in its path.
	It will detonate when reaching its max range(or hits a wall) or the ability is activated again.
	==============================================================================================================================================
	
	==================================================C R Y S T A L L I Z E=======================================================================
	--Original--
	Anivia condenses the moisture in the air into an impenetrable wall of ice to block the movement of all units.
	The wall lasts 5 seconds before it melts.  
	--War3Source-- (ability1)
	Condense moisture in the air into a solid wall of ice(wall will remain for up to 8 seconds).
	==============================================================================================================================================
	
	==================================================F R O S T B I T E===========================================================================
	--Original--
	Anivia blasts her target with a freezing wind, dealing magic damage.
	If the target has been "chilled" by Anivia's other abilities, they will take double damage. 
	--War3Source-- (passive on attack)
	Blasts your target with a freezing wind to deal magical damage.
	If the target has been frosted by one of your other abilites, they will take a way more damage!
	==============================================================================================================================================
	
	==================================================G L A C I A L - S T O R M===================================================================
	--Original--
	Anivia summons a driving rain of ice and hail on a nearby target area to continuously deal magic damage to enemies on it, slowing their movement and attack speed by 20% for 1 second, and "chilling" them. 
	--War3Source-- (ultimate)
	Summons a driving rain of ice and hail on a nearby target area to continuously deal magic damage and slow them down by 20%
	==============================================================================================================================================
	*/
	thisRaceID=War3_CreateNewRaceT("anivia");
	SKILL_1=War3_AddRaceSkillT(thisRaceID,"FlashFrost",false,4);
	SKILL_2=War3_AddRaceSkillT(thisRaceID,"Crystallize",false,4);
	SKILL_3=War3_AddRaceSkillT(thisRaceID,"Frostbite",false,4);
	ULT=War3_AddRaceSkillT(thisRaceID,"Glacialstorm",true,4); 
	War3_CreateRaceEnd(thisRaceID); ///DO NOT FORGET THE END!!!
	if(bExtension) {
		W3ManaSystem(thisRaceID,true);
	}
}

public Action:UpdateMana(Handle:h,any:data){
	if(bExtension==false) {
		for(new i=1;i<=MaxClients;i++){
			if(ValidPlayer(i,true)){
				if(War3_GetRace(i)==thisRaceID){
					if(iManaValue[i]<=100) {
						//using hint engine instead of this...PrintCenterText(i,"Mana: %i/100",iManaValue[i]);
						W3Hint(i,HINT_LOWEST,1.0,"Mana: %i/100",iManaValue[i]);
						iManaValue[i]++;
					}
				}
			}
		}
	}
}

public OnClientPutInServer(client) {	
	ResetArrayVals(client);
}

public OnRaceChanged(client,oldrace,newrace) {
	/*if(bExtension) {
		if(newrace==thisRaceID) {
			W3ToggleMana(client,thisRaceID,true);
		}
		else {
			W3ToggleMana(client,thisRaceID,false);
			W3ResetAllBuffRace(client,thisRaceID);
		}
	}*/
	ResetArrayVals(client);
}

ResetArrayVals(client) {
	if(client>0) {
		War3_SetBuff(client,fSlow,thisRaceID,1.0);
		War3_SetBuff(client,fAttackSpeed,thisRaceID,1.0);
		W3ResetPlayerColor(client,thisRaceID);
		bUltActive[client]=false;
		bChilled[client]=false;
		bFrosted[client]=false;
		bOverlayed[client]=false;
		iManaValue[client]=0;
		iFlashFrostEnt[client]=-1;
		iGlacialEntity[client]=-1;
		hUltimateEndTimer[client]=INVALID_HANDLE;
	}
}

public OnWar3EventSpawn(client)
{
	if(ValidPlayer(client, false))
	{	
		if(bOverlayed[client]) {
			ClientCommand(client, "r_screenoverlay 0");
		}
		ResetArrayVals(client);
		if(bExtension) W3SetManaRegen(client,1);
	}
}

public OnWar3EventDeath(victim,attacker){
	if(ValidPlayer(victim,false)) {
		new entity = iGlacialEntity[victim];
		if(entity>0&&IsValidEntity(entity)) {
			AcceptEntityInput(entity, "Kill");
		}
		bUltActive[victim]=false;
		if(bExtension) W3SetManaRegen(victim,0);
	}
}

public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		if(IsPlayerAlive(attacker)&&IsPlayerAlive(victim)&&GetClientTeam(victim)!=GetClientTeam(attacker))
		{
			new Float:chance_mod=W3ChanceModifier(attacker);
			if(War3_GetRace(attacker)==thisRaceID && !W3HasImmunity(victim,Immunity_Skills))
			{
				new skill_level = War3_GetSkillLevel(attacker,thisRaceID,SKILL_3);
				if(!Hexed(attacker,false)&&GetRandomFloat(0.0,1.0)<=chance_mod*BiteChanceArr[skill_level])
				{
					new dmg = BiteDamageArray[skill_level];					
					new Float:fClientPos[3];
					GetClientAbsOrigin(victim,fClientPos);
					decl Float:fClientEyePos[3];
					GetClientEyePosition(attacker, fClientEyePos);
					fClientPos[2]+=20.0;
					ThrowAwayParticle("water_splash_01_refract", fClientPos, 1.5); //"slime_splash_01"
					fClientPos[2]+=20.0;
					if(bChilled[victim] || bFrosted[victim]) {
						War3_DamageModPercent(1.4);
						ThrowAwayParticle("water_impact_bubbles_1d", fClientPos, 1.5);						
					}
					fClientPos[2]+=10.0;
					TE_SetupBeamRingPoint(fClientPos,10.0,200.0,BeamSprite,HaloSprite,0,10,1.5,32.0,2.0,{120,120,255,255},12,0);
					TE_SendToAll();
					//TE_SetupBeamPoints(fPos, TargetPos, LaserSprite, HaloSprite, 0, 25, 2.0, 150.0, 200.0, 1, 2.0, {255,120,55,255}, 20);
					TE_SetupBeamPoints(fClientPos,fClientEyePos,BeamSprite,HaloSprite,0,35,1.25,30.0,10.0,0,0.5,{135,135,255,255},10);
					TE_SendToAll();
					//War3_DealDamage(victim,dmg,attacker,DMG_ENERGYBEAM,"frostbite",W3DMGORIGIN_SKILL,W3DMGTYPE_MAGIC);
					DealDamageWorkaround(victim,attacker,dmg,"frostbite");
					PrintHintText(attacker,"%T","You've used Frostbite on your target causing {damage} extra damage!",attacker,dmg);
				}
			}
		}
	}
}

#define PROJECTILE_NAME "w3s_shard"
#define CONDENSE_NAME "w3s_wall"
#define PROJECTILE_MDL1 "models/props_junk/ibeam01a.mdl"//"models/props_c17/trappropeller_lever.mdl"
#define CONDENSE_MDL1 "models/props_lab/blastdoor001c.mdl"
//#define GLACIAL_MDL1 "models/effects/portalrift.mdl"
#define LASER_SPRITE "materials/sprites/laserbeam.vmt"

//new Float:PROJECTILE_SPEED=280.0;
new Float:PROJECTILE_IGNORETME=1.80;
new Float:PROJECTILE_RADIUS=80.0;
new CONDENSE_STRENGTH=600;

public OnMapStart(){
	//War3_PrecacheSound(flash1);
	//War3_PrecacheSound(flash2);
	//War3_PrecacheSound(flash3);
	//War3_PrecacheSound(crystallize);
	//War3_PrecacheSound(glacial);
	PrecacheModel(PROJECTILE_MDL1);
	PrecacheModel(CONDENSE_MDL1);
	Glow = PrecacheModel("materials/particle/fire.vmt");
	LaserSprite = PrecacheModel(LASER_SPRITE);
	HaloSprite = PrecacheModel( "materials/sprites/halo01.vmt" );
	BeamSprite = PrecacheModel( "materials/sprites/laser.vmt" );
	PlasmaBeam = PrecacheModel( "materials/sprites/plasmabeam.vmt" );
	if(bExtension==false) {
		if(GetExtensionFileStatus("w3mana.ext") == 1) {
			PrintToServer("[Anivia] Extension found, using w3mana system");
			W3ManaSystem(thisRaceID,true);
			bExtension=true;
		}
	}
	else {
		W3ManaSystem(thisRaceID,true);
	}
}

public ShardTouchHook(entity, other)
{
	new client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	War3_CooldownMGR(client,8.0,thisRaceID,SKILL_1,true,true);
	RemoveShard(entity);//remove the shard on hit	
}

public Action:ShardThink( Handle:timer, any:entity )
{
	if (IsValidEntity(entity)) {
		new client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		if(ValidPlayer(client,false)) {
			for(new i=1; i<= MaxClients; i++)
			{
				if(ValidPlayer(i,true) && GetClientTeam(client) != GetClientTeam(i) && !W3HasImmunity(i,Immunity_Skills) && !bChilled[i]) //target is alive, not immune, a enemy and not frosted..
				{
					new skill=War3_GetSkillLevel(client,thisRaceID,ULT);
					if(skill>0) {				
						decl Float:fEntityPos[3];
						GetEntPropVector(entity, Prop_Send, "m_vecOrigin", fEntityPos);
						new Float:fTargetPos[3];
						GetClientAbsOrigin(i, fTargetPos);
						if(GetVectorDistance(fEntityPos,fTargetPos) <= PROJECTILE_RADIUS)
						{
							War3_DealDamage(i,FlashFrostDmg[skill],client,DMG_DISSOLVE,PROJECTILE_NAME,W3DMGORIGIN_SKILL,W3DMGTYPE_MAGIC);
							decl Float:fClientEyePos[3];
							GetClientEyePosition(i, fClientEyePos);
							fClientEyePos[2]-=50;
							TE_SetupBeamRingPoint(fEntityPos,45.0,295.0,BeamSprite,HaloSprite,0,10,1.2,12.0,0.0,{100,100,255,255},0,0);
							TE_SendToAll();
							//ThrowAwayParticle("water_impact_bubbles_1d", fClientEyePos, 1.6);
							bChilled[i]=true;
							War3_SetBuff(i,fSlow,thisRaceID,0.82);
							War3_SetBuff(i,fAttackSpeed,thisRaceID,0.85);
							W3FlashScreen(i,RGBA_COLOR_BLUE,PROJECTILE_IGNORETME);
							W3SetPlayerColor(i,thisRaceID, 120, 120, 255, _, GLOW_SKILL);//marks the target as chilled OR frosted
							CreateTimer(PROJECTILE_IGNORETME,Timer_RemoveChill,i);
						}
					}
				}
			}
			//think again and again till the entity is destroyed...
			CreateTimer(0.1, ShardThink, entity);
		}
	}
}

public Action:Timer_RemoveChill(Handle:timer,any:client)
{
	if(ValidPlayer(client,true))
	{
		bChilled[client]=false;
		War3_SetBuff(client,fSlow,thisRaceID,1.0);
		War3_SetBuff(client,fAttackSpeed,thisRaceID,1.0);
		W3ResetPlayerColor(client,thisRaceID);
	}
}

public Action:ShardDamageHook(entity, &attacker, &inflictor, &Float:damage, &damagetype){
	//PrintToChatAll("shard got damaged (damage: %f ?)",damage);
	decl Float:fEntityPos[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", fEntityPos);
	new Float:fAngles[3]={0.0,0.0,0.0};
	TE_SetupSparks(fEntityPos, fAngles, 28, 20);
	TE_SendToAll();
	return Plugin_Handled;
}

public Action:Timer_ShardOvertime( Handle:timer, any:ent )
{
	if (IsValidEntity(ent)) {
		decl String:classname[64];
		GetEdictClassname(ent, classname, sizeof(classname));
		if(StrEqual(classname, PROJECTILE_NAME, false))
		{
			RemoveShard(ent);
		}
	}
}

stock DealAreaDamage(owner,Float:fPos[3],Float:fRadius)
{
	for(new i=1; i<= MaxClients; i++)
	{
		if(ValidPlayer(i,true) && GetClientTeam(owner) != GetClientTeam(i) && !W3HasImmunity(i,Immunity_Skills)) //target is alive, not immune and an enemy..
		{
			new Float:enemyVec[3];
			GetClientAbsOrigin(i, enemyVec);
			if(GetVectorDistance(enemyVec,fPos) <= fRadius)
			{
				War3_DealDamage(i,50,owner,DMG_BULLET,"flashfrost");
				if(!bChilled[i])
				{
					bChilled[i]=true;
					War3_SetBuff(i,fSlow,thisRaceID,0.75);
					War3_SetBuff(i,fAttackSpeed,thisRaceID,0.80);
					W3SetPlayerColor(i,thisRaceID, 120, 120, 255, _, GLOW_SKILL);
					CreateTimer(PROJECTILE_IGNORETME,Timer_RemoveChill,i);
				}
			}
		}
	}
}

stock RemoveShard(ent) {
	decl Float:fEntityPos[3];
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", fEntityPos);
	new client = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
	decl String:buffer[64];
	new dice = GetRandomInt(0,2);
	if(dice==0) {
		buffer = flash1;
	}
	else if(dice==1) {
		buffer = flash2;
	}
	else {
		buffer = flash3;
	}
	EmitSoundToAll(buffer, ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, fEntityPos, NULL_VECTOR, true, 0.0);
	SDKUnhook(ent, SDKHook_StartTouch, ShardTouchHook);
	SDKUnhook(ent, SDKHook_OnTakeDamage, ShardDamageHook);
	AcceptEntityInput(ent, "Kill");
	TE_SetupBeamRingPoint(fEntityPos,10.0,250.0,BeamSprite,HaloSprite,0,10,0.3,25.0,0.0,{20,20,255,255},8,0);
	TE_SendToAll();
	TE_SetupExplosion(fEntityPos, BeamSprite, 10.0,1,0,0,0);
	TE_SendToAll();
	DealAreaDamage(client,fEntityPos,180.0);
}

public Action:Timer_RemoveEntity(Handle:timer,any:i)if(IsValidEdict(i))AcceptEntityInput(i,"Kill");

stock W3_SpearLaunch(client,skill){
	new shard = iFlashFrostEnt[client];
	if(shard>0) {
		if (IsValidEntity(shard)) {
			decl String:classname[64];
			GetEdictClassname(shard, classname, sizeof(classname));
			if(StrEqual(classname, PROJECTILE_NAME, false))
			{
				RemoveShard(shard);
				War3_CooldownMGR(client,8.0,thisRaceID,SKILL_1,true,true);
			}
			else {
				iFlashFrostEnt[client]=-1;
				W3_SpearLaunch(client,skill);
			}
		}
		else {
			iFlashFrostEnt[client]=-1;
			W3_SpearLaunch(client,skill);
		}		
	}
	else {
		new old_mana = GetManaWrapper(client);
		if(old_mana>=10) {
			SetManaWrapper(client,old_mana-10);
			decl Float:fClientEyeAngle[3], Float:fClientEyePos[3], Float:fAngleVec[3], Float:fResultPos[3];
			decl entity, Float:fClientSpeed[3];
			GetClientEyeAngles(client, fClientEyeAngle);
			GetClientEyePosition(client, fClientEyePos);
			GetAngleVectors(fClientEyeAngle, fAngleVec, NULL_VECTOR, NULL_VECTOR);
			NormalizeVector(fAngleVec, fAngleVec);
			ScaleVector(fAngleVec, 10.0);
			AddVectors(fClientEyePos, fAngleVec, fResultPos);
			NormalizeVector(fAngleVec,fAngleVec);
			ScaleVector(fAngleVec, GetConVarFloat(shardSpeedCvar));
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", fClientSpeed);
			AddVectors(fAngleVec, fClientSpeed, fAngleVec);
			
			entity = CreateEntityByName("hegrenade_projectile");
			if(entity > 0) {
				new Float:vecmax[3] = {8.0, 8.0, 8.0};
				new Float:vecmin[3] = {-8.0, -8.0, -8.0};
				new Float:recoil[3] = {0.0,0.0,-35.0};
				new Float:duration = FlashFrostLifetime[skill];
				DispatchKeyValue(entity, "classname", PROJECTILE_NAME);
				SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
				SDKHook(entity, SDKHook_StartTouch, ShardTouchHook);
				SDKHook(entity, SDKHook_OnTakeDamage, ShardDamageHook);
				CreateTimer(0.1, ShardThink, entity);
				SetEntPropFloat(entity, Prop_Send, "m_flElasticity", 0.0);
				SetEntProp(entity, Prop_Send, "m_CollisionGroup", 3);//use 3 instead of 2(on 3 teleporter and other triggers WILL work)..
				SetEntProp(entity, Prop_Data, "m_takedamage", 0);
				DispatchSpawn(entity);
				SetEntityRenderMode(entity, RENDER_GLOW);
				SetEntityModel(entity,PROJECTILE_MDL1);
				SetEntPropVector(entity, Prop_Send, "m_vecMins", vecmin);
				SetEntPropVector(entity, Prop_Send, "m_vecMaxs", vecmax);
				SetEntProp(entity, Prop_Send, "m_fEffects", GetEntProp(entity, Prop_Send, "m_fEffects") | EF_NOSHADOW | EF_NORECEIVESHADOW | EF_BRIGHTLIGHT);
				SetEntityMoveType(entity, MOVETYPE_FLY);
				TeleportEntity(entity, fResultPos, fClientEyeAngle, fAngleVec);
				SetEntProp(entity, Prop_Data, "m_takedamage", 2);
				W3SimulateRecoil(client,recoil);
				W3FlashScreen(client,RGBA_COLOR_BLUE,1.5,0.6);
				CreateTimer(duration,Timer_ShardOvertime,entity);
				new color[4] = {120,120,255,255};
				new team = GetClientTeam(client);
				if(team==2) {
					color[0] = 255;
					color[2] = 140; //more blue cause red is "stronger"?! :p
				}
				SetEntityRenderFx(entity,RENDERFX_HOLOGRAM);//disort+distance fade
				SetEntityRenderColor(entity, color[0], color[1], color[2], 255);
				TE_SetupBeamFollow(entity, BeamSprite, HaloSprite, 2.6, 12.0, 8.0, 6, {80,80,255,255});
				TE_SendToTeam(team);
				TE_SetupBeamFollow(entity, BeamSprite, HaloSprite, 2.6, 12.0, 8.0, 6, {255,100,100,255});
				TE_SendToAllButTeam(team);
				iFlashFrostEnt[client]=entity;
				PrintCenterText(client,"%T","Shard launched!",client);
			}
		}
		else
		PrintHintText(client,"%T","You do not have enough Mana to do that!",client);
	}
}

stock W3_Condense(client,skill,team){
	new Float:fClientAimPos1[3];
	new Float:fClientAimPos2[3];
	decl Float:fAngles[3];
	GetClientEyeAngles(client, fAngles);
	new ax = 1;
	fAngles[0]=0.0,fAngles[2]=0.0;//we only need the 'theoretical' yaw value...
	if(fAngles[1]<150 && fAngles[1]>25) {
		ax = 0;
		fAngles[1]=90.0;
	}
	else if(fAngles[1]>-150 && fAngles[1]<-25) {
		ax = 0;
		fAngles[1]=90.0;
	}
	War3_GetAimEndPoint(client, fClientAimPos1);
	fClientAimPos2[0]=fClientAimPos1[0],fClientAimPos2[1]=fClientAimPos1[1],fClientAimPos2[2]=fClientAimPos1[2];
	new Float:duration = CondenseDuration[skill]; //max duration!
	new ent = SpawnFrozenProp(fClientAimPos1,fAngles,CONDENSE_MDL1,CONDENSE_STRENGTH,team,duration,true);
	EmitSoundToAll(crystallize, ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, fClientAimPos1, NULL_VECTOR, true, 0.0);
	//0=pitch/1=yaw/2=roll
	//my workaround to keep the walls in the right "direction"..	
	for(new i = 1; i <= skill; i++){
		new randomizer = GetRandomInt(80,110);
		fClientAimPos1[ax]+=randomizer;	
		fClientAimPos2[ax]-=randomizer;	
		SpawnFrozenProp(fClientAimPos1,fAngles,CONDENSE_MDL1,CONDENSE_STRENGTH,team,duration,true);
		SpawnFrozenProp(fClientAimPos2,fAngles,CONDENSE_MDL1,CONDENSE_STRENGTH,team,duration,true);
	}
	/*TE_SetupBeamPoints(fClientAimPos1, fClientAimPos2, BeamSprite, HaloSprite, 0, 35, duration, 
			120.0, 120.0, 0, 0.0, {100,100,255}, 10);
	TE_SendToAll();*/
	fClientAimPos1[2]+=35;
	fClientAimPos2[2]+=35;
	fClientAimPos1[ax]+=40;
	fClientAimPos2[ax]+=40;
	new beam_ent = CreateEntityByName("env_beam");
	if (beam_ent > 0 && IsValidEdict(beam_ent))
	{
		decl String:beamname[16];
		Format(beamname, sizeof(beamname), "w3s_beam_%d", client);
		DispatchKeyValueVector(beam_ent, "origin", fClientAimPos1);
		SetEntPropVector(beam_ent, Prop_Send, "m_vecEndPos", fClientAimPos2);
		
		SetEntityModel(beam_ent, LASER_SPRITE);
		SetEntPropFloat(beam_ent, Prop_Send, "m_fWidth", 100.0);
		SetEntPropFloat(beam_ent, Prop_Send, "m_fEndWidth", 100.0);

		DispatchKeyValue(beam_ent, "texture", LASER_SPRITE);
		DispatchKeyValue(beam_ent, "targetname", beamname);
		DispatchKeyValue(beam_ent, "LightningStart", beamname);
		DispatchKeyValue(beam_ent, "TouchType", "0");
		DispatchKeyValue(beam_ent, "BoltWidth", "12.0");
		DispatchKeyValue(beam_ent, "life", "0");
		DispatchKeyValue(beam_ent, "rendercolor", "0 0 0");
		DispatchKeyValue(beam_ent, "renderamt", "0");
		DispatchKeyValue(beam_ent, "HDRColorScale", "1.0");
		DispatchKeyValue(beam_ent, "decalname", "Bigshot");
		DispatchKeyValue(beam_ent, "StrikeTime", "0");
		DispatchKeyValue(beam_ent, "TextureScroll", "35");
		SetEntityRenderMode(beam_ent, RENDER_TRANSCOLOR);
		SetEntityRenderColor(beam_ent, 100, 100, 255);
		SetEntityRenderFx(beam_ent,RENDERFX_NO_DISSIPATION);
		AcceptEntityInput(beam_ent, "TurnOn");
		CreateTimer(duration, Timer_RemoveEntity, beam_ent);
	}
}

stock W3SimulateRecoil(client, Float:angle[3]){
	decl Float:oldangle[3];
	GetEntPropVector(client, Prop_Send, "m_vecPunchAngle", oldangle);
	oldangle[0] = oldangle[0] + angle[0];
	oldangle[1] = oldangle[1] + angle[1];
	oldangle[2] = oldangle[2] + angle[2];
	SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", oldangle);
	SetEntPropVector(client, Prop_Send, "m_vecPunchAngleVel", angle);
}

stock SpawnFrozenProp(const Float:Origin[3],const Float:fAngles[3],String:modelName[],iHealth,iTeamNum,Float:fLifetime,bool:bDrawInvisible=false) {
	new PhysicsProp = CreateEntityByName("prop_physics_override");
	SetEntityModel(PhysicsProp, modelName);
	DispatchKeyValue(PhysicsProp, "StartDisabled", "false");
	DispatchKeyValue(PhysicsProp, "classname", CONDENSE_NAME);
	DispatchKeyValue(PhysicsProp, "disableshadows", "1");
	SetEntProp(PhysicsProp, Prop_Data, "m_CollisionGroup", 6);
	SetEntProp(PhysicsProp, Prop_Data, "m_usSolidFlags", 5);
	SetEntProp(PhysicsProp, Prop_Data, "m_nSolidType", 6);
	DispatchSpawn(PhysicsProp);
	AcceptEntityInput(PhysicsProp, "DisableMotion");
	SetEntProp(PhysicsProp, Prop_Send, "m_iTeamNum", iTeamNum);
	TeleportEntity(PhysicsProp, Origin, fAngles, NULL_VECTOR);
	if(iHealth>0) {
		SetEntProp(PhysicsProp, Prop_Data, "m_iHealth", iHealth);
		SetEntProp(PhysicsProp, Prop_Data, "m_takedamage", 2);
	}
	if(bDrawInvisible) { //haaxxx them away!
		SetEntProp(PhysicsProp, Prop_Send, "m_fEffects", GetEntProp(PhysicsProp, Prop_Send, "m_fEffects") | EF_NODRAW);
	}
	ModifyEntityAddDeathTimer(PhysicsProp, fLifetime);
	return PhysicsProp;
}

/*public Action:Timer_RenderNone(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new entity = ReadPackCell(pack);
	SetEntityRenderMode(entity, RENDER_NONE);
}*/

public OnAbilityCommand(client,ability,bool:pressed) {
	if(War3_GetRace(client)==thisRaceID && pressed && IsPlayerAlive(client)) {
		if(!Silenced(client)) {
			switch (ability)
			{
			case 0:
				{
					new skill = War3_GetSkillLevel(client,thisRaceID,SKILL_1);
					if(skill > 0) {
						if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_1,true)) {
							W3_SpearLaunch(client,skill);
						}
					}
				}
			case 1:
				{
					new skill = War3_GetSkillLevel(client,thisRaceID,SKILL_2);
					if(skill > 0) {
						if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_2,true)) {
							new old_mana = GetManaWrapper(client);
							if(old_mana>=15) {
								SetManaWrapper(client,old_mana-15);
								new team = GetClientTeam(client);								
								W3FlashScreen(client,(team==2)?RGBA_COLOR_RED:RGBA_COLOR_BLUE,1.5,0.6);
								W3_Condense(client,skill,team);
								new Float:fClientAimPos1[3];
								War3_GetAimEndPoint(client, fClientAimPos1);
								new Float:fClientPos[3];
								GetClientAbsOrigin(client,fClientPos);						
								War3_CooldownMGR(client,8.0,thisRaceID,SKILL_2,true,true);								
								PrintCenterText(client,"Condensed!",client);
							}
							else
							PrintHintText(client,"%T","You do not have enough Mana to do that!",client);
						}
					}
				}
			}
		}
	}
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(ValidPlayer(client, true) && pressed && race==thisRaceID)
	{
		new skill_level = War3_GetSkillLevel(client, thisRaceID, ULT);
		if( skill_level > 0)
		{
			if(War3_SkillNotInCooldown(client,thisRaceID,ULT,true))
			{
				new Float:max_distance = GlacialMaxDistance[skill_level];
				decl Float:aimVec[3], Float:clientVec[3];
				War3_GetAimEndPoint(client, aimVec);
				GetClientAbsOrigin( client, clientVec );
				if(GetVectorDistance(clientVec,aimVec) <= max_distance)
				{
					if(!bUltActive[client]) {
						new Float:radius = GlacialMaxRadius[skill_level];						
						new Float:fAngles[3] = {0.0,0.0,0.0};
						new entity = CreateSmokestack(aimVec,fAngles,radius/2,35.0,0.1,40.0,"particle/fire.vmt","200 200 255","4","80","60","80");
						bUltActive[client] = true;
						/*
							DataTimer - Timer_GlacialStorm
							Purpose : Anivia's Ultimate
							Member :
							- client index
							- damage per loop(every 0.4 seconds)
							- max distance between the player and 'the storm'
							- area of effect
							- slowdown amount
							- targetpos x
							- targetpos y
							- targetpos z
						*/
						decl Handle:pack;
						CreateDataTimer(0.4, Timer_GlacialStorm, pack);
						WritePackCell(pack, client);		
						WritePackCell(pack, GlacialDamagePerTick[skill_level]);	
						WritePackFloat(pack, max_distance);
						WritePackFloat(pack, radius);
						WritePackFloat(pack, GlacialSlowdown[skill_level]);					
						WritePackFloat(pack, aimVec[0]);
						WritePackFloat(pack, aimVec[1]);
						WritePackFloat(pack, aimVec[2]);
						
						/*
							DataTimer - Timer_GlacialStormFX
							Purpose : Anivia's Ultimate Effects
							Member :
							- client index
							- target position[3]
						*/
						decl Handle:packfx;
						CreateDataTimer(0.5, Timer_GlacialStormFX, packfx);
						WritePackCell(packfx, client);
						WritePackFloat(packfx, radius);
						WritePackFloat(packfx, aimVec[0]);
						WritePackFloat(packfx, aimVec[1]);
						WritePackFloat(packfx, aimVec[2]);
						/*
							DataTimer - Timer_UltimateOvertimed
							Purpose : Turns Anivia's Ultimate off!
							Member :
							- client index
							- entity index (optional/-1 if not used)
						*/
						decl Handle:pack2;
						hUltimateEndTimer[client] = CreateDataTimer(GlacialMaxTime[skill_level], Timer_UltimateOvertimed, pack2);
						WritePackCell(pack2, client);
						WritePackCell(pack2, entity);
						iGlacialEntity[client]=entity;
						EmitSoundToAll(glacial, entity, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,SNDPITCH_NORMAL,-1, aimVec, NULL_VECTOR,true,0.3);
						W3Hint(client,HINT_SKILL_STATUS,2.0,"Glacial Storm casted!");
					}
					else {
						bUltActive[client]=false;
						decl Handle:pack;
						CreateDataTimer(0.1, Timer_UltimateOvertimed, pack);
						WritePackCell(pack, client);
						WritePackCell(pack, iGlacialEntity[client]);
						War3_CooldownMGR(client,GetConVarFloat(ultCooldownCvar),thisRaceID,ULT,_,true);
					}
				}
				else {
					PrintHintText(client,"Target position is too far away!");		
					War3_CooldownMGR(client,2.0,thisRaceID,ULT,_,true);
				}
			}
		}
	}
}

public Action:Timer_GlacialStormFX(Handle:timer, Handle:pack) //some point of lazy-ness :S
{
	//Resolve order must be: client,max_distance,AoE,slowdown amount,damage,targetpos[3]
	ResetPack(pack);
	new client = ReadPackCell(pack);
	if(bUltActive[client]==true&&ValidPlayer(client,false)) {
		new owner_team=GetClientTeam(client);

		decl Float:aimVec[3],Float:radius;
		radius=ReadPackFloat(pack);
		aimVec[0]=ReadPackFloat(pack);
		aimVec[1]=ReadPackFloat(pack);
		aimVec[2]=ReadPackFloat(pack);
		TE_SetupDynamicLight(aimVec, 65,65,255,2,radius+10,0.6,1.5);
		TE_SendToAll();
		
		new Float:fx_old_dist = 1.0;
		new Float:fx_dist = radius;
		fx_dist /= 4;			
		for(new splitter = 1; splitter <= 4; splitter++) 
		{
			TE_SetupBeamRingPoint(aimVec,fx_old_dist,fx_dist,LaserSprite,HaloSprite,0,10,0.8,25.0,0.0,{120,120,255,255},8,FBEAM_HALOBEAM|FBEAM_ONLYNOISEONCE);//draw beamring with +10(looks better)
			TE_SendToTeam(owner_team); //blue = friendly
			TE_SetupBeamRingPoint(aimVec,fx_old_dist,fx_dist,LaserSprite,HaloSprite,0,10,0.8,25.0,0.0,{255,20,20,255},8,FBEAM_HALOBEAM|FBEAM_ONLYNOISEONCE);
			TE_SendToAllButTeam(owner_team); //red = evil ! >:D				
			fx_old_dist = fx_dist;
			fx_dist *= 2;
		}
		TE_SetupBubbles(aimVec,aimVec,radius,Glow,12,GetRandomFloat(28.0,150.0));
		TE_SendToAll();
		TE_SetupBeamRingPoint(aimVec,18.0,20.0,LaserSprite,HaloSprite,0,10,0.8,40.0,0.0,{255,255,255,255},8,FBEAM_HALOBEAM);
		TE_SendToTeam(owner_team);
		TE_SetupBeamRingPoint(aimVec,18.0,20.0,LaserSprite,HaloSprite,0,10,0.8,40.0,0.0,{255,255,255,255},8,FBEAM_HALOBEAM);
		TE_SendToAllButTeam(owner_team);
		decl Handle:packfx;
		CreateDataTimer(0.5, Timer_GlacialStormFX, packfx);
		WritePackCell(packfx, client);
		WritePackFloat(packfx, radius);
		WritePackFloat(packfx, aimVec[0]);
		WritePackFloat(packfx, aimVec[1]);
		WritePackFloat(packfx, aimVec[2]);
	}
}

public Action:Timer_GlacialStorm(Handle:timer, Handle:pack)
{
	//Resolve order must be: client,damage,targetpos[0->2],max_distance,AoE,slowdown amount
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new damage = ReadPackCell(pack);
	if(bUltActive[client]==true && ValidPlayer(client,true)) {
		new old_mana = GetManaWrapper(client);
		new manacost = 3;
		if(old_mana>=manacost) {
			SetManaWrapper(client,old_mana-manacost);
			new Float:max_distance = ReadPackFloat(pack);
			decl Float:aimVec[3],Float:clientVec[3],Float:distance,Float:slowdown;
			distance = ReadPackFloat(pack);
			slowdown = ReadPackFloat(pack);			
			aimVec[0]=ReadPackFloat(pack);
			aimVec[1]=ReadPackFloat(pack);
			aimVec[2]=ReadPackFloat(pack);
			GetClientAbsOrigin( client, Float:clientVec );
			if(GetVectorDistance(clientVec,aimVec) <= max_distance)
			{
				new team = GetClientTeam(client);				
				decl Float:enemyVec[3];
				for(new i=1; i<= MaxClients; i++)
				{
					if(ValidPlayer(i,true) && team != GetClientTeam(i) && !W3HasImmunity(i,Immunity_Ultimates))
					{
						GetClientAbsOrigin(i, enemyVec);
						if(GetVectorDistance(aimVec,enemyVec) <= distance)
						{
							GlacialStorm(client,i,damage,slowdown,enemyVec,aimVec);
						}
					}
				}	
			}
			else {				
				decl Handle:packstop;
				CreateDataTimer(0.1, Timer_UltimateOvertimed, packstop);
				WritePackCell(packstop, client);
				WritePackCell(packstop, iGlacialEntity[client]);
				PrintHintText(client,"Glacial Storm is too far away!");	
			}
			//Re-Start the timer (loop will automatic cancel if bUltActive is false!)
			decl Handle:datapack;
			CreateDataTimer(0.4, Timer_GlacialStorm, datapack);
			WritePackCell(datapack, client);		
			WritePackCell(datapack, damage);	
			WritePackFloat(datapack, max_distance);
			WritePackFloat(datapack, distance);
			WritePackFloat(datapack, slowdown);					
			WritePackFloat(datapack, aimVec[0]);
			WritePackFloat(datapack, aimVec[1]);
			WritePackFloat(datapack, aimVec[2]);
		}
		else {
			decl Handle:packstop;
			CreateDataTimer(0.1, Timer_UltimateOvertimed, packstop);
			WritePackCell(packstop, client);
			WritePackCell(packstop, iGlacialEntity[client]);
			PrintHintText(client,"You don't have enough mana left, glacial storm aborted!");
		}
	}
}

stock GlacialStorm(attacker,target,damage,Float:slowdown,Float:pos[3],Float:pos2[3]) {
	if(War3_DealDamage(target,damage,attacker,DMG_DISSOLVE,"glacialstorm",W3DMGORIGIN_ULTIMATE,W3DMGTYPE_MAGIC,true,false)) {
		pos2[2]+=40;
		pos[2]+=40;
		new Float:direction[3]={0.0,0.0,0.0};
		bFrosted[target]=true;
		War3_SetBuff(target,fSlow,thisRaceID,slowdown);
		War3_SetBuff(target,fAttackSpeed,thisRaceID,slowdown);
		W3FlashScreen(target,RGBA_COLOR_BLUE,0.5 );
		W3SetPlayerColor(target,thisRaceID, 120, 120, 255, _, GLOW_SKILL);
		W3GlacialOverlay(target,0.0,"effects/strider_bulge_dudv_DX60");	
		W3GlacialOverlay(target,0.6,"effects/strider_bulge_dudv_DX60");	
		TE_SetupEnergySplash(pos, direction, true);
		TE_SendToAll();
		TE_SetupBeamPoints(pos,pos2,PlasmaBeam,HaloSprite,0,80,1.0,15.0,15.0,1,1.0,{255,255,255,220},20);
		TE_SendToAll();
		pos2[2]-=40;
		pos[2]-=40;
		/*
		DataTimer - Timer_UnfrostAttempt
		Purpose : Try's ti deactivate long-term effects from ultimate
		Member :
		- attacker(ultimate caster)
		- target(ultimate victim)
		*/
		decl Handle:pack;
		CreateDataTimer(0.5, Timer_UnfrostAttempt, pack);
		WritePackCell(pack, attacker);
		WritePackCell(pack, target);
	}
}

public Action:Timer_UnfrostAttempt(Handle:timer, Handle:pack)
{
	//Resolve order must be: owner,target
	ResetPack(pack);
	new attacker = ReadPackCell(pack);
	if(bUltActive[attacker]==false) {
		//Only deactive if ultimate from the attacker is off..
		new client = ReadPackCell(pack);
		if(client>0) {
			bFrosted[client]=false;
			War3_SetBuff(client,fSlow,thisRaceID,1.0);
			War3_SetBuff(client,fAttackSpeed,thisRaceID,1.0);
			W3ResetPlayerColor(client,thisRaceID);
		}
	}
}

public Action:Timer_UltimateOvertimed(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	bUltActive[client]=false;
	if(hUltimateEndTimer[client]!=INVALID_HANDLE && timer!=hUltimateEndTimer[client]) {
		KillTimer(hUltimateEndTimer[client]);
		hUltimateEndTimer[client]=INVALID_HANDLE;
	}
	if(ValidPlayer(client,false)) {
		W3Hint(client,HINT_SKILL_STATUS,2.0,"Glacial Storm finished!");
	}
	new entity = ReadPackCell(pack);
	if(entity>0) {
		StopSound(entity,SNDCHAN_AUTO,glacial);
		if(IsValidEntity(entity)) {
			AcceptEntityInput(entity, "TurnOff");
			CreateTimer(1.0, Timer_RemoveEntity, entity);
		}
	}
}
//W3GlacialOverlay similar as W3Screenoverlay but glacial only removes the screen if target is not frosted anymore
stock W3GlacialOverlay(target,Float:delay,String:material[])
{
	decl Handle:pack;
	CreateDataTimer(delay, Timer_DoGlacialOverlay, pack);
	WritePackCell(pack, target);
	WritePackString(pack, material);
}

public Action:Timer_DoGlacialOverlay(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new target = ReadPackCell(pack);
	if(ValidPlayer(target,false)) {
		new String:buffer[64];
		ReadPackString(pack, buffer, sizeof(buffer));
		if (StrEqual(buffer, "0", false)) {
			bOverlayed[target]=true;
			ClientCommand(target, "r_screenoverlay %s",buffer);
		}
		else {
			if(!bFrosted[target]) {
				bOverlayed[target]=false;
				ClientCommand(target, "r_screenoverlay 0");
			}
		}
	}
}

stock CreateSmokestack(Float:fPos[3],Float:fAng[3],Float:BaseSpread,Float:StartSize,Float:EndSize,Float:Twist,String:material[],String:renderclr[],String:SpreadSpeed[],String:JetLength[],String:Speed[],String:Rate[]){
	new particle = CreateEntityByName("env_smokestack");
	if(IsValidEdict(particle))
	{
		decl String:Name[32];
		Format(Name, sizeof(Name), "w3s_particles");
		// Set Key Values
		DispatchKeyValueVector(particle, "Origin", fPos);
		DispatchKeyValueVector(particle, "Angles", fAng);
		DispatchKeyValueFloat(particle, "BaseSpread", BaseSpread);
		DispatchKeyValueFloat(particle, "StartSize", StartSize);
		DispatchKeyValueFloat(particle, "EndSize", EndSize);
		DispatchKeyValueFloat(particle, "Twist", Twist);		
		DispatchKeyValue(particle, "Name", Name);
		DispatchKeyValue(particle, "SmokeMaterial", material);
		DispatchKeyValue(particle, "RenderColor", renderclr);
		DispatchKeyValue(particle, "SpreadSpeed", SpreadSpeed);
		DispatchKeyValue(particle, "RenderAmt", "255");
		DispatchKeyValue(particle, "JetLength", JetLength);
		DispatchKeyValue(particle, "RenderMode", "0");
		DispatchKeyValue(particle, "Initial", "0");
		DispatchKeyValue(particle, "Speed", Speed);
		DispatchKeyValue(particle, "Rate", Rate);
		DispatchSpawn(particle);
		AcceptEntityInput(particle, "TurnOn");
		return particle;
	}
	else
	{
		LogError("Failed to create entity env_smokestack!");
	}
	return -1;
}

stock TE_SetupBubbles(Float:startposi[3],Float:finalposi[3],Float:fHeight,nModelIndex,nCount,Float:fSpeed)
{
	TE_Start("Bubbles");
	TE_WriteVector("m_vecMins", startposi);
	TE_WriteVector("m_vecMaxs", finalposi);
	TE_WriteFloat("m_fHeight", fHeight);
	TE_WriteNum("m_nModelIndex", nModelIndex);
	TE_WriteNum("m_nCount", nCount);
	TE_WriteFloat("m_fSpeed", fSpeed);
}

stock TE_SetupDynamicLight(const Float:vecOrigin[3], r,g,b,iExponent,Float:fRadius,Float:fTime,Float:fDecay)
{
	TE_Start("Dynamic Light");
	TE_WriteVector("m_vecOrigin",vecOrigin);
	TE_WriteNum("r",r);
	TE_WriteNum("g",g);
	TE_WriteNum("b",b);
	TE_WriteNum("exponent",iExponent);
	TE_WriteFloat("m_fRadius",fRadius);
	TE_WriteFloat("m_fTime",fTime);
	TE_WriteFloat("m_fDecay",fDecay);
}

stock TE_SendToTeam(team,Float:delay=0.0)
{
	new total = 0;
	new clients[MaxClients];
	for (new i=1; i<=MaxClients; i++)
	{
		if (ValidPlayer(i,false)&&!IsFakeClient(i))
		{
			if(GetClientTeam(i)==team) {
				clients[total++] = i;
			}
		}
	}
	return TE_Send(clients, total, delay);
}
stock TE_SendToAllButTeam(team,Float:delay=0.0)
{
	new total = 0;
	new clients[MaxClients];
	for (new i=1; i<=MaxClients; i++)
	{
		if (ValidPlayer(i,false)&&!IsFakeClient(i))
		{
			if(GetClientTeam(i)!=team) {
				clients[total++] = i;
			}
		}
	}
	return TE_Send(clients, total, delay);
}

GetManaWrapper(client) {
	decl mana;
	if(bExtension) {
		mana = W3GetMana(client);
	}
	else {
		mana = iManaValue[client];
	}
	return mana;
}

SetManaWrapper(client,value) {
	if(bExtension) {
		W3SetMana(client,value);
	}
	else {
		iManaValue[client]=value;
	}
}

//dirty dealdamage workaround.. tell me if you got another idea :o
stock DealDamageWorkaround(victim,attacker,damage,String:classname[32],Float:delay=0.1) {
	new Handle:pack;
	CreateDataTimer(delay, Timer_DealDamage, pack);
	WritePackCell(pack, victim);
	WritePackCell(pack, attacker);
	WritePackCell(pack, damage);
	WritePackString(pack, classname);
}
public Action:Timer_DealDamage(Handle:timer, Handle:pack)
{
	ResetPack(pack); //resolve the package...
	new victim = ReadPackCell(pack);
	new attacker = ReadPackCell(pack);
	new damage = ReadPackCell(pack);
	decl String:classname[32];
	ReadPackString(pack,classname,sizeof(classname));
	War3_DealDamage(victim,damage,attacker,DMG_BULLET,classname);
}