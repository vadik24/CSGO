/**
* File: War3Source_Wisp.sp
* Description: The Wisp for War3Source.
* Author(s): [Oddity]TeacherCreature
*/
 
#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>

new thisRaceID;

public Plugin:myinfo = 
{
	name = "War3Source Race - Wisp",
	author = "Teacher Creature",
	description = "The Wisp race for War3Source.",
	version = "1.0.7.6",
	url = "http://warcraft-source.net/"
};

new SKILL_WISP, SKILL_GHOSTLY, SKILL_SPIRIT, SKILL_ANCIENT, SKILL_SUICIDE;

new Float:WispSpeed[]={1.0,1.4,1.45,1.50,1.55,1.6};
new Float:InvisArr[]={1.0, 0.8, 0.6, 0.4, 0.2, 0.01};
new HealthArr[]={-99,-98,-97,-96,-95,-94};
new Float:AncientChance[]={0.0, 0.1, 0.15, 0.2, 0.25, 0.3};

new Handle:FriendlyFireSuicideCvar;
new Handle:SuicideDamageSentryCvar;
new Handle:MPFFCvar;
new ExplosionModel;
new bool:bSuicided[MAXPLAYERS];
new suicidedAsTeam[MAXPLAYERS];
new String:explosionSound1[]="music/war3source/particle_suck1.mp3";
new Float:SuicideBomberRadius[5]={0.0,200.0,233.0,275.0,333.0}; 

new Float:SuicideBomberDamage[5]={0.0,166.0,200.0,233.0,266.0};
new Float:SuicideBomberDamageTF[5]={0.0,133.0,175.0,250.0,300.0};
new Float:SuicideLocation[MAXPLAYERS][3];

new BeamSprite;
new HaloSprite;

public OnPluginStart()
{
	FriendlyFireSuicideCvar=CreateConVar("war3_undead_suicidebomber_ff","0","Friendly fire for suicide bomber, 0 for no, 1 for yes, 2 for mp_friendlyfire");
	SuicideDamageSentryCvar=CreateConVar("war3_undead_suicidebomber_sentry","1","Should suicide bomber damage sentrys?");
	MPFFCvar=FindConVar("mp_friendlyfire");
	
	RegConsoleCmd("spriteme",cmdspriteme);
}

new glowsprite;
public Action:cmdspriteme(client,args){
	
	
	new Float:endpos[3];
	War3_GetAimEndPoint(client,endpos);
	/*PrintToChatAll("1 %d",glowsprite);
	new Float:loc[3];
	GetClientAbsOrigin(client,loc);
	
	loc[2]+=40;
	*/
	//TE_SetupGlowSprite(endpos,glowsprite,30.0,6.0,255);
	//TE_SendToAll(0.0);
	
	TE_Start("Sprite Spray");
	TE_WriteVector("m_vecOrigin",endpos);
	TE_WriteNum("m_nModelIndex",glowsprite);
	TE_WriteFloat("m_fNoise",99.0);
	TE_WriteNum("m_nSpeed",1);
	TE_WriteNum("m_nCount",10);
	TE_SendToAll(0.0);
	//TE_WriteNum("exponent",iExponent);
    //TE_WriteFloat("m_fRadius",fRadius);
	/*
	
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
	//TE_WriteNum("m_nModelIndex", glowsprite);

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
	
	PrintToConsole(client,"spriteme completed");
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
	//glowsprite=PrecacheModel("sprites/strider_blackball.spr");
	//glowsprite++;   //stfu
	//glowsprite--;
	
	if(War3_GetGame()==Game_TF)
	{
		ExplosionModel=PrecacheModel("materials/particles/fluidexplosions/fluidexplosion.vmt",false);
		PrecacheSound("weapons/explode1.mp3",false);
	}
	else
	{
		ExplosionModel=PrecacheModel("materials/sprites/zerogxplode.vmt",false);
		PrecacheSound("weapons/explode5.mp3",false);
	}
	
	BeamSprite=War3_PrecacheBeamSprite();
	HaloSprite=War3_PrecacheHaloSprite();
	
	
	
	//SetFailState("[War3Source] There was a failure in creating the shop vector, definately halting.");
	//new String:longsound[130];
	//new String:sound[]="music/war3source/particle_suck1.mp3";
	
	//Format(longsound,sizeof(longsound), "sound/%s", sound);
	////AddFileToDownloadsTable(longsound); 
	//PrecacheSound(sound, true);	
	//if(!
	////War3_PrecacheSound(explosionSound1);
	//){
	//	SetFailState("[War3Source UNDEAD] FATAL ERROR! FAILURE TO PRECACHE SOUND %s!!! CHECK TO SEE IF U HAVE THE SOUND FILES",explosionSound1);
	//}
	//("music/war3source/levelupcaster.mp3");
}

public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num==121)
	{
		thisRaceID=War3_CreateNewRace("Wisp","wisp");
		SKILL_WISP=War3_AddRaceSkill(thisRaceID,"Wisp(passive)","More Speed",false,5);
		SKILL_GHOSTLY=War3_AddRaceSkill(thisRaceID,"Ghostly(passive)","Invisible but less health",false,5);
		SKILL_SPIRIT=War3_AddRaceSkill(thisRaceID,"Spirit(passive)","Skill Immunity",false,1);
		SKILL_ANCIENT=War3_AddRaceSkill(thisRaceID,"Ancient Wisp(attacker)","Shocks an enemy, inflicting Nature damage",false,5);
		SKILL_SUICIDE=War3_AddRaceSkill(thisRaceID,"Detonate","Explode and do damage, will not activate near teamates",true,4);
		War3_CreateRaceEnd(thisRaceID);
	}
}
public OnRaceChanged(client, oldrace, newrace)
{
	if(newrace != thisRaceID){
		War3_WeaponRestrictTo(client,thisRaceID,"");
		W3ResetAllBuffRace(client,thisRaceID);

	}
	if(newrace == thisRaceID){
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_p250");
		War3_SetBuff(client,bDoNotInvisWeapon,thisRaceID,true);
		if(ValidPlayer(client,true)){
			//GivePlayerItem(client, "weapon_glock");
			PassiveSkills(client);
		}
	}
}

public PassiveSkills(client){
	if(ValidPlayer(client,true)&&War3_GetRace(client)==thisRaceID)
	{
		bSuicided[client]=false;
		new skill_speed=War3_GetSkillLevel(client,thisRaceID,SKILL_WISP);
		if(skill_speed)
		{
			new Float:speed=WispSpeed[skill_speed];
			War3_SetBuff(client,fMaxSpeed,thisRaceID,speed);
		}
		new skill_ghost=War3_GetSkillLevel(client,thisRaceID,SKILL_GHOSTLY);
		if(skill_ghost)
		{
			War3_SetBuff(client,fInvisibilitySkill,thisRaceID,InvisArr[skill_ghost]);
			War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,HealthArr[skill_ghost]);
		}
		new skill_spirit=War3_GetSkillLevel(client,thisRaceID,SKILL_SPIRIT);
		if(skill_spirit)
		{
			War3_SetBuff(client,bImmunitySkills,thisRaceID,true);
		}
	}
}

public OnWar3EventSpawn(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		GivePlayerItem(client, "weapon_p250");
		PassiveSkills(client);
	}
	else{
		bSuicided[client]=true; //kludge, not to allow some other race switch to this race and explode on death (ultimate)
	}
}

public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			new race_attacker=War3_GetRace(attacker);
			new level_ancient=War3_GetSkillLevel(attacker,thisRaceID,SKILL_ANCIENT);
			if(race_attacker==thisRaceID && level_ancient>0 && IsPlayerAlive(victim))
			{
				if(GetRandomFloat(0.0,1.0) < AncientChance[level_ancient] && !W3HasImmunity(victim,Immunity_Skills))
				{  
					War3_DamageModPercent(1.2);   
					W3FlashScreen(victim,RGBA_COLOR_RED);
				}
			}
		}
	}
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
	
	//W3EmitSoundToAll(explosionSound1,client);
	
	if(War3_GetGame()==Game_TF){
		//W3EmitSoundToAll("weapons/explode1.mp3",client);
	}
	else{
		//W3EmitSoundToAll("weapons/explode5.mp3",client);
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
				PrintToConsole(client,"[W3S] Suicide bomber damage: %d to %d at distance %f",War3_GetWar3DamageDealt(),x,distance);
				
				
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
				PrintHintText(client,"Level Your Ultimate First");
			}
		}
	}
}

public OnWar3EventDeath(victim,attacker)
{
	bSuicided[victim]=true;
}
public Action:DelayedBomber(Handle:h,any:client){
	if(ValidPlayer(client)&&!IsPlayerAlive(client)&& suicidedAsTeam[client]==GetClientTeam(client) ){
		SuicideBomber(client,War3_GetSkillLevel(client,thisRaceID,SKILL_SUICIDE));
	}
	else{
		bSuicided[client]=false;
	}
}
