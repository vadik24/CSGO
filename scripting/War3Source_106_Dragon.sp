/**
* File: War3Source_Dragon.sp
* Description: Dragon race of warcraft.
* Author: Lucky 
*/
 
#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
#include <sdkhooks>

new thisRaceID;

//Evolution
new EvolutionHealth[9]={100,125,150,175,200,225,250,275,300};
new Float:EvolutionGravity[9]={1.0,0.95,0.90,0.85,0.80,0.75,0.70,0.65,0.60};
new Float:EvolutionSpeed[9]={1.0,0.95,0.90,0.85,0.80,0.75,0.75,0.75,0.75};

//Relentless Claws
new Float:ClawChance[9]={0.0,0.25,0.30,0.35,0.40,0.45,0.50,0.55,0.60};

//Ellementals on attack
new bIsElemental[MAXPLAYERS];
new Float:ElemAFireTime[9]={0.0,1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0};
new Float:ElemADarkTime[9]={0.0,0.5,1.0,1.5,2.0,2.5,3.0,3.5,4.0};
new Float:ElemAFrostTime[9]={0.0,0.4,0.6,0.8,1.0,1.2,1.4,1.6,2.0};
new Float:ElemAFrostEff[9]={1.0,0.95,0.9,0.85,0.80,0.75,0.70,0.65,0.60};
new Float:ElemACorruptTime[9]={0.0,1.0,1.5,2.0,2.5,3.0,3.5,4.0,5.0};
new Float:ElemACorruptEff[9]={1.0,0.95,0.9,0.85,0.80,0.75,0.70,0.65,0.60};
new Float:ElemAShockTime[9]={0.0,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5};
new const ElemAPoisonCont=10;
new PoisonTimes[9]={0,1,1,2,2,3,3,4,4};
new BeingPoisonedBy[MAXPLAYERS];
new PoisonRemaining[MAXPLAYERS];

//Ellementals on breath
new Float:ElemBFireTime[9]={0.0,1.0,2.0,3.0,4.0,5.0,6.0,7.0,8.0};
new Float:ElemBDarkTime[9]={0.0,1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0};
new Float:ElemBFrostTime[9]={0.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0};
new Float:ElemBFrostEff[9]={1.0,0.85,0.8,0.75,0.7,0.65,0.60,0.55,0.50};
new Float:ElemBCorruptTime[9]={0.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0};
new Float:ElemBCorruptEff[9]={1.0,0.85,0.8,0.75,0.7,0.65,0.60,0.55,0.50};
new Float:ElemBShockTime[9]={0.0,1.0,2.0,3.0,4.0,5.0,6.0,7.0,8.0};
new const ElemBPoisonCont=5;

//Stored timers
new bool:bDispelled[MAXPLAYERS];
new bool:bFrozen[MAXPLAYERS];
new bool:bSlown[MAXPLAYERS];
new bool:bEating[MAXPLAYERS];

//Devour
new bool:bIsDevour[MAXPLAYERS];
new bDevour[MAXPLAYERS];
new HealthRemaining[MAXPLAYERS];
new DevourHeal[9]={0,2,3,4,5,6,7,8,9};
new DevourDamage[9]={0,3,4,5,6,7,8,9,10};
new BeingDevouredBy[MAXPLAYERS];
new DevourKilled[MAXPLAYERS];
new bHealth[MAXPLAYERS];

//Breath
new Float:BreathDistance[9]={0.0,250.0,300.0,350.0,400.0,450.0,500.0,550.0,600.0};
new Float:BreathRadius[9]={0.0,16.0,18.0,20.0,22.0,24.0,26.0,28.0,30.0};
new BreathTime[9]={0,3,4,5,6,7,8,9,10};
new BreathRemaining[MAXPLAYERS];
new const BreathDamage=10;

//Skills & Ultimate
new SKILL_EVOLUTION, SKILL_CLAWS, SKILL_BREATH, SKILL_ELEMENTAL, ULT_DEVOUR;
 
new BurnSprite, g_iExplosionModel; 
new String:frost[]="dragon/attack/frost.mp3";
new String:corruption[]="dragon/attack/cripple.mp3";
new String:purge[]="dragon/attack/purge.mp3";
new String:darkness[]="dragon/attack/banish.mp3";
new String:poison[]="dragon/attack/poison.mp3";
new String:Bcorruption[]="dragon/breath/corruption.mp3";
new String:Bfire[]="dragon/breath/fire.mp3";
new String:Bfrost[]="dragon/breath/frozen.mp3";
new String:Bpoison[]="dragon/breath/corrosive.mp3";
new String:Bpurge[]="dragon/breath/purge.mp3";
new String:dragon[]="dragon/dragon.mp3";
new String:devour[]="dragon/devour/devour.mp3";
new String:Bdarkness[]="dragon/breath/darkness.mp3";
 
public Plugin:myinfo = 
{
	name = "War3Source Race - Dragon",
	author = "Lucky",
	description = "Dragon race of warcraft",
	version = "alpha",
	url = "http://warcraft-source.net/forum/index.php?topic=374.0"
}

public OnMapStart()
{
BurnSprite=PrecacheModel("materials/sprites/fire1.vmt");
g_iExplosionModel = PrecacheModel("materials/effects/fire_cloud1.vmt");
//War3_PrecacheSound(frost);
//War3_PrecacheSound(corruption);
//War3_PrecacheSound(purge);
//War3_PrecacheSound(poison);
//War3_PrecacheSound(Bcorruption);
//War3_PrecacheSound(darkness);
//War3_PrecacheSound(Bfire);
//War3_PrecacheSound(Bfrost);
//War3_PrecacheSound(Bdarkness);
//War3_PrecacheSound(Bpoison);
//War3_PrecacheSound(Bpurge);
//War3_PrecacheSound(dragon);
//War3_PrecacheSound(devour);
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==160)
	{
		thisRaceID=War3_CreateNewRace("Dragon", "dragon");
		SKILL_EVOLUTION=War3_AddRaceSkill(thisRaceID,"Evolution", "Increase health and time breath, decrease gravity and speed",false,8);
		SKILL_CLAWS=War3_AddRaceSkill(thisRaceID,"Relentless Claws", "Increase chance of elemental attack and it's effect",false,8);
		SKILL_BREATH=War3_AddRaceSkill(thisRaceID,"Dragon Breath (Ability)","Breath fire",false,8);
		SKILL_ELEMENTAL=War3_AddRaceSkill(thisRaceID,"Elemental Shift (Ability1)","Shift your element",false,8);
		ULT_DEVOUR=War3_AddRaceSkill(thisRaceID,"Devour (Ultimate)","Eat your opponent and restore your strenght by attacking him",true,8);
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
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
		if(ValidPlayer(client,true)){
			GivePlayerItem(client, "weapon_knife");
			Passive(client);
		}
		
	}
	
}

public OnWar3EventSpawn(client)
{
	//reset all timers
	bFrozen[client]=false;
	bDispelled[client]=false;
	bSlown[client]=false;
	
	if(War3_GetRace(client)==thisRaceID){
		Passive(client);
		bDevour[client]=false;
		HealthRemaining[client]=0;
		BreathRemaining[client]=0;
		bEating[client]=false;
		EmitSoundToAll(dragon,client);
		bIsDevour[client]=false;
	}
	
}

public Passive(client){
	if(ValidPlayer(client,true)&&War3_GetRace(client)==thisRaceID){
		new skill_evo=War3_GetSkillLevel(client,thisRaceID,SKILL_EVOLUTION);
		
		if(skill_evo){
			new Float:gravity=EvolutionGravity[skill_evo];
			new Float:speed=EvolutionSpeed[skill_evo];
			new health=EvolutionHealth[skill_evo];
			
			War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,health);
			SetEntityHealth(client,health);
			War3_SetBuff(client,fLowGravitySkill,thisRaceID,gravity);
			War3_SetBuff(client,fSlow,thisRaceID,speed);
		}
		
		//Give random element to client
		bIsElemental[client]=GetRandomInt(0,5); 
		//new rand_element=bIsElemental[client];
		switch (bIsElemental[client])
			{
				case 0:
					PrintToChat(client,"Fire");						
				case 1:
					PrintToChat(client,"Darkness");
				case 2:
					PrintToChat(client,"Frost");
				case 3:
					PrintToChat(client,"Lightning");
				case 4:
					PrintToChat(client,"Venom");
				case 5:
					PrintToChat(client,"Corruption");
			}
	}
	
}

public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim){
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		
		if(vteam!=ateam){
			new race_attacker=War3_GetRace(attacker);
			new skill_claw=War3_GetSkillLevel(attacker,thisRaceID,SKILL_CLAWS);
			
			if(race_attacker==thisRaceID && skill_claw>0 && !Silenced(attacker)){
				if(GetRandomFloat(0.0,1.0)<=ClawChance[skill_claw] && !W3HasImmunity(victim,Immunity_Skills)){
					new rand_element=bIsElemental[attacker];
					new skill_shift=War3_GetSkillLevel(attacker,thisRaceID,SKILL_ELEMENTAL);
					
					//Fire
					if(rand_element==0){
						//Give information to the players
						PrintHintText(attacker, "You set your enemy on fire");
						PrintHintText(victim, "You've been set on fire");
						
						IgniteEntity(victim, ElemAFireTime[skill_shift]);
					}
					//Darkness
					if(rand_element==1){
						EmitSoundToAll(darkness,victim);
						//Give information to the players
						PrintHintText(attacker, "You blind your enemy");
						PrintHintText(victim, "You've been blinded");
						
						W3FlashScreen(victim,{0,0,0,255},0.5,_,FFADE_STAYOUT);
						//Start timer to undo blinding
						CreateTimer(ElemADarkTime[skill_shift],Darkness,GetClientUserId(victim));
					}
					//Frost
					if(rand_element==2){
						EmitSoundToAll(frost,victim);
						//Check if the opponent is already being frozen, this to prevent overwrite of speed when getting it's value
						if (bFrozen[victim]){
							//Give information to the player
							PrintHintText(attacker, "Your enemy is already frozen");
						}
						else
						{
							//Give information to the players
							PrintHintText(attacker, "You freeze your enemy");
							PrintHintText(victim, "You've been frozen");
							
							War3_SetBuff(victim,fSlow,thisRaceID,ElemAFrostEff[skill_shift]);
							//Set the status to frozen to prevent overwrite
							bFrozen[victim]=true;
							//Start timer to undo slowdown
							CreateTimer(ElemAFrostTime[skill_shift],Frost,victim);
						}
							
					}
					//Lightning
					if(rand_element==3){
						EmitSoundToAll(purge,victim);
						//Check if the opponent is already being dispelled, this to prevent overwrite of the values
						if (bDispelled[victim]){
							//Give information to the player
							PrintHintText(attacker, "Your enemy is already dispelled");			
						}
						else
						{
							//Give information to the players
							PrintHintText(attacker, "You've dispelled your enemy");
							PrintHintText(victim, "You've been dispelled");
							
							War3_SetBuff(victim,bBuffDenyAll,thisRaceID,true);
							//Set the status to dispelled to prevent overwrite
							bDispelled[victim]=true;
							//Start timer to undo dispell
							CreateTimer(ElemAShockTime[skill_shift],Shock,victim);
						}
						
					}
					//Poison
					if(rand_element==4){
						EmitSoundToAll(poison,victim);
						//Give information to the players
						PrintHintText(attacker, "You've poisoned your enemy");
						PrintHintText(victim, "You've been poisoned");
						
						BeingPoisonedBy[victim]=attacker;
						PoisonRemaining[victim]=PoisonTimes[skill_shift];
						//Create timer to undo the poisoning
						CreateTimer(1.0,Poison,GetClientUserId(victim));
					}
					//Corruption
					if(rand_element==5){
						EmitSoundToAll(corruption,victim);
						//Check if the opponent is already being corrupted, this to prevent overwrite of attackspeed
						if(bSlown[victim]){
							//Give information to the player
							PrintHintText(attacker, "Your enemy is already slowed");
						}
						else
						{
							//Give information to the players
							PrintHintText(attacker, "You slow your enemy");
							PrintHintText(victim, "You've been slowed");
							
							War3_SetBuff(victim,fAttackSpeed,thisRaceID,ElemACorruptEff[skill_shift]);
							//Set the status to Corrupted to prevent overwrite
							bSlown[victim]=true;
							//Start timer to undo the corruption							
							CreateTimer(ElemACorruptTime[skill_shift],Corruption,victim);
						}
						
					}
				}
			}	
			//Devour
			//kill the victim and save his health to the attacker
			if(race_attacker==thisRaceID && bIsDevour[attacker] && !Silenced(attacker) &&!W3HasImmunity(victim,Immunity_Ultimates)){
				EmitSoundToAll(devour,victim);
				bHealth[victim]=GetClientHealth(victim);
				bEating[attacker]=true;
				War3_DealDamage(victim,900,	attacker,DMG_BULLET,"Devoured");
			}
			
		}	
				
	}
}

public Action:Stop(Handle:timer,any:client)
{
	StopSound(client,SNDCHAN_AUTO,Bdarkness);
}

public OnW3TakeDmgAllPre(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim){
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		
		if(vteam!=ateam){
			new race_victim=War3_GetRace(victim);
			
			if(race_victim==thisRaceID){	
				War3_DamageModPercent(0.60);
			}
			
		}
		
	}
	
}

public Action:Darkness(Handle:timer,any:userid)
{
		new client = GetClientOfUserId(userid);
		W3FlashScreen(client,{0,0,0,0},0.1,_,(FFADE_IN|FFADE_PURGE));
}

public Action:Frost(Handle:timer,any:victim)
{
		//Set status to Unfrozen
		bFrozen[victim]=false;

		War3_SetBuff(victim,fSlow,thisRaceID,1.0);
}

public Action:Shock(Handle:timer,any:victim)
{	
		//Set status to undispelled
		bDispelled[victim]=false;
		War3_SetBuff(victim,bBuffDenyAll,thisRaceID,false);
}

public Action:Poison(Handle:timer,any:userid)
{
	new client = GetClientOfUserId(userid);
	
	if(PoisonRemaining[client]>0 && ValidPlayer(BeingPoisonedBy[client]) && ValidPlayer(client,true)){
		War3_DealDamage(client,ElemAPoisonCont,BeingPoisonedBy[client],DMG_BULLET,"poison");
		PoisonRemaining[client]--;
		//Start timer over again
		CreateTimer(1.0,Poison,userid);
	}
	
}

public Action:PoisonBreath(Handle:timer,any:userid)
{
	new client = GetClientOfUserId(userid);
	
	if(PoisonRemaining[client]>0 && ValidPlayer(BeingPoisonedBy[client]) && ValidPlayer(client,true)){
		War3_DealDamage(client,ElemBPoisonCont,BeingPoisonedBy[client],DMG_BULLET,"poison");
		PoisonRemaining[client]--;
		//Start timer over again
		CreateTimer(1.0,PoisonBreath,userid);
	}
	
}

public Action:Corruption(Handle:timer,any:victim)
{		
	if (ValidPlayer(victim,true)){	
		//Set status to uncorrupted
		bSlown[victim]=false;
		War3_SetBuff(victim,fAttackSpeed,thisRaceID,1.0);
	}
	
}

public Action:Devour(Handle:timer,any:userid)
{
	new client=GetClientOfUserId(userid);
	new ult_devour=War3_GetSkillLevel(client,thisRaceID,ULT_DEVOUR);
	if(HealthRemaining[client]>0 && ValidPlayer(client,true)&&bDevour[client]){
		new hpremove=DevourDamage[ult_devour];
		new hpadd=DevourHeal[ult_devour];
		War3_HealToMaxHP(client,hpadd);	
		HealthRemaining[client]-=hpremove;
		
		if(HealthRemaining[client]<=0){
				HealthRemaining[client]=0;
				PrintHintText(client,"Your enemy has been devoured");
				bEating[client]=false;
				War3_CooldownMGR(client,40.0,thisRaceID,ULT_DEVOUR,_,_);
		}
	
		CreateTimer(1.0,Devour,userid);
	}
	
}

public OnWar3EventDeath(victim,attacker)
{
	if(ValidPlayer(victim)&&ValidPlayer(attacker)){
		new race_attacker=War3_GetRace(attacker);
		//Devour	
		if(race_attacker==thisRaceID && bIsDevour[attacker] && !Silenced(attacker) &&!W3HasImmunity(victim,Immunity_Ultimates)){
			//Give information to the player
			PrintHintText(attacker,"You have devoured your victim");
			PrintHintText(victim,"You've been devoured");
			BeingDevouredBy[attacker]=victim;
			bDevour[attacker]=true;
			HealthRemaining[attacker]=bHealth[victim];
			CreateTimer(1.0,Devour,GetClientUserId(attacker));
			bIsDevour[attacker]=false;
		}
			
		new devoured=BeingDevouredBy[victim];
		
		if(ValidPlayer(devoured)){
			if(!IsPlayerAlive(devoured) && HealthRemaining[attacker]>0){
				War3_ChatMessage(devoured, "Your killer died, you get to respawn");
				DevourKilled[devoured]=victim;
				CreateTimer(0.2,RespawnPlayer,devoured);
			}
			
			BeingDevouredBy[victim]=0;
		}
		
	}
	
}

public Action:RespawnPlayer(Handle:timer,any:client)
{
	if(client>0&&!IsPlayerAlive(client)&&ValidPlayer(DevourKilled[client])){
		War3_SpawnPlayer(client);
		new Float:pos[3];
		new Float:ang[3];
		new enemy=DevourKilled[client];
		new health=HealthRemaining[enemy];
		
		War3_CachedAngle(DevourKilled[client],ang);
		War3_CachedPosition(DevourKilled[client],pos);
		TeleportEntity(client,pos,ang,NULL_VECTOR);
		SetEntityHealth(client,health);
	}
	
}

public Action:Breath(Handle:timer,any:client)
{
	if(BreathRemaining[client]>0 && ValidPlayer(client,true)){
		new skill_breath=War3_GetSkillLevel(client,thisRaceID,SKILL_BREATH);
		new target = War3_GetTargetInViewCone(client,BreathDistance[skill_breath],false,BreathRadius[skill_breath]);
		new Float:pos[3]; 
		
		GetClientAbsOrigin(client,pos);
		pos[2]+=30;		
		
		if(target>0){
			new Float:targpos[3];
			TE_SetupGlowSprite(pos,BurnSprite,1.0,1.9,255);
			TE_SendToAll();
			GetClientAbsOrigin(target,targpos);
			TE_SetupBeamPoints(pos, targpos, BurnSprite, BurnSprite, 0, 8, 0.5, 10.0, 10.0, 10, 10.0, {255,255,255,255}, 70); 
			TE_SendToAll();
			GetClientAbsOrigin(target,targpos);
			targpos[2]+=50;
			TE_SetupGlowSprite(targpos,BurnSprite,1.0,1.9,255);
			TE_SendToAll();
			if(!W3HasImmunity(target,Immunity_Skills)){
				new rand_element=bIsElemental[client];
				
				War3_DealDamage(target,BreathDamage,client,DMG_BULLET,"breath");						
				//Fire
				if(rand_element==0){
					PrintHintText(target, "You've been set on fire");
					
					IgniteEntity(target, ElemBFireTime[skill_breath]);
					new Float:distance=BreathDistance[skill_breath]; 
					GetClientAbsOrigin(client,pos);
					TE_SetupGlowSprite(pos,BurnSprite,1.0,1.9,255);
					TE_SendToAll();
					TE_SetupBeamRingPoint(pos, distance, distance+5, BurnSprite, g_iExplosionModel,0,15,1.0,5.0,3.0,{255,0,0,255},10,0);
					TE_SendToClient(client, 0.0);
				}
				//Darkness
				if(rand_element==1){
					new Float:distance=BreathDistance[skill_breath]; 
					GetClientAbsOrigin(client,pos);
					TE_SetupGlowSprite(pos,BurnSprite,1.0,1.9,255);
					TE_SendToAll();
					TE_SetupBeamRingPoint(pos, distance, distance+5, BurnSprite, g_iExplosionModel,0,15,1.0,5.0,3.0,{50,50,50,255},10,0);
					TE_SendToClient(client, 0.0);
					PrintHintText(target, "You've been blinded");
					W3FlashScreen(target,{0,0,0,255},0.5,_,FFADE_STAYOUT);
					CreateTimer(ElemBDarkTime[skill_breath],Darkness,GetClientUserId(target));
				}
				//Frost
				if(rand_element==2){
					new Float:distance=BreathDistance[skill_breath];
					GetClientAbsOrigin(client,pos);
					TE_SetupGlowSprite(pos,BurnSprite,1.0,1.9,255);
					TE_SendToAll();
					TE_SetupBeamRingPoint(pos, distance, distance+5, BurnSprite, g_iExplosionModel,0,15,1.0,5.0,3.0,{0,0,255,255},10,0);
					TE_SendToClient(client, 0.0);
					if (bFrozen[target]){
						PrintHintText(client, "Your enemy is already frozen");
					}
					else
					{
						PrintHintText(target, "You've been frozen");

						War3_SetBuff(target,fSlow,thisRaceID,ElemBFrostEff[skill_breath]);
						//Set the status to frozen to prevent overwrite
						bFrozen[target]=true;
						//Start timer to undo slowdown
						CreateTimer(ElemBFrostTime[skill_breath],Frost,target);
					}
							
				}
				//Lightning
				if(rand_element==3){
					new Float:distance=BreathDistance[skill_breath];
					GetClientAbsOrigin(client,pos);
					TE_SetupGlowSprite(pos,BurnSprite,1.0,1.9,255);
					TE_SendToAll();
					TE_SetupBeamRingPoint(pos, distance, distance+5, BurnSprite, g_iExplosionModel,0,15,1.0,5.0,3.0,{255,255,0,255},10,0);
					TE_SendToClient(client, 0.0);
					if (bDispelled[target]){
						PrintHintText(client, "Your enemy is already dispelled");			
					}
					else
					{
						PrintHintText(target, "You've been dispelled");
						
						War3_SetBuff(target,bBuffDenyAll,thisRaceID,true);
						//Set the status to dispelled to prevent overwrite
						bDispelled[target]=true;
						//Start timer to undo dispell
						CreateTimer(ElemBShockTime[skill_breath],Shock,target);
					}
						
				}
				//Poison
				if(rand_element==4){
					new Float:distance=BreathDistance[skill_breath];
					GetClientAbsOrigin(client,pos);
					TE_SetupGlowSprite(pos,BurnSprite,1.0,1.9,255);
					TE_SendToAll();
					TE_SetupBeamRingPoint(pos, distance, distance+5, BurnSprite, g_iExplosionModel,0,15,1.0,5.0,3.0,{0,255,0,255},10,0);
					TE_SendToClient(client, 0.0);
					PrintHintText(target, "You've been poisoned");
						
					BeingPoisonedBy[target]=client;
					PoisonRemaining[target]=PoisonTimes[skill_breath];
					//Create timer to undo the poisoning
					CreateTimer(1.0,PoisonBreath,GetClientUserId(target));
				}
				//Corruption
				if(rand_element==5){
					new Float:distance=BreathDistance[skill_breath];
					GetClientAbsOrigin(client,pos);
					TE_SetupGlowSprite(pos,BurnSprite,1.0,1.9,255);
					TE_SendToAll();
					TE_SetupBeamRingPoint(pos, distance, distance+5, BurnSprite, g_iExplosionModel,0,15,1.0,5.0,3.0,{120,0,255,255},10,0);
					TE_SendToClient(client, 0.0);
					if(bSlown[target]){
						PrintHintText(client, "Your enemy is already slowed"); 
					}
					else
					{
						PrintHintText(target, "You've been slowed");

						War3_SetBuff(target,fAttackSpeed,thisRaceID,ElemBCorruptEff[skill_breath]);
						//Set the status to Corrupted to prevent overwrite
						bSlown[target]=true;
						//Start timer to undo the corruption							
						CreateTimer(ElemBCorruptTime[skill_breath],Corruption,target);
					}
						
				}
				}	
			}
			else
			{
				new rand_element=bIsElemental[client];
					
				if(rand_element==0){
					new Float:distance=BreathDistance[skill_breath];
					GetClientAbsOrigin(client,pos);
					TE_SetupGlowSprite(pos,BurnSprite,1.0,1.9,255);
					TE_SendToAll();
					TE_SetupBeamRingPoint(pos, distance, distance+5, BurnSprite, g_iExplosionModel,0,15,1.0,5.0,3.0,{255,0,0,255},10,0);
					TE_SendToClient(client, 0.0);
				}
				if(rand_element==1){
					new Float:distance=BreathDistance[skill_breath]; 
					GetClientAbsOrigin(client,pos);
					TE_SetupGlowSprite(pos,BurnSprite,1.0,1.9,255);
					TE_SendToAll();
					TE_SetupBeamRingPoint(pos, distance, distance+5, BurnSprite, g_iExplosionModel,0,15,1.0,5.0,3.0,{50,50,50,255},10,0);
					TE_SendToClient(client, 0.0);
				}
				if(rand_element==2){
					new Float:distance=BreathDistance[skill_breath];
					GetClientAbsOrigin(client,pos);
					TE_SetupGlowSprite(pos,BurnSprite,1.0,1.9,255);
					TE_SendToAll();
					TE_SetupBeamRingPoint(pos, distance, distance+5, BurnSprite, g_iExplosionModel,0,15,1.0,5.0,3.0,{0,0,255,255},10,0);
					TE_SendToClient(client, 0.0);
				}
				if(rand_element==3){
					new Float:distance=BreathDistance[skill_breath];
					GetClientAbsOrigin(client,pos);
					TE_SetupGlowSprite(pos,BurnSprite,1.0,1.9,255);
					TE_SendToAll();
					TE_SetupBeamRingPoint(pos, distance, distance+5, BurnSprite, g_iExplosionModel,0,15,1.0,5.0,3.0,{255,255,0,255},10,0);
					TE_SendToClient(client, 0.0);					
				}
				if(rand_element==4){
					new Float:distance=BreathDistance[skill_breath]; 
					GetClientAbsOrigin(client,pos);
					TE_SetupGlowSprite(pos,BurnSprite,1.0,1.9,255);
					TE_SendToAll();
					TE_SetupBeamRingPoint(pos, distance, distance+5, BurnSprite, g_iExplosionModel,0,15,1.0,5.0,3.0,{0,255,0,255},10,0);
					TE_SendToClient(client, 0.0);
				}
				if(rand_element==5){
					new Float:distance=BreathDistance[skill_breath]; 
					GetClientAbsOrigin(client,pos);
					TE_SetupGlowSprite(pos,BurnSprite,1.0,1.9,255);
					TE_SendToAll();
					TE_SetupBeamRingPoint(pos, distance, distance+5, BurnSprite, g_iExplosionModel,0,15,1.0,5.0,3.0,{120,0,255,255},10,0);
					TE_SendToClient(client, 0.0);
				}
			}
			
		BreathRemaining[client]--;					
		CreateTimer(1.0,Breath,client);
		if (BreathRemaining[client]<=0){
			PrintHintText(client, "You stop breathing fire"); 
		}
	}
	
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(!Silenced(client)){
		//Breath
		if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client)){
			new skill_breath=War3_GetSkillLevel(client,thisRaceID,SKILL_BREATH);
			new skill_evo=War3_GetSkillLevel(client,thisRaceID,SKILL_EVOLUTION);
			
			if(skill_breath>0){	
				if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_BREATH,true)){
					new rand_element=bIsElemental[client];
					
					if(rand_element==0){
					EmitSoundToAll(Bfire,client);
					new Float:distance=BreathDistance[skill_breath];
					new Float:pos[3]; 
					GetClientAbsOrigin(client,pos);
					TE_SetupGlowSprite(pos,BurnSprite,1.0,1.9,255);
					TE_SendToAll();
					TE_SetupBeamRingPoint(pos, distance, distance+5, BurnSprite, g_iExplosionModel,0,15,1.0,5.0,3.0,{255,0,0,255},10,0);
					TE_SendToClient(client, 0.0);
					}
					if(rand_element==1){
					new Float:distance=BreathDistance[skill_breath];
					new Float:pos[3]; 
					GetClientAbsOrigin(client,pos);
					TE_SetupGlowSprite(pos,BurnSprite,1.0,1.9,255);
					TE_SendToAll();
					TE_SetupBeamRingPoint(pos, distance, distance+5, BurnSprite, g_iExplosionModel,0,15,1.0,5.0,3.0,{50,50,50,255},10,0);
					TE_SendToClient(client, 0.0);
					EmitSoundToAll(Bdarkness,client);
					CreateTimer(4.0, Stop, client);
					}
					if(rand_element==2){
					EmitSoundToAll(Bfrost,client);
					new Float:distance=BreathDistance[skill_breath];
					new Float:pos[3]; 
					GetClientAbsOrigin(client,pos);
					TE_SetupGlowSprite(pos,BurnSprite,1.0,1.9,255);
					TE_SendToAll();
					TE_SetupBeamRingPoint(pos, distance, distance+5, BurnSprite, g_iExplosionModel,0,15,1.0,5.0,3.0,{0,0,255,255},10,0);
					TE_SendToClient(client, 0.0);
					}
					if(rand_element==3){
					EmitSoundToAll(Bpurge,client);	
					new Float:distance=BreathDistance[skill_breath];
					new Float:pos[3]; 
					GetClientAbsOrigin(client,pos);
					TE_SetupGlowSprite(pos,BurnSprite,1.0,1.9,255);
					TE_SendToAll();
					TE_SetupBeamRingPoint(pos, distance, distance+5, BurnSprite, g_iExplosionModel,0,15,1.0,5.0,3.0,{255,255,0,255},10,0);
					TE_SendToClient(client, 0.0);					
					}
					if(rand_element==4){
					EmitSoundToAll(Bpoison,client);
					new Float:distance=BreathDistance[skill_breath];
					new Float:pos[3]; 
					GetClientAbsOrigin(client,pos);
					TE_SetupGlowSprite(pos,BurnSprite,1.0,1.9,255);
					TE_SendToAll();
					TE_SetupBeamRingPoint(pos, distance, distance+5, BurnSprite, g_iExplosionModel,0,15,1.0,5.0,3.0,{0,255,0,255},10,0);
					TE_SendToClient(client, 0.0);
					}
					if(rand_element==5){
					EmitSoundToAll(Bcorruption,client);
					new Float:distance=BreathDistance[skill_breath];
					new Float:pos[3]; 
					GetClientAbsOrigin(client,pos);
					TE_SetupGlowSprite(pos,BurnSprite,1.0,1.9,255);
					TE_SendToAll();
					TE_SetupBeamRingPoint(pos, distance, distance+5, BurnSprite, g_iExplosionModel,0,15,1.0,5.0,3.0,{120,0,255,255},10,0);
					TE_SendToClient(client, 0.0);
					}
					
					PrintHintText(client,"You start breathing fire");
					BreathRemaining[client]=BreathTime[skill_evo];
					CreateTimer(1.0,Breath,client);
					War3_CooldownMGR(client,20.0,thisRaceID,SKILL_BREATH,_,_);
				}
				
			}
			else
			{
				PrintHintText(client,"Level your Ability First");
			}
			
		}
		//Shift Elemental
		if(War3_GetRace(client)==thisRaceID && ability==1 && pressed && IsPlayerAlive(client)){
			new skill_elemental=War3_GetSkillLevel(client,thisRaceID,SKILL_ELEMENTAL);
			
			if(skill_elemental>0){
				if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_ELEMENTAL,true)){
					new rand_element_new=GetRandomInt(0,5);
					new rand_element_oud=bIsElemental[client];
					
					while (rand_element_oud==rand_element_new){
					rand_element_new=GetRandomInt(0,5);
					}
					
					new rand_element=rand_element_new;
					
					bIsElemental[client]=rand_element;
					switch (rand_element)
					{
						case 0:
							PrintHintText(client, "Fire");
						case 1:
							PrintHintText(client, "Darkness");
						case 2:
							PrintHintText(client, "Frost");
						case 3:
							PrintHintText(client, "Lightning");
						case 4:
							PrintHintText(client, "Venom");
						case 5:
							PrintHintText(client, "Corruption");
					}
					
					War3_CooldownMGR(client,5.0,thisRaceID,SKILL_ELEMENTAL,_,_);
				}
				
			}
			else
			{
				PrintHintText(client,"Level your Ability1 First");
			}
		
		}
		
	}
	else
	{
		PrintHintText(client,"Silenced: Can not cast");
	}
	
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && IsPlayerAlive(client)){
		new ult_devour=War3_GetSkillLevel(client,thisRaceID,ULT_DEVOUR);
		
		if(ult_devour>0){
			if(!Silenced(client)){
				if(bEating[client]){
				PrintHintText(client, "You're already eating");
				}
				else
				{
				if(War3_SkillNotInCooldown(client,thisRaceID,ULT_DEVOUR,true)){ 
			
					if (bIsDevour[client]){
						PrintHintText(client, "Your Ultimate is already active, stab someone!");
					}
					else
					{
						bIsDevour[client]=true;
						PrintHintText(client, "Your Ultimate is active, stab someone!");
					}
				
				}
				}
				
			}
			else
			{
				PrintHintText(client,"Silenced: Can Not Cast"); 
			}
			
		}
		else
		{
			PrintHintText(client,"Level Your Ultimate First");
		}	
		
	}
	
}
