/**
* File: War3Source_Zackei.sp
* Description: The Zackei race for War3Source(ported from wc source).
* Author(s): Revan
*/

#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#define CHAT_COLOR 0x03

new thisRaceID;

new Handle:ultCooldownCvar;
new bool:bIsLANCEed[MAXPLAYERS];
//chances etc.
new Float:LANCEChance[5]={0.0,0.15,0.25,0.35,0.46};
new Float:MChance[5]={0.0,0.15,0.25,0.32,0.39};
new Float:FChance[5]={0.0,0.35,0.42,0.46,0.49};
//new Float:ARCANEDistance[5]={0.0,600.0,800.0,1000.0,1200.0};
new Float:burnarr[9]={1.0,1.5,2.0,3.5,4.12};
new Float:dmgref[5]={1.0,4.0,6.0,7.0,8.0};
new bool:bBeenHit[MAXPLAYERS][MAXPLAYERS];
//new DevotionFBALL[5]={0,15,25,35,45};

new Float:LastDamageTime[MAXPLAYERS];

new BeamSprite,HaloSprite, Laserbeam, Orangebeam, FireBall;

new SKILL_MDMG, SKILL_LANCE, SKILL_FBALL,ULT_ARCANE;

new String:ARCANESound[]="weapons/physcannon/energy_sing_flyby2.mp3";
new String:snd[]="weapons/explode4.mp3";
new String:amr[]="physics/concrete/boulder_impact_hard4.mp3";
new FlameSprite;
new Float:ChainDistanced[5]={0.0,50.0,100.0,150.0,200.0};
new spelldmg[5]={0,5,10,20,30};
//new Float:spelldmg2[5]={0.0,5.0,10.0,15.0,20.0};
public Plugin:myinfo = 
{
	name = "War3Source Race - Zackei",
	author = "Revan",
	description = "Zackei race for War3Source ported by revan.",
	version = "1.0.0.0",
	url = "http://wcs-lagerhaus.de"
};

public OnPluginStart()
{
	ultCooldownCvar=CreateConVar("war3_zackei_cooldown","35.0","Cooldown between ARCANES");
	ultCooldownCvar=CreateConVar("war3_human_teleport_cooldown","20.0","Cooldown between teleports");
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==123)
	{
		
		thisRaceID=War3_CreateNewRace("Zackei - Elementary Mage","zackei");
		SKILL_LANCE=War3_AddRaceSkill(thisRaceID,"Icelance","Freeze your enemy deep in the cold to slowdown his movement and attacking rate!",false,4);
		SKILL_FBALL=War3_AddRaceSkill(thisRaceID,"Fireball","Launches a Fireball at your target enemy hero to inclit a fire",false,4);
		SKILL_MDMG=War3_AddRaceSkill(thisRaceID,"Icearmor","Reflecs some damage done to you with your Magic Frost Armor",false,4);
		ULT_ARCANE=War3_AddRaceSkill(thisRaceID,"Arcane Explosion","Releases an Arcane Explosion:\nThe main damage target will be the nearest...\nthe other will only get small damage",true,4);
		W3SkillCooldownOnSpawn(thisRaceID,ULT_ARCANE,10.0,_);
		War3_CreateRaceEnd(thisRaceID);
	}
}


public OnMapStart()
{
	BeamSprite=War3_PrecacheBeamSprite();
	Laserbeam=PrecacheModel("sprites/laserbeam.vmt");
	Orangebeam=PrecacheModel("sprites/orangelight1.vmt");
	HaloSprite=War3_PrecacheHaloSprite();
	FlameSprite=PrecacheModel("sprites/fireburst.vmt");
	FireBall=PrecacheModel("sprites/flatflame.vmt");
	////War3_PrecacheSound(ARCANESound);
	////War3_PrecacheSound(snd);
	////War3_PrecacheSound(amr);
}

public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
	LastDamageTime[victim]=GetGameTime();
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			new race=War3_GetRace(attacker);
			if(race==thisRaceID)
			{
				new skill_LANCE=War3_GetSkillLevel(attacker,race,SKILL_LANCE);
				if(skill_LANCE && !W3HasImmunity(victim,Immunity_Skills))
				{
					// ICE LANCE
					new Float:chance_mod=1.0;
					new Float:percent=LANCEChance[skill_LANCE];
					if(GetRandomFloat(0.0,1.0)<=percent*chance_mod && !bIsLANCEed[victim] && IsPlayerAlive(attacker))
					{
						//PrintToChat(victim, "You've been slowed down", CHAT_COLOR);
						PrintToChat(attacker, "\x03You've slowed  enemy and damaged him for some extra damage.");
						PrintToChat(victim, "\x03You've been slowed down");
						//PrintToChat(attacker, "You've slowed  enemy and damaged him for 10 damage.", CHAT_COLOR);
						bIsLANCEed[victim]=true;
						//EmitSoundToAll( ARCANESound , victim,_,SNDLEVEL_TRAIN);
						//EmitSoundToAll( ARCANESound , attacker,_,SNDLEVEL_TRAIN);
						War3_SetBuff(victim,fSlow,thisRaceID,0.6);
						War3_SetBuff(victim,fAttackSpeed,thisRaceID,0.6);
						W3FlashScreen(victim,RGBA_COLOR_BLUE);
						CreateTimer(0.19,slow,GetClientUserId(victim));
						War3_DealDamage(victim,10,attacker,DMG_BULLET,"Ice Lance");
						new Float:spos[3];
						new Float:epos[3];
						GetClientAbsOrigin(attacker,epos);
						GetClientAbsOrigin(victim,spos);
						spos[2]+=50;
						epos[2]+=60;
						TE_SetupBeamPoints(epos,spos,Laserbeam,HaloSprite,0,41,1.6,6.0,15.0,1,4.5,{154,209,209,220},45);
						TE_SendToAll();
						TE_SetupBeamRingPoint(epos, 10.0, 20.0, Laserbeam, HaloSprite, 0, 15, 0.5, 5.0, 50.0, {255,100,100,220}, 120, 0);
						TE_SendToAll();
					}
				}
				new skill_FBALL=War3_GetSkillLevel(attacker,race,SKILL_FBALL);
				if(skill_FBALL && !W3HasImmunity(victim,Immunity_Skills))
				{
					// FIRE BALL
					new Float:chance_mod=1.0;
					new Float:percent=FChance[skill_FBALL];
					if(GetRandomFloat(0.0,1.0)<=percent*chance_mod && IsPlayerAlive(attacker))
					{
						new skill_level_burn=War3_GetSkillLevel(attacker,thisRaceID,SKILL_FBALL);
						PrintHintText(victim,"A Fireball hits you!");
						PrintHintText(attacker,"Fireball launched!");
						IgniteEntity(victim,burnarr[skill_level_burn]);
						War3_DealDamage(victim,GetRandomInt(3,6),attacker,DMG_BURN,"Fireball");
						//EmitSoundToAll( snd , victim,_,SNDLEVEL_TRAIN);
						//EmitSoundToAll( snd , attacker,_,SNDLEVEL_TRAIN);
						W3FlashScreen(victim,RGBA_COLOR_RED);
						W3FlashScreen(attacker,RGBA_COLOR_RED);
						new Float:spos[3];
						new Float:epos[3];
						GetClientAbsOrigin(victim,epos);
						GetClientAbsOrigin(attacker,spos);
						spos[2]+=45;
						epos[2]+=55;
						TE_SetupBeamPoints(epos, spos, FlameSprite, FlameSprite, 2, 5, 2.0, 50.0, 60.0, 3, 3.0, {255,80,20,255}, 30);
						TE_SendToAll();
						TE_SetupGlowSprite( epos,FireBall, 5.0 , 1.5 , 200);
						TE_SendToAll();
						TE_SetupBeamRingPoint(spos, 10.0, 120.0, FlameSprite, HaloSprite, 0, 15, 0.5, 10.0, 20.0, {255,255,255,120}, 120, 0);
						TE_SendToAll();
					}
				}
			}
			new racev=War3_GetRace(victim);
			if(racev==thisRaceID)
			{		
				new skill_LANCED=War3_GetSkillLevel(victim,racev,SKILL_MDMG);
				if(skill_LANCED && !W3HasImmunity(attacker,Immunity_Skills))
				{
					// Mirror Damage
					new Float:chance_mod=1.0;
					new Float:dam=dmgref[skill_LANCED];
					new Float:percent=MChance[skill_LANCED];
					if(GetRandomFloat(0.0,1.0)<=percent*chance_mod && IsPlayerAlive(victim))
					{
						PrintCenterText(attacker,"Got -%f damage!",dam);
						//War3_DealDamage(attacker,dam,victim,DMG_BULLET,"Ice Armor",false);
						War3_DealDamage(attacker,GetRandomInt(1,12),victim,DMG_BURN,"Ice Armor");
						// The Legendary Effects
						new Float:spos[3];
						new Float:epos[3];
						GetClientAbsOrigin(attacker,epos);
						GetClientAbsOrigin(victim,spos);
						spos[2]+=40;
						epos[2]+=40;
						TE_SetupBeamPoints(epos,spos,BeamSprite,HaloSprite,0,41,1.6,6.0,15.0,0,4.5,{255,160,130,255},45);
						TE_SendToAll();
						epos[1]+=170;
						TE_SetupBeamPoints(epos,spos,BeamSprite,HaloSprite,0,41,1.6,6.0,15.0,0,4.5,{255,160,130,255},45);
						TE_SendToAll(0.2);
						epos[0]+=70;
						TE_SetupBeamPoints(epos,spos,BeamSprite,HaloSprite,0,41,1.6,6.0,15.0,0,4.5,{255,160,130,255},45);
						TE_SendToAll(0.4);
						epos[0]-=70;
						epos[1]-=170;
						epos[2]-=40;
						TE_SetupBeamPoints(epos,spos,BeamSprite,HaloSprite,0,41,1.6,6.0,15.0,0,4.5,{255,160,130,255},45);
						TE_SendToAll(0.1);
						epos[0]+=50;
						TE_SetupBeamPoints(epos,spos,Orangebeam,HaloSprite,0,41,1.6,6.0,15.0,0,4.5,{255,160,130,255},45);
						TE_SendToAll(0.4);
					}
				}
			}
		}
	}
}


public OnWar3EventSpawn(client){
	bIsLANCEed[client]=false;
	new race = War3_GetRace(client);
	if (race == thisRaceID)
	{ 
		// Wirld Warl Effect
		new Float:iVec[ 3 ];
		GetClientAbsOrigin( client, Float:iVec );
		//TE_SetupSmoke( iVec, smokey, 10.0, 1 );
		//TE_SendToAll(1.0);
		new Float:iVec2[ 3 ];
		GetClientAbsOrigin( client, Float:iVec2 );
		TE_SetupBeamRingPoint(iVec, 10.0, 120.0, FlameSprite, HaloSprite, 0, 15, 1.5, 10.0, 20.0, {255,255,255,120}, 120, 0);
		TE_SendToAll();
		iVec[2]+=10.0;
		TE_SetupBeamRingPoint(iVec, 10.0, 120.0, FlameSprite, HaloSprite, 0, 15, 1.5, 10.0, 20.0, {255,255,255,120}, 120, 0);
		TE_SendToAll(0.21);
		iVec[2]+=10.0;
		TE_SetupBeamRingPoint(iVec, 10.0, 120.0, FlameSprite, HaloSprite, 0, 15, 1.5, 10.0, 20.0, {255,255,255,120}, 120, 0);
		TE_SendToAll(0.22);
		iVec[2]+=10.0;
		TE_SetupBeamRingPoint(iVec, 10.0, 120.0, FlameSprite, HaloSprite, 0, 15, 1.5, 10.0, 20.0, {255,255,255,120}, 120, 0);
		TE_SendToAll(0.23);
		iVec[2]+=10.0;
		/*TE_SetupBeamRingPoint(iVec, 10.0, 120.0, FlameSprite, HaloSprite, 0, 15, 0.5, 10.0, 20.0, {255,255,255,120}, 120, 0);
		TE_SendToAll(0.24);
		iVec[2]+=10.0;
		TE_SetupBeamRingPoint(iVec, 10.0, 120.0, FlameSprite, HaloSprite, 0, 15, 0.5, 10.0, 20.0, {255,255,255,120}, 120, 0);
		TE_SendToAll(0.25);
		iVec[2]+=10.0;
		TE_SetupBeamRingPoint(iVec, 10.0, 120.0, FlameSprite, HaloSprite, 0, 15, 0.5, 10.0, 20.0, {255,255,255,120}, 120, 0);
		TE_SendToAll(0.26);
		iVec[2]+=10.0;
		TE_SetupBeamRingPoint(iVec, 10.0, 120.0, FlameSprite, HaloSprite, 0, 15, 0.5, 10.0, 20.0, {255,255,255,120}, 120, 0);
		TE_SendToAll(0.32);
		iVec[2]+=10.0;
		TE_SetupBeamPoints(iVec, iVec2, BeamSprite, HaloSprite, 0, 35, 1.0, 10.0, 10.0, 0, 10.0, {25,25,25,255}, 30);
		TE_SendToAll(0.38);
		iVec2[2]+=110.0;
		iVec2[0]+=20.0;
		TE_SetupBeamPoints(iVec2,iVec,BeamSprite,HaloSprite,0,41,3.6,6.0,15.0,0,4.5,beamColor,45);
		TE_SendToAll();
		iVec2[0]-=40.0;
		TE_SetupBeamPoints(iVec2,iVec,BeamSprite,HaloSprite,0,41,3.6,6.0,15.0,0,4.5,beamColor,45);
		TE_SendToAll();
		iVec2[0]+=5.0;
		iVec2[2]-=5.0;
		TE_SetupBeamPoints(iVec2,iVec,BeamSprite,HaloSprite,0,41,3.6,6.0,15.0,0,4.5,beamColor,45);
		TE_SendToAll();
		iVec2[1]+=20.0;
		TE_SetupBeamPoints(iVec2,iVec,BeamSprite,HaloSprite,0,41,3.6,6.0,15.0,0,4.5,beamColor,45);
		TE_SendToAll();
		iVec2[2]+=5.0;
		iVec2[0]+=5.0;
		TE_SetupBeamPoints(iVec2,iVec,BeamSprite,HaloSprite,0,41,3.6,6.0,15.0,0,4.5,beamColor,45);
		TE_SendToAll();*/
		IgniteEntity(client,0.1);
	}
}


public Action:slow(Handle:timer,any:userid)
{
	new client=GetClientOfUserId(userid);
	if(client>0)
	{
		bIsLANCEed[client]=false;
		War3_SetBuff(client,fSlow,thisRaceID,1.0);
		War3_SetBuff(client,fAttackSpeed,thisRaceID,1.0);
	}
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && IsPlayerAlive(client))
	{
		new skill=War3_GetSkillLevel(client,race,ULT_ARCANE);
		if(skill>0)
		{
			if(War3_SkillNotInCooldown(client,thisRaceID,3,true))
			{
				for(new x=0;x<65;x++)
				bBeenHit[client][x]=false;
				new Float:distance=ChainDistanced[skill];
				new dmg=spelldmg[skill];
				DoSpell(client,distance,dmg,true,false);
				new Float:spos[3];
				GetClientAbsOrigin(client,spos);
				TE_SetupBeamRingPoint(spos,8.0,300.0,Orangebeam,HaloSprite,2,9,1.1,2.0,2.0,{255,255,255,255},15,0);
				TE_SendToAll();
			}
		}
		else
		{
			W3MsgUltNotLeveled(client);
		}
	}
}

public DoSpell(client,Float:distance,dmg,bool:first_call,last_target)
{
	new target=0;
	new Float:target_dist=distance+1.0;
	new caster_team=GetClientTeam(client);
	new Float:start_pos[3];
	if(last_target<=0)
	GetClientAbsOrigin(client,start_pos);
	else
	GetClientAbsOrigin(last_target,start_pos);
	for(new x=1;x<=MaxClients;x++)
	{
		if(ValidPlayer(x,true)&&!bBeenHit[client][x]&&caster_team!=GetClientTeam(x)&&!W3HasImmunity(x,Immunity_Ultimates))
		{
			new Float:this_pos[3];
			GetClientAbsOrigin(x,this_pos);
			new Float:dist_check=GetVectorDistance(start_pos,this_pos);
			if(dist_check<=target_dist)
			{
				target=x;
				target_dist=dist_check;
			}
		}
	}
	if(target<=0)
	{
		if(first_call)
		{
			W3MsgNoTargetFound(client,distance);
		}
		else
		{
			new Float:cooldown=GetConVarFloat(ultCooldownCvar);
			War3_CooldownMGR(client,cooldown,thisRaceID,ULT_ARCANE,_,_);
		}
	}
	else
	{
		bBeenHit[client][target]=true;
		War3_DealDamage(target,58,client,DMG_ENERGYBEAM,"Arcane Explosion");
		PrintHintText(target,"Arcane Explosion dealt -%d damage to you!",War3_GetWar3DamageDealt());
		PrintHintText(client,"Arcane Explosion");
		start_pos[2]+=30.0;
		new Float:target_pos[3];
		GetClientAbsOrigin(target,target_pos);
		target_pos[2]+=30.0;
		TE_SetupBeamPoints(start_pos,target_pos,Orangebeam,HaloSprite,0,35,1.0,40.0,40.0,0,40.0,{255,111,255,90},40);
		TE_SendToAll();
		TE_SetupBeamRingPoint(target_pos,8.0,distance,FireBall,HaloSprite,2,9,1.0,135.0,2.0,{255,255,255,255},15,0);
		TE_SendToAll(0.1);
		TE_SetupBeamRingPoint(start_pos,8.0,distance,BeamSprite,HaloSprite,2,9,3.5,135.0,2.0,{255,20,20,255},15,0);
		TE_SendToAll(0.3);
		/*
		TE_SetupBeamRingPoint(start_pos,5.0,distance,FireBall,HaloSprite,2,9.0,8.0,200.0,7.0,{255,255,255,90},50,0);
		TE_SendToAll(1.2);
		TE_SetupBeamRingPoint(start_pos,5.0,distance,FireBall,HaloSprite,2,9.0,8.0,200.0,7.0,{255,255,255,90},50,0);
		TE_SendToAll(1.4);
		new race = War3_GetRace(client);
		if (race == thisRaceID)
		new level = War3_GetSkillLevel(client,race,ULT_ARCANE);
		if(level>0) {
			new Float:damage2=spelldmg2[level];*/
		DoSpell(client,distance,20,false,target);
		//}
	}
}