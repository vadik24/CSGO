public Plugin:myinfo = 
{
	name = "War3Source Race - Witch Doctor",
	author = "TeachCreature and Lucky",
	description = "Witch Doctor race of warcraft",
	version = "1.9",
	url = "warcraft-source.net"
}

#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
#include <sdkhooks>

new thisRaceID;

//Training
new WitchDoctorhealth[4]={0,20,30,40};
new Float:regen[4]={0.0,3.0,2.0,1.0};

//Sentry Ward
new EyeSprite, GlowSprite;
new bool:bDidCastYet[MAXPLAYERS];
new bool:bSentry[MAXPLAYERS];
new bool:bInRadius[MAXPLAYERS];
new Float:SentryWardLocation[MAXPLAYERS][3];
new Float:this_pos[MAXPLAYERS][3];
new Float:SentryRad[7]={0.0,500.0,550.0,600.0,650.0,700.0,750.0};
new SentryCLIENT[MAXPLAYERS];
new SentryTimer[MAXPLAYERS];

//Healing Ward
new BeamSprite, HaloSprite;
new bool:bHealing[MAXPLAYERS];
new Float:HealWardLocation[MAXPLAYERS][3];
new Float:HealRad[7]={0.0,250.0,300.0,350.0,400.0,450.0,500.0};
new HealCLIENT[MAXPLAYERS];

//Stasis Ward
new GlowEffect, StasisSprite;
new bool:bStasis[MAXPLAYERS];
new String:stasis[]="ambient/energy/zap9.mp3";
new Float:StasisWardLocation[MAXPLAYERS][3];
new Float:StasisRad[7]={0.0,125.0,130.0,135.0,140.0,145.0,150.0};
new StasisCLIENT[MAXPLAYERS];

//Skills & Ultimate
new SKILL_TRAINING, SKILL_SENTRY, ULT_HEALING, SKILL_STASIS;

public OnPluginStart()
{
	CreateTimer(0.1,CalcSentry,_,TIMER_REPEAT);
	CreateTimer(1.0,CalcStasis,_,TIMER_REPEAT);
	CreateTimer(0.5,CalcHeal,_,TIMER_REPEAT);
	LoadTranslations("w3s.race.wdoctor.phrases");
}

public OnMapStart()
{
	EyeSprite=PrecacheModel("models/props/wow/h_totem/totem.mdl");
	GlowSprite=PrecacheModel("materials/effects/fluttercore.vmt");
	StasisSprite=PrecacheModel("models/Roller_spikes.mdl");
	GlowEffect=PrecacheModel("sprites/physring1.vmt");
	BeamSprite=War3_PrecacheBeamSprite();
	HaloSprite=War3_PrecacheHaloSprite();
	//War3_PrecacheSound(stasis);
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==100){
		thisRaceID=War3_CreateNewRaceT("wdoctor");
		SKILL_TRAINING=War3_AddRaceSkillT(thisRaceID,"1",false,3);
		SKILL_SENTRY=War3_AddRaceSkillT(thisRaceID,"2",false,6);
		SKILL_STASIS=War3_AddRaceSkillT(thisRaceID,"3",false,6);
		ULT_HEALING=War3_AddRaceSkillT(thisRaceID,"4",false,6);
		War3_CreateRaceEnd(thisRaceID);
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace != thisRaceID){
		War3_WeaponRestrictTo(client,thisRaceID,"");
		W3ResetAllBuffRace(client,thisRaceID);
	}
	
	if(newrace == thisRaceID){
		//SetEntityModel(client, "models/player/war3/slow.mdl");
		Passive(client);
		SentryTimer[client]=0;
	}
	
}

public OnWar3EventSpawn(client)
{	
	bInRadius[client]=false;
	if(War3_GetRace(client)==thisRaceID){
		//SetEntityModel(client, "models/player/war3/slow.mdl");
		bDidCastYet[client]=false;
		bSentry[client]=false;
		bHealing[client]=false;
		bStasis[client]=false;
		Passive(client);
		SentryTimer[client]=0;
	}
	
}

public OnWar3EventDeath(victim,attacker)
{
	new race_victim=War3_GetRace(victim);
	
	if(race_victim==thisRaceID){
		bDidCastYet[victim]=false;
		bSentry[victim]=false;
		bHealing[victim]=false;
		bStasis[victim]=false;
		SentryTimer[victim]=0;
	}
}

public Passive(client){
	new skill_training=War3_GetSkillLevel(client,thisRaceID,SKILL_TRAINING);
		
	//War3_SetMaxHP(client,War3_GetMaxHP(client)+health[skill_training]);
	if(ValidPlayer(client,true,true))
	{
		War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,WitchDoctorhealth[skill_training]);
	}
	CreateTimer(regen[skill_training], Regen, client);
}

public Action:Regen(Handle:timer,any:client)
{
	if (ValidPlayer(client,true)){
		new skill_training=War3_GetSkillLevel(client,thisRaceID,SKILL_TRAINING);
		War3_HealToMaxHP(client,1);
		
		CreateTimer(regen[skill_training], Regen, client);
	}
	
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(!Silenced(client)){
		new skill_training=War3_GetSkillLevel(client,thisRaceID,SKILL_TRAINING);
		new skill_sentry=War3_GetSkillLevel(client,thisRaceID,SKILL_SENTRY);
		new skill_stasis=War3_GetSkillLevel(client,thisRaceID,SKILL_STASIS);
		
		
		if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client)){
			if(!bDidCastYet[client]){	
				if(skill_sentry>0){
					new Float:position111[3];
					War3_CachedPosition(client,position111);
					position111[2]+=5.0;
					bDidCastYet[client]=true;
					War3_CachedPosition(client,SentryWardLocation[client]);
					SentryCLIENT[client]=client;
					//bSentry[client]=true;
					//CreateTimer(60.0, disableSentry, client);
					SentryTimer[client]=600;
				}
				else
				{
					PrintHintText(client, "%T", "Level your Sentry Ward first", client);
				}
				
			}
			else
			{
				PrintHintText(client, "%T", "You've already used your ward", client);
			}
			
		}
		
		if(War3_GetRace(client)==thisRaceID && ability==1 && pressed && IsPlayerAlive(client)){
			if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_STASIS,true)){
				if(skill_stasis>0){
					if(skill_training>0){
						if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_STASIS,true)){
							new Float:position111[3];
							War3_CachedPosition(client,position111);
							position111[2]+=5.0;
							War3_CachedPosition(client,StasisWardLocation[client]);
							bStasis[client]=true;
							StasisCLIENT[client]=client;
							TE_SetupGlowSprite(StasisWardLocation[client],StasisSprite,1.2,5.0,255);
							TE_SendToClient(client,0.0);
							War3_CooldownMGR(client,15.0,thisRaceID,SKILL_STASIS,_,_);
							CreateTimer(15.0, disableStasis, client);
						}
					}
					else
					{
						PrintHintText(client, "%T", "You need more training", client);
					}
					
				}
				else
				{
					PrintHintText(client, "%T", "Level your Stasis Trap Ward first", client);
				}
				
			}
			
		}
		
	}
	else
	{
		PrintHintText(client,"%T","Silenced: Can not cast",client);
	}
	
}

//public Action:disableSentry(Handle:timer,any:client)
//{
//	bSentry[client]=false;
//}

public Action:disableHealing(Handle:timer,any:client)
{
	bHealing[client]=false;
}

public Action:disableStasis(Handle:timer,any:client)
{
	bStasis[client]=false;
}

public Action:CalcSentry(Handle:timer,any:userid)
{
	for(new x=1;x<=MaxClients;x++){
		if(ValidPlayer(x,true)){
			if(War3_GetRace(x)==thisRaceID){
				new client=SentryCLIENT[x];
				new skill_stasis=War3_GetSkillLevel(client,thisRaceID,SKILL_STASIS);
				new Float:victimPos[3];
				if(SentryWardLocation[client][0]==0.0&&SentryWardLocation[client][1]==0.0&&SentryWardLocation[client][2]==0.0){
				}
				else 
				{
					if(SentryTimer[client]>1){
						TE_SetupGlowSprite(SentryWardLocation[client],EyeSprite,1.0,10.0,255);
						TE_SendToAll();
						SentryTimer[client]--;
						new ownerteam=GetClientTeam(client);
						for (new i=1;i<=MaxClients;i++){
							if(ValidPlayer(i,true)&& GetClientTeam(i)!=ownerteam){
								GetClientAbsOrigin(i,victimPos);
								if(GetVectorDistance(SentryWardLocation[client],victimPos)<SentryRad[skill_stasis]){
									GetClientAbsOrigin(i,this_pos[i]);
									this_pos[i][2]+=20;
									TE_SetupGlowSprite(this_pos[i],GlowSprite,0.1,0.3,80);
									TE_SendToClient(client,0.0);
									
								}
							}
						}
					}
				}
			}
		}
	}
}

public Action:CalcHeal(Handle:timer,any:userid)
{
	for(new x=1;x<=MaxClients;x++){
		if(ValidPlayer(x,true)){
			if(War3_GetRace(x)==thisRaceID){
				new client=HealCLIENT[x];
				new ult_healing=War3_GetSkillLevel(client,thisRaceID,ULT_HEALING);
				new Float:allyPos[3];
				if(HealWardLocation[client][0]==0.0&&HealWardLocation[client][1]==0.0&&HealWardLocation[client][2]==0.0){
				}
				else 
				{
					if(bHealing[client])
					{
						new ownerteam=GetClientTeam(client);
						for (new i=1;i<=MaxClients;i++){
							if(ValidPlayer(i,true)&& GetClientTeam(i)==ownerteam){
								GetClientAbsOrigin(i,allyPos);
								if(GetVectorDistance(HealWardLocation[client],allyPos)<HealRad[ult_healing]){
									if(GetClientHealth(i)<War3_GetMaxHP(i)){
										new hpadd=(War3_GetMaxHP(i)*2/100);
										War3_HealToMaxHP(i,hpadd);	
										W3FlashScreen(i,{0,100,0,50});
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

public Action:CalcStasis(Handle:timer,any:userid)
{
	for(new x=1;x<=MaxClients;x++){
		if(ValidPlayer(x,true)){
			if(War3_GetRace(x)==thisRaceID){
				new client=StasisCLIENT[x];
				new skill_stasis=War3_GetSkillLevel(client,thisRaceID,SKILL_STASIS);
				new Float:victimPos[3];
				if(StasisWardLocation[client][0]==0.0&&StasisWardLocation[client][1]==0.0&&StasisWardLocation[client][2]==0.0){
				}
				else 
				{
					if(bStasis[client]){
						TE_SetupGlowSprite(StasisWardLocation[client],StasisSprite,1.2,5.0,255);
						TE_SendToClient(client);
						new ownerteam=GetClientTeam(client);
						for (new i=1;i<=MaxClients;i++){
							if(ValidPlayer(i,true)&& GetClientTeam(i)!=ownerteam&&bStasis[client]){
								GetClientAbsOrigin(i,victimPos);
								if(GetVectorDistance(StasisWardLocation[client],victimPos)<StasisRad[skill_stasis]){
									PrintHintText(i, "%T", "You've fallen for a trap", i);
									bStasis[client]=false;
									W3FlashScreen(i,{255,50,0,50});
									War3_DealDamage(i,10,client,DMG_BULLET,"Stasis Trap Ward");
									War3_SetBuff(i,bStunned,thisRaceID,true);
									TE_SetupGlowSprite(StasisWardLocation[client],GlowEffect,2.5,5.0,255);
									TE_SendToClient(client,0.0);
									EmitSoundToAll(stasis,client);
									EmitSoundToAll(stasis,i);
									CreateTimer(2.5, Undo, i);
								}
							}
						}
					}
				}
			}
		}
	}
}

public Action:Undo(Handle:timer,any:victim)
{
	War3_SetBuff(victim,bStunned,thisRaceID,false);
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true)){
		if(War3_SkillNotInCooldown(client,thisRaceID,ULT_HEALING,true)){
			new ult_healing=War3_GetSkillLevel(client,thisRaceID,ULT_HEALING);
			new skill_training=War3_GetSkillLevel(client,thisRaceID,SKILL_TRAINING);
			if(ult_healing>0){
				if(skill_training>2){
					if(War3_SkillNotInCooldown(client,thisRaceID,ULT_HEALING,true)){
						new Float:position111[3];
						War3_CachedPosition(client,position111);
						position111[2]+=5.0;
						War3_CachedPosition(client,HealWardLocation[client]);
						HealCLIENT[client]=client;
						bHealing[client]=true;
						CreateTimer(3.0, disableHealing, client);
						War3_CooldownMGR(client,5.0,thisRaceID,ULT_HEALING,_,_);
						new colors1[4]={65,190,226,155};
						new colors2[4]={0,0,255,155};
						new colors3[4]={100,100,100,155};
						if(GetClientTeam(client)==2){
							colors1={226,61,26,155};
							colors2={0,100,0,155};
							TE_SetupBeamRingPoint(position111,0.0,75.0,BeamSprite,HaloSprite,0,15,3.0,20.0,3.0,colors1,10,0);
							TE_SendToAll();
							TE_SetupBeamRingPoint(position111,75.0,150.0,BeamSprite,HaloSprite,0,15,3.0,20.0,3.0,colors2,10,0);
							TE_SendToAll();
							TE_SetupBeamRingPoint(position111,150.0,225.0,BeamSprite,HaloSprite,0,15,3.0,20.0,3.0,colors1,10,0);
							TE_SendToAll();
							TE_SetupBeamRingPoint(position111,225.0,300.0,BeamSprite,HaloSprite,0,15,3.0,20.0,3.0,colors2,10,0);
							TE_SendToAll();
							TE_SetupBeamRingPoint(position111,300.0,375.0,BeamSprite,HaloSprite,0,15,3.0,20.0,3.0,colors1,10,0);
							TE_SendToAll();
							TE_SetupBeamRingPoint(position111,375.0,450.0,BeamSprite,HaloSprite,0,15,3.0,20.0,3.0,colors2,10,0);
							TE_SendToAll();
							TE_SetupBeamRingPoint(position111,450.0,525.0,BeamSprite,HaloSprite,0,15,3.0,20.0,3.0,colors3,10,0);
							TE_SendToAll();
						}
						if(GetClientTeam(client)==3){
							colors1={40,190,255,155};
							colors2={0,100,0,155};
							TE_SetupBeamRingPoint(position111,0.0,75.0,BeamSprite,HaloSprite,0,15,3.0,20.0,3.0,colors1,10,0);
							TE_SendToAll();
							TE_SetupBeamRingPoint(position111,75.0,150.0,BeamSprite,HaloSprite,0,15,3.0,20.0,3.0,colors2,10,0);
							TE_SendToAll();
							TE_SetupBeamRingPoint(position111,150.0,225.0,BeamSprite,HaloSprite,0,15,3.0,20.0,3.0,colors1,10,0);
							TE_SendToAll();
							TE_SetupBeamRingPoint(position111,225.0,300.0,BeamSprite,HaloSprite,0,15,3.0,20.0,3.0,colors2,10,0);
							TE_SendToAll();
							TE_SetupBeamRingPoint(position111,300.0,375.0,BeamSprite,HaloSprite,0,15,3.0,20.0,3.0,colors1,10,0);
							TE_SendToAll();
							TE_SetupBeamRingPoint(position111,375.0,450.0,BeamSprite,HaloSprite,0,15,3.0,20.0,3.0,colors2,10,0);
							TE_SendToAll();
							TE_SetupBeamRingPoint(position111,450.0,525.0,BeamSprite,HaloSprite,0,15,3.0,20.0,3.0,colors3,10,0);
							TE_SendToAll();
						}
					}
				}
				else
				{
					PrintHintText(client, "%T", "You need more training");
				}
				
			}
			else
			{
				PrintHintText(client, "%T","Level your Healing Ward first", client);
			}
			
		}	
	}
}