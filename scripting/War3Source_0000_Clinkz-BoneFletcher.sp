/**
* File: War3Source_OnyxVendetta.sp
* Description: The Onyx Vendetta race for War3Source.
* Author(s): (Don)Revan
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include "W3SIncs/War3Source_Interface"
#include "revantools.inc"

new thisRaceID;
new SKILL_1,SKILL_2,SKILL_3,ULT;
new BeamSprite,BeamSprite2,HaloSprite,Skydome;
new bool:bWinded[MAXPLAYERS];
new Float:WindWalkTime[5]={0.0,2.0,3.0,4.5,6.0};
new Float:WindWalkInvis[5]={1.00,0.50,0.40,0.30,0.22};
new StrafeArrows[5]={0,2,3,4,5};
new regain0[5]={0,10,15,20,25};
new regain1[5]={0,15,20,25,35};
new ToDealArrow[MAXPLAYERS];
new ArrowTarget[MAXPLAYERS];
new String:Sound1[] = {"weapons/fx/nearmiss/bulletltor03.mp3"};
new String:ww_on[]="npc/scanner/scanner_nearmiss1.mp3";
new String:ww_off[]="npc/scanner/scanner_nearmiss2.mp3";
new String:Sound2[] = { "ambient/fire/mtov_flame2.mp3"};
new String:Sound3[] = {"weapons/fx/nearmiss/bulletltor05.mp3"};
new Handle:abCooldownCvar=INVALID_HANDLE;
new Handle:SearingArrowCh=INVALID_HANDLE;
new Handle:ultCircleEnable=INVALID_HANDLE;
public Plugin:myinfo = 
{
	name = "War3Source Race - Clinkz-Bone Fletcher",
	author = "DonRevan",
	description = "The old creature for War3Source.",
	version = "1.0.5.0",
	url = "www.wcs-lagerhaus.de"
};

public OnMapStart()
{
	BeamSprite2=PrecacheModel("materials/sprites/fire.vmt");
	BeamSprite=PrecacheModel("materials/sprites/laser.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
	Skydome=PrecacheModel("models/props_combine/portalskydome.mdl");
	PrecacheModel("effects/strider_bulge_dudv.vmt");
	PrecacheModel("sprites/tp_beam001.vmt");
	PrecacheSound("ambient/atmosphere/city_skypass1.mp3");
	//War3_PrecacheSound(Sound1);
	//War3_PrecacheSound(Sound2);
	//War3_PrecacheSound(Sound3);
	//War3_PrecacheSound(ww_on);
	//War3_PrecacheSound(ww_off);
}

public OnPluginStart()
{
	abCooldownCvar=CreateConVar("war3_clinkz_ability_cooldown","18","Cooldown time for Bonefletchers WindWalk.");
	SearingArrowCh=CreateConVar("war3_clinkz_searing_chance","0.21","Chance for Bonefletchers Searing Arrow skill.");
	ultCircleEnable=CreateConVar("war3_clinkz_ultimate_circle","1","Enable the big Circle Effect for the ultimate");
}

public OnWar3PluginReady()
{
	thisRaceID = War3_CreateNewRace( "Clinkz-Bone Fletcher", "clinkz" );
	SKILL_1=War3_AddRaceSkill(thisRaceID,"Strafe","Fire a large number of arrows in a short time period.",false,4);
	SKILL_2=War3_AddRaceSkill(thisRaceID,"Searing Arrows","Increases the damage of the Hero's attack by adding fire.",false,4);
	SKILL_3=War3_AddRaceSkill(thisRaceID,"Wind Walk","Turn invisible for a period of time, increasing movement speed.(+ability)",false,4); 
	ULT=War3_AddRaceSkill(thisRaceID,"Death Pact","Gain Health from killing targets",true,4); 
	War3_CreateRaceEnd( thisRaceID );
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

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
	{
		new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_3);
		if(skill_level>0)
		{
			if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_3,true))
			{
				if(!Silenced(client))
				{
					War3_SetBuff(client,fMaxSpeed,thisRaceID,1.3);
					new Float:this_pos[3];
					GetClientAbsOrigin(client,this_pos);
					TE_SetupBeamRingPoint(this_pos, 40.0, 90.0, HaloSprite, HaloSprite, 0, 5, 0.8, 50.0, 0.0, {155,115,100,200}, 1, 0) ;
					TE_SendToAll();
					TE_SetupBeamRingPoint(this_pos, 88.0, 150.0, HaloSprite, HaloSprite, 0, 5, 1.5, 20.0, 0.0, {155,115,100,200}, 1, 0) ;
					TE_SendToAll(0.75);
					TE_SetupDynamicLight(this_pos,120,120,120,12,80.0,1.88,1.0);
					TE_SendToAll();
					War3_SetBuff(client,fInvisibilitySkill,thisRaceID,WindWalkInvis[skill_level]);
					CreateTimer(WindWalkTime[skill_level],RemoveWindWalkBuff,client);
					War3_CooldownMGR(client,GetConVarFloat(abCooldownCvar),thisRaceID,SKILL_3,_,_);
					PrintHintText(client,"Wind Walk");
					bWinded[client]=true;
					new Float:fAngles[3]={0.0,0.0,0.0};
					CreateParticles(client,true,WindWalkTime[skill_level]+0.8,fAngles,45.0,15.0,25.0,0.0,"effects/strider_bulge_dudv.vmt","255 255 255","25","120","200","120");
					//CreateParticles(const client,bool:parentent,Float:fLifetime,Float:fAng[3],Float:BaseSpread,Float:StartSize,Float:EndSize,Float:Twist,String:material[],String:renderclr[],String:SpreadSpeed[],String:JetLength[],String:Speed[],String:Rate[]){
					EmitSoundToAll(ww_on,client);
					War3_SetBuff(client,bImmunitySkills,thisRaceID,true);
				}
				else
				{
					PrintHintText(client,"Silenced: Can not cast!");
				}
			}
		}
	}
}

public Action:RemoveWindWalkBuff(Handle:t,any:client)
{
	if(ValidPlayer(client,true) && bWinded[client]==true)
	{
		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0);
		War3_SetBuff(client,bImmunitySkills,thisRaceID,false);
		bWinded[client]=false;
		PrintHintText(client,"WindWalk disappears");
		EmitSoundToAll(ww_off,client);
		War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
		new Float:this_pos[3];
		GetClientAbsOrigin(client,this_pos);
		TE_SetupBeamRingPoint(this_pos, 90.0, 40.0, HaloSprite, HaloSprite, 0, 5, 0.8, 50.0, 0.0, {155,115,100,200}, 1, 0) ;
		TE_SendToAll();
		TE_SetupDynamicLight(this_pos,120,120,120,12,80.0,1.88,1.0);
		TE_SendToAll();
	}
}

public bool:FireArrow(const attacker,const victim,Float:delay,damage,bool:searingfire){
	if(ValidPlayer( attacker, true )&&ValidPlayer( victim, true ))
	{
		ToDealArrow[attacker]=damage;
		ArrowTarget[attacker]=victim;
		new Float:start_pos[3];
		new Float:target_pos[3];
		GetClientAbsOrigin(attacker,start_pos);
		GetClientAbsOrigin(victim,target_pos);
		target_pos[2]+=40.0;
		start_pos[2]+=45.0;
		
		start_pos[0] += GetRandomFloat( -38.0, 38.0 );
		start_pos[1] += GetRandomFloat( -38.0, 38.0 );
		if(searingfire==false)
		{
			new Float:FatTony = GetRandomFloat(1.0,2.8);
			TE_SetupBeamPoints(start_pos, target_pos, BeamSprite, HaloSprite, 0, 10, GetRandomFloat(0.8,1.4), FatTony, FatTony, 0, 4.5, {255,205,25,255}, 100);
			TE_SendToAll(delay);
		}
		else
		{
			TE_SetupBeamPoints(start_pos, target_pos, BeamSprite2, HaloSprite, 0, 80, GetRandomFloat(0.8,1.4), 1.35, 1.6, 0, 4.5, {255,255,255,255}, 100);
			TE_SendToAll(delay);
		}
		if(damage>0)
		{
			CreateTimer(delay,Timer_DealDamage,attacker);
		}
		else {
			EmitSoundToAll(Sound1,victim);
			EmitSoundToAll(Sound1,attacker);
		}
		return true;
	}
	return false;
}

public Action:Timer_DealDamage(Handle:t,any:attacker)
{
	if(ValidPlayer(attacker,true))
	{
		new victim = ArrowTarget[attacker];
		if(ValidPlayer(victim,true))
		{
			new damage = ToDealArrow[attacker];
			War3_DealDamage( victim, damage, attacker, DMG_BULLET, "arrow" );
			PrintHintText(victim,"Dealt +%i damage to your victim",damage);
			EmitSoundToAll(Sound1,victim);
			EmitSoundToAll(Sound1,attacker);
		}
	}
}

public OnW3TakeDmgBullet(victim,attacker,Float:damage)//OnWar3EventPostHurt( victim, attacker, damage )
{
	if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( attacker ) == thisRaceID && !W3HasImmunity(victim,Immunity_Skills) && !Hexed( attacker, false ))
		{
			new skill_level_strafe=War3_GetSkillLevel(attacker,thisRaceID,SKILL_1);
			if(skill_level_strafe>0)
			{	
				if( GetRandomFloat( 0.0, 1.0 ) <= 0.30 )
				{
					new arrows = StrafeArrows[attacker];
					for(new num=1;num<=arrows;num++)
					FireArrow(attacker,victim,GetRandomFloat(0.1,5.1),skill_level_strafe,false);
				}
			}
			new skill_dmg = War3_GetSkillLevel( attacker, thisRaceID, SKILL_2 );
			if(skill_dmg > 0)
			{
				if( GetRandomFloat( 0.0, 1.0 ) <= GetConVarFloat(SearingArrowCh) )
				{
					new String:wpnstr[32];
					GetClientWeapon( attacker, wpnstr, 32 );
					if(!StrEqual( wpnstr, "wep_knife" ) )
					{
						if(FireArrow(attacker,victim,0.2,0,true))
						{
							new damageamount = GetRandomInt(3,5);
							FireArrow(attacker,victim,1.8,0,true);
							EmitSoundToAll(Sound2,victim);
							EmitSoundToAll(Sound3,attacker);
							CreateFire(victim,"55","2","3","normal","16",0.0,3.0);
							War3_DealDamage( victim, damageamount, attacker, DMG_BULLET, "searing_arrow" );
							PrintCenterText(attacker,"Searing Arrows dealt +%i damage!",damageamount);
						}
					}
				}
			}
		}
	}
}

public OnWar3EventDeath(victim,attacker)
{
	new race=War3_GetRace(attacker);
	new skill=War3_GetSkillLevel(attacker,thisRaceID,ULT);
	if(race==thisRaceID && skill>0 && ValidPlayer( victim, false ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		new hpadd = GetRandomInt(regain1[skill],regain0[skill]);
		SetEntityHealth(attacker,GetClientHealth(attacker)+ hpadd);
		W3FlashScreen(attacker,RGBA_COLOR_RED,1.2,_,FFADE_IN);
		new Float:fVec[3] = {0.0,0.0,900.0};
		TE_SetupGlowSprite(fVec,Skydome,5.0,1.0,255);
		TE_SendToAll();
		CreateTesla(victim,1.0,3.0,10.0,60.0,3.0,4.0,600.0,"160","200","255 25 25","ambient/atmosphere/city_skypass1.mp3","sprites/tp_beam001.vmt",true);
		new Float:fAngles[3]={90.0,90.0,90.0};
		if(GetConVarBool(ultCircleEnable))
		CreateParticles(victim,false,3.0,fAngles,65.0,40.0,20.0,10.0,"sprites/tp_beam001.vmt","255 140 140","45","28","150","450");

		PrintHintText(victim,"Affected by a Death Pact");
		PrintHintText(attacker,"Death Pact :\nGained %d Health",hpadd);
	}
} 

public OnWar3EventSpawn(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		new Float:fVec[3] = {0.0,0.0,900.0};
		TE_SetupGlowSprite(fVec,Skydome,5.0,1.0,255);
		TE_SendToAll();
		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0);
		War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
		CreateTesla(client,1.0,3.0,10.0,60.0,3.0,4.0,600.0,"160","200","255 25 25","ambient/atmosphere/city_skypass1.mp3","sprites/tp_beam001.vmt",true);
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
    if(newrace!=thisRaceID)
    {
		bWinded[client]=false;
		W3ResetAllBuffRace(client,thisRaceID);
    }
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer( client, true ))
	{
		new skill=War3_GetSkillLevel(client,race,ULT);
		if(skill>0)
		//PrintHintText(client,"This is a passive ultimate!");
		W3MsgUltimateNotActivatable(client);
		else
		W3MsgUltNotLeveled(client);
	}
}