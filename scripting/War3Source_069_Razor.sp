/**
* File: War3Source_Razor.sp
* Description: The Razor race for War3Source.
* Author(s): Anthony Iacono 
*/

#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>

// War3Source stuff
new thisRaceID;

new BeamSprite;
new HaloSprite;

new Handle:ultCooldownCvar;

//skill 1
new Float:StaticPercent[5]={0.0,0.07,0.14,0.22,0.30};
//skill 2
new ElectricTideMaxDamage[5]={0,40,60,100,140};
new Float:ElectricTideRadius=370.0;
new Float:AbilityCooldownTime=15.0;
//skill 3
new Float:UnholySpeed[5]={1.0,1.05,1.10,1.15,1.20};
new Float:ThornsReturnDamage[5]={0.0,0.05,0.10,0.15,0.20};
// new Float:ThornsChance=0.30;
//skill4
new OverloadDuration=3; //HIT TIMES, DURATION DEPENDS ON TIMER
new OverloadRadius=300;
new OverloadDamagePerHit[5]={0,2,4,6,8};
new Float:OverloadDamageIncrease[5]={1.0,1.01,1.015,1.020,1.025};
new String:lightningSound[]="war3source/lightningbolt.mp3";
//other stuff
new SKILL_STATIC,SKILL_FIELD,SKILL_CURRENT,ULT_EOTS;

new Float:ElectricTideOrigin[MAXPLAYERS][3];
new ElectricTideLoopCountdown[MAXPLAYERS];

new UltimateZapsRemaining[MAXPLAYERS];
new Float:PlayerDamageIncrease[MAXPLAYERS];

new bool:HitOnForwardTide[MAXPLAYERS][MAXPLAYERS]; //[VICTIM][ATTACKER]
new bool:HitOnBackwardTide[MAXPLAYERS][MAXPLAYERS];
new bool:canreturndmg;

public Plugin:myinfo = 
{
	name = "War3Source Race - Razor",
	author = "Scyther",
	description = "The Razor race for War3Source.",
	version = "1.0.0.0",
	url = "http://war3source.com"
};

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==145)
	{
		thisRaceID=War3_CreateNewRace("Razor","razor");
		SKILL_STATIC=War3_AddRaceSkill(thisRaceID,"Charging","You create a bond between himself and the enemy,\nextorting from him HP",false,4);
		SKILL_FIELD=War3_AddRaceSkill(thisRaceID,"Plasma field","[+ability] Damage to all nearby enemies",false,4);
		SKILL_CURRENT=War3_AddRaceSkill(thisRaceID,"Beast","Increases movement speed and represents the damage",false,4);
		ULT_EOTS=War3_AddRaceSkill(thisRaceID,"Eye of storm","You call a violent storm that causes\ndamage to the enemies of deadly lightning flashed.\nYour lightning strikes weak enemies",true,4); 
		War3_CreateRaceEnd(thisRaceID);
	}
}

public OnPluginStart()
{
	ultCooldownCvar=CreateConVar("war3_cd_ult_cooldown","30","Cooldown time for Razor ult Storm.");
}

public OnMapStart()
{
	BeamSprite=War3_PrecacheBeamSprite();
	HaloSprite=War3_PrecacheHaloSprite();
	////War3_PrecacheSound(lightningSound);
}

public OnW3TakeDmgAllPre(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			new race=War3_GetRace(attacker);
			//new Float:chance_mod=W3ChanceModifier(attacker);
			if(race==thisRaceID)
			{
				new skill_level=War3_GetSkillLevel(attacker,race,SKILL_STATIC);
				// new Float:chance=0.40*chance_mod; //&&GetRandomFloat(0.0,1.0)<=chance&&
				if(skill_level>0&&!W3HasImmunity(victim,Immunity_Skills))
				{	
					new Float:percent_health=StaticPercent[skill_level];
					new leechhealth=RoundToFloor(damage*percent_health);
					if(leechhealth>40) leechhealth=40; // woah, woah, woah, AWPs!
					if(leechhealth)
					{
						
						PrintHintText(victim,"The enemy has stolen -%d HP",leechhealth);
						PrintHintText(attacker,"Stolen +%d HP!",leechhealth);
						
						
						//new newhealth_attacker=GetClientHealth(attacker)+leechhealth;
						//new Float:multi=(War3_GetGame()==Game_TF)?1.5:1.0;
						//
						//if(newhealth_attacker>War3_GetMaxHP(attacker)*multi){
						//	newhealth_attacker=RoundFloat(War3_GetMaxHP(attacker)*multi);
						//}
						
						
						new Float:victimoriginp[3];
						new Float:attackeroriginp[3];
						GetClientAbsOrigin(victim,victimoriginp);
						GetClientAbsOrigin(attacker,attackeroriginp);
						attackeroriginp[2]+=15.0;
						victimoriginp[2]+=15.0;
						TE_SetupBeamPoints(attackeroriginp,victimoriginp,BeamSprite,0,0,0,1.0,4.0,4.0,10,9.0,{0,178,238,255},20);
						TE_SendToAll();
						//SetEntityHealth(attacker,newhealth_attacker);
						
						War3_HealToBuffHP(attacker,leechhealth);
					}
				}
			}
			/*new race_victim=War3_GetRace(victim);
			new skill_dist=War3_GetSkillLevel(victim,race_victim,1);
			if(War3_GetGame()==Game_TF && race_victim==thisRaceID && skill_dist>0)
			{
			new Float:chance=DistractChance[skill_dist]*chance_mod;
			if(GetRandomFloat(0.0,1.0)<=chance &&!War3_GetImmunity(attacker,Immunity_Skills))
			{
			new Float:vel[3];
			new pos=GetRandomInt(0,1);
			vel[0]=GetRandomFloat(220.0,250.0);
			if(!pos)	vel[0]*=-1.0;
			pos=GetRandomInt(0,1);
			vel[1]=GetRandomFloat(220.0,250.0);
			if(!pos)	vel[1]*=-1.0;
			vel[2]=GetRandomFloat(220.0,250.0);
			TeleportEntity(attacker,NULL_VECTOR,NULL_VECTOR,vel);
			PrintHintText(attacker,"You are Distracted");
			War3_FlashScreen(attacker,RGBA_COLOR_BLUE);
			PrintHintText(victim,"Distracted Enemy!");
			}
			}*/
			canreturndmg=true;//this is a real bullet attack
			if(War3_GetRace(victim)==thisRaceID)
			{
				new skill_level=War3_GetSkillLevel(victim,thisRaceID,SKILL_CURRENT);
				if(skill_level>0)
				{
					new Float:chance_mod=W3ChanceModifier(attacker);
					if(GetRandomFloat(0.0,1.0)<=chance_mod) 
					{
						War3_DamageModPercent(1.0);  
					}
				}				
			}
		}
	}
}

public OnWar3EventPostHurt(victim,attacker,damage)
{
	
	if(canreturndmg&&ValidPlayer(victim,true)&&ValidPlayer(attacker,true)&&GetClientTeam(victim)!=GetClientTeam(attacker))
	{
		canreturndmg=false;
		if(War3_GetRace(victim)==thisRaceID)
		{
			new skill_level=War3_GetSkillLevel(victim,thisRaceID,SKILL_CURRENT);
			if(skill_level>0)
			{
				if(!W3HasImmunity(attacker,Immunity_Skills)){
					if(War3_GetGame()==Game_CS)
					{
						
						new returndmg=RoundFloat(FloatMul(ThornsReturnDamage[skill_level],float(damage)));
						War3_DealDamage(attacker,returndmg,victim,_,"spiked_carapace",W3DMGORIGIN_SKILL,W3DMGTYPE_PHYSICAL);
						new Float:victimoriginm[3];
						GetClientAbsOrigin(victim,victimoriginm);
						victimoriginm[2]+=12.0;
						TE_SetupBeamRingPoint(victimoriginm,5.0,50.0,BeamSprite,HaloSprite,0,50,1.0,2.0,10.0,{0,154,205,255},50,0);
						TE_SendToAll();
						PrintHintText(victim,"The enemy is reflected %d damage",War3_GetWar3DamageDealt());
						PrintHintText(attacker,"%d reflected %d damage skill of the Beast",victim,War3_GetWar3DamageDealt());
					}
				}
			}
		}
	}
}


public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
	{
		new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_FIELD);
		if(skill_level>0)
		{
			if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_FIELD,true))
			{
				GetClientAbsOrigin(client,ElectricTideOrigin[client]);
				ElectricTideOrigin[client][2]+=15.0;
				ElectricTideLoopCountdown[client]=20;
				
				for(new i=1;i<=MaxClients;i++){
					HitOnBackwardTide[i][client]=false;
					HitOnForwardTide[i][client]=false;
				}
				//50 IS THE CLOSE CHECK
				TE_SetupBeamRingPoint(ElectricTideOrigin[client], 20.0, ElectricTideRadius+50, BeamSprite, HaloSprite, 0, 5, 0.5, 5.0, 11.0, {99,184,255,183}, 60, 0);
				TE_SendToAll();
				
				CreateTimer(0.1,BurnLoop,GetClientUserId(client)); //damage
				CreateTimer(0.13,BurnLoop,GetClientUserId(client)); //damage
				CreateTimer(0.17,BurnLoop,GetClientUserId(client)); //damage
				
				CreateTimer(0.5,SecondRing,GetClientUserId(client));
				
				War3_CooldownMGR(client,AbilityCooldownTime,thisRaceID,SKILL_FIELD,_,_);
				
				PrintHintText(client,"Plasma Field!");
			}
		}
	}
}

public Action:SecondRing(Handle:timer,any:userid)
{
	new client=GetClientOfUserId(userid);
	TE_SetupBeamRingPoint(ElectricTideOrigin[client], ElectricTideRadius+50,20.0, BeamSprite, HaloSprite, 0, 5, 0.5, 5.0, 11.0, {99,184,255,183}, 60, 0);
	TE_SendToAll();
}

public Action:BurnLoop(Handle:timer,any:userid)
{
	new attacker=GetClientOfUserId(userid);
	if(ValidPlayer(attacker) && ElectricTideLoopCountdown[attacker]>0)
	{
		new team = GetClientTeam(attacker);
		//War3_DealDamage(victim,damage,attacker,DMG_BURN);
		CreateTimer(0.1,BurnLoop,userid);
		
		new Float:damagingRadius=(1.0-FloatAbs(float(ElectricTideLoopCountdown[attacker])-10.0)/10.0)*ElectricTideRadius;
		
		//PrintToChatAll("distance to damage %f",damagingRadius);
		
		ElectricTideLoopCountdown[attacker]--;
		
		new Float:otherVec[3];
		for(new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,true)&&GetClientTeam(i)!=team&&!W3HasImmunity(i,Immunity_Skills))
			{
				if(ElectricTideLoopCountdown[attacker]<10){
					if(HitOnBackwardTide[i][attacker]==true){
						continue;
					}
				}
				else{
					if(HitOnForwardTide[i][attacker]==true){
						continue;
					}
				}	
				
				GetClientAbsOrigin(i,otherVec);
				otherVec[2]+=30.0;
				new Float:victimdistance=GetVectorDistance(ElectricTideOrigin[attacker],otherVec);
				if(victimdistance<ElectricTideRadius&&FloatAbs(otherVec[2]-ElectricTideOrigin[attacker][2])<25)
				{
					if(FloatAbs(victimdistance-damagingRadius)<(ElectricTideRadius/10.0))
					{
						if(ElectricTideLoopCountdown[attacker]<10){
							HitOnBackwardTide[i][attacker]=true;
						}
						else{
							HitOnForwardTide[i][attacker]=true;
						}
						War3_DealDamage(i,RoundFloat(ElectricTideMaxDamage[War3_GetSkillLevel(attacker,thisRaceID,SKILL_FIELD)]*victimdistance/ElectricTideRadius/5.0),attacker,DMG_ENERGYBEAM,"electrictide");
					}
					
				}
			}
		}
	}
}

public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		InitPassiveSkills(client);
	}
}
public InitPassiveSkills(client){
	if(War3_GetRace(client)==thisRaceID)
	{
		new skilllevel_unholy=War3_GetSkillLevel(client,thisRaceID,SKILL_CURRENT);
		if(skilllevel_unholy)
		{
			new Float:speed=UnholySpeed[skilllevel_unholy];
			War3_SetBuff(client,fMaxSpeed,thisRaceID,speed);
		}
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{
		//if(War3_GetGame()!=Game_TF) 
		W3ResetAllBuffRace(client,thisRaceID);
	}
	else
	{
		//if(oldrace==0){
		if(IsPlayerAlive(client)){
			InitPassiveSkills(client);
		}
	}
}

public OnWar3EventSpawn(client)
{
	new race=War3_GetRace(client);
	if(race==thisRaceID)
	{
		InitPassiveSkills(client);
		UltimateZapsRemaining[client]=0;
	}	
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && IsPlayerAlive(client))
	{
		//if(
		
		new skill=War3_GetSkillLevel(client,race,ULT_EOTS);
		if(skill>0)
		{
			if(War3_SkillNotInCooldown(client,thisRaceID,ULT_EOTS,true))
			{
				UltimateZapsRemaining[client]=OverloadDuration;
				if(War3_GetGame()==Game_CS){
					UltimateZapsRemaining[client]=OverloadDuration*2;
				}
				PlayerDamageIncrease[client]=1.0;
				War3_CooldownMGR(client,GetConVarFloat(ultCooldownCvar),thisRaceID,ULT_EOTS);
				
				CreateTimer(War3_GetGame()==Game_CS?0.25:0.5,UltimateLoop,GetClientUserId(client)); //damage
				
				//EmitSoundToAll(lightningSound,client);
			}
			
		}
		else
		{
			W3MsgUltNotLeveled(client);
		}
	}
}

public Action:UltimateLoop(Handle:timer,any:userid)
{
	new attacker=GetClientOfUserId(userid);
	if(ValidPlayer(attacker) && UltimateZapsRemaining[attacker]>0&&IsPlayerAlive(attacker))
	{
		UltimateZapsRemaining[attacker]--;
		new Float:pos[3];
		new Float:otherpos[3];
		GetClientEyePosition(attacker,pos);
		new team = GetClientTeam(attacker);
		new lowesthp=99999;
		new besttarget=0;
		
		for(new i=1;i<=MaxClients;i++){
			if(ValidPlayer(i,true)){
				
				if(GetClientTeam(i)!=team&&!W3HasImmunity(i,Immunity_Ultimates)){
					GetClientEyePosition(i,otherpos);
					if(War3_GetGame()==Game_CS){
						otherpos[2]-=20;
					}
					//PrintToChatAll("%d distance %f",i,GetVectorDistance(pos,otherpos));
					if(GetVectorDistance(pos,otherpos)<OverloadRadius){
						
						//TE_SetupBeamPoints(pos,otherpos,BeamSprite,HaloSprite,0,35,0.15,6.0,5.0,0,1.0,{255,255,255,100},20);
						//TE_SendToAll();
						
						new Float:distanceVec[3];
						SubtractVectors(otherpos,pos,distanceVec);
						new Float:angles[3];
						GetVectorAngles(distanceVec,angles);
						
						TR_TraceRayFilter(pos, angles, MASK_PLAYERSOLID, RayType_Infinite, CanHitThis,attacker);
						new ent;
						if(TR_DidHit(_))
						{
							ent=TR_GetEntityIndex(_);
							//PrintToChatAll("trace hit: %d      wanted to hit player: %d",ent,i);
						}
						
						if(ent==i&&GetClientHealth(i)<lowesthp){
							besttarget=i;
							lowesthp=GetClientHealth(i);
						}
					}
				}
			}
		}
		if(besttarget>0){
			pos[2]-=20.0;
			
			GetClientEyePosition(besttarget,otherpos);
			otherpos[2]-=20.0;
			TE_SetupBeamPoints(pos,otherpos,BeamSprite,HaloSprite,0,35,0.25,1.5,1.5,0,15.0,{99,184,255,255},20);
			TE_SendToAll();
			War3_DealDamage(besttarget,OverloadDamagePerHit[War3_GetSkillLevel(attacker,thisRaceID,ULT_EOTS)],attacker,_,"overload");
			PlayerDamageIncrease[attacker]*=OverloadDamageIncrease[War3_GetSkillLevel(attacker,thisRaceID,ULT_EOTS)];
			
		}
		CreateTimer(War3_GetGame()==Game_CS?0.25:0.5,UltimateLoop,GetClientUserId(attacker)); //damage
	}
	else
	{
		UltimateZapsRemaining[attacker]=0;
	}
}



public bool:CanHitThis(entity, mask, any:data)
{
	if(entity == data)
	{// Check if the TraceRay hit the itself.
		return false; // Don't allow self to be hit
	}
	return true; // It didn't hit itself
}

