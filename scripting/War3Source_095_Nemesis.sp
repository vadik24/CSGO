/**
 * File: War3Source_Nemesis.sp
 * Description: Nemesis race for War3Source.
 * Author(s): Schmarotzer 
 */
 
#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
#include <sdkhooks>
#include <cstrike>

new thisRaceID;
new bool:bNemHasRespawned[MAXPLAYERS]; //cs
new Handle:RespawnDelayCvar;
new Handle:FriendlyFireSuicideCvar;
new Handle:SuicideDamageSentryCvar;
new Handle:MPFFCvar;
new ExplosionModel;
new bool:bSuicided[MAXPLAYERS];
new suicidedAsTeam[MAXPLAYERS];
new String:explosionSound1[]="war3source/particle_suck1.mp3";
new BeamSprite;
new HaloSprite;
//new Handle:FreezeTimeCvar;


// Chance/Info Arrays
// 6 skill
new Float:SuicideBomberRadius[5]={0.0,200.0,233.0,275.0,333.0}; 
new Float:SuicideBomberDamage[5]={0.0,166.0,200.0,233.0,266.0};
new Float:SuicideBomberDamageTF[5]={0.0,133.0,175.0,250.0,300.0}; 
new Float:SuicideLocation[MAXPLAYERS][3];
// 5 skill
new Float:InjectionSpeed[5]={1.0,1.06,1.12,1.18,1.23};
// 1 skill
new FleshHealth[5]={0,15,25,35,45};

// 2 skill
new RegenHP[5]={0,1,2,3,4};

//new health_Offset;
// 3 skill
new Float:RespawnChance[5]={0.0,0.15,0.37,0.59,0.8};
new MyWeaponsOffset,AmmoOffset;
// 4 skill
new const InfectionInitialDamage=20;
new const InfectionTrailingDamage=5;
new Float:InfectionChanceArr[]={0.0,0.05,0.1,0.15,0.2};
new InfectionTimes[]={0,2,3,4,5};
new BeingInfectedBy[66];
new InfectionRemaining[66];
new String:Fangsstr[]={"npc/roller/mine/rmine_blades_out2.mp3"};

//new Float:LastDamageTime[MAXPLAYERS];


new SKILL_HEALTH,SKILL_REGEN,SKILL_RESPAWN,SKILL_INFECTION,SKILL_SPEED,SKILL_SUICIDE;


public Plugin:myinfo = 
{
	name = "War3Source Race - Nemesis",
	author = "Schmarotzer",
	description = "Nemesis race for War3Source",
	version = "1.0.0.0",
	url = "http://css.bashtel.ru"
};

public OnPluginStart()
{
	LoadTranslations("w3s.race.nemesis.phrases");
	HookEvent("round_start",RoundStartEvent);
	FriendlyFireSuicideCvar=CreateConVar("war3_nemesis_suicidebomber_ff","2","Friendly fire for suicide bomber, 0 for no, 1 for yes, 2 for mp_friendlyfire");
	SuicideDamageSentryCvar=CreateConVar("war3_nemesis_suicidebomber_sentry","1","Should suicide bomber damage sentrys?");
	MPFFCvar=FindConVar("mp_friendlyfire");
	RespawnDelayCvar=CreateConVar("war3_nemesis_respawn_delay","5","How long before spawning for reincarnation?");
	//CreateTimer(2.0,doReg,client,TIMER_REPEAT);
	CreateTimer(2.0,doReg,_,TIMER_REPEAT);
	MyWeaponsOffset=FindSendPropOffs("CBaseCombatCharacter","m_hMyWeapons");
}

public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num==20)
	{
		thisRaceID		=	War3_CreateNewRaceT("nemesis");
		SKILL_HEALTH	=	War3_AddRaceSkillT(thisRaceID,"1",false,4);
		SKILL_REGEN		=	War3_AddRaceSkillT(thisRaceID,"2",false,4);
		SKILL_RESPAWN	=	War3_AddRaceSkillT(thisRaceID,"3",false,4);
		SKILL_INFECTION	=	War3_AddRaceSkillT(thisRaceID,"4",false,4);
		SKILL_SPEED		=	War3_AddRaceSkillT(thisRaceID,"5",false,4);
		SKILL_SUICIDE	=	War3_AddRaceSkillT(thisRaceID,"6",true,4);
		W3SkillCooldownOnSpawn(thisRaceID,SKILL_SUICIDE,5.0,_);
		War3_CreateRaceEnd(thisRaceID);
	}
}

public OnMapStart()
{
	//War3_PrecacheSound(Fangsstr);
	if(War3_GetGame()==Game_TF)
	{
		ExplosionModel=PrecacheModel("materials/particles/explosion/explosionfiresmoke.vmt",false);
		PrecacheSound("weapons/explode1.mp3",false);
	}
	else
	{
		ExplosionModel=PrecacheModel("materials/sprites/zerogxplode.vmt",false);
		PrecacheSound("weapons/explode5.mp3",false);
	}
	
	BeamSprite=War3_PrecacheBeamSprite();
	HaloSprite=War3_PrecacheHaloSprite();

	//War3_PrecacheSound(explosionSound1);
}


public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
	ActivateSkills(client);
}

public ActivateSkills(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		
		// SPEED
		new skill_level_speed=War3_GetSkillLevel(client,thisRaceID,SKILL_SPEED);
		new Float:speed=InjectionSpeed[skill_level_speed];
		War3_SetBuff(client,fMaxSpeed,thisRaceID,speed);
	}
}

public InitPassiveSkills(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		bSuicided[client]=false;
		// HEALTH
		new skill_level_flesh=War3_GetSkillLevel(client,thisRaceID,SKILL_HEALTH);
		if(skill_level_flesh)
		{
			new hpadd=FleshHealth[skill_level_flesh];
			new Float:vec[3];
			GetClientAbsOrigin(client,vec);
			vec[2]+=25.0;
			new ringColor[4]={0,0,0,0};
			new team=GetClientTeam(client);
			if(team==2)
			{
				ringColor={255,0,0,255};
			}
			else if(team==3)
			{
				ringColor={0,0,255,255};
			}
			TE_SetupBeamRingPoint(vec,40.0,10.0,BeamSprite,HaloSprite,0,15,1.0,15.0,0.0,ringColor,10,0);
			TE_SendToAll();

			War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,hpadd);
			//War3_ChatMessage(client,"+%d HP",hpadd);
		}
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(oldrace==thisRaceID)
	{
		W3ResetAllBuffRace(client,thisRaceID);
	}
	if(newrace==thisRaceID)
	{	
		if(ValidPlayer(client,true))
		{
			ActivateSkills(client);
			InitPassiveSkills(client);
		}
	}
}

public Action:doReg(Handle:timer,any:client)
{
	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true) && War3_GetRace(i)==thisRaceID)
		{
			DoRegeneration(i);
		
			//new skill_level_regen=War3_GetSkillLevel(client,thisRaceID,SKILL_REGEN);
			//if(skill_level_regen>0)
			//{
				//new reg_hp=RegenHP[skill_level_regen];
			//War3_HealToMaxHP(client,reg_hp);
		}
	}
}

public DoRegeneration(client)
{
	new skill_level_regen=War3_GetSkillLevel(client,thisRaceID,SKILL_REGEN);
	if(skill_level_regen>0)
	{
		new reg_hp=RegenHP[skill_level_regen];
		War3_HealToMaxHP(client,reg_hp);
	}
}

public SuicideBomber(client,level)
{
	if(suicidedAsTeam[client]!=GetClientTeam(client)){
		return; //switched team
	}
	new Float:radius=SuicideBomberRadius[level];
	if(level<=0)
		return; // just a safety check
	new ss_ff=GetConVarInt(FriendlyFireSuicideCvar);
	new bool:mp_ff=GetConVarBool(MPFFCvar);
	new our_team=GetClientTeam(client); 
	new Float:client_location[3];
	for(new i=0;i<3;i++){
		client_location[i]=SuicideLocation[client][i];
	}
	
	TE_SetupExplosion(client_location,ExplosionModel,10.0,1,0,RoundToFloor(radius),160);
	TE_SendToAll();
	
	if(War3_GetGame()==Game_TF){
		client_location[2]+=30.0;
	}
	else{
		client_location[2]-=40.0;
	}
	
	TE_SetupBeamRingPoint(client_location, 10.0, radius, BeamSprite, HaloSprite, 0, 15, 0.5, 10.0, 10.0, {255,255,255,33}, 120, 0);
	TE_SendToAll();
	
	new beamcolor[]={0,200,255,255}; //blue //secondary ring
	if(our_team==2)
	{ //TERRORISTS/RED in TF?
		beamcolor[0]=255;
		beamcolor[1]=0;
		beamcolor[2]=0;
		
	} //secondary ring
	TE_SetupBeamRingPoint(client_location, 20.0, radius+10.0, BeamSprite, HaloSprite, 0, 15, 0.5, 10.0, 10.0, beamcolor, 120, 0);
	TE_SendToAll();

	if(War3_GetGame()==Game_TF){
		client_location[2]-=30.0;
	}
	else{
		client_location[2]+=40.0;
	}
	
	EmitSoundToAll(explosionSound1,client);
	
	if(War3_GetGame()==Game_TF){
		EmitSoundToAll("weapons/explode1.mp3",client);
	}
	else{
		EmitSoundToAll("weapons/explode5.mp3",client);
	}
	
	///building damage
	if(War3_GetGame()==Game_TF && GetConVarBool(SuicideDamageSentryCvar))
	{
		// Do they have a sentry that should get blasted too?
		new ent=0;
		
		new buildinglist[1000];
		new buildingsfound=0;
		
		while((ent = FindEntityByClassname(ent,"obj_sentrygun"))>0)
		{
			buildinglist[buildingsfound]=ent;
			buildingsfound++;
		}
		while((ent = FindEntityByClassname(ent,"obj_teleport"))>0)
		{
			buildinglist[buildingsfound]=ent;
			buildingsfound++;
		}
		while((ent = FindEntityByClassname(ent,"obj_dispenser"))>0)
		{
			buildinglist[buildingsfound]=ent;
			buildingsfound++;
		}

		for(new i=0;i<buildingsfound;i++){
			ent=buildinglist[i];
			if(!IsValidEdict(ent)) continue;
			new builder=GetEntPropEnt(ent,Prop_Send,"m_hBuilder");
			if(GetClientTeam(builder)!=our_team)
			{
				new Float:pos_comp[3];
				GetEntPropVector(ent,Prop_Send,"m_vecOrigin",pos_comp);
				new Float:dist=GetVectorDistance(client_location,pos_comp);
				if(dist>radius)
					continue;
				
				if(!W3HasImmunity(builder,Immunity_Ultimates))
				{
					//new damage=RoundFloat(100*(1-FloatDiv(dist,radius)+0.40));
					new damage=RoundFloat(SuicideBomberDamageTF[level]*(radius-dist)/radius); //special case
					
					PrintToConsole(client,"[W3S] Suicide bomber BUILDING damage: %d at distance %f",damage,dist);
					
					SetVariantInt(damage);
					AcceptEntityInput(ent,"RemoveHealth",client); // last parameter should make death messages work
				}
				else{
					PrintToConsole(client,"[W3S] Player %d has immunity (protecting buildings)",builder);
				}
			}
		}
	}
	
	new Float:location_check[3];
	for(new x=1;x<=MaxClients;x++)
	{
		if(ValidPlayer(x,true)&&client!=x)
		{
			new team=GetClientTeam(x);
			if(ss_ff==0 && team==our_team)
				continue;
			else if(ss_ff==2 && !mp_ff && team==our_team)
				continue;

			GetClientAbsOrigin(x,location_check);
			new Float:distance=GetVectorDistance(client_location,location_check);
			if(distance>radius)
				continue;
			
			if(!W3HasImmunity(x,Immunity_Ultimates))
			{
				new Float:factor=(radius-distance)/radius;
				new damage;
				if(War3_GetGame()==Game_TF){
					damage=RoundFloat(SuicideBomberDamageTF[level]*factor);
				}
				else{
					damage=RoundFloat(SuicideBomberDamage[level]*factor);
				}
				//PrintToChatAll("daage suppose to be %d/%.1f max. distance %.1f",damage,SuicideBomberDamage[level],distance);
				
				War3_DealDamage(x,damage,client,_,"suicidebomber",W3DMGORIGIN_ULTIMATE,W3DMGTYPE_PHYSICAL);
				PrintToConsole(client,"[W3S] Finishing Blow damage: %d to %d at distance %f",War3_GetWar3DamageDealt(),x,distance);
				
				
				War3_ShakeScreen(x,3.0*factor,250.0*factor,30.0);
				W3FlashScreen(x,RGBA_COLOR_RED);
			}
			else
			{
				PrintToConsole(client,"[W3S] Could not damage player %d due to immunity",x);
			}
			
		}
	}
	//PrintCenterText(client,"BOMB DETONATED!");
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(pressed)
	{
		if(race==thisRaceID&&IsPlayerAlive(client)&&!bSuicided[client]&&!Silenced(client))
		{
			new ult_level=War3_GetSkillLevel(client,race,SKILL_SUICIDE);
			if(ult_level>0)
			{
				suicidedAsTeam[client]=GetClientTeam(client);
				ForcePlayerSuicide(client); //this causes them to die...
			}
			else
			{
				W3MsgUltNotLeveled(client);
			}
		}
	}
}
public OnWar3EventSpawn(client)
{
	new race=War3_GetRace(client);
	if(race==thisRaceID)
	{
		suicidedAsTeam[client]=GetClientTeam(client);
		ActivateSkills(client);
		InitPassiveSkills(client);
	}
	else
	{
		bSuicided[client]=true; 
	}
}

public OnWar3EventDeath(victim,attacker)
{
	if(!bSuicided[victim])
	{
		new race=War3_GetRace(victim);
		new skill_level_suicide=War3_GetSkillLevel(victim,thisRaceID,SKILL_SUICIDE);
		if(race==thisRaceID && skill_level_suicide>0 && !Hexed(victim))
		{
			bSuicided[victim]=true;
			suicidedAsTeam[victim]=GetClientTeam(victim); 
			GetClientAbsOrigin(victim,SuicideLocation[victim]);
			CreateTimer(0.15,DelayedBomber,victim);
		}
	}
	if(ValidPlayer(victim))
	{
		new race=W3GetVar(DeathRace); //get  immediate variable, which indicates the race of the player when he died
		if(race==thisRaceID && bNemHasRespawned[victim]==false)
		{
			new skill_level_respawn=War3_GetSkillLevel(victim,race,SKILL_RESPAWN);
			if(skill_level_respawn) //let them revive even if hexed
			{
				new Float:percent=RespawnChance[skill_level_respawn];
				if(W3Chance(percent))
				{
					for(new slot=0;slot<10;slot++)
					{
						new ent=War3_CachedWeapon(victim,slot);
						if(ent)
						{
							if(IsValidEdict(ent))
							{
								decl String:wepName[64];
								War3_CachedDeadWeaponName(victim,slot,wepName,64);
								if(StrEqual(wepName,"weapon_c4") || StrEqual(wepName,"weapon_knife"))
								{
									continue; // don't think we need to delete these
								}
								UTIL_Remove(ent);
							}
						}
					}
					new Float:delay_spawn=GetConVarFloat(RespawnDelayCvar);
					if(delay_spawn<0.25)
						delay_spawn=0.25;
					CreateTimer(delay_spawn,RespawnNemesis,victim);
					PrintHintText(victim,"%T","String_01",victim,delay_spawn);
					// PrintHintText(victim,"Will be revived through%.1f seconds!",delay_spawn);
				}
			}
		}
	}
}
public Action:DelayedBomber(Handle:h,any:client){
	if(ValidPlayer(client)&&!IsPlayerAlive(client)&& suicidedAsTeam[client]==GetClientTeam(client) ){
		SuicideBomber(client,War3_GetSkillLevel(client,thisRaceID,SKILL_SUICIDE));
	}
	else{
		bSuicided[client]=false;
	}
}





public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
	if(ValidPlayer(attacker,true)&&ValidPlayer(victim,true)&&GetClientTeam(victim)!=GetClientTeam(attacker))
	{

		//ATTACKER IS headcrab
		if(War3_GetRace(attacker)==thisRaceID)
		{
			//fangs poison
			new Float:chance_mod=W3ChanceModifier(attacker);
			/// CHANCE MOD BY VICTIM
			new skill_level = War3_GetSkillLevel(attacker,thisRaceID,SKILL_INFECTION);
			if(skill_level>0 && InfectionRemaining[victim]==0 && GetRandomFloat(0.0,1.0)<=chance_mod*InfectionChanceArr[skill_level]&&!Silenced(attacker))
			{
				if(W3HasImmunity(victim,Immunity_Skills))
				{
					//PrintHintText(victim,"You have immunity to the T-virus");
					//PrintHintText(attacker,"The enemy immune to the T-virus");
					PrintHintText(victim,"%T","String_02",victim);
					PrintHintText(attacker,"%T","String_03",attacker);
				}
				else
				{
					//PrintHintText(victim,"You have infected T-Virus");
					//PrintHintText(attacker,"You are infected with the enemy T-Virus");
					PrintHintText(victim,"%T","String_04",victim);
					PrintHintText(attacker,"%T","String_05",attacker);
					BeingInfectedBy[victim]=attacker;
					InfectionRemaining[victim]=InfectionTimes[skill_level];
					War3_DealDamage(victim,InfectionInitialDamage,attacker,DMG_BULLET,"T-Virus");
					W3FlashScreen(victim,RGBA_COLOR_RED);
					
					EmitSoundToAll(Fangsstr,attacker);
					EmitSoundToAll(Fangsstr,victim);
					CreateTimer(1.0,InfectionLoop,victim);
				}
			}
		}
	}
}

public Action:InfectionLoop(Handle:timer,any:victim)
{
	if(InfectionRemaining[victim]>0 && ValidPlayer(BeingInfectedBy[victim]) && ValidPlayer(victim,true))
	{
		War3_DealDamage(victim,InfectionTrailingDamage,BeingInfectedBy[victim],_,"T-Virus",W3DMGORIGIN_ULTIMATE,W3DMGTYPE_TRUEDMG);
		InfectionRemaining[victim]--;
		W3FlashScreen(victim,RGBA_COLOR_RED, 0.3, 0.4);
		CreateTimer(1.0,InfectionLoop,victim);
	}
}





public Action:RespawnNemesis(Handle:timer,any:client)
{
	if(ValidPlayer(client)&&!IsPlayerAlive(client)&&GetClientTeam(client)>1)
	{
		War3_SpawnPlayer(client);
		new Float:pos[3];
		new Float:ang[3];
		War3_CachedAngle(client,ang);
		War3_CachedPosition(client,pos);
		TeleportEntity(client,pos,ang,NULL_VECTOR);
		bNemHasRespawned[client]=true;
		//War3_ChatMessage(client,"Revived with the help of skill");
		War3_ChatMessage(client,"%T","String_06",client);
		
		// cool, now remove their weapons besides knife and c4 
		for(new slot=0;slot<10;slot++)
		{
			new ent=GetEntDataEnt2(client,MyWeaponsOffset+(slot*4));
			if(ent>0 && IsValidEdict(ent))
			{
				new String:ename[64];
				GetEdictClassname(ent,ename,64);
				if(StrEqual(ename,"weapon_c4") || StrEqual(ename,"weapon_knife"))
				{
					continue; // don't think we need to delete these
				}
				W3DropWeapon(client,ent);
				UTIL_Remove(ent);
			}
		}
		// restore iAmmo
		for(new ammotype=0;ammotype<32;ammotype++)
		{
			SetEntData(client,AmmoOffset+(ammotype*4),War3_CachedDeadAmmo(client,ammotype),4);
		}
		// give them their weapons
		for(new slot=0;slot<10;slot++)
		{
			new String:wep_check[64];
			War3_CachedDeadWeaponName(client,slot,wep_check,64);
			if(!StrEqual(wep_check,"weapon_c4") && !StrEqual(wep_check,"weapon_knife"))
			{
				new wep_ent=GivePlayerItem(client,wep_check);
				if(wep_ent>0) 
				{
					///dont set clip
					//SetEntData(wep_ent,Clip1Offset,War3_CachedDeadClip1(client,slot),4);
				}
			}
		}
		
	}
	else{
		//gone or respawned via some other race/item
		bNemHasRespawned[client]=false;
	}
}

public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	for(new x=1;x<=MaxClients;x++)
		bNemHasRespawned[x]=false;
}