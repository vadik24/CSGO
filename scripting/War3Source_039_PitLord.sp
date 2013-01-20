//Azgalor - Pit Lord
//From War3Source - http://www.dotastrategy.com/hero-91-AzgalorPitLord.html
//THANKS TO:
//Ownz & Pimpin - War3Source
#include <sourcemod>
#include <sdktools_functions>
#include <sdktools_sound>
#include "W3SIncs/War3Source_Interface"
new DamageStorm[5]={10,15,18,24,29};
new MaximumDamage[5]={15,18,24,29,30};
new Float:Chance[5]={0.00,0.20,0.25,0.28,0.30};
new Float:RadiusStorm[5]={0.00,0.20,0.25,0.28,0.30};
new Float:PitSlow[5]={0.00,0.60,0.55,0.45,0.32};
new Float:PitMaxDistance[5]={0.00,350.0,400.0,800.0,1200.0};
new Float:ult_delay[5]={0.0,6.5,5.0,3.5,1.95};
new DamageFire1[5]={30,40,49,52,60};
new DamageFire2[5]={35,46,52,60,72};
new addhp[5]={0,10,15,20,25};
new bool:bIsTarget[MAXPLAYERS];
//WARD(Fire) BY OWNZ & PIMPINJUICE
#define MAXWARDS 64*4
#define WARDRADIUS 80
#define WARDBELOW -2.0
#define WARDABOVE 160.0
#define WARDDAMAGE 6
//new CurrentWardCount[MAXPLAYERS];
//new WardStartingArr[]={0,1,1,1,2}; 
new Float:WardLocation[MAXWARDS][3]; 
//new PitOwner[MAXWARDS];
new FlameOwner[MAXWARDS];
new Float:LastThunderClap[MAXPLAYERS];
new CurrentFlameCount[MAXPLAYERS];
new Handle:ultCooldownCvar_SPAWN;
new Handle:ultCooldownCvar;
new Handle:SFXCvar;
new thisRaceID, SKILL_FIRE, SKILL_PIT, SKILL_IGNITE, ULT_RIFT;
new String:burnsnd[]="ambient/explosions/explode_4.wav";
new String:catchsnd[]="npc/strider/fire.wav";
new String:pitsnd[]="ambient/levels/labs/teleport_postblast_thunder1.wav";
new String:riftsnd[]="weapons/irifle/irifle_fire2.wav";
new String:ignitesnd[]="ambient/fire/gascan_ignite1.wav";

//temp ents
new BeamSprite, HaloSprite, FireSprite, Explosion, HydraSprite, SimpleFire, Particle, BlackSprite, Ventilator;

public Plugin:myinfo = 
{
	name = "War3Source Race - Pit Lord[DotA]",
	author = "Revan",
	description = "One of the many regents of Lord Archimonde - DotA",
	version = "1.0.0.5",
	url = "www.wcs-lagerhaus.de"
};

public OnPluginStart()
{
	HookEvent("round_end",RoundEvent);
	//CreateTimer(0.14,DeadlyPit,_,TIMER_REPEAT);
	CreateTimer(0.25,Flame,_,TIMER_REPEAT);
	ultCooldownCvar_SPAWN=CreateConVar("war3_azgalor_ult_cooldown_spawn","10","(Azgalor)Pit Lord's Ultimate Cooldown on spawn.");
	ultCooldownCvar=CreateConVar("war3_azgalor_ult_cooldown","25","(Azgalor)Pit Lord's Ultimate Cooldown.");
	SFXCvar=CreateConVar("war3_azgalor_hugefx_enable","1","Enable/Disable distracting and revealing sfx");
	HookConVarChange(ultCooldownCvar_SPAWN, W3CvarCooldownHandler);
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==228)
	{
		thisRaceID = War3_CreateNewRace( "Azgalor - Pit Lord", "azgalor" );
		SKILL_FIRE = War3_AddRaceSkill( thisRaceID, "Fire Storm", "Calls down up to 3 waves(per cast) of fire that damage enemy units in an area\nEach wave deals damage and then burns enemies for 2 seconds.", false, 4 );	
		SKILL_PIT = War3_AddRaceSkill( thisRaceID, "Pit of Malice", "A deadly pit is conjured at target location\nAny enemy unit that enters it becomes corrupted with malicious forces and are slowed down for some time.(ability)", false, 4 );	
		SKILL_IGNITE = War3_AddRaceSkill( thisRaceID, "Expulsion", "Ignites the rotten gases of corpses, detonating them to cause damage\n to any enemy within the explosion radius.", false, 4 );
		ULT_RIFT = War3_AddRaceSkill( thisRaceID, "Dark Rift", "Opens an rift that pass through the netherworld.", true, 4 );
		W3SkillCooldownOnSpawn( thisRaceID, ULT_RIFT, GetConVarFloat(ultCooldownCvar_SPAWN) );
		War3_CreateRaceEnd( thisRaceID );
	}
}

public OnMapStart() {
  //tons of precaches..
  War3_PrecacheSound(catchsnd);
  War3_PrecacheSound(burnsnd);
  War3_PrecacheSound(ignitesnd);
  War3_PrecacheSound(riftsnd);
  War3_PrecacheSound(pitsnd);
  BeamSprite=PrecacheModel("sprites/orangelight1.vmt");
  HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
  FireSprite=PrecacheModel("effects/fire_cloud2.vmt");
  SimpleFire=PrecacheModel("sprites/flatflame.vmt");
  Explosion=PrecacheModel("sprites/floorfire4_.vmt");
  HydraSprite=PrecacheModel("sprites/hydragutbeam.vmt");
  Particle=PrecacheModel("particle/fire.vmt");
  BlackSprite=PrecacheModel("sprites/scanner.vmt");
  Ventilator=PrecacheModel("decals/decalmetalvent006a.vmt");
}

public W3CvarCooldownHandler(Handle:cvar, const String:oldValue[], const String:newValue[]) 
{ 
	new Float:value = StringToFloat(newValue);
	if(value>0.0)
	W3SkillCooldownOnSpawn( thisRaceID, ULT_RIFT, value );
}

public CreateFlame(client,target)
{
	for(new i=0;i<MAXWARDS;i++)
	{
		if(FlameOwner[i]==0)
		{
			FlameOwner[i]=client;
			GetClientAbsOrigin(target,WardLocation[i]);
			break;
		}
	}
}

public RemoveFlames(client)
{
	for(new i=0;i<MAXWARDS;i++)
	{
		if(FlameOwner[i]==client)
		{
			FlameOwner[i]=0;
		}
	}
	CurrentFlameCount[client]=0;
}

public Action:Flame(Handle:timer,any:userid)
{
	new client;
	for(new i=0;i<MAXWARDS;i++)
	{
		if(FlameOwner[i]!=0)
		{
			client=FlameOwner[i];
			if(!ValidPlayer(client,true))
			{
				FlameOwner[i]=0;
				--CurrentFlameCount[client];
			}
			else
			{
				FlameLoop(client,i);
			}
		}
	}
}

public FlameLoop(owner,wardindex)
{
	new ownerteam=GetClientTeam(owner);
	new Float:start_pos[3];
	new Float:end_pos[3];
	new Float:tempVec1[]={0.0,0.0,WARDBELOW};
	new Float:tempVec2[]={0.0,0.0,WARDABOVE};
	AddVectors(WardLocation[wardindex],tempVec1,start_pos);
	AddVectors(WardLocation[wardindex],tempVec2,end_pos);
	//TE_SetupGlowSprite(start_pos,SimpleFire,0.26,1.00,212);
	//TE_SendToAll();
	new Float:BeamXY[3];
	for(new x=0;x<3;x++) BeamXY[x]=start_pos[x];
	new Float:BeamZ= BeamXY[2];
	BeamXY[2]=0.0;
	
	
	new Float:VictimPos[3];
	new Float:tempZ;
	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true)&& GetClientTeam(i)!=ownerteam )
		{
			GetClientAbsOrigin(i,VictimPos);
			tempZ=VictimPos[2];
			VictimPos[2]=0.0;
			      
			if(GetVectorDistance(BeamXY,VictimPos) < WARDRADIUS)
			{
				if(tempZ>BeamZ+WARDBELOW && tempZ < BeamZ+WARDABOVE)
				{
					if(W3HasImmunity(i,Immunity_Skills))
					{
						W3MsgSkillBlocked(i,_,"Expulsion");
					}
					else
					{
						W3FlashScreen(i,{0,0,0,255});
						if(War3_DealDamage(i,WARDDAMAGE,owner,DMG_BULLET,"flame",_,W3DMGTYPE_MAGIC))
						{
							if(LastThunderClap[i]<GetGameTime()-2){
								EmitSoundToAll(ignitesnd,i,SNDCHAN_WEAPON);
								LastThunderClap[i]=GetGameTime();
							}
						}
					}
				}
			}
		}
	}
}

public Action:StopSlow( Handle:timer, any:client )
{
	War3_SetBuff(client,fSlow,thisRaceID,1.0);
	PrintToConsole(client,"[W3S] Slowdown is fading away...");
	new Float:startpos[3];
	GetClientAbsOrigin(client,startpos);
	TE_SetupBeamRingPoint(startpos,120.1,20.0,BeamSprite,BeamSprite,0,15,1.20,27.0,12.0,{255,120,120,255},0,0);
	TE_SendToAll();
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{
		RemoveFlames(client);
	}
}

public RoundEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	for(new x=1;x<=64;x++)
	{
		new race = War3_GetRace(x);
		if (race == thisRaceID)
		{
			RemoveFlames(x);
			bIsTarget[x]=true;
		}
	}
}

public OnWar3EventSpawn(client)
{
	new user_race = War3_GetRace(client);
	if (user_race == thisRaceID)
	{ 
		RemoveFlames(client);
		new Float:iVec[3];
		GetClientAbsOrigin(client, Float:iVec);
		new Float:iVec2[3];
		GetClientAbsOrigin(client, Float:iVec2);
		iVec[2]+=100;
		iVec2[2]+=100;
		TE_SetupBeamRingPoint(iVec,20.0,75.0,HaloSprite,HaloSprite,0,15,0.4,15.0,2.0,{255,120,120,255},0,0);
		TE_SendToAll(0.3);
		iVec[2]-=10;
		TE_SetupBeamRingPoint(iVec,20.0,75.0,HaloSprite,HaloSprite,0,15,0.4,15.0,2.0,{255,120,120,255},0,0);
		TE_SendToAll(0.6);
		iVec[2]-=10;
		TE_SetupBeamRingPoint(iVec,20.0,75.0,HaloSprite,HaloSprite,0,15,0.4,15.0,2.0,{255,120,120,255},0,0);
		TE_SendToAll(0.9);
		iVec[2]-=10;
		TE_SetupBeamRingPoint(iVec,20.0,75.0,HaloSprite,HaloSprite,0,15,0.4,15.0,2.0,{255,120,120,255},0,0);
		TE_SendToAll(1.2);
		iVec[2]-=10;
		TE_SetupBeamRingPoint(iVec,20.0,75.0,HaloSprite,HaloSprite,0,15,0.4,15.0,2.0,{255,120,120,255},0,0);
		TE_SendToAll(1.5);
		iVec[2]-=10;
		TE_SetupBeamRingPoint(iVec,20.0,75.0,HaloSprite,HaloSprite,0,15,0.4,15.0,2.0,{255,120,120,255},0,0);
		TE_SendToAll(1.8);
		iVec[2]-=10;
		TE_SetupBeamRingPoint(iVec,20.0,120.0,HaloSprite,HaloSprite,0,15,0.4,15.0,2.0,{255,120,120,255},0,0);
		TE_SendToAll(2.1);
		iVec[2]-=10;
		TE_SetupBeamRingPoint(iVec,20.0,120.0,HaloSprite,HaloSprite,0,15,0.4,15.0,2.0,{255,120,120,255},0,0);
		TE_SendToAll(2.1);
		iVec[2]-=10;
		TE_SetupBeamRingPoint(iVec,20.0,120.0,HaloSprite,HaloSprite,0,15,0.4,15.0,2.0,{255,120,120,255},0,0);
		TE_SendToAll(2.4);
		TE_SetupGlowSprite(iVec,SimpleFire,3.0,1.00,212);
		TE_SendToAll();
		//TE_SetupDynamicLight(iVec,255,28,28,10,30.0,2.2,2.2);
		//TE_SendToAll();
		TE_SetupDynamicLight(iVec,255,0,0,12,80.0,2.8,1.0);
		TE_SendToAll(2.4);
	}
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
			new skill_level=War3_GetSkillLevel(attacker,thisRaceID,SKILL_FIRE);
			if(race_attacker==thisRaceID && skill_level>0 )
			{
				if(GetRandomFloat(0.0,1.0)<=Chance[skill_level] && !W3HasImmunity(victim,Immunity_Skills))
				{
					new Float:spos[3];
					new Float:epos[3];
					GetClientAbsOrigin(victim,epos);
					GetClientAbsOrigin(attacker,spos);
					epos[2]+=35;
					spos[2]+=100;
					if(GetConVarBool(SFXCvar))
					{
						TE_SetupBeamPoints(spos, epos, BeamSprite, BeamSprite, 0, 35, 1.0, 10.0, 10.0, 0, 10.0, {255,25,25,255}, 30);
						TE_SendToAll();
					}
					new damage1=DamageStorm[skill_level];
					new damage2=MaximumDamage[skill_level];
					new Float:radius=RadiusStorm[skill_level];
					DoFire(attacker,victim,radius,damage1,damage2,true);
					
					W3FlashScreen(victim,RGBA_COLOR_RED);
				
					//bIsTarget[victim]=true;
					CreateTimer( 0.10, Timer_DeSelect, victim );

					EmitSoundToAll(burnsnd,victim);
					//PrintHintText(attacker,"Fire Storm");
				}
			}
		}
	}
}

//extra wagante effekte
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

//DoFire(angreifer, getroffener, radius, schaden
public DoFire(attacker,victim,Float:radius,damage,maxdmg,bool:showmsg)
{
	if(ValidPlayer(victim,true)&&ValidPlayer(attacker,true)){
		//if(IsPlayerAlive(victim)&&IsPlayerAlive(attacker));
		//{
			if(War3_GetRace(attacker)==thisRaceID && War3_GetRace(victim)!=War3_GetRaceIDByShortname("azgalor"))
			{
				new Float:StartPos[3];
				new Float:EndPos[3];
				
				GetClientAbsOrigin( attacker, StartPos );
				GetClientAbsOrigin( victim, EndPos );

				StartPos[2]+=100;
				TE_SetupGlowSprite(StartPos,FireSprite,3.0,0.80,212);
				TE_SendToAll();
				TE_SetupBeamRingPoint(StartPos,74.0,76.0,HaloSprite,HaloSprite,0,15,3.45,280.0,2.0,{255,77,77,255},0,0);
				TE_SendToAll();
				TE_SetupDynamicLight(StartPos,255,80,80,10,radius,3.30,2.2);
				TE_SendToAll();
				W3FlashScreen(attacker,RGBA_COLOR_RED);
				EmitSoundToClient(attacker, catchsnd);				
				new waveammount = GetRandomInt(1,3);
				if(waveammount!=0)
				{
					DoExplosion(damage,maxdmg,attacker,victim);
				}
				if(waveammount==2)
				{
					DoExplosion(damage,maxdmg,attacker,victim);
				}
				if(waveammount==3)
				{
					DoExplosion(damage,maxdmg,attacker,victim);
				}
				if(showmsg)
				{
					PrintHintText(attacker,"Fire Storm:\nCasted %i waves of Fire",waveammount);
				}
			}
		//}
	}
}

public OnWar3EventDeath(victim,attacker)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			new race_attacker=War3_GetRace(attacker);
			new skill_level=War3_GetSkillLevel(attacker,thisRaceID,SKILL_IGNITE);
			if(race_attacker==thisRaceID && skill_level>0 )
			{
				new Float:Vec[3];
				GetClientAbsOrigin(victim,Vec);
				new Float:Vec2[3];
				GetClientAbsOrigin(victim,Vec2);
				new Float:Vec3[3];
				GetClientAbsOrigin(attacker,Vec3);
				Vec2[2]+=100;
				Vec3[2]+=45;
				TE_SetupGlowSprite( Vec, SimpleFire, 10.0 , 1.6 , 195);
				TE_SendToAll();
				if(GetConVarBool(SFXCvar))
				{
					TE_SetupExplosion(Vec, Explosion, 6.5, 1, 4, 0, 0);
					TE_SendToAll();
					TE_SetupExplosion(Vec, Explosion, 6.5, 1, 4, 0, 0);
					TE_SendToAll();
					TE_SetupBeamPoints( Vec, Vec3, HydraSprite, HaloSprite, 0, 1, 2.3, 45.0, 2.0, 0, 3.0, { 255, 0, 0, 255 }, 1 );
					TE_SendToAll();
				}
				EmitSoundToClient(attacker, burnsnd);

				new damage1=DamageFire1[skill_level];
				new damage2=DamageFire2[skill_level];
				//bIsTarget[victim]=true;
				CreateTimer( 0.10, Timer_DeSelect, victim );
				IgniteExplosion(damage1,damage2,attacker,victim)
				CreateFlame(attacker,victim);
				CreateTimer(10.0, Timer_Extinguish, attacker);
				TE_Start("Bubbles");
				TE_WriteVector("m_vecMins", Vec);
				TE_WriteVector("m_vecMaxs", Vec2);
				TE_WriteFloat("m_fHeight", 228.0);
				TE_WriteNum("m_nModelIndex", Particle);
				TE_WriteNum("m_nCount", 35);
				TE_WriteFloat("m_fSpeed", 0.5);
				TE_SendToAll();
			}
		}
	}
}
public DoExplosion(magnitude,maxdmg,client,target)
{
	//Destination = Owner
	//Vec = Fireball
	//Origin = Victim
	new Float:Destination[3];
	GetClientAbsOrigin(client,Destination);
	new AttackerTeam = GetClientTeam(client);
	TE_SetupBeamRingPoint(Destination,1.0,9000.0,HaloSprite,HaloSprite,0,15,2.8,10.0,2.0,{255,120,120,255},0,0);
	TE_SendToAll();
	War3_DealDamage(target,3,client,DMG_BULLET,"firestorm");
	//schaden simlurieren und spieler schmokeln lassen
	for(new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,true) && GetClientTeam(i)!=AttackerTeam && !bIsTarget[i])
			{
				bIsTarget[i]=true;
				CreateTimer( 0.10, Timer_DeSelect, i );
				new Float:Vec[3];
				GetClientAbsOrigin(target,Vec);
				new Float:Origin[3];
				GetClientAbsOrigin(i,Origin);
				Vec[0] += GetRandomFloat( -150.0, 150.0 );
				Vec[1] += GetRandomFloat( -150.0, 150.0 );
				Vec[2] += 10.0;
				if(GetConVarBool(SFXCvar))
				{
					TE_SetupExplosion(Vec, Explosion, 6.5, 1, 4, 0, 0);
					TE_SendToAll();
					TE_SetupExplosion(Vec, Explosion, 6.5, 1, 4, 0, 0);
					TE_SendToAll(0.18);
					Destination[2] += 100.0;
					TE_SetupBeamPoints( Vec, Destination, BeamSprite, HaloSprite, 0, 1, 0.61, 20.0, 2.0, 0, 1.0, { 255, 11, 11, 255 }, 1 );
					TE_SendToAll();
				}
				if(GetVectorDistance(Origin,Vec) < 100.0)
				{
					new magdmg = GetRandomInt(magnitude,maxdmg);
					PrintToConsole(client,"FireStorm hit a target and damaged him for %d damage",magdmg);
					IgniteEntity(i, 2.0);
					EmitSoundToClient(i, ignitesnd);
					W3FlashScreen(i,RGBA_COLOR_RED);
					War3_ShakeScreen(i);
					//TODO 1 - may add explosion sounds?
					War3_DealDamage(i,magdmg,client,DMG_BULLET,"firestorm");
					PrintToConsole(i,"hit by a firestorm");
					PrintCenterText(client,"Firestorm was successfully");
				}
			}
		}
}

public IgniteExplosion(mindmg,maxdmg,client,target)
{
	new Float:Destination[3];
	GetClientAbsOrigin(target,Destination);
	new AttackerTeam = GetClientTeam(client);
	EmitSoundToClient(client, catchsnd);
	for(new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,true)&&GetClientTeam(i)!=AttackerTeam && !bIsTarget[i])
			{
				new Float:Vec[3];
				GetClientAbsOrigin(i,Vec);
				if(GetVectorDistance(Destination,Vec)<=110.0)
				{
					bIsTarget[i]=true;
					CreateTimer( 0.10, Timer_DeSelect, i );
					//new Float:dir[3]={0.0,0.0,-90.0};
					new magdmg = GetRandomInt(mindmg,maxdmg);
					PrintToConsole(client,"[Notice] Expulsion dealing %i damage",magdmg);
					PrintToChat(i,"\x05Hit by Expulsion");
					IgniteEntity(i, 2.0);
					W3FlashScreen(i,RGBA_COLOR_RED);
					War3_ShakeScreen(i);
					//TODO 1 - may add explosion sounds?
					War3_DealDamage(i,magdmg,client,DMG_BULLET,"expulsion");
					if(GetConVarBool(SFXCvar))
					{
						TE_SetupExplosion(Vec, Explosion, 6.5, 1, 4, 0, 0);
						TE_SendToAll();
						TE_SetupBeamRingPoint( Vec,65.0,75.0,HaloSprite,HaloSprite,0,15,12.20,100.0,2.0,{255,0,0,255},30,0);
						TE_SendToAll();
						TE_SetupBeamRingPoint( Vec,74.0,9000.0,SimpleFire,HaloSprite,0,15,3.45,20.0,2.0,{255,0,0,255},0,0);
						TE_SendToAll();
					}
				}
			}
		}
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && IsPlayerAlive(client))
	{
		new skill=War3_GetSkillLevel(client,race,ULT_RIFT);
		if(skill>0)
		{
			if(War3_SkillNotInCooldown(client,thisRaceID,ULT_RIFT,true)&&!Silenced(client))
			{
				new Float:startpos[3];
				new Float:targetpos[3];
				GetClientAbsOrigin(client,startpos);
				GetClientAbsOrigin(client,targetpos);
				targetpos[2]+=850;
				TE_SetupBeamPoints(startpos, targetpos, BeamSprite, BeamSprite, 0, 5, 10.0, 65.0, 5.5, 2, 0.2, {255,128,35,255}, 70);  
				TE_SendToAll();
				TE_SetupBeamPoints(startpos, targetpos, BeamSprite, BeamSprite, 0, 5, 8.0, 65.0, 5.5, 2, 0.2, {255,128,35,240}, 70);  //do it twice so it disappears more smoothly
				TE_SendToAll();
				CreateTimer(ult_delay[skill], Timer_Rift, client);
				//PrintToChat(client,"Rift in %f seconds.",delay[skill]);
				War3_ChatMessage(client,"Rift in %f seconds.",ult_delay[skill]);
				EmitSoundToAll(riftsnd,client);
				new Float:ult_cooldown=GetConVarFloat(ultCooldownCvar);
				War3_CooldownMGR(client,ult_cooldown,thisRaceID,ULT_RIFT,_,_);
			}
		}
		else
		{
			W3MsgUltNotLeveled(client);
		}
	}
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && pressed && IsPlayerAlive(client))
	{
		new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_PIT);
		if(skill_level>0)
		{
			if(!Silenced(client))
			{
				if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_PIT,true))
				{
					new Float:startpos[3];
					new Float:targetpos[3];
					War3_GetAimEndPoint(client,targetpos);
					GetClientAbsOrigin(client,startpos);
					startpos[2]+=45;
					if(GetConVarBool(SFXCvar))
					{
						TE_SetupBeamPoints(startpos, targetpos, BlackSprite, BlackSprite, 0, 5, 1.0, 4.0, 9.0, 2, 3.5, {255,128,35,255}, 70);  
						TE_SendToAll();
						TE_SetupBeamRingPoint(targetpos,120.1,120.0,BlackSprite,BlackSprite,0,15,3.50,1.0,50.0,{255,255,255,255},0,0);
						TE_SendToAll();
						TE_Start("Bubbles");
						TE_WriteVector("m_vecMins", startpos);
						TE_WriteVector("m_vecMaxs", targetpos);
						TE_WriteFloat("m_fHeight", 310.0);
						TE_WriteNum("m_nModelIndex", Ventilator);
						TE_WriteNum("m_nCount", 180);
						TE_WriteFloat("m_fSpeed", 2.8);
						TE_SendToAll();
					}
					W3FlashScreen(client,{10,10,15,228}, 0.65, 0.8, FFADE_OUT);
					EmitSoundToAll(riftsnd,client);
					War3_CooldownMGR(client,2.5,thisRaceID,SKILL_PIT,true,true);
					//new Float:maxdist=PitMaxDistance[skill_level];
					new target = War3_GetTargetInViewCone(client,PitMaxDistance[skill_level],false,5.0);
					if(target>0 && !W3HasImmunity(target,Immunity_Skills))
					{
						TE_SetupBeamRingPoint(targetpos,120.1,120.0,FireSprite,HaloSprite,0,15,3.50,1.0,50.0,{255,230,230,255},0,0);
						TE_SendToAll();
						EmitSoundToAll(burnsnd,target);
						new ddmg = GetRandomInt(1,10);
						War3_DealDamage(target,ddmg,client,DMG_ENERGYBEAM,"pit_of_malice",W3DMGORIGIN_SKILL,W3DMGTYPE_TRUEDMG);
						W3FlashScreen(target,{10,10,15,255}, 1.08, 1.3, FFADE_OUT);
						//War3_CooldownMGR(client,12.0,thisRaceID,SKILL_PIT,_,_,_,"Pit of Malice");
						War3_CooldownMGR(client,12.0,thisRaceID,SKILL_PIT,true,true);
						new Float:slowmotion=PitSlow[skill_level];
						War3_SetBuff(target,fSlow,thisRaceID,slowmotion);
						CreateTimer( 6.25, StopSlow, target );
						TE_SetupDynamicLight(targetpos,255,255,100,110,88.0,1.00,5.0);
						TE_SendToAll();
						PrintToConsole(client,"damaged enemy (%i -hp)",ddmg);
						PrintHintText(client,"Pit Of Malice : Hit Target");
						PrintHintText(target,"Slowed down by Pit Of Malice");
					}
					else
					{
						War3_CooldownMGR(client,3.0,thisRaceID,SKILL_PIT,true,true);
						PrintHintText(client,"No Valid Target in %f Feed found",PitMaxDistance[skill_level]/10.0);
					}
				}
			}
			else
			{
				PrintToChat(client,"\x05Failed, you are Silenced!");
			}	
		}
	}
}

public Action:Timer_Rift(Handle:timer, any:client)
{
	new skill=War3_GetSkillLevel(client,thisRaceID,SKILL_PIT);
	if(skill>0)
	{
		new Float:iVec[3];
		GetClientAbsOrigin(client,iVec);  
		War3_SpawnPlayer(client,true);
		//War3_SpawnPlayer(client,false);
		//thanks to Ownz ( War3_SpawnPlayer(client,bool:ignore_dead_check=false) )
		TE_SetupGlowSprite( iVec, BeamSprite, 3.5 , 1.5 , 150);
		TE_SendToAll();
		TE_SetupBeamRingPoint( iVec,1.0,75.0,HaloSprite,HaloSprite,0,15,16.0,280.0,2.0,{255,0,0,255},0,0);
		TE_SendToAll();
		TE_SetupBeamFollow(client,SimpleFire,0,0.4,10.0,20.0,20,{250,250,250,255});
		TE_SendToAll();
		TE_SetupEnergySplash(iVec, iVec,false);
		TE_SendToAll();
		new morehealth=addhp[skill];
		SetEntityHealth(client,GetClientHealth(client)+morehealth);
		PrintToChat(client,"\x03Dark Rift : \x02 A Rift opens, gained +%d HP",morehealth);
		EmitSoundToAll(riftsnd, SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, 500, -1, iVec, NULL_VECTOR, true, 0.0);
	}
}

public Action:Timer_DeSelect(Handle:timer, any:client)
{
	if(ValidPlayer(client,true))
	{
		bIsTarget[client]=false;
	}
}

public Action:Timer_Extinguish(Handle:timer, any:client)
{
	if(ValidPlayer(client,true))
	{
		RemoveFlames(client);
	}
}