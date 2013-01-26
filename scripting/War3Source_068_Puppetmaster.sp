#pragma semicolon 1
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
new thisRaceID;
new addhp[9]={0,5,6,7,8,9,10,12,15};
new bool:bFrenzy[66];
new addgold[9]={100,150,200,250,300,320,360,380,400};
new String:facsnd[]="weapons/physcannon/physcannon_tooheavy.mp3";
new String:halsnd[]="weapons/physcannon/physcannon_charge.mp3";
new Raiser[66];
new bool:Skeleton[66];
new Float:RaiseDeadChance[9]={0.0,0.40,0.50,0.60,0.70,0.75,0.80,0.85,0.90};
new addxp[9]={0,10,10,10,20,25,28,30,32};
new maxspawns[9]={0,1,2,3,4,5,6,7,8};
new currentspawns[MAXPLAYERS];
new g_offsCollisionGroup;
new g_money;
new BeamSprite, BeamSprite2, HaloSprite;
new prey, vendetta, reward, summon;
new obsolet;
new SKILL_PREY, SKILL_VENDETT, SKILL_REWRD, ULT_DOLLSUMMON;
new Handle:ultCooldownCvar;
new Handle:ultCooldownCvar2;
new doll;
public Plugin:myinfo = 
{
	name = "War3Source Race - PuppetMaster",
	author = "Revan",
	description = "The Puppetmaster for War3Source.",
	version = "1.0.0.0",
	url = "wcs-lagerhaus.de"
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==310)
	{
		thisRaceID=War3_CreateNewRace("PuppetMaster","dollv1");
		SKILL_PREY=War3_AddRaceSkill(thisRaceID,"Prey","Get some health if a doll dies.",false,8);
		SKILL_VENDETT=War3_AddRaceSkill(thisRaceID,"Vendetta","Increases your current ammount of cash for each kill of you summoned doll!",false,8);
		SKILL_REWRD=War3_AddRaceSkill(thisRaceID,"Reward","Raises current xp count if one of your dolls dies!",false,8);
		ULT_DOLLSUMMON=War3_AddRaceSkill(thisRaceID,"Summoning technique","Summons a magic doll to fight for you",true,8); 
		War3_CreateRaceEnd(thisRaceID);
	}
}

public OnMapStart()
{
	////War3_PrecacheSound(facsnd);
	////War3_PrecacheSound(halsnd);
	BeamSprite=War3_PrecacheBeamSprite();
	BeamSprite2=PrecacheModel("sprites/plasmabeam.vmt", true);
	doll=PrecacheModel("models/props_c17/doll01.mdl", true);
	HaloSprite=War3_PrecacheHaloSprite();
	obsolet=PrecacheModel("sprites/obsolete.vmt");
	prey=PrecacheModel("effects/blueblacklargebeam.vmt");
	vendetta=PrecacheModel("effects/hydraspinalcord.vmt");
	reward=PrecacheModel("sprites/laser.vmt");
	summon=PrecacheModel("sprites/blueshaft1.vmt");	
	PrecacheModel("models/props_c17/doll01.mdl", true);
}

public OnPluginStart()
{
	ultCooldownCvar=CreateConVar("war3_doll_ult_cd","30","Ultimate Cooldown between possible doll summons");
	ultCooldownCvar2=CreateConVar("war3_doll_fail_cd","8","Ultimate Cooldown if summon failed");
	g_offsCollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");	
	g_money=FindSendPropInfo("CCSPlayer","m_iAccount");
}

public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			new race_attacker=War3_GetRace(attacker);
			if(race_attacker==thisRaceID)
			{
				new Float:spos[3];
				new Float:epos[3];
				GetClientAbsOrigin(victim,epos);
				GetClientAbsOrigin(attacker,spos);
				spos[2]+=366;
				epos[2]+=40;
				spos[1]+=4.53;
				TE_SetupDynamicLight(epos,255,29,29,9,100.0,2.0,2.0);
				TE_SendToAll();
				//TE_SetupFunnel(epos, 80, doll);
				//TE_SendToAll();
				spos[1]-=91;
				TE_SetupBeamPoints(spos, epos, BeamSprite2, BeamSprite, 1, 5, 0.35, 1.0, 1.0, 2, 20.0, {255,129,129,155}, 10);
				TE_SendToAll(0.3);
				spos[1]-=91;
				TE_SetupBeamPoints(spos, epos, BeamSprite2, BeamSprite, 1, 5, 0.35, 1.0, 1.0, 2, 20.0, {129,255,129,155}, 10);
				TE_SendToAll(0.6);
				spos[1]-=91;
				spos[0]+=20;
				TE_SetupBeamPoints(spos, epos, BeamSprite2, BeamSprite, 1, 5, 0.35, 1.0, 1.0, 2, 20.0, {129,255,129,155}, 10);
				TE_SendToAll(0.9);
				spos[1]-=91;
				spos[0]-=15;
				TE_SetupBeamPoints(spos, epos, BeamSprite2, BeamSprite, 1, 5, 0.35, 1.0, 1.0, 2, 20.0, {129,255,129,155}, 10);
				TE_SendToAll(1.2);
				spos[1]-=91;
				TE_SetupBeamPoints(spos, epos, BeamSprite2, BeamSprite, 1, 5, 0.35, 1.0, 1.0, 2, 20.0, {129,129,255,155}, 10);
				TE_SendToAll();
				//new Direction;
				//Direction[0] = GetRandomFloat(-100.0, 100.0);
				//Direction[1] = GetRandomFloat(-100.0, 100.0);
				//Direction[2] = 300.0;
				new Float:Direction[3]={0.0,0.0,300.0};
				Gib(spos, Direction, "models/props_c17/doll01.mdl");
				War3_ShakeScreen(victim,2.2,35.0,36.0);
			}
		}
	}
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
/*
stock TE_SetupFunnel(const Float:vector1,reversed,modelIndex)
{
	TE_Start("Large Funnel");
	TE_WriteFloat("m_vecOrigin", vector1);
	TE_WriteNum("m_nModelIndex", modelIndex);
	TE_WriteNum("m_nReversed", reversed);
}
*/
stock WL_GetMoney(player)
{
	return GetEntData(player,g_money);
}

stock WL_SetMoney(player,money)
{
	SetEntData(player,g_money,money);
}

stock WL_Blood(player)
{
	new ent = CreateEntityByName("env_blood");
	DispatchSpawn(ent);
	DispatchKeyValue(ent, "spawnflags", "158");
	DispatchKeyValue(ent, "amount", "100");
	DispatchKeyValue(ent, "color", "0");
	AcceptEntityInput(ent, "EmitBlood", player);
	CreateTimer(2.0, DisableEffect, ent);
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && pressed && IsPlayerAlive(client))
	{
		PrintHintText(client,"PuppetMaster:\n This Race has no ability skill!");
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	Skeleton[client]=false;
	if(newrace!=thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID,"");
		bFrenzy[client]=false;
		W3ResetPlayerColor(client,thisRaceID);
		W3ResetAllBuffRace(client,thisRaceID);
	}
	if(newrace==thisRaceID)
	{
		if(GetClientTeam(client)==2)
		{
			W3SetPlayerColor(client,thisRaceID,220,100,100,255,1);
		}
		else{
			W3SetPlayerColor(client,thisRaceID,100,100,255,255,1);
		}
	}
}

public OnWar3EventSpawn(client)
{
	War3_SetBuff(client,bSilenced,thisRaceID,false);
	new race = War3_GetRace(client);
	if (race == thisRaceID)
	{ 
		new Float:iVec[ 3 ];
		GetClientAbsOrigin( client, Float:iVec );
		TE_SetupGlowSprite(iVec,obsolet,3.12,3.20,200);
		TE_SendToAll();
		TE_SetupBeamRingPoint(iVec,20.0,75.0,reward,HaloSprite,0,15,1.2,15.0,2.0,{255,255,255,255},0,0);
		TE_SendToAll(0.3);
		TE_SetupBeamRingPoint(iVec,20.0,75.0,reward,HaloSprite,0,15,1.2,15.0,2.0,{255,255,255,255},0,0);
		TE_SendToAll(0.6);
		TE_SetupBeamRingPoint(iVec,20.0,75.0,reward,HaloSprite,0,15,1.2,15.0,2.0,{255,255,255,255},0,0);
		TE_SendToAll(0.9);
		TE_SetupBeamRingPoint(iVec,20.0,75.0,reward,HaloSprite,0,15,1.2,15.0,2.0,{255,255,255,255},0,0);
		TE_SendToAll(1.2);
		TE_SetupBeamRingPoint(iVec,20.0,75.0,reward,HaloSprite,0,15,1.2,15.0,2.0,{255,255,255,255},0,0);
		TE_SendToAll(1.5);
		TE_SetupBeamRingPoint(iVec,20.0,75.0,reward,HaloSprite,0,15,1.2,15.0,2.0,{255,255,255,255},0,0);
		TE_SendToAll(1.8);
		TE_SetupBeamRingPoint(iVec,20.0,120.0,reward,HaloSprite,0,15,2.5,15.0,2.0,{255,255,255,255},0,0);
		TE_SendToAll(2.1);
		TE_SetupGlowSprite(iVec,doll,1.85,2.8,180);
		TE_SendToAll();
		TE_SetupDynamicLight(iVec,255,28,28,10,30.0,2.2,2.2);
		TE_SendToAll();
		/*new Direction;
		Direction[0] = GetRandomFloat(-100.0, 100.0);
		Direction[1] = GetRandomFloat(-100.0, 100.0);
		Direction[2] = 300.0;*/
		new Float:Direction[3]={100.0,-50.0,300.0};
		Gib(iVec, Direction, "models/props_c17/doll01.mdl");
		
		currentspawns[client] = 0;
		
		if(GetClientTeam(client)==2)
		{
			W3SetPlayerColor(client,thisRaceID,220,100,100,255,1);
		}
		else{
			W3SetPlayerColor(client,thisRaceID,100,100,255,255,1);
		}
	}
	else{
		War3_WeaponRestrictTo(client,thisRaceID,"");
		Skeleton[client]=false;
		//W3ResetAllBuff(client,thisRaceID);
		W3ResetPlayerColor(client,thisRaceID);
	}
}

stock Gib(Float:Origin[3], Float:Direction[3], String:Model[])
{
	if (!IsEntLimitReached(.message="unable to create gibs"))
	{
		new Ent = CreateEntityByName("prop_physics");
		DispatchKeyValue(Ent, "model", Model);
		SetEntProp(Ent, Prop_Send, "m_CollisionGroup", 1); 
		DispatchSpawn(Ent);
		TeleportEntity(Ent, Origin, Direction, Direction);
		CreateTimer(GetRandomFloat(20.0, 35.0), RemoveGib,EntIndexToEntRef(Ent));
	}
}

public Action:RemoveGib(Handle:Timer, any:Ref)
{
	new Ent = EntRefToEntIndex(Ref);
	if (Ent > 0 && IsValidEdict(Ent))
	{
		RemoveEdict(Ent);
	}
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && IsPlayerAlive(client))
	{
		new skill=War3_GetSkillLevel(client,race,ULT_DOLLSUMMON);
		if(skill>0)
		{
			if(War3_SkillNotInCooldown(client,thisRaceID,ULT_DOLLSUMMON,true))
			{
				if(GetRandomFloat(0.0,1.0)<=RaiseDeadChance[skill])
				{
					new summonerteam;
					summonerteam=GetClientTeam(client);
					new possibletargets[MAXPLAYERS];
					new possibletargetsfound;
					new necrorace=War3_GetRaceIDByShortname("doll");
					for(new x=1;x<=MaxClients;x++)
					{
						if(x!=client&&ValidPlayer(x) && GetClientTeam(x)==summonerteam && IsPlayerAlive(x)==false && War3_GetRace(x)!=necrorace)
						{
							possibletargets[possibletargetsfound]=x;
							possibletargetsfound++;
						}
					}
					new onetarget;
					if(possibletargetsfound>0)
					{
						onetarget=possibletargets[GetRandomInt(0, possibletargetsfound-1)];
						if(onetarget>0)
						{
							if( currentspawns[client] < maxspawns[skill])
							{
								currentspawns[client]++;
								War3_CooldownMGR(client,GetConVarFloat(ultCooldownCvar),thisRaceID,ULT_DOLLSUMMON,_,_);
								new Float:ang[3];
								new Float:pos[3];
								War3_SpawnPlayer(onetarget);
								GetClientEyeAngles(client,ang);
								GetClientAbsOrigin(client,pos);
								TeleportEntity(onetarget,pos,ang,NULL_VECTOR);
								//EmitSoundToAll(facsnd,client);
								Raiser[onetarget]=client;
								Skeleton[onetarget]=true;
								if(GetClientTeam(onetarget)==3)
								{
									W3SetPlayerColor(onetarget,thisRaceID,20,100,255,255,1);
								}
								else
								{
									W3SetPlayerColor(onetarget,thisRaceID,255,100,20,255,1);
								}
								new Float:this_pos[ 3 ];
								GetClientAbsOrigin(onetarget,this_pos);
								War3_SetBuff(onetarget,bSilenced,thisRaceID,true);
								War3_SetBuff(onetarget,fMaxSpeed,thisRaceID,0.85);
								this_pos[2]+=35.0;
								new Float:iVec2[ 3 ];
								GetClientAbsOrigin( client, Float:iVec2 );
								iVec2[2]+=3500.0;
								TE_SetupBeamPoints(iVec2,this_pos,BeamSprite,HaloSprite,0,41,1.6,6.0,15.0,0,4.5,{255,255,255,255},45);
								TE_SendToAll();
								/*new Direction;
						Direction[0] = GetRandomFloat(-50.0, 50.0);
						Direction[1] = GetRandomFloat(-50.0, 50.0);
						Direction[2] = 100.0;*/
								new Float:Direction[3]={25.0,-15.0,250.1};
								this_pos[2]+=220.0;
								Gib(iVec2, Direction, "models/props_c17/doll01.mdl");
								TE_SetupGlowSprite(this_pos,summon,2.5,2.5,200);
								TE_SendToAll();
								PrintHintText(client,"S U M M O N E D");
								PrintCenterText(onetarget,"You are a summoned as a DOLL!");
								SetEntData(onetarget, g_offsCollisionGroup, 2, 4, true);
								SetEntData(client, g_offsCollisionGroup, 2, 4, true);
								CreateTimer(7.0,normal,onetarget);
								CreateTimer(7.0,normal,client);
								CreateTimer(1.0,dmsg,onetarget);
								PrintHintText(client, "Summoned Doll(%d/%d)!", currentspawns[client], maxspawns[skill]);
							}
							else
							{
								PrintHintText(client, "Cannot summon! Limit (%d/%d) reached!", currentspawns[client], maxspawns[skill]);
							}
						}
						else
						{
							War3_CooldownMGR(client,GetConVarFloat(ultCooldownCvar2),thisRaceID,ULT_DOLLSUMMON,_,_);
							PrintCenterText(client,"Summoning technique failed!");
						}
					}
				}
			}
		}
	} 
}

public Action:dmsg(Handle:timer,any:client)
{
	PrintCenterText(client,"Summon Complete.");

	FakeClientCommandEx(client, "drop");
	FakeClientCommandEx(client, "drop");
	CreateTimer(0.1,dropagain,client);
}

public Action:dropagain(Handle:timer,any:client)
{
	FakeClientCommandEx(client, "drop");
	GivePlayerItem(client,"weapon_hegrenade");
	GivePlayerItem(client,"weapon_deagle");
}

public OnWar3EventDeath(victim,attacker)
{
	War3_SetBuff(victim,bSilenced,thisRaceID,false);
	if(Skeleton[attacker]==true && ValidPlayer(Raiser[attacker]))
	{
		if(ValidPlayer(attacker))
		{
			//PrintToServer("[Notice] : PuppetMaster's doll got a kill");
			new old_XP = War3_GetXP(Raiser[attacker],thisRaceID);
			new revive=War3_GetSkillLevel(Raiser[attacker],thisRaceID,SKILL_REWRD);
			if(revive>0)
			{
				new xp=addxp[revive];
				WL_Blood(Raiser[attacker]);
				War3_SetXP(Raiser[attacker],thisRaceID,old_XP+xp);
				PrintHintText(Raiser[attacker],"You receive %dxp from your doll",xp);
				PrintToChat(Raiser[attacker],"\x03Reward:You receive %dxp from your doll",xp);
				new String:Message[250] = "You receive xp from you doll";
				PrintCenterText(Raiser[attacker],"+%dxp",xp);
				new Handle:hBuffer = StartMessageOne("KeyHintText",Raiser[attacker]);
				BfWriteByte(hBuffer, 1);
				BfWriteString(hBuffer, Message);
				EndMessage();
				new Float:effect_vec[3];
				GetClientAbsOrigin(Raiser[attacker],effect_vec);
				//EmitSoundToAll(halsnd,Raiser[attacker]);
				effect_vec[2]+=15.0;
				TE_SetupBeamRingPoint(effect_vec,45.0,5.0,reward,HaloSprite,0,15,0.3,1.0,50.0,{255,255,255,255},0,0);
				TE_SendToAll(0.3);
				TE_SetupBeamRingPoint(effect_vec,45.0,3.0,reward,HaloSprite,0,15,0.3,3.0,50.0,{255,255,255,255},0,0);
				TE_SendToAll(0.6);
				TE_SetupBeamRingPoint(effect_vec,45.0,1.0,reward,HaloSprite,0,15,0.3,6.5,50.0,{255,255,255,255},0,0);
				TE_SendToAll(0.9);
			}
			
			new skill=War3_GetSkillLevel(Raiser[attacker],thisRaceID,SKILL_PREY);
			if(skill>0)
			{
				new hpadd=addhp[skill];
				new war3_health = GetClientHealth(Raiser[attacker])+hpadd;
				SetEntityHealth(Raiser[attacker],war3_health);
				PrintHintText(Raiser[attacker],"You receive %dhp from your doll",hpadd);
				PrintCenterText(Raiser[attacker],"+%dhp",hpadd);
				new String:Message[250] = "Summoning technique\nYou receive hp from your doll";
				PrintToChat(Raiser[attacker],"\x03Prey:You receive %dhp from your doll",hpadd);
				new Handle:hBuffer = StartMessageOne("KeyHintText",Raiser[attacker]);
				BfWriteByte(hBuffer, 1);
				BfWriteString(hBuffer, Message);
				EndMessage();  
				W3FlashScreen(Raiser[attacker],{255,100,100,80});
				WL_Blood(Raiser[attacker]);
				PrintToConsole(Raiser[attacker],"[Notice] Health Changed, Current Health : %d",war3_health);
				new Float:effect_vec[3];
				GetClientAbsOrigin(Raiser[attacker],effect_vec);
				//EmitSoundToAll(halsnd,Raiser[attacker]);
				effect_vec[2]+=15.0;
				TE_SetupBeamRingPoint(effect_vec,0.1,120.0,prey,HaloSprite,0,15,0.3,1.0,50.0,{255,100,100,255},0,0);
				TE_SendToAll(0.3);
				TE_SetupBeamRingPoint(effect_vec,0.1,120.0,prey,HaloSprite,0,15,0.3,3.0,50.0,{255,100,100,255},0,0);
				TE_SendToAll(0.6);
				TE_SetupBeamRingPoint(effect_vec,0.1,120.0,prey,HaloSprite,0,15,0.3,6.5,50.0,{255,100,100,255},0,0);
				TE_SendToAll(0.9);
			}
			new skill2=War3_GetSkillLevel(Raiser[attacker],thisRaceID,SKILL_VENDETT);
			if(skill2>0)
			{
				new bonus2=War3_GetSkillLevel(Raiser[attacker],thisRaceID,SKILL_VENDETT);
				new bonus=addgold[bonus2];
				new new_money=WL_GetMoney(Raiser[attacker])+bonus;
				WL_SetMoney(Raiser[attacker],new_money);
				WL_Blood(Raiser[attacker]);
				WL_Blood(victim);
				PrintHintText(Raiser[attacker],"You receive %d $ from a doll",bonus);
				PrintCenterText(Raiser[attacker],"+%d$",bonus);
				new String:Message[250] = "Summoning technique\nYou receive cash from your doll";
				PrintToChat(Raiser[attacker],"\x03Vendetta:You receive %d$ from your doll",bonus);
				new Handle:hBuffer = StartMessageOne("KeyHintText",Raiser[attacker]);
				BfWriteByte(hBuffer, 1);
				BfWriteString(hBuffer, Message);
				EndMessage();  
				PrintCenterText(attacker,"Puppetmasters Vendetta activatet!");
				//EmitSoundToAll(halsnd,Raiser[attacker]);
				new Float:iVec[ 3 ];
				GetClientAbsOrigin( Raiser[attacker], Float:iVec );
				iVec[2]+=35.0;
				TE_SetupDynamicLight(iVec,232,250,12,1,120.0,2.85,3.0);
				TE_SendToAll();
				W3FlashScreen(attacker,{232,250,10,80});
				W3FlashScreen(Raiser[attacker],{232,250,10,80});
				new Float:spos[3];
				new Float:epos[3];
				GetClientAbsOrigin(victim,epos);
				GetClientAbsOrigin(attacker,spos);
				epos[2]+=45;
				spos[2]+=48;
				spos[1]+=6;
				spos[2]+=28;
				TE_SetupBeamPoints(spos, epos, BeamSprite2, HaloSprite, 0, 120, 1.2, 12.0, 10.0, 0, 500.0, {255,255,255,255}, 30);
				TE_SendToAll();
				spos[2]-=28;
				TE_SetupBeamPoints(spos, epos, vendetta, HaloSprite, 0, 30, 1.2, 5.0, 5.0, 0, 10.0, {255,255,255,255}, 30);
				TE_SendToAll();
			}
		}
		/*
		if(ValidPlayer(attacker) && ValidPlayer(Raiser[attacker]))
		{
			new bonus2=War3_GetSkillLevel(Raiser[attacker],thisRaceID,SKILL_VENDETT);
			new bonus=addgold[bonus2];
			new new_money=WL_GetMoney(Raiser[attacker])+bonus;
			WL_SetMoney(attacker,new_money);
			PrintHintText(Raiser[attacker],"You receive %d $ from a doll",bonus);
			PrintCenterText(Raiser[attacker],"+%d$",bonus);
			new String:Message[250] = "Summoning technique\nYou receive cash from a doll";
			new Handle:hBuffer = StartMessageOne("KeyHintText",Raiser[attacker]);
			BfWriteByte(hBuffer, 1);
			BfWriteString(hBuffer, Message);
			EndMessage();  
			PrintCenterText(attacker,"Puppetmasters Vendetta activatet!");
			//EmitSoundToAll(halsnd,Raiser[attacker]);
			new Float:iVec[ 3 ];
			GetClientAbsOrigin( Raiser[attacker], Float:iVec );
			iVec[2]+=35.0;
			TE_SetupDynamicLight(iVec,232,250,12,1.2,120,2.85,3.0);
			TE_SendToAll();
			W3FlashScreen(attacker,{232,250,10,80});
			W3FlashScreen(Raiser[attacker],{232,250,10,80});
			new Float:spos[3];
			new Float:epos[3];
			GetClientAbsOrigin(victim,epos);
			GetClientAbsOrigin(attacker,spos);
			epos[2]+=45;
			spos[2]+=48;
			spos[1]+=6;
			TE_SetupBeamPoints(spos, epos, vendetta, HaloSprite, 0, 120, 1.2, 12.0, 10.0, 0, 500.0, {255,255,255,255}, 30);
			TE_SendToAll();
			TE_SetupBeamPoints(spos, epos, vendetta, BeamSprite2, 0, 30, 1.2, 5.0, 5.0, 0, 10.0, {255,255,255,255}, 30);
			TE_SendToAll();
		}
		*/
	}/*
	if(Skeleton[victim] && ValidPlayer(Raiser[attacker]))
	{
		if(ValidPlayer(victim))
		{
		PrintToServer("[Notice] : PuppetMaster's doll got killed");
		
	}
	PrintToChatAll("\x04DEBUG MESSAGE,\x02Reporting \x05: \x03Skelton_victim \x02= %d", Skeleton[victim]);*/
}

public Action:DisableEffect(Handle:timer, any:ent){
	if ((ent == -1) || (!IsValidEdict(ent)))
	{
		return Plugin_Continue;
	}
	RemoveEdict(ent);
	return Plugin_Handled;
}

public Action:normal(Handle:timer,any:client)
{
	SetEntData(client, g_offsCollisionGroup, 5, 4, true);
	new Float:iVec[ 3 ];
	GetClientAbsOrigin( client, Float:iVec );
	TE_SetupDynamicLight(iVec,232,100,100,1,120.0,2.85,3.0);
	TE_SendToAll();
}

/**
* Description: Function to check the entity limit.
*              Use before spawning an entity.
*/
#tryinclude <entlimit>
#if !defined _entlimit_included
stock IsEntLimitReached(warn=20,critical=16,client=0,const String:message[]="")
{
	new max = GetMaxEntities();
	new count = GetEntityCount();
	new remaining = max - count;
	if (remaining <= warn)
	{
		if (count <= critical)
		{
			PrintToServer("Warning: Entity limit is nearly reached! Please switch or reload the map!");
			LogError("Entity limit is nearly reached: %d/%d (%d):%s", count, max, remaining, message);
			
			if (client > 0)
			{
				PrintToConsole(client, "Entity limit is nearly reached: %d/%d (%d):%s",
				count, max, remaining, message);
			}
		}
		else
		{
			PrintToServer("Caution: Entity count is getting high!");
			LogMessage("Entity count is getting high: %d/%d (%d):%s", count, max, remaining, message);
			
			if (client > 0)
			{
				PrintToConsole(client, "Entity count is getting high: %d/%d (%d):%s",
				count, max, remaining, message);
			}
		}
		return count;
	}
	else
	return 0;
}
#endif
