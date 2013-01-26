/**
* File: War3Source_Terminator.sp
* Description: The ES version of Terminator race for War3Source.
* Author(s): Schmarotzer, Frenzzy
*/

#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include "W3SIncs/AmmoControl" 

new thisRaceID;

new String:laserSound[]="war3source/terminator/laser1.mp3";
new String:metalSound0[]="physics/metal/metal_solid_impact_bullet1.mp3";
new String:metalSound1[]="physics/metal/metal_solid_impact_bullet2.mp3";
new String:metalSound2[]="physics/metal/metal_solid_impact_bullet3.mp3";
new String:metalSound3[]="physics/metal/metal_solid_impact_bullet4.mp3";

//skill 1
new Float:LaserPercent[5]={0.0,0.2,0.4,0.6,0.8};
new Handle:GameConf = INVALID_HANDLE;
new Handle:WeaponPosition = INVALID_HANDLE;
new BulletSprite;

//new g_iAmmoOffset = -1;
//new g_iClipOffset = -1;
new g_iArmorOffset = -1;

//skill 2
new Float:MetallDivider[5]={1.00,0.85,0.70,0.55,0.4};

//skill 3 
new Float:OrganicChance[5]={0.0,0.10,0.30,0.50,0.70};

//skill 4.
new Handle:FriendlyFireSuicideCvar;
new Handle:SuicideDamageSentryCvar;
new Handle:MPFFCvar;
new ExplosionModel;
new bool:bSuicided[MAXPLAYERS];
new suicidedAsTeam[MAXPLAYERS];
new String:explosionSound1[]="war3source/particle_suck1.mp3";
new BeamSprite;
new HaloSprite;
new Float:SuicideBomberRadius[5]={0.0,200.0,233.0,275.0,333.0}; 
new Float:SuicideBomberDamage[5]={0.0,166.0,200.0,233.0,266.0};
new Float:SuicideBomberDamageTF[5]={0.0,133.0,175.0,250.0,300.0}; 
new Float:SuicideLocation[MAXPLAYERS][3];

new SKILL_LASER, SKILL_METALL, SKILL_ORGANIC, ULT_SHORTCURT;

public Plugin:myinfo = 
{
	name = "War3Source Race - Terminator",
	author = "Schmarotzer, Frenzzy",
	description = "The ES Terminator race for War3Source.",
	version = "1.0.0.1",
	url = "http://war3source.com"
};

public OnPluginStart()
{
	LoadTranslations("w3s.race.terminator.phrases");
	//g_iAmmoOffset = FindSendPropInfo("CCSPlayer", "m_iAmmo");
	//g_iClipOffset = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1");
	g_iArmorOffset = FindSendPropOffs("CCSPlayer", "m_ArmorValue");
	
	HookEvent("bullet_impact", Event_BulletImpact);
	
	GameConf = LoadGameConfigFile("laser_tag.games");
	if(GameConf == INVALID_HANDLE)
	{
		SetFailState("gamedata/laser_tag.games.txt not loadable");
	}
	
	// Prep some virtual SDK calls
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(GameConf, SDKConf_Virtual, "Weapon_ShootPosition");
	PrepSDKCall_SetReturnInfo(SDKType_Vector, SDKPass_ByValue);
	WeaponPosition = EndPrepSDKCall();
	
	FriendlyFireSuicideCvar=CreateConVar("war3_terminator_suicidebomber_ff","0","Friendly fire for suicide bomber, 0 for no, 1 for yes, 2 for mp_friendlyfire");
	SuicideDamageSentryCvar=CreateConVar("war3_terminator_suicidebomber_sentry","1","Should suicide bomber damage sentrys?");
	MPFFCvar=FindConVar("mp_friendlyfire");
}

public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num==2)
	{
		thisRaceID=War3_CreateNewRaceT("terminator");
		SKILL_LASER=War3_AddRaceSkillT(thisRaceID,"LaserBullets",false,4);
		SKILL_METALL=War3_AddRaceSkillT(thisRaceID,"MetallicSkin",false,4);
		SKILL_ORGANIC=War3_AddRaceSkillT(thisRaceID,"OrganicSkin",false,4);
		ULT_SHORTCURT=War3_AddRaceSkillT(thisRaceID,"ShortCurt",true,4);
		War3_CreateRaceEnd(thisRaceID);
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID, "");
		War3_SetAmmoControl(client, "");
		W3ResetPlayerColor(client,thisRaceID);
		W3ResetAllBuffRace(client,thisRaceID);
	}
	else
	{
		/*
		SetEntityModel(client, "models/player/slow/t600/slow.mdl");
		if(GetClientTeam(client)==3)
		{
			W3SetPlayerColor(client,thisRaceID,20,100,200,255,1);
		}
		else if(GetClientTeam(client)==2)
		{
			W3SetPlayerColor(client,thisRaceID,220,50,0,255,1);
		}
		else{
			W3ResetPlayerColor(client,thisRaceID);
		}
		*/
		//War3_WeaponRestrictTo(client,thisRaceID,"weapon_deagle");
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_deagle");
		if(IsPlayerAlive(client)) bSuicided[client]=false;
		if(ValidPlayer(client,true)) {
			GivePlayerItem(client,"weapon_deagle");
			War3_SetAmmoControl(client, "weapon_deagle", 120, 14, true);
			//SetEntData(client, g_iAmmoOffset + (1 * 4), 120);
			SetEntData(client, g_iArmorOffset, 100);
		}
	}
}

public OnMapStart()
{
	////War3_PrecacheSound(laserSound);
	////War3_PrecacheSound(metalSound0);
	////War3_PrecacheSound(metalSound1);
	////War3_PrecacheSound(metalSound2);
	////War3_PrecacheSound(metalSound3);
	
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
	////War3_PrecacheSound(explosionSound1);
	
	BulletSprite = PrecacheModel("materials/sprites/laser.vmt");
}

public OnWar3EventSpawn(client)
{
	new race=War3_GetRace(client);
	if(race==thisRaceID)
	{
		bSuicided[client]=false;
		/*
		SetEntityModel(client, "models/player/slow/t600/slow.mdl");
		if(GetClientTeam(client)==3)
		{
			W3SetPlayerColor(client,thisRaceID,20,100,200,255,1);
		}
		else if(GetClientTeam(client)==2)
		{
			W3SetPlayerColor(client,thisRaceID,220,50,0,255,1);
		}
		else{
			W3ResetPlayerColor(client,thisRaceID);
		}
		*/
		suicidedAsTeam[client]=GetClientTeam(client);
		GivePlayerItem(client,"weapon_deagle");
		War3_SetAmmoControl(client, "weapon_deagle", 120, 14, true);
		//SetEntData(client, g_iAmmoOffset + (1 * 4), 120);
		SetEntData(client, g_iArmorOffset, 100);
		
		new skill_organic_level=War3_GetSkillLevel(client,race,SKILL_ORGANIC);
		if(skill_organic_level>0)
		{
			if(GetRandomFloat(0.0,1.0)<=OrganicChance[skill_organic_level])
			{
			/*
				if(GetClientTeam(client)==3)
				{
					new random = GetRandomInt(0,3);
					if(random==0){
						SetEntityModel(client, "models/player/t_guerilla.mdl");
					}else if(random==1){
						SetEntityModel(client, "models/player/t_leet.mdl");
					}else if(random==2){
						SetEntityModel(client, "models/player/t_phoenix.mdl");
					}else{
						SetEntityModel(client, "models/player/t_arctic.mdl");
					}
					W3ResetPlayerColor(client,thisRaceID);
				}
				else if(GetClientTeam(client)==2)
				{
					new random = GetRandomInt(0,3);
					if(random==0){
						SetEntityModel(client, "models/player/ct_gign.mdl");
					}else if(random==1){
						SetEntityModel(client, "models/player/ct_urban.mdl");
					}else if(random==2){
						SetEntityModel(client, "models/player/ct_gsg9.mdl");
					}else{
						SetEntityModel(client, "models/player/ct_sas.mdl");
					}
					W3ResetPlayerColor(client,thisRaceID);
				}
				War3_ChatMessage(client,"%T","Organic Skin Activated",client);
				//decl String:strcmd[192];
				//Format(strcmd,191,"say_team %T","Im in your team",client);
				//FakeClientCommandEx(client, strcmd);
				*/
				decl String:szPlayerName[255];
				GetClientName(client, szPlayerName, sizeof(szPlayerName));
				
				for (new i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i)==GetClientTeam(client) && i != client)
					{
						new String:szMessage[150];
						
						Format(szPlayerName, sizeof(szPlayerName), "\x03%s\x01", szPlayerName);
						
						Format(szMessage, sizeof(szMessage), "\x04[W3S] %s :  %T", szPlayerName,"Im in your team", i);
						SayText2(i, i, szMessage);
					}
				}
			}
		}
	}
	else
	{
		bSuicided[client]=true;
	}
}

public SayText2(client, author, const String:szMessage[])
{
	new Handle:hBuffer = StartMessageOne("SayText2", client);
	
	if (hBuffer != INVALID_HANDLE)
	{
		BfWriteByte(hBuffer, author);
		BfWriteByte(hBuffer, true);
		BfWriteString(hBuffer, szMessage);
		EndMessage();
	}
}
public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
			if(War3_GetRace(victim)==thisRaceID)
			{
				new skill_level_metall=War3_GetSkillLevel(attacker,thisRaceID,SKILL_METALL);
				if(skill_level_metall>0&&!Hexed(victim,false))
				{
					War3_DamageModPercent(MetallDivider[skill_level_metall]);  
				}
				new random = GetRandomInt(0,3);
				if(random==0)
				{
					//EmitSoundToAll(metalSound0,victim);
				}
				else if(random==1)
				{
					//EmitSoundToAll(metalSound1,victim);
				}
				else if(random==2)
				{
					//EmitSoundToAll(metalSound2,victim);
				}
				else
				{
					//EmitSoundToAll(metalSound3,victim);
				}
			}
}
		
		
public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		new race_attacker=War3_GetRace(attacker);
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(race_attacker==thisRaceID && vteam!=ateam)
		{
			new skill_level_laser=War3_GetSkillLevel(attacker,race_attacker,SKILL_LASER);
			if(skill_level_laser>0&&!Hexed(attacker,false))
			{
				if( GetRandomFloat(0.0,1.0)<=0.6 && !W3HasImmunity(victim,Immunity_Skills))
				{
					new Float:percent=LaserPercent[skill_level_laser];
					new health_take=RoundFloat(damage*percent);
					new ent = W3GetCurrentWeaponEnt(attacker);
					if(ent>0 && IsValidEdict(ent))
					{
						decl String:wepName[64];
						GetEdictClassname(ent,wepName,64);
						if(StrEqual(wepName,"weapon_deagle",true))
						{
							if(health_take>60) health_take=60;
							if(War3_DealDamage(victim,health_take,attacker,_,"laserbullets",W3DMGORIGIN_SKILL,W3DMGTYPE_PHYSICAL,true))
							{	
								W3PrintSkillDmgHintConsole(victim,attacker,War3_GetWar3DamageDealt(),SKILL_LASER);
								W3FlashScreen(victim,RGBA_COLOR_RED);
							}
						}
					}
				}
			}

		}

	}
}
public Action:Event_BulletImpact(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid=GetEventInt(event,"userid");
	new attacker=GetClientOfUserId(userid);
	if(War3_GetRace(attacker)==thisRaceID)
	{
		new Float:bulletOrigin[3];
		SDKCall( WeaponPosition, attacker, bulletOrigin );
		
		new Float:bulletDestination[3];
		War3_GetAimEndPoint(attacker,bulletDestination);
		
		// The following code moves the beam a little bit further away from the player
		new Float:distance = GetVectorDistance( bulletOrigin, bulletDestination );
		//PrintToChatAll( "vector distance: %f", distance );
		
		// calculate the percentage between 0.4 and the actual distance
		new Float:percentage = 0.4 / ( distance / 100 );
		//PrintToChatAll( "percentage (0.4): %f", percentage );
		
		// we add the difference between origin and destination times the percentage to calculate the new origin
		new Float:newBulletOrigin[3];
		newBulletOrigin[0] = bulletOrigin[0] + ( ( bulletDestination[0] - bulletOrigin[0] ) * percentage );
		newBulletOrigin[1] = bulletOrigin[1] + ( ( bulletDestination[1] - bulletOrigin[1] ) * percentage ) - 0.08;
		newBulletOrigin[2] = bulletOrigin[2] + ( ( bulletDestination[2] - bulletOrigin[2] ) * percentage );
		
		new color[4];
		if ( GetClientTeam( attacker ) == 2 )
		{
			color[0] = 200; 
			color[1] = 25;
			color[2] = 25;
		}
		else
		{
			color[0] = 25; 
			color[1] = 25;
			color[2] = 200;
		}
		color[3] = 250;
		
		new Float:life;
		life = 0.3;
		
		new Float:width;
		width = 3.0;
		
		/*
		start				Start position of the beam
		end					End position of the beam
		ModelIndex	Precached model index
		HaloIndex		Precached model index
		StartFrame	Initital frame to render
		FrameRate		Beam frame rate
		Life				Time duration of the beam
		Width				Initial beam width
		EndWidth		Final beam width
		FadeLength	Beam fade time duration
		Amplitude		Beam amplitude
		color				Color array (r, g, b, a)
		Speed				Speed of the beam
		*/
		
		TE_SetupBeamPoints( newBulletOrigin, bulletDestination, BulletSprite, 0, 0, 0, life, width, width, 1, 0.0, color, 0);
		TE_SendToAll();
		
		//EmitSoundToAll(laserSound,attacker);
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
	
	//EmitSoundToAll(explosionSound1,client);
	
	if(War3_GetGame()==Game_TF){
		//EmitSoundToAll("weapons/explode1.mp3",client);
	}
	else{
		//EmitSoundToAll("weapons/explode5.mp3",client);
	}
	if(War3_GetGame()==Game_TF && GetConVarBool(SuicideDamageSentryCvar))
	{
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
					new damage=RoundFloat(SuicideBomberDamageTF[level]*(radius-dist)/radius); //special case
					PrintToConsole(client,"%T","Suicide bomber BUILDING damage: {amount} at distance {amount}",client,damage,dist);
					SetVariantInt(damage);
					AcceptEntityInput(ent,"RemoveHealth",client); // last parameter should make death messages work
				}
				else{
					PrintToConsole(client,"%T","Player {player} has immunity (protecting buildings)",client,builder);
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
				War3_DealDamage(x,damage,client,_,"suicidebomber",W3DMGORIGIN_ULTIMATE,W3DMGTYPE_PHYSICAL);
				PrintToConsole(client,"%T","Suicide bomber damage: {amount} to {amount} at distance {amount}",client,War3_GetWar3DamageDealt(),x,distance);
				War3_ShakeScreen(x,3.0*factor,250.0*factor,30.0);
				W3FlashScreen(x,RGBA_COLOR_RED);
			}
			else
			{
				PrintToConsole(client,"%T","Could not damage player {player} due to immunity",client,x);
			}
			
		}
	}
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(pressed)
	{
		if(race==thisRaceID&&IsPlayerAlive(client)&&!bSuicided[client]&&!Silenced(client))
		{
			new ult_level=War3_GetSkillLevel(client,race,ULT_SHORTCURT);
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

public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
	bSuicided[client]=false;
}

public OnWar3EventDeath(victim,attacker)
{
	if(!bSuicided[victim])
	{
		new race=War3_GetRace(victim);
		new skill=War3_GetSkillLevel(victim,thisRaceID,ULT_SHORTCURT);
		if(race==thisRaceID && skill>0 && !Hexed(victim))
		{
			bSuicided[victim]=true;
			suicidedAsTeam[victim]=GetClientTeam(victim); 
			GetClientAbsOrigin(victim,SuicideLocation[victim]);
			CreateTimer(0.15,DelayedBomber,victim);
		}
	}
}

public Action:DelayedBomber(Handle:h,any:client){
	if(ValidPlayer(client)&&!IsPlayerAlive(client)&& suicidedAsTeam[client]==GetClientTeam(client) ){
		SuicideBomber(client,War3_GetSkillLevel(client,thisRaceID,ULT_SHORTCURT));
	}
	else{
		bSuicided[client]=false;
	}
}
