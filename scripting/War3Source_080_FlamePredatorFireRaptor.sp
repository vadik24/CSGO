/**
* File: War3Source_FlamePredator.sp
* Description: The Flame Predator race for War3Source.
* Author(s): Anthony Iacono ,tmu(fixed remove disarm
*/

#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
#include <cstrike>
#define REQUIRE_EXTENSIONS

new thisRaceID;
// new g_GameType;
new Handle:FriendlyFireSuicideCvar;
new Handle:SuicideDamageSentryCvar;
new Handle:MPFFCvar;
new ExplosionModel;
new bool:bSuicided[MAXPLAYERS];
// new MyWeaponsOffset;
new String:explosionSound1[]="music/war3source/particle_suck1.mp3";
new BeamSprite;
new HaloSprite;

//skill 1

new Float:BeserkSpeed[5]={1.0,1.30,1.40,1.50,1.60};

new BeserkHP[5]={0,10,20,30,40};

//skill 2
new Float:CloakInvisiCS[5]={1.0,0.8,0.6,0.4,0.3};
new Float:CloakInvisiTF[5]={1.0,0.8,0.6,0.4,0.28};
//skill 3
new Float:LevitationGravity[5]={1.0,0.85,0.70,0.55,0.40};
//skill 4
new Float:BurnArr[5]={0.0,0.5,1.0,1.5,2.0};
//skill 5
new Float:SuicideBomberRadius[5]={0.0,200.0,233.0,275.0,333.0}; 

new Float:SuicideBomberDamage[5]={0.0,166.0,200.0,233.0,266.0};
new Float:SuicideBomberDamageTF[5]={0.0,133.0,175.0,250.0,300.0}; 

new Float:SuicideLocation[MAXPLAYERS][3];

//names
new SKILL_BESERK,SKILL_CLOAK,SKILL_LEVI,SKILL_BURN,SKILL_INFERN;

public Plugin:myinfo = 
{
	name = "War3Source Race - Flame Predator",
	author = "Scyther",
	description = "The Orcish Horde race for War3Source.",
	version = "1.0.0.0",
	url = "http://war3source.com"
};


public OnPluginStart()
{ 
	//HookEvent("player_spawn",PlayerSpawnEvent);
	//HookEvent("player_death",PlayerDeathEvent);
	FriendlyFireSuicideCvar=CreateConVar("war3_undead_suicidebomber_ff","0","Friendly fire for suicide bomber, 0 for no, 1 for yes, 2 for mp_friendlyfire");
	SuicideDamageSentryCvar=CreateConVar("war3_undead_suicidebomber_sentry","1","Should suicide bomber damage sentrys?");
	MPFFCvar=FindConVar("mp_friendlyfire");
	// g_GameType = War3_GetGame();
	
}	

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==300)
	{
		thisRaceID=War3_CreateNewRace("VIP Fire Raptor","flame");
		SKILL_BESERK=War3_AddRaceSkill(thisRaceID,"Berserker","Additional health and speed",false,4);
		SKILL_CLOAK=War3_AddRaceSkill(thisRaceID,"invisibility","Will blend with the environment",false,4);
		SKILL_LEVI=War3_AddRaceSkill(thisRaceID,"levitation","You will be able to jump much higher",false,4);
		SKILL_BURN=War3_AddRaceSkill(thisRaceID,"Flaming Blade","A chance to burn the enemy ",false,4);		
		SKILL_INFERN=War3_AddRaceSkill(thisRaceID,"Fiery Hell","A chance to explode after death, or ultimate",true,4);
		War3_CreateRaceEnd(thisRaceID);
		
	}
}


public OnMapStart()
{
	
	if(War3_GetGame()==Game_TF)
	{
		ExplosionModel=PrecacheModel("materials/particles/explosion/explosionfiresmoke.vmt",false);
		//PrecacheSound("weapons/explode1.mp3",false);
	}
	else
	{
		ExplosionModel=PrecacheModel("materials/sprites/zerogxplode.vmt",false);
		//PrecacheSound("weapons/explode5.mp3",false);
	}
	
	BeamSprite=War3_PrecacheBeamSprite();
	HaloSprite=War3_PrecacheHaloSprite();
	
	
	
	//SetFailState("[War3Source] There was a failure in creating the shop vector, definately halting.");
	//new String:longsound[130];
	//new String:sound[]="war3source/particle_suck1.mp3";
	
	//Format(longsound,sizeof(longsound), "sound/%s", sound);
	////AddFileToDownloadsTable(longsound); 
	//PrecacheSound(sound, true);	
	//if(!//War3_PrecacheSound(explosionSound1)){
	//	SetFailState("[War3Source UNDEAD] FATAL ERROR! FAILURE TO PRECACHE SOUND %s!!! CHECK TO SEE IF U HAVE THE SOUND FILES",explosionSound1);
	//}
	//("war3source/levelupcaster.mp3");
}


public SuicideBomber(client,level)
{
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
	
	//EmitSoundToAll(explosionSound1,client);
	
	if(War3_GetGame()==Game_TF){
		//EmitSoundToAll("weapons/explode1.mp3",client);
	}
	else{
		//EmitSoundToAll("weapons/explode5.mp3",client);
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
			
			
			if(War3_GetGame()==Game_TF && GetConVarBool(SuicideDamageSentryCvar))
			{
				// Do they have a sentry that should get blasted too?
				new ent=0;
				while((ent = FindEntityByClassname(ent,"obj_sentrygun"))>0)
				{
					if(!IsValidEdict(ent)) continue;
					new builder=GetEntPropEnt(ent,Prop_Send,"m_hBuilder");
					if(builder==x)
					{
						new Float:pos_comp[3];
						GetEntPropVector(ent,Prop_Send,"m_vecOrigin",pos_comp);
						new Float:dist=GetVectorDistance(client_location,pos_comp);
						if(dist>radius)
							continue;
						
						if(!W3HasImmunity(x,Immunity_Ultimates))
						{
							//new damage=RoundFloat(100*(1-FloatDiv(dist,radius)+0.40));
							new damage=RoundFloat(SuicideBomberDamageTF[level]*(radius-dist)/radius); //special case
							
							PrintToConsole(client,"Suicide bomber BUILDING damage: %d at distance %f",damage,dist);
							
							SetVariantInt(damage);
							AcceptEntityInput(ent,"RemoveHealth",client); // last parameter should make death messages work
						}
						else{
							PrintToConsole(client,"Player %d has immunity (protecting buildings)",x);
						}
					}
				}
				while((ent = FindEntityByClassname(ent,"obj_teleport"))>0)
				{
					if(!IsValidEdict(ent)) continue;
					new builder=GetEntPropEnt(ent,Prop_Send,"m_hBuilder");
					if(builder==x)
					{
						new Float:pos_comp[3];
						GetEntPropVector(ent,Prop_Send,"m_vecOrigin",pos_comp);
						new Float:dist=GetVectorDistance(client_location,pos_comp);
						if(dist>radius)
							continue;
						
						if(!W3HasImmunity(x,Immunity_Ultimates))
						{
							//new damage=RoundFloat(100*(1-FloatDiv(dist,radius)+0.40));
							new damage=RoundFloat(SuicideBomberDamageTF[level]*(radius-dist)/radius); //special case
							
							PrintToConsole(client,"Suicide bomber BUILDING damage: %d at distance %f",damage,dist);
							
							SetVariantInt(damage);
							AcceptEntityInput(ent,"RemoveHealth",client); // last parameter should make death messages work
						}
						else{
							PrintToConsole(client,"Player %d has immunity (protecting buildings)",x);
						}
					}
				}
				while((ent = FindEntityByClassname(ent,"obj_dispenser"))>0)
				{
					if(!IsValidEdict(ent)) continue;
					new builder=GetEntPropEnt(ent,Prop_Send,"m_hBuilder");
					if(builder==x)
					{
						new Float:pos_comp[3];
						GetEntPropVector(ent,Prop_Send,"m_vecOrigin",pos_comp);
						new Float:dist=GetVectorDistance(client_location,pos_comp);
						if(dist>radius)
							continue;
						
						if(!W3HasImmunity(x,Immunity_Ultimates))
						{
							//new damage=RoundFloat(100*(1-FloatDiv(dist,radius)+0.40));
							new damage=RoundFloat(SuicideBomberDamageTF[level]*(radius-dist)/radius); //special case
							
							PrintToConsole(client,"Suicide bomber BUILDING damage: %d at distance %f",damage,dist);
							
							SetVariantInt(damage);
							AcceptEntityInput(ent,"RemoveHealth",client); // last parameter should make death messages work
						}
						else{
							PrintToConsole(client,"Player %d has immunity (protecting buildings)",x);
						}
					}
				}
			}
			if(distance>radius)
				continue;
			// TODO: Possible traceline for explosion?
			//new damage=RoundFloat(100*(1-FloatDiv(distance,radius)+0.40));
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
				PrintToConsole(client,"[W3S] Suicide bomber damage: %d to %d at distance %f",War3_GetWar3DamageDealt(),x,distance);
				
				
				War3_ShakeScreen(x,3.0*factor,250.0*factor,30.0);
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
		if(race==thisRaceID&&IsPlayerAlive(client)&&!bSuicided[client])
		{
			new ult_level=War3_GetSkillLevel(client,race,SKILL_INFERN);
			if(ult_level>0)
			{
				ForcePlayerSuicide(client); //this causes them to die...
			}
			else
			{
				W3MsgUltNotLeveled(client);
			}
		}
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{
		W3ResetAllBuffRace(client,thisRaceID);
		War3_WeaponRestrictTo(client,thisRaceID,"");
		
	}
	else
	{
		ActivateSkills(client);
		
	}
	if(newrace == thisRaceID){
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
		if(ValidPlayer(client,true)){
			GivePlayerItem(client, "weapon_knife");
		}
	}
}
public ActivateSkills(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		bSuicided[client]=false;
		new skill_devo=War3_GetSkillLevel(client,thisRaceID,SKILL_BESERK);
		if(skill_devo)
		{
			// Devotion Aura
			new hpadd=BeserkHP[skill_devo];
			War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,hpadd);
			War3_ChatMessage(client,"+%d HP",hpadd);
		}
		new skilllevel_bspeed=War3_GetSkillLevel(client,thisRaceID,SKILL_BESERK);
		if(skilllevel_bspeed)
		{
			new Float:speed=BeserkSpeed[skilllevel_bspeed];
			War3_SetBuff(client,fMaxSpeed,thisRaceID,speed);
		}
		new skilllevel_levi=War3_GetSkillLevel(client,thisRaceID,SKILL_LEVI);
		if(skilllevel_levi)
		{
			new Float:gravity=LevitationGravity[skilllevel_levi];
			War3_SetBuff(client,fLowGravitySkill,thisRaceID,gravity);
		}		
		new skilllevel=War3_GetSkillLevel(client,thisRaceID,SKILL_CLOAK);
		new Float:alpha=(War3_GetGame()==Game_CS)?CloakInvisiCS[skilllevel]:CloakInvisiTF[skilllevel];
		//if(skill_invis>0)
		//War3_ChatMessage(client,"You fade %s into the backdrop.",(skill_invis==1)?"slightly":(skill_invis==2)?"well":(skill_invis==3)?"greatly":"dramatically");
		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,alpha);
		
	}
}

public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
}
public OnW3TakeDmgAll(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		for(new s=0;s<5;s++)	
			if(vteam!=ateam)
		{
			new race_attacker=War3_GetRace(attacker);
			
				// Liquid Fire
				new skill_level_burn=War3_GetSkillLevel(attacker,thisRaceID,SKILL_BURN);
				if(race_attacker==thisRaceID && skill_level_burn>0)
				{
					if(GetRandomFloat(0.0,1.0)<=0.3 && !W3HasImmunity(victim,Immunity_Skills))
					{
						IgniteEntity(victim,BurnArr[skill_level_burn]);
						PrintToConsole(attacker,"Flame set fire to your enemy's blade");
					}
				}
		}
		
	}
}

public OnWar3EventSpawn(client){
	//PrintToChatAll("3");
	War3_SetBuff(client,bBashed,thisRaceID,false);
	new race=War3_GetRace(client);
	if(race==thisRaceID)
	{
		ActivateSkills(client);	
	}
}

public OnWar3EventDeath(victim,attacker)
{			
	ExtinguishEntity(victim);
	/*new uid_victim=GetEventInt(event,"userid");
	if(uid_victim>0)
	{
	new deathFlags = GetEventInt(event, "death_flags");
	if (War3_GetGame()==Game_TF&&deathFlags & 32)
	{
	//PrintToChat(client,"war3 debug: dead ringer kill");
	}
	else
	{
	new victim=GetClientOfUserId(uid_victim);*/
	
	if(!bSuicided[victim])
	{
		new race=War3_GetRace(victim);
		new skill=War3_GetSkillLevel(victim,thisRaceID,SKILL_INFERN);
		if(race==thisRaceID && skill>0)
		{
			bSuicided[victim]=true;
			GetClientAbsOrigin(victim,SuicideLocation[victim]);
			CreateTimer(0.15,DelayedBomber,victim);
		}
	}
	
	
	
	//}
	//}
}
public Action:DelayedBomber(Handle:h,any:client){
	if(ValidPlayer(client)){
		SuicideBomber(client,War3_GetSkillLevel(client,thisRaceID,SKILL_INFERN));
	}
}
