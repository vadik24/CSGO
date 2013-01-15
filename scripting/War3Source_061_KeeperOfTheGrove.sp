/**
* File: War3Source_KeeperOfTheGrove.sp
* Description: The Keeper Of The Grove race for War3Source.
* Author(s): Cereal Killer
*/

#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
#include <sdkhooks>
new healwardtimer=-1337;
new thisRaceID;

new bool:bIsEntangled[MAXPLAYERS];

new Handle:EntangleTypeCvar; // 0=traceline, 1=all users in a radius
new Handle:EntangleTimeCvar; // how long should they be entangled?
new Handle:EntangleDropWeaponsCvar; // drop their weapons?
new Handle:EntangleNoShootCvar;//cannot shoot?
new Handle:EntangleCooldownCvar; // cooldown







//******************************
//ward stuff 1
//******************************
#define MAXWARDS 64*1 //on map LOL
#define WARDRADIUS 200
#define WARDDAMAGE 3
#define WARDBELOW -2.0 // player is 60 units tall about (6 feet)
#define WARDABOVE 160.0
new CurrentWardCount[MAXPLAYERS];
new WardStartingArr[]={0,1,2,3,4}; 
new Float:WardLocation[MAXWARDS][3]; 
new WardOwner[MAXWARDS];
new String:wardDamageSound[]="ambient/misc/wood1.mp3";
new Float:LastThunderClap[MAXPLAYERS];
new HealWardBool[1]={0};
new Float:HealWardLocation[3]={0.0,0.0,0.0};
new thisisCLIENT;
//****************************
//end of ward stuff1
//****************************






new SKILL_FON, SKILL_THORNS, SKILL_TRANQUILITY, ULT_ENTANGLE;


new Float:ThornsReturnDamage[5]={0.0,0.05,0.10,0.15,0.20};
new Float:EntangleDistance[5]={0.0,400.0,500.0,600.0,700.0};
new Float:FoNDistance[5]={0.0,125.0,150.0,175.0,200.0};
new Ward_Damage[5]={0,1,2,2,3}; 

new String:entangleSound[]="war3source/entanglingrootsdecay1.mp3";

// Effects
new BeamSprite,HaloSprite;




public Plugin:myinfo = 
{
	name = "War3Source Race - Keeper Of The Grove",
	author = "Cereal Killer",
	description = "The Keeper Of The Grove for War3Source.",
	version = "1.0.0.0",
	url = "http://warcraft-source.net/"
};
public DropWeapon(client,weapon)
{
	//	new Float:angle[3];
	//	GetClientEyeAngles(client,angle);
	//	new Float:dir[3];
	//	GetAngleVectors(angle,dir,NULL_VECTOR,NULL_VECTOR);
	//	ScaleVector(dir,20.0);
	//	SDKCall(hWeaponDrop,client,weapon,NULL_VECTOR,dir);
}

public OnPluginStart()
{
	//HookEvent("player_hurt",PlayerHurtEvent);
	//HookEvent("player_spawn",PlayerSpawnEvent);
	EntangleTypeCvar=CreateConVar("war3_nightelf_entangle_type","0","If 0, entangle player being aimed at, if 1, get all enemies in a radius");
	EntangleTimeCvar=CreateConVar("war3_nightelf_entangle_time","5","How long a target is entangled.");
	EntangleDropWeaponsCvar=CreateConVar("war3_nightelf_entangle_drop","0","Should an entangled target drop their weapons?");
	EntangleCooldownCvar=CreateConVar("war3_nightelf_entangle_cooldown","20","Cooldown timer.");
	CreateTimer(0.14,CalcWards,_,TIMER_REPEAT);
	CreateTimer(0.5,CalcHealWards,_,TIMER_REPEAT);
	EntangleNoShootCvar=CreateConVar("war3_nightelf_entangle_noshoot","0","Disable shooting when entangled?");
}

public OnMapStart()
{
	BeamSprite= War3_PrecacheBeamSprite();
	HaloSprite=War3_PrecacheHaloSprite();
	PrecacheModel("models/props_foliage/tree_deciduous_01a-lod.mdl");
	PrecacheModel("models/props/de_inferno/tree_small.mdl");
	////War3_PrecacheSound(wardDamageSound);
	
	
	////War3_PrecacheSound(entangleSound);
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==130)
	{
		thisRaceID=War3_CreateNewRace("Keeper of the Grove","keeper");
		SKILL_THORNS=War3_AddRaceSkill(thisRaceID,"Aura of Thorns","Partial reflection of the damage an attacker",false,4);
		SKILL_FON=War3_AddRaceSkill(thisRaceID,"Force of Nature","Creates treant (+ability)",false,4);
		SKILL_TRANQUILITY=War3_AddRaceSkill(thisRaceID,"Tranquility (+ability1)","Creates a field of vital energy,treat allies.(+ability1)",false,4);
		ULT_ENTANGLE=War3_AddRaceSkill(thisRaceID,"Roots","Envelops enemies roots, to those\n could not move",true,4);
		War3_CreateRaceEnd(thisRaceID);
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(bIsEntangled[client] && War3_GetGame()==Game_TF)
	{
		if(GetConVarInt(EntangleNoShootCvar)>0){
			if((buttons & IN_ATTACK) || (buttons & IN_ATTACK2))
				return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}
public OnRaceChanged(client, oldrace, newrace)
{
	if(newrace !=thisRaceID)
	{
		RemoveWards(client);
		W3ResetAllBuffRace(client,thisRaceID);
	}
}
new ClientTracer;

public bool:AimTargetFilter(entity,mask)
{
	return !(entity==ClientTracer);
}

public bool:ImmunityCheck(client)
{
	if(bIsEntangled[client]||W3HasImmunity(client,Immunity_Ultimates))
	{
		return false;
	}
	return true;
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && IsPlayerAlive(client) && pressed)
	{
		new skill_level=War3_GetSkillLevel(client,race,ULT_ENTANGLE);
		if(skill_level>0)
		{
			
			if(War3_SkillNotInCooldown(client,thisRaceID,ULT_ENTANGLE,true)){
				
				new Float:distance=EntangleDistance[skill_level];
				new targetList[64];
				new our_team=GetClientTeam(client);
				new Float:our_pos[3];
				GetClientAbsOrigin(client,our_pos);
				if(GetConVarBool(EntangleTypeCvar))
				{
					new curIter=0;
					for(new x=1;x<=MaxClients;x++)
					{
						if(ValidPlayer(x,true)&&client!=x&&GetClientTeam(x)!=our_team&&!bIsEntangled[x]&&!W3HasImmunity(x,Immunity_Ultimates))
						{
							new Float:x_pos[3];
							GetClientAbsOrigin(x,x_pos);
							if(GetVectorDistance(our_pos,x_pos)<=distance)
							{
								targetList[curIter]=x;
								++curIter;
							}
						}
					}
				}
				else
				{
					targetList[0]=War3_GetTargetInViewCone(client,distance,false,23.0,ImmunityCheck);
				}
				new bool:gotOne=false;
				for(new x=0;x<64;x++)
				{
					if(targetList[x]==0)
						break;
					gotOne=true;
					bIsEntangled[targetList[x]]=true;
					if(GetConVarBool(EntangleDropWeaponsCvar) && War3_GetGame()!=Game_TF)
					{
						CreateTimer(0.1,NoWeapons,GetClientUserId(targetList[x]),TIMER_REPEAT);
					}
					War3_SetBuff(targetList[x],bNoMoveMode,thisRaceID,true);
					new Float:entangle_time=GetConVarFloat(EntangleTimeCvar);
					CreateTimer(entangle_time,StopEntangle,GetClientUserId(targetList[x]));
					new Float:effect_vec[3];
					GetClientAbsOrigin(targetList[x],effect_vec);
					effect_vec[2]+=15.0;
					TE_SetupBeamRingPoint(effect_vec,45.0,44.0,BeamSprite,HaloSprite,0,15,entangle_time,5.0,0.0,{0,255,0,255},10,0);
					TE_SendToAll();
					effect_vec[2]+=15.0;
					TE_SetupBeamRingPoint(effect_vec,45.0,44.0,BeamSprite,HaloSprite,0,15,entangle_time,5.0,0.0,{0,255,0,255},10,0);
					TE_SendToAll();
					effect_vec[2]+=15.0;
					TE_SetupBeamRingPoint(effect_vec,45.0,44.0,BeamSprite,HaloSprite,0,15,entangle_time,5.0,0.0,{0,255,0,255},10,0);
					TE_SendToAll();
					new String:name[64];
					GetClientName(targetList[x],name,64);
					War3_ChatMessage(targetList[x],"You entangled roots");//%s!")//,(War3_GetGame()==Game_TF)?", your weapons are POWERLESS until you are released":"");
					//EmitSoundToAll(entangleSound,targetList[x]);
					//EmitSoundToAll(entangleSound,targetList[x]);
					
					PrintHintText(client,"ROOTS entangled enemy!");
				}
				if(gotOne)
				{
					
					War3_CooldownMGR(client,GetConVarFloat(EntangleCooldownCvar),thisRaceID,ULT_ENTANGLE);
				}
				else
				{
					if(GetConVarBool(EntangleTypeCvar))
					{
						PrintHintText(client,"No results found objectives within %.1f feet",distance/10.0);
					}
					else
					{
						PrintHintText(client,"No results found objectives within %.1f feet",distance/10.0);
					}
				}
			}
		}
		else
		{
			PrintHintText(client,"First, elevate the level of ultimate");
		}
	}
}

public OnWar3PlayerAuthed(client)
{
	LastThunderClap[client]=0.0;
}

public Action:NoWeapons(Handle:timer,any:userid)
{
	new client=GetClientOfUserId(userid);
	if(client>0)
	{
		if(bIsEntangled[client])
		{
			for(new s=0;s<5;s++)
			{
				new ent=GetPlayerWeaponSlot(client,s);
				if(ent>0)
				{
					new String:wepname[64];
					GetEdictClassname(ent,wepname,64);
					if(!StrEqual(wepname,"weapon_knife",false))
					{
						DropWeapon(client,ent);
					}
				}
			}
		}
		else
		{
			return Plugin_Stop;
		}
	}
	else
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}



public Action:StopEntangle(Handle:timer,any:userid)
{
	new client=GetClientOfUserId(userid);
	if(ValidPlayer(client))
	{
		bIsEntangled[client]=false;
		War3_SetBuff(client,bNoMoveMode,thisRaceID,false);
	}
}

public OnWar3EventSpawn(client)
{
	if(bIsEntangled[client])
	{
		SetEntityMoveType(client,MOVETYPE_WALK);
		bIsEntangled[client]=false;
	}
	RemoveWards(client);
	HealWardBool[0]=0;
}


// Torns Aura
public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			//new race_attacker=War3_GetRace(attacker);
			new race_victim=War3_GetRace(victim);
			new skill_level_thorns=War3_GetSkillLevel(victim,thisRaceID,SKILL_THORNS);
			if(race_victim==thisRaceID && skill_level_thorns>0 && IsPlayerAlive(attacker))
			{                                                                                
				if(!W3HasImmunity(attacker,Immunity_Skills))
				{
					new damage_i=RoundToFloor(damage*ThornsReturnDamage[skill_level_thorns]);
					if(damage_i>0)
					{
						if(damage_i>40) damage_i=40;
						War3_DealDamage(attacker,damage_i,victim,_,"thorns",_,W3DMGTYPE_PHYSICAL);
						PrintToConsole(attacker,"Recieved -%d Thorns dmg",War3_GetWar3DamageDealt());
						PrintToConsole(victim,"You reflected -%d Thorns damage",War3_GetWar3DamageDealt());
						
					}
				}
			}
		}
	}
}


/*public OnAbilityCommand(client,ability,bool:pressed)
{
new Float:playerpos[3];
War3_CachedPosition(client,Float:playerpos);
new entindex = CreateEntityByName("prop_dynamic");// *+/ goes here

TeleportEntity(entindex, playerpos, NULL_VECTOR, NULL_VECTOR);

//SetEntityModel(entindex, "models/props_foliage/oak_tree01.mdl");
new Float:playerpos[3];
GetEntPropVector(client, Prop_Send, "m_vecOrigin", playerpos);

new entindex = CreateEntityByName("prop_dynamic");
if (entindex != -1)
{
DispatchKeyValue(entindex, "targetname", "loltest");
DispatchKeyValue(entindex, "model", "models/props_foliage/oak_tree01.mdl");
}

DispatchSpawn(entindex);
ActivateEntity(entindex);

TeleportEntity(entindex, playerpos, NULL_VECTOR, NULL_VECTOR);
}*/


public OnAbilityCommand(client,ability,bool:pressed)
{
	if (ability==0){
		if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
		{
			new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_FON);
			if(skill_level>0)
			{
				if(CurrentWardCount[client]<WardStartingArr[1])
				{
					
					new bool:conf_found=false;
					if(conf_found)
					{
						PrintHintText(client,"You can not call treant here...");
					}
					else
					{
						CreateWard(client);
						CurrentWardCount[client]++;
						PrintHintText(client,"You are encouraged treant...");
						new Float:playerpos[3];
						GetEntPropVector(client, Prop_Send, "m_vecOrigin", playerpos);
						
						new entindex = CreateEntityByName("prop_dynamic");
						if (entindex != -1)
						{
							DispatchKeyValue(entindex, "targetname", "loltest");
							if(GetClientTeam(client)==2){
								DispatchKeyValue(entindex, "model", "models/props_foliage/tree_deciduous_01a-lod.mdl");
							}
							if(GetClientTeam(client)==3){
								DispatchKeyValue(entindex, "model", "models/props/de_inferno/tree_small.mdl");
							}
						}
						
						DispatchSpawn(entindex);
						ActivateEntity(entindex);
						//playerpos[2]-=150; //enter your height choice there ^.^
						TeleportEntity(entindex, playerpos, NULL_VECTOR, NULL_VECTOR);
					}
				}
				else
				{
					PrintHintText(client,"You have already called treant...");
				}      
			}
		}
	}
	if (ability==1){
		if(War3_GetRace(client)==thisRaceID && ability==1 && pressed && IsPlayerAlive(client)){
			new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_TRANQUILITY);
			if(skill_level>0){
				if(HealWardBool[0]==0){
					new Float:position111[3];
					War3_CachedPosition(client,position111);
					War3_CachedPosition(client,HealWardLocation);
					position111[2]+=5.0;
					thisisCLIENT=client;
					new colors1[4]={65,190,226,155};
					new colors2[4]={0,0,255,155};
					new colors3[4]={100,100,100,155};
					if(GetClientTeam(client)==2){
						colors1={226,61,26,155};
						colors2={255,30,30,155};
					}
					if(GetClientTeam(client)==3){
						colors1={40,190,255,155};
						colors2={0,0,255,155};
					}
					TE_SetupBeamRingPoint(position111,0.0,75.0,BeamSprite,HaloSprite,0,15,20.0,20.0,3.0,colors2,10,0);
					TE_SendToAll();
					TE_SetupBeamRingPoint(position111,75.0,150.0,BeamSprite,HaloSprite,0,15,20.0,20.0,3.0,colors1,10,0);
					TE_SendToAll();
					TE_SetupBeamRingPoint(position111,150.0,225.0,BeamSprite,HaloSprite,0,15,20.0,20.0,3.0,colors2,10,0);
					TE_SendToAll();
					TE_SetupBeamRingPoint(position111,225.0,300.0,BeamSprite,HaloSprite,0,15,20.0,20.0,3.0,colors1,10,0);
					TE_SendToAll();        
					TE_SetupBeamRingPoint(position111,300.0,375.0,BeamSprite,HaloSprite,0,15,20.0,20.0,3.0,colors2,10,0);
					TE_SendToAll();
					TE_SetupBeamRingPoint(position111,375.0,450.0,BeamSprite,HaloSprite,0,15,20.0,20.0,3.0,colors1,10,0);
					TE_SendToAll();
					TE_SetupBeamRingPoint(position111,450.0,525.0,BeamSprite,HaloSprite,0,15,20.0,20.0,3.0,colors2,10,0);
					TE_SendToAll();
					TE_SetupBeamRingPoint(position111,525.0,600.0,BeamSprite,HaloSprite,0,15,20.0,20.0,3.0,colors3,10,0);
					TE_SendToAll();
					HealWardBool[0]++;
					healwardtimer=0;
				}
				else {
					PrintHintText(client,"You have already used this capability...");
				}
			}
			else {
				PrintHintText(client,"First, promote the skill of balance to use it");
			}
		}
	}
}



public CreateWard(client)
{
	for(new i=0;i<MAXWARDS;i++)
	{
		if(WardOwner[i]==0)
		{
			WardOwner[i]=client;
			GetClientAbsOrigin(client,WardLocation[i]);
			break;
			////CHECK BOMB HOSTAGES TO BE IMPLEMENTED
		}
	}
}
public RemoveWards(client)
{
	for(new i=0;i<MAXWARDS;i++)
	{
		if(WardOwner[i]==client)
		{
			WardOwner[i]=0;
		}
	}
	CurrentWardCount[client]=0;
}

public Action:CalcWards(Handle:timer,any:userid)
{
	new client;
	for(new i=0;i<MAXWARDS;i++)
	{
		if(WardOwner[i]!=0)
		{
			client=WardOwner[i];
			if(!ValidPlayer(client,true))
			{
				WardOwner[i]=0; //he's dead, so no more wards for him
				--CurrentWardCount[client];
			}
			else
			{
				WardEffectAndDamage(client,i); 
			}
		}
	}
}

public Action:CalcHealWards(Handle:timer,any:userid){
	new client=thisisCLIENT;
	new Float:VictimPos[3];
	if(HealWardLocation[0]==0.0&&HealWardLocation[1]==0.0&&HealWardLocation[2]==0.0){
	}
	else {
		if(healwardtimer<40&&healwardtimer!=-1337){
			healwardtimer++;
			if(HealWardBool[0]==1){
				new ownerteam=GetClientTeam(client);	
				for (new i=1;i<=MaxClients;i++){
					if(ValidPlayer(i,true)&& GetClientTeam(i)==ownerteam ){
						GetClientAbsOrigin(i,VictimPos);
						if(GetVectorDistance(HealWardLocation,VictimPos)<400){
							if(W3HasImmunity(i,Immunity_Skills)){
								PrintHintText(i,"Blocking");
							}
							else {
								if(War3_GetMaxHP(i)==GetClientHealth(i)){
								}
								else {
									SetEntityHealth(i,GetClientHealth(i)+1);
								}
							}
						}
					}
				}
			}
		}
		else {
			healwardtimer=-1337;
		}
	}
}



public WardEffectAndDamage(owner,wardindex)
{
	new ownerteam=GetClientTeam(owner);
	new Float:start_pos[3];
	new Float:end_pos[3];
	
	new Float:tempVec1[]={0.0,0.0,WARDBELOW};
	new Float:tempVec2[]={0.0,0.0,WARDABOVE};
	AddVectors(WardLocation[wardindex],tempVec1,start_pos);
	AddVectors(WardLocation[wardindex],tempVec2,end_pos);
	new Float:BeamXY[3];
	for(new x=0;x<3;x++) BeamXY[x]=start_pos[x]; //only compare xy
	new Float:BeamZ= BeamXY[2];
	BeamXY[2]=0.0;
	new wardradiusskill=War3_GetSkillLevel(owner,thisRaceID,SKILL_FON);
	
	new Float:VictimPos[3];
	new Float:tempZ;
	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true)&& GetClientTeam(i)!=ownerteam )
		{
			GetClientAbsOrigin(i,VictimPos);
			tempZ=VictimPos[2];
			VictimPos[2]=0.0; //no Z
			
			if(GetVectorDistance(BeamXY,VictimPos) < FoNDistance[wardradiusskill]) ////ward RADIUS
			{
				// now compare z
				if(tempZ>BeamZ+WARDBELOW && tempZ < BeamZ+WARDABOVE)
				{
					if(W3HasImmunity(i,Immunity_Skills))
					{
						PrintHintText(i,"Blocking");
					}
					else
					{
						War3_DealDamage(i,Ward_Damage[wardradiusskill],owner,DMG_ENERGYBEAM,"wards",_,W3DMGTYPE_MAGIC);
						
						if(LastThunderClap[i]<GetGameTime()-2){
							new Float:postionplayer[3];
							postionplayer[0]=start_pos[0];
							postionplayer[1]=start_pos[1];
							postionplayer[2]=start_pos[2]+20.0;
							//EmitSoundToAll(wardDamageSound,i,SNDCHAN_WEAPON);
							LastThunderClap[i]=GetGameTime();
							TE_SetupBeamRingPoint(postionplayer,FoNDistance[wardradiusskill]-50.0,FoNDistance[wardradiusskill],BeamSprite,HaloSprite,0,15,2.0,5.0,0.0,{255,100,0,255},10,0);
							TE_SendToAll(); 
						}
						
					}
				}
			}
		}
	}
}


