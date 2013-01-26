
 /**
* File: War3Source_ClockWerkGoblin.sp
* Description: The Clock Werk Goblin for War3Source.
* Author(s): [Oddity]TeacherCreature
*/

#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdkhooks>
#include <sdktools>

// War3Source stuff
new thisRaceID;
new Handle:FriendlyFireSuicideCvar;
new Handle:SuicideDamageSentryCvar;
new Handle:MPFFCvar;
new ExplosionModel;
new bool:bSuicided[65];

new String:explosionSound1[]="music/war3source/particle_suck1.mp3";

new BeamSprite;
new HaloSprite;


new Float:ClockworkSpeed[4]={0.0,1.45,1.5,1.55};
// Chance/Data Arrays
//new Float:DistractChance[5]={0.0,0.05,0.10,0.15,0.2};
new Float:SuicideBomberRadius[4]={0.0,200.0,233.0,275.0}; 

new Float:SuicideBomberDamage[4]={0.0,70.0,80.0,90.0};
new Float:SuicideBomberDamageTF[4]={0.0,133.0,175.0,250.0}; 

//new Float:VampirePercent[5]={0.0,0.07,0.14,0.22,0.30};

new Float:SuicideLocation[MAXPLAYERS][3];


new SKILL_CLOCKWERK,SKILL_SUICIDE;

public Plugin:myinfo = 
{
	name = "War3Source Race - Clockwerk Goblin",
	author = "[Oddity]TeacherCreature",
	description = "The Clockwerk Goblin for War3Source.",
	version = "1.0.0.0",
	url = "warcraft-source.net"
};

public OnPluginStart()
{	
	FriendlyFireSuicideCvar=CreateConVar("war3_clockwerk_suicidebomber_ff","0","Friendly fire for suicide bomber, 0 for no, 1 for yes, 2 for mp_friendlyfire");
	SuicideDamageSentryCvar=CreateConVar("war3_clockwerk_suicidebomber_sentry","1","Should suicide bomber damage sentrys?");
	MPFFCvar=FindConVar("mp_friendlyfire");
	RegConsoleCmd("spriteme",cmdspriteme);
	
	LoadTranslations("w3s.race.clockwerk.phrases");
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==36)
	{
		thisRaceID=War3_CreateNewRaceT("clockwerk");
		SKILL_CLOCKWERK=War3_AddRaceSkillT(thisRaceID,"Clockwerk",false,3); 
		SKILL_SUICIDE=War3_AddRaceSkillT(thisRaceID,"Kaboom",false,3); 
		War3_CreateRaceEnd(thisRaceID);
	}
}
//War3_SetBuff(i,fMaxSpeed,thisRaceID,1.1);


new glowsprite;
public Action:cmdspriteme(client,args){
	/*PrintToChatAll("1 %d",glowsprite);
	new Float:loc[3];
	GetClientAbsOrigin(client,loc);
	
	loc[2]+=40;
	//TE_SetupGlowSprite(loc,glowsprite,30.0,6.0,255);
	//TE_SendToAll(0.0);
	
	
	//TE_SetupDynamicLight(loc,255,0,255,5,100.0,2.0,2.0);
	//TE_SendToAll(0.0);
	
	new ent = CreateEntityByName("env_sprite");
	if (ent)
	{
		DispatchKeyValue(ent, "model", "sprites/strider_blackball.spr");
		DispatchKeyValue(ent, "classname", "env_sprite");
		DispatchKeyValue(ent, "spawnflags", "1");
		DispatchKeyValue(ent, "scale", "1.0");
		DispatchKeyValue(ent, "rendermode", "1");
		DispatchKeyValue(ent, "rendercolor", "255 255 255");
		DispatchKeyValue(ent, "targetname", "donator_spr");
		DispatchSpawn(ent);

		new Float:vOrigin[3];
		if (War3_GetGame()==Game_TF)
			GetClientEyePosition(client, vOrigin);
		else
			GetClientAbsOrigin(client, vOrigin);

		vOrigin[2] += 90.0;

		TeleportEntity(ent, vOrigin, NULL_VECTOR, {0.0,0.0,-20.0});
		
		//if (War3_GetGame()==Game_TF)
		SetEntityMoveType(ent, MOVETYPE_VPHYSICS);
			
		//else
		//{
			//new String:szTemp[64]; 
			//Format(szTemp, sizeof(szTemp), "client%i", client);
			//DispatchKeyValue(client, "targetname", szTemp);
			//DispatchKeyValue(ent, "parentname", szTemp);

		//	SetVariantString(szTemp);
		//	AcceptEntityInput(ent, "SetParent", ent, ent, 0);
		//	SetVariantString("head");
		//	AcceptEntityInput(ent, "SetParentAttachmentMaintainOffset", ent, ent, 0);
		//}
	}
	
	 */
	
	
	//est_Effect_33 <Player Filter> <Delay> <model> <Position "X Y Z"> <size> <brightness> 
	/*TE_Start("Sprite");
	TE_WriteNum("m_nModelIndex", glowsprite);

    TE_WriteVector("m_vecOrigin",loc);
	//TE_WriteFloat("m_flSize", 1.0);
	TE_WriteNum("m_nBrightness", 100);

    //TE_WriteNum("g",g);
    //TE_WriteNum("b",b);
    //TE_WriteNum("exponent",iExponent);
    //TE_WriteFloat("m_fRadius",fRadius);
    //TE_WriteFloat("m_fTime",fTime);
    //TE_WriteFloat("m_fDecay",fDecay);
	TE_SendToAll(0.0);*/
	
	//PrintToChatAll("2");
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

public OnMapStart()
{
	glowsprite=PrecacheModel("sprites/strider_blackball.spr");
	glowsprite++;   //stfu
	glowsprite--;
	
	if(War3_GetGame()==Game_TF)
	{
		ExplosionModel=PrecacheModel("materials/particles/fluidexplosions/fluidexplosion.vmt",false);
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
	//new String:sound[]="music/war3source/particle_suck1.mp3";
	
	//Format(longsound,sizeof(longsound), "sound/%s", sound);
	////AddFileToDownloadsTable(longsound); 
	//PrecacheSound(sound, true);	

	//("music/war3source/levelupcaster.mp3");
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
							
							PrintToConsole(client,"%T","Suicide bomber BUILDING damage: {amount} at distance {amount}",client,damage,dist);
							
							SetVariantInt(damage);
							AcceptEntityInput(ent,"RemoveHealth",client); // last parameter should make death messages work
						}
						else{
							PrintToConsole(client,"%T","Player {player} has immunity (protecting buildings)",client,x);
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
							
							PrintToConsole(client,"%T","Suicide bomber BUILDING damage: {amount} at distance {amount}",client,damage,dist);
							
							SetVariantInt(damage);
							AcceptEntityInput(ent,"RemoveHealth",client); // last parameter should make death messages work
						}
						else{
							PrintToConsole(client,"%T","Player {player} has immunity (protecting buildings)",client,x);
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
							
							PrintToConsole(client,"%T","Suicide bomber BUILDING damage: {amount} at distance {amount}",client,damage,dist);
							
							SetVariantInt(damage);
							AcceptEntityInput(ent,"RemoveHealth",client); // last parameter should make death messages work
						}
						else{
							PrintToConsole(client,"%T","Player {player} has immunity (protecting buildings)",client,x);
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
				
				War3_DealDamage(x,damage,client,_,"suicidebomber",W3DMGORIGIN_ULTIMATE,W3DMGTYPE_TRUEDMG);
				PrintToConsole(client,"%T","Suicide bomber damage: {amount} at distance {amount}",client,War3_GetWar3DamageDealt(),distance);
				
				
				War3_ShakeScreen(x,3.0*factor,250.0*factor,30.0);
				W3FlashScreen(x,RGBA_COLOR_RED);
			}
			else
			{
				PrintToConsole(client,"%T","Player {player} has immunity",client,x);
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
			new ult_level=War3_GetSkillLevel(client,race,SKILL_SUICIDE);
			if(ult_level>0)
			{
				ForcePlayerSuicide(client); //this causes them to die...
			}
			else
			{
				PrintHintText(client,"%T","Level Your Ultimate First",client);
			}
		}
	}
}

public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		InitSkills(client);
	}
}
public InitSkills(client){
	if(War3_GetRace(client)==thisRaceID)
	{
		bSuicided[client]=false;
		new clocklevel=War3_GetSkillLevel(client,thisRaceID,SKILL_CLOCKWERK);
		War3_SetBuff(client,fMaxSpeed,thisRaceID,ClockworkSpeed[clocklevel]);
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{
		//if(War3_GetGame()!=Game_TF) 
		W3ResetAllBuffRace(client,thisRaceID);
		W3ResetPlayerColor(client,thisRaceID);
		War3_WeaponRestrictTo(client,thisRaceID,"");
	}
	if(newrace==thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
		InitSkills(client);
	}
}

//public PlayerDeathEvent(Handle:event,const String:name[],bool:dontBroadcast)

public OnWar3EventDeath(victim,attacker)
{
	
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
		new skill=War3_GetSkillLevel(victim,thisRaceID,SKILL_SUICIDE);
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
		SuicideBomber(client,War3_GetSkillLevel(client,thisRaceID,SKILL_SUICIDE));
	}
}

public OnWar3EventSpawn(client)
{
	new race=War3_GetRace(client);
	if(race==thisRaceID)
	{ 
		InitSkills(client);
	}
	else{
		bSuicided[client]=true; //kludge, not to allow some other race switch to this race and explode on death (ultimate)
	}
}
