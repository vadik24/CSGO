#pragma semicolon 1    ///WIR EMPFEHLEN DAS SEMICOLON

#include <sourcemod>
#include <sdktools>
#include "W3SIncs/War3Source_Interface"  

new thisRaceID;
new regain[5]={15,20,23,25,30};
new Float:bugspeed[5]={1.0,1.10,1.20,1.35,1.45};
new Float:ultRange=400.0;
new Float:ultiDamageMulti[3]={0.0,0.8,1.2};
new String:ultsnd[]="npc/antlion/attack_single1.mp3";
new Handle:ultCooldownCvar;
new SKILL_HEAT,SKILL_ASPEE,ULT_ALIEN;
//new iVec,iVec2;
//new attacker;
new g_hirnrauch;
new g_OrangeGlowSprite;
new striderbulge;
new BeamSprite,HaloSprite;
new plasma;

new bugtrail[MAXPLAYERSCUSTOM];

public Plugin:myinfo = 
{
	name = "War3Source Race - Mystic Bug",
	author = "DonRevan",
	description = "Mystic Bug Race with 3 Skills and 4 Levels - War3Source.",
	version = "1.3.3.7 Leet Reached :D",
	url = "http://wcs-lagerhaus.de"
};

public OnPluginStart()
{
	ultCooldownCvar=CreateConVar("war3_mystbug_ulti_cd","35","Mystic Bugs Ultimate Cooldown");
}

public OnMapStart() 
{
	PrecacheSound( ultsnd, true );
	g_hirnrauch = PrecacheModel( "particle/fire.vmt");
	g_OrangeGlowSprite = PrecacheModel("materials/sprites/orangeglow1.vmt");
	plasma = PrecacheModel("sprites/plasma1.vmt");
	//dunst = PrecacheModel("sprites/steam.vmt");
	BeamSprite=PrecacheModel("materials/sprites/laser.vmt");
	HaloSprite=War3_PrecacheHaloSprite();
	striderbulge=PrecacheModel("effects/strider_bulge_dudv_dx60.vmt");
	//PrintToServer("[WAR3] Race loaded : Mystic Bug");
}

public OnWar3PluginReady(){
	thisRaceID=War3_CreateNewRace("Mystic Bug","mystbug");
	SKILL_HEAT=War3_AddRaceSkill(thisRaceID,"Men eater bug","Upon a successful kill, you eat some of your enemies flesh, gaining 15-30 health!",false,4);
	SKILL_ASPEE=War3_AddRaceSkill(thisRaceID,"Swarm Rush","Grants you a great bonus on your movement speed!10-45% more speed!",false,4);
	ULT_ALIEN=War3_AddRaceSkill(thisRaceID,"Alien Swarm","Creates some alien bugs that will hardly damage your target\nThe damage is based on the hp of the victim and some additionaly damage",true,2); 
	War3_CreateRaceEnd(thisRaceID);
}

public OnWar3EventDeath(victim,client)
{
	War3_SetBuff(victim,fMaxSpeed,thisRaceID,1.0);
	new race=War3_GetRace(client);
	new skill=War3_GetSkillLevel(client,thisRaceID,SKILL_HEAT);
	if(race==thisRaceID && skill>0)
	{
		CreateTimer(0.61,Delayedhp,client);
		PrintHintText(victim,"You bodys got eaten!");
		new Float:iVec[ 3 ];
		GetClientAbsOrigin( client, Float:iVec );
		TE_SetupSmoke( iVec, g_hirnrauch, 10.0, 3 );
		TE_SendToAll();
		///give the health after a half second...
	}
}

public Action:Delayedhp(Handle:h,any:client){
	if(ValidPlayer(client,true)){
		new skilllevel_heat=War3_GetSkillLevel(client,thisRaceID,SKILL_HEAT);
		new hpadd=regain[skilllevel_heat];
		SetEntityHealth(client,GetClientHealth(client)+hpadd);
		W3FlashScreen(client,RGBA_COLOR_GREEN,0.3,_,FFADE_IN);
		new Float:iVec[ 3 ];
		GetClientAbsOrigin( client, Float:iVec );
		TE_SetupSmoke( iVec, g_hirnrauch, 10.0, 3 );
		TE_SendToAll();
		TE_SetupGlowSprite( iVec, g_OrangeGlowSprite, 5.0 , 1.5 , 200);
		TE_SendToAll();
		PrintHintText(client,"+%d Addintionaly Health Eaten!",hpadd);
	}
}

public OnWar3EventSpawn(client)
{
	new race=War3_GetRace(client);
	if(race==thisRaceID)
	{
		InitSkills(client);
	}
	else {
		bugtrail[client] = -1;
	}
}

public InitSkills(client){
	if(War3_GetRace(client)==thisRaceID)
	{
		new skilllevel_rush=War3_GetSkillLevel(client,thisRaceID,SKILL_ASPEE);
		if(skilllevel_rush)
		{
			new Float:speed=bugspeed[skilllevel_rush];
			War3_SetBuff(client,fMaxSpeed,thisRaceID,speed);
			//PrintToChat(client, "[War3] You self casted a buff on you 'Swarm Rush' that allows you to move very fast!");
			War3_ChatMessage(client,"You self casted a buff on you 'Swarm Rush' that allows you to move very fast!");
			decl Float:iVec[ 3 ];
			GetClientAbsOrigin( client, Float:iVec );
			TE_SetupGlowSprite( iVec, plasma, 5.0 , 1.5 , 200);
			TE_SendToAll();
			TE_SetupSmoke( iVec, g_hirnrauch, 10.0, 3 );
			TE_SendToAll();
			//TE_SetupBeamFollow(client,plasma,0,5.1,18.0,20.0,20,{120,255,120,255});
			//TE_SendToAll();
			bugtrail[client] = AttachTrail(client);
			War3_SetBuff(client,fInvisibilitySkill,thisRaceID,0.9);
		}
	}
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && IsPlayerAlive(client))
	{	
		new skill=War3_GetSkillLevel(client,race,ULT_ALIEN);
		if(skill>0)
		{
			if(War3_SkillNotInCooldown(client,thisRaceID,ULT_ALIEN,true))
			{
				new target=War3_GetTargetInViewCone(client,ultRange,false);
				// new test=War3_GetTargetInViewCone(client,5000,true);
				// PrintToConsole(client,"[debugging] %d - target",target);
				// PrintToConsole(client,"[debugging] %d - test",test);
				if(ValidPlayer(target,true)&&!W3HasImmunity(target,Immunity_Ultimates))
				{

					new hpmissing=100-GetClientHealth(target);
					decl Float:iVec[ 3 ];
					GetClientAbsOrigin( target, Float:iVec );
					iVec[2]+=51.0;
					new dmg=RoundFloat(FloatMul(float(hpmissing),ultiDamageMulti[skill]));
					//new dmg=1;
					PrintToConsole(client,"[WcsL-Check]Alien Swarm targeted enemy and damaged him with %d damage",dmg);
					PrintToChat(client, "[Alien Swarm] : Found target and dealt %d damage",dmg);
					PrintToConsole(target,"[WcsL-Check]Got damaged by Mystic Bugs Ultimate for %d damage",dmg);
					PrintToChat(target, ": Got damaged by a mysterios bug swarm!!",dmg);
					War3_DealDamage(target,dmg,client,DMG_BULLET,"alienswarm");
					War3_CooldownMGR(client,GetConVarFloat(ultCooldownCvar),thisRaceID,ULT_ALIEN,true,true);
					TE_SetupGlowSprite( iVec, striderbulge, 5.0 , 1.5 , 200);
					TE_SendToAll();
					TE_SetupGlowSprite( iVec, g_OrangeGlowSprite, 9.0 , 3.0 , 222);
					TE_SendToAll();
					TE_SetupSmoke( iVec, g_hirnrauch, 20.0, 6 );
					TE_SendToAll();
					TE_SetupBeamFollow(target,striderbulge,0,1.0,5.0,20.0,8,{255,255,255,255});
					TE_SendToAll();
					decl Float:iVec2[ 3 ];
					GetClientAbsOrigin( client, Float:iVec2 );
					iVec2[2]+=35.0;
					new beamColor[4]={255,255,255,255};
					// TE_SetupBeamLaser( iVec, iVec2, BeamSprite, HaloSprite, 0, 10, 1.0, 3.8, 8.0, 5, 1.2, beamcolor, 5.0);
					TE_SetupSmoke( iVec2, g_hirnrauch, 20.0, 6 );
					TE_SendToAll();
					TE_SetupBeamPoints(iVec2,iVec,BeamSprite,HaloSprite,0,41,1.6,6.0,15.0,0,4.5,beamColor,45);
					TE_SendToAll();
					EmitSoundToAll(ultsnd,client);
					EmitSoundToAll(ultsnd,target);
				}
				else
				{
					PrintHintText(client,"The Swarm did not found any attackable target in %.1f Feet",ultRange/10.0);
				}
			}
		}
		else
		{
			PrintHintText(client,"Mystic Bug:\nYou cant use your ultimate now!");
		}
	}
}

//AttachTrail(client) - attaches the mystic bug trail to the target player
//made by twisted panda(playertrails)
AttachTrail(client)
{
	decl String:_sTemp[32];
	Format(_sTemp, 32, "MysticTrail_%d", GetClientUserId(client));
	DispatchKeyValue(client, "targetname", _sTemp);

	new _iEntity = CreateEntityByName("env_spritetrail");
	if(_iEntity > 0 && IsValidEntity(_iEntity))
	{
		decl Float:g_fOrigin[3], Float:g_fAngle[3];
		GetClientAbsOrigin(client, g_fOrigin);
		GetClientAbsAngles(client, g_fAngle);

		DispatchKeyValue(_iEntity, "parentname", _sTemp);
		DispatchKeyValue(_iEntity, "lifetime", "15");
		DispatchKeyValue(_iEntity, "startwidth", "18");
		DispatchKeyValue(_iEntity, "endwidth", "20");
		DispatchKeyValue(_iEntity, "rendermode", "0");
		DispatchKeyValue(_iEntity, "spritename", "sprites/plasma1.vmt");
		DispatchKeyValue(_iEntity, "rendercolor", "140 255 140 255");
		DispatchKeyValue(_iEntity, "renderamt", "255");
		DispatchSpawn(_iEntity);

		GetEntPropVector(client, Prop_Data, "m_angAbsRotation", g_fAngle);
		new Float:g_fTemp[3] = { 0.0, 90.0, 0.0 };
		SetEntPropVector(client, Prop_Data, "m_angAbsRotation", g_fTemp);
		//AddVectors(g_fOrigin, g_fLayoutPosition[g_iTrailData[client][INDEX_LAYOUT]][i], g_fOrigin);
		TeleportEntity(_iEntity, g_fOrigin, g_fTemp, NULL_VECTOR);
		SetVariantString(_sTemp);
		AcceptEntityInput(_iEntity, "SetParent", _iEntity, _iEntity);
		SetEntPropVector(client, Prop_Data, "m_angAbsRotation", g_fAngle);
	}
	else {
		return -1;
	}
	return _iEntity;
}