/**
* File: War3Source_Tremble.sp
* Description: Tremble from HoN for War3Source
* Author(s): Revan
*/
//war3source handles the includes 8)
#include "W3SIncs/War3Source_Interface"
//#include "revantools.inc"
#include <sdkhooks.inc>
#define SWARMLOOP 0.2
#define SWARMRANGE 250
#define TREMBLEMAX 12
#define TREMBLEREGEN 1
#define DARKSWARMDUR 8.0
#define MAX_BEAM_SCROLLSPEED 100
#define MAXEDICT 2048
new thisRaceID;
new Handle:ultCooldownCvar;
new Handle:abiCooldownCvar;
new Handle:TrembleDist;
new Handle:ImpalerChanceCvar;
new Handle:CvarPushForce;
new Handle:ReUseOnDeathCvar;

new SKILL_1,SKILL_2,SKILL_3,ULT;
new LargeBeam,BeamSprite,Bug1,Bug2,Bug3,Bug4;

new MasterLevel[MAXPLAYERS];
new nTrembleCount[MAXPLAYERS];
new nTrembleOwner[MAXPLAYERS];

new Float:nLastBuff[MAXPLAYERS];
new Float:nLastLongBuff[MAXPLAYERS];
new Float:SavedPos[TREMBLEMAX][3];

new bool:bSwarmed[MAXPLAYERS];
new bool:bSwarmEffect[MAXPLAYERS];
new bool:bImpaled[MAXPLAYERS];
new bool:bShudderSpawnd[MAXPLAYERS];

new String:BuffSound[] = "ambient/machines/teleport4.mp3";
new String:Spawn[]="ambient/levels/citadel/weapon_disintegrate2.mp3";
new String:Impalers[]="weapons/mortar/mortar_explode2.mp3";
//npcsoundset - defined
new String:NPCHurt1[] = "npc/antlion_guard/angry1.mp3";
new String:NPCHurt2[] = "npc/antlion_guard/angry2.mp3";
new String:NPCHurt3[] = "npc/antlion_guard/angry3.mp3";
new String:NPCHit1[] = "npc/antlion_guard/foot_heavy2.mp3";
new String:NPCHit2[] = "npc/antlion_guard/foot_light2.mp3";
new String:NPCDeath[] = "npc/antlion_guard/antlion_guard_die1.mp3";

public Plugin:myinfo = 
{
	name = "War3Source Race - Tremble",
	author = "Revan",
	description = "Tremble from HoN for War3Source",
	version = "1.1.0",
	url = "www.wcs-lagerhaus.de"
};

public OnMapStart()
{
	////War3_PrecacheSound(BuffSound);
	////War3_PrecacheSound(Spawn);
	////War3_PrecacheSound(Impalers);
	//npcsoundset - precache
	////War3_PrecacheSound(NPCHurt1);
	////War3_PrecacheSound(NPCHurt2);
	////War3_PrecacheSound(NPCHurt3);
	////War3_PrecacheSound(NPCHit1);
	////War3_PrecacheSound(NPCHit2);
	////War3_PrecacheSound(NPCDeath);
	LargeBeam=PrecacheModel("effects/blueblacklargebeam.vmt");
	BeamSprite=War3_PrecacheBeamSprite();
	Bug1=PrecacheModel("materials/effects/blueflare1.vmt");
	Bug2=PrecacheModel("materials/effects/yellowflare.vmt");
	Bug3=PrecacheModel("materials/effects/blueblackflash.vmt");
	Bug4=PrecacheModel("materials/effects/redflare.vmt");
	//PrecacheModel("models/antlion_guard.mdl");
}

public OnPluginStart()
{
	CreateTimer(0.42,CalcTremble,_,TIMER_REPEAT);
	HookEvent("round_start",RoundStartEvent);
	ultCooldownCvar=CreateConVar("war3_tremble_ultimate_cooldown","20","Cooldown time for hive mind(on spawn/death).");
	abiCooldownCvar=CreateConVar("war3_tremble_ability_cooldown","10","Cooldown time for tremble's ability's(on spawn).");
	TrembleDist=CreateConVar("war3_tremble_ability_radius","200","Radius for tremble's ability's.");
	ImpalerChanceCvar=CreateConVar("war3_tremble_impaler_chance","0.38","Chance of tremble's Implaer skill (0.00 - 1.00)");
	CvarPushForce=CreateConVar("war3_tremble_ultimate_force","0.1","Push Force of Shudders attack");
	ReUseOnDeathCvar=CreateConVar("war3_tremble_ultimate_reuse", "1","Should the Player be able to reuse the ultimate if shudder dies?");
	HookConVarChange(abiCooldownCvar, UltimateCvarChange);
	HookConVarChange(ultCooldownCvar, AbilitysCvarChange);
}

public UltimateCvarChange(Handle:Enabled, const String:OldValue[], const String:Value[])
if (StringToInt(Value) > 0)
W3SkillCooldownOnSpawn( thisRaceID, ULT, GetConVarFloat(ultCooldownCvar));
public AbilitysCvarChange(Handle:h_ScjEnabled, const String:s_ScjOldValue[], const String:Value[])
if (StringToInt(Value) > 0)
W3SkillCooldownOnSpawn( thisRaceID, SKILL_2, GetConVarFloat(abiCooldownCvar));

public OnWar3PluginReady()
{
	thisRaceID = War3_CreateNewRace( "VIP Tremble", "tremble" );
	
	SKILL_1 = War3_AddRaceSkill( thisRaceID, "Dark Swarm","Summons a massive swarm of bugs to act as his personal shield\ndeflecting ranged attackers and suffocating nearby enemies.", false, 4 );
	SKILL_2 = War3_AddRaceSkill( thisRaceID, "Terrorform / Terrorport", "Terrorform(+ability):\nBuilds up a Terror Mound, granting invisibility, movement speed, and health regeneration.\nTerror Port(+ability1):\nGrants the Ability to teleport between each Terror Mound", false, 4 );	
	SKILL_3 = War3_AddRaceSkill( thisRaceID, "Impalers", "Passively adds damage to your attacks and slows the target enemy.", false, 4 );
	ULT = War3_AddRaceSkill( thisRaceID, "Hive Mind", "Permanently summon Shudder to aid you in battle.", true, 4 ); // The Anti Team Ressurection Skill :p
	W3SkillCooldownOnSpawn( thisRaceID, ULT, GetConVarFloat(ultCooldownCvar) );
	W3SkillCooldownOnSpawn( thisRaceID, SKILL_2, GetConVarFloat(abiCooldownCvar));
	War3_CreateRaceEnd( thisRaceID );
}

public OnWar3EventSpawn(client)
{
	nTrembleCount[client]=-1;
	bSwarmed[client]=false;
	bSwarmEffect[client]=false;
	W3ResetPlayerColor(client,thisRaceID); //just to be sure...
}
//darkswarm
new Float:SwarmChance[5] = { 0.0, 0.10, 0.12, 0.15, 0.18 };
new Float:SwarmPercent[5] = { 1.0, 0.9, 0.88, 0.70, 0.65};
new SwarmDamage[5] = { 0, 2, 3, 3, 4 };
//impalers
new Float:ImpAtkSlow[5] = { 1.0, 0.9, 0.88, 0.82, 0.78};
new Float:ImpAgiSlow[5] = { 1.0, 0.9, 0.8, 0.75, 0.70};
new ImpDamage[5] = { 0, 2, 4, 6, 7};
new Float:ImpTime[5] = { 0.0, 0.65, 0.70, 0.88, 0.9};
public OnW3TakeDmgBulletPre( victim, attacker, Float:damage )
{
	if( IS_PLAYER( victim ) && IS_PLAYER( attacker ) && victim > 0 && attacker > 0 && attacker != victim )
	{
		if( GetClientTeam( victim ) != GetClientTeam( attacker ))
		{
			new race_victim = War3_GetRace( victim );
			new skill = War3_GetSkillLevel( victim, thisRaceID, SKILL_1 );
			if( race_victim == thisRaceID && skill > 0 && !Hexed( victim, false ) ) 
			{
				new Float:percent = SwarmChance[skill];
				if( GetRandomFloat( 0.0, 1.0 ) <= percent && !bSwarmed[victim])
				{
					War3_DamageModPercent(SwarmPercent[skill]);
					bSwarmEffect[victim]=true;
					bSwarmed[victim]=true;
					PrintHintText(victim,"Dark Swarm summoned for %f seconds",DARKSWARMDUR);
					CreateTimer(SWARMLOOP, Timer_LoopSwarm, victim);
					CreateTimer(DARKSWARMDUR, Timer_DeCastSwarm, victim);
				}
				else if (bSwarmed[victim]) {
					War3_DamageModPercent(SwarmPercent[skill]);
				}
			}
			/*new race_attacker = War3_GetRace( attacker );
			new skill2 = War3_GetSkillLevel( attacker, thisRaceID, SKILL_3 );
			if( race_attacker == thisRaceID && skill2 > 0 && !Hexed( attacker, false ) ) 
			{
				if( !bImpaled[victim] && !W3HasImmunity(victim,Immunity_Skills) )
				{
					new Float:percent = GetConVarFloat(ImpalerChanceCvar);
					if( GetRandomFloat( 0.0, 1.0 ) <= percent) {
						W3FlashScreen( victim, {128,60,128,120}, 0.6, 0.1);
						W3SetPlayerColor( victim, thisRaceID, 128, 60, 128, _, GLOW_DEFAULT);
						War3_SetBuff( victim, fAttackSpeed, thisRaceID, ImpAtkSlow[skill2] );
						War3_SetBuff( victim, fSlow, thisRaceID, ImpAgiSlow[skill2] );
						War3_DealDamage( victim, ImpDamage[skill2], attacker, DMG_BULLET, "impalers");
						new String:namebuffer[64];
						GetClientName(victim,namebuffer,sizeof(namebuffer));
						PrintCenterText(attacker,"Impaled %s!",namebuffer);
						GetClientName(attacker,namebuffer,sizeof(namebuffer));
						PrintCenterText(victim,"Got Impaled by %s!!",namebuffer);
						CreateTimer(ImpTime[skill2], Timer_DeCastImpale, victim);
						ImpalerFX(attacker,victim);
					}
				}
			}*/
		}
	}
}
public OnW3TakeDmgBullet( victim, attacker, Float:damage )
{
	if( IS_PLAYER( victim ) && IS_PLAYER( attacker ) && victim > 0 && attacker > 0 && attacker != victim )
	{
		if( GetClientTeam( victim ) != GetClientTeam( attacker ))
		{
			new race_attacker = War3_GetRace( attacker );
			new skill2 = War3_GetSkillLevel( attacker, thisRaceID, SKILL_3 );
			if( race_attacker == thisRaceID && skill2 > 0 && !Hexed( attacker, false ) ) 
			{
				if( !bImpaled[victim] && !W3HasImmunity(victim,Immunity_Skills) )
				{
					new Float:percent = GetConVarFloat(ImpalerChanceCvar);
					if( GetRandomFloat( 0.0, 1.0 ) <= percent) {
						W3FlashScreen( victim, {128,60,128,120}, 0.6, 0.1);
						W3SetPlayerColor( victim, thisRaceID, 128, 60, 128, _, GLOW_DEFAULT);
						War3_SetBuff( victim, fAttackSpeed, thisRaceID, ImpAtkSlow[skill2] );
						War3_SetBuff( victim, fSlow, thisRaceID, ImpAgiSlow[skill2] );
						War3_DealDamage( victim, ImpDamage[skill2], attacker, DMG_BULLET, "impalers");
						new String:namebuffer[64];
						GetClientName(victim,namebuffer,sizeof(namebuffer));
						PrintCenterText(attacker,"Impaled %s!",namebuffer);
						GetClientName(attacker,namebuffer,sizeof(namebuffer));
						PrintCenterText(victim,"Got Impaled by %s!!",namebuffer);
						CreateTimer(ImpTime[skill2], Timer_DeCastImpale, victim);
						ImpalerFX(attacker,victim);
					}
				}
			}
		}
	}
}


ImpalerFX(attacker,victim) {
	new Float:apos[3];
	GetClientAbsOrigin(attacker,apos);
	new Float:vpos[3];
	GetClientAbsOrigin(victim,vpos);
	new Float:vpos2[3];
	GetClientAbsOrigin(victim,vpos2);
	apos[2]+=80;
	vpos[2]+=35;
	vpos2[2]+=35;
	TE_SetupBeamRingPoint(apos,20.0,15.0,BeamSprite,BeamSprite,0,28,5.0,52.0,1.0,{128,60,128,255},6,0);
	TE_SendToAll();
	TE_SetupBeamPoints(apos,vpos,LargeBeam,LargeBeam,0,MAX_BEAM_SCROLLSPEED,3.0,35.0,10.0,0,2.0,{255,255,255,220},20);
	TE_SendToAll();
	new Float:fx_delay = 0.1;
	new Float:fx_showtime = 0.1;	
	new axis = GetRandomInt(0,1);
	vpos[axis] += 150;
	vpos2[axis] += 150;
	for(new i=0;i<30;i++)
	{
		TE_SetupBeamRingPoint(vpos,200.0,100.0,BeamSprite,BeamSprite,0,28,fx_showtime,25.0,1.0,{128,60,128,255},6,0);
		TE_SendToAll(fx_delay);
		TE_SetupBeamRingPoint(vpos2,200.0,100.0,BeamSprite,BeamSprite,0,28,fx_showtime,25.0,1.0,{128,60,128,255},6,0);
		TE_SendToAll(fx_delay);
		vpos[axis]-=5.0;
		vpos2[axis]-=5.0;
		fx_delay += 0.1;
	}
	TE_SetupExplosion(vpos, BeamSprite, 2.0, 1, 4, 0, 0);
	TE_SendToAll(5.1); 
	//EmitSoundToAll(Impalers,victim);
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && pressed && IsPlayerAlive(client))
	{
		new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_2);
		if(skill_level>0&&War3_SkillNotInCooldown(client,thisRaceID,SKILL_2,true))
		{
			if(ability==0) {
				if(nTrembleCount[client]<=1) {
					/*new sfx_ent = CreateEntityByName("prop_dynamic_override");
					if (sfx_ent > 0 && IsValidEdict(sfx_ent))
					{
						CreateTesla(client,5.0,5.2,18.0,20.0,2.8,4.0,GetConVarFloat(TrembleDist),"20","30","255 200 200","ambient/levels/citadel/weapon_disintegrate2.mp3",War3_PrecacheBeamSprite(),false);
					}*/
					nTrembleCount[client]++;
					PrintHintText(client,"Building up a Terror Mound(#%i)",nTrembleCount[client]);
					W3FlashScreen(client,RGBA_COLOR_RED, 0.3,0.4);
					CreateMount(client);
					//new Float:direction[3] = {0.0,0.0,-90.0};
					War3_CooldownMGR(client,3.0,thisRaceID,SKILL_2,_,_);
				}
				else {
					PrintHintText(client,"Terror Mound Maximum Reached!");
				}
			}
			else {
				if(nTrembleCount[client]>0 ) {
					MountPlayer(client);
				}
				else {
					PrintHintText(client,"You need to create at least 2 Terror Mounds to tunnel");
				}
			}
		}
	}
}
/*
thx to ownz&pimpin (terrorthing works like a ward)
||    ||
||====||
||    ||
\/	  \/
*/
public CreateMount(client)
{
	for(new i=0;i<TREMBLEMAX;i++)
	{
		if(nTrembleOwner[i]==0)
		{
			nTrembleOwner[i]=client;
			GetClientAbsOrigin( client, SavedPos[i] );
			break;
		}
	}
}

public MountPlayer(client)
{
	for(new i=0;i<TREMBLEMAX;i++)
	{
		if(nTrembleOwner[i]==client)
		{
			new tremble = i;
			new Float:actualpos[3];
			GetClientAbsOrigin( client, actualpos );
			if(GetVectorDistance(SavedPos[tremble],actualpos) <= GetConVarFloat(TrembleDist)) {
				for(i=0;i<TREMBLEMAX;i++) //find the 2nd tunnel
				{
					if(nTrembleOwner[i]==client && tremble!=i)
					{
						PrintHintText(client,"Tunneled");
						//EmitSoundToAll(BuffSound,client,SNDCHAN_AUTO);
						TE_SetupBeamPoints(SavedPos[i],SavedPos[tremble],BeamSprite,BeamSprite,0,15,1.6,5.0,10.0,1,1.0,{255,255,255,220},20); //trace the route
						TE_SendToAll();
						TE_SetupBeamFollow(client, BeamSprite, BeamSprite, 0.5, 10.0, 12.0, 2, {255,255,255,200}); //trace tremble
						TE_SendToAll();
						TE_SetupBeamRingPoint(SavedPos[i],20.0,GetConVarFloat(TrembleDist)+10.0,BeamSprite,BeamSprite,2,6,0.2,50.0,7.0,{255,50,50,255},40,0); //destination - outgoing ring
						TE_SendToAll();
						TE_SetupBeamRingPoint(SavedPos[tremble],GetConVarFloat(TrembleDist)+10.0,20.0,BeamSprite,BeamSprite,2,6,0.2,50.0,7.0,{255,50,50,255},40,0); //start - incoming ring
						TE_SendToAll();
						TeleportEntity(client, SavedPos[i], NULL_VECTOR, NULL_VECTOR);
						War3_CooldownMGR(client,10.0,thisRaceID,SKILL_2,_,_);
					}
				}
			}
		}
	}
}

public RemoveMount(client,bool:showexplosion)
{
	for(new i=0;i<TREMBLEMAX;i++)
	{
		if(nTrembleOwner[i]==client)
		{
			nTrembleOwner[i]=0;
			if(showexplosion)
			{
				TE_SetupExplosion( SavedPos[i], BeamSprite, 4.0, 1, 4, 0, 0);
				TE_SendToAll();
			}
		}
	}
	nTrembleCount[client]--;
}

public Action:CalcTremble(Handle:timer, any:uid)
{
	new client;
	for(new i=0;i<TREMBLEMAX;i++)
	{
		if(nTrembleOwner[i]!=0)
		{
			client=nTrembleOwner[i];
			if(!ValidPlayer(client,true))
			{
				RemoveMount(client,true);
			}
			else
			{
				MountAoE(client,i); //checks for targets
			}
		}
	}
}

new Float:BuffSpeed[5]={1.0,1.10,1.12,1.18,1.23};
new Float:BuffInvis[5]={1.0,0.9,0.8,0.72,0.66};
public MountAoE(owner,tremble)
{
	new team=GetClientTeam(owner);
	new Float:start_pos[3];
	new Float:end_pos[3];
	
	new Float:tempVec1[]={0.0,0.0,-2.0};
	new Float:tempVec2[]={0.0,0.0,150.0};
	AddVectors(SavedPos[tremble],tempVec1,start_pos);
	AddVectors(SavedPos[tremble],tempVec2,end_pos);
	
	new Float:BeamXY[3];
	for(new x=0;x<3;x++) BeamXY[x]=start_pos[x]; //only compare xy
	new Float:BeamZ= BeamXY[2];
	BeamXY[2]=0.0;
	
	new dice = GetRandomInt(0,3);
	new Sprite=Bug1;
	if(dice==1)
	Sprite=Bug2;
	else if(dice==2)
	Sprite=Bug3;
	else if(dice==3)
	Sprite=Bug4;
	for(new reptimes=0;reptimes<=3;reptimes++) {
		TE_SetupBubbles(start_pos,end_pos,220.0,Sprite,2,GetRandomFloat(28.0,30.0));
		TE_SendToAll();
	}
	new Float:dist_tr=GetConVarFloat(TrembleDist)-30.0;
	if(dist_tr<1)
	dist_tr=170.0;
	TE_SetupDynamicLight(start_pos, 140,74,0,2,dist_tr,1.5,2.0);
	TE_SendToAll();
	new Float:VictimPos[3];
	new Float:tempZ;
	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true)&& GetClientTeam(i)==team )
		{
			//
			//if(i==owner) {
			GetClientAbsOrigin(i,VictimPos);
			tempZ=VictimPos[2];
			VictimPos[2]=0.0; //no Z
			if(GetVectorDistance(BeamXY,VictimPos) < dist_tr)
			{
				if(tempZ>BeamZ-2 && tempZ < BeamZ+150)
				{
					/*new flashscreened[]={0,0,200,255};
					if(team==2)
					{ 
						flashscreened[0]=255;
						flashscreened[2]=0;
						flashscreened[3]=100;
					}
					W3FlashScreen(i,flashscreened);*/
					if(nLastLongBuff[i]<GetGameTime()-4){
						W3FlashScreen(i,{100,64,10,120});
						new skill = War3_GetSkillLevel(i,thisRaceID,SKILL_2);
						new Float:speedbuffer=BuffSpeed[skill];
						new Float:invisbuffer=BuffInvis[skill];
						War3_SetBuff(i,fMaxSpeed,thisRaceID,speedbuffer);
						War3_SetBuff(i,fInvisibilitySkill,thisRaceID,invisbuffer);
						CreateTimer(3.90, Timer_RemoveTrembleBuff, i); //0.1 sec unbuffed should be ok^^
						//EmitSoundToAll(BuffSound,i,SNDCHAN_WEAPON);
						nLastLongBuff[i]=GetGameTime();
					}
					if(nLastBuff[i]<GetGameTime()-0.4){
						War3_HealToMaxHP(i,TREMBLEREGEN); 
						nLastBuff[i]=GetGameTime();
					}
				}
			}
			//}
		}
	}
}

public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	for(new x=1;x<=64;x++)
	if(ValidPlayer(x,false)) {
		RemoveMount(x,false);
		nTrembleCount[x]=0;
		bShudderSpawnd[x]=false;
	}
}

stock TE_SetupDynamicLight(const Float:vecOrigin[3], r,g,b,iExponent,Float:fRadius,Float:fTime,Float:fDecay)
{
	//If someone need's a list, check this -> http://88.198.9.70/coding/33
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

stock TE_SetupBubbles(Float:startposi[3],Float:finalposi[3],Float:fHeight,nModelIndex,nCount,Float:fSpeed)
{
	TE_Start("Bubbles");
	TE_WriteVector("m_vecMins", startposi);
	TE_WriteVector("m_vecMaxs", finalposi);
	TE_WriteFloat("m_fHeight", fHeight);
	TE_WriteNum("m_nModelIndex", nModelIndex);
	TE_WriteNum("m_nCount", nCount);
	TE_WriteFloat("m_fSpeed", fSpeed);
}

public Action:DoSwarm(client)
{
	new level=War3_GetSkillLevel(client,thisRaceID,SKILL_1);
	if(level>0)
	{
		PrintCenterText(client,"DarkSwarm active...");
		for(new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,true))
			{
				new Float:origin[3];
				GetClientAbsOrigin(client,origin);
				new Float:VictimPos[3];
				GetClientAbsOrigin(i,VictimPos);
				if(GetVectorDistance(VictimPos,origin) < SWARMRANGE && GetClientTeam(i) != GetClientTeam(client))
				{
					if(W3HasImmunity( i, Immunity_Ultimates ) && !bSwarmed[i] )
					{
						PrintCenterText(i,"You blocked an ability!");
					}
					else
					{
						new damage = SwarmDamage[level];
						if(War3_DealDamage(i,damage,client,DMG_BULLET,"darkswarm",W3DMGORIGIN_SKILL,W3DMGTYPE_PHYSICAL,true))
						{
							PrintHintText(client,"Dark Swarm caused %d dmg",damage);
							new dice = GetRandomInt(0,3);
							new Sprite=Bug1;
							if(dice==1)
							Sprite=Bug2;
							else if(dice==2)
							Sprite=Bug3;
							else if(dice==3)
							Sprite=Bug4;
							origin[2]+=GetRandomInt(20,60);
							VictimPos[2]+=GetRandomInt(20,60);
							TE_SetupBeamPoints(origin,VictimPos,Sprite,Sprite,0,MAX_BEAM_SCROLLSPEED,GetRandomFloat(2.5,6.2),5.0,10.0,1,1.0,{255,255,255,220},20);
							TE_SendToAll();
							W3FlashScreen(i,RGBA_COLOR_RED);
							
							//if(GetRandomInt(0,1)==1)
							//EmitSoundToAll(NPCHit1, i, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, 100, -1, VictimPos, NULL_VECTOR, true, 0.0);
							//else
							//EmitSoundToAll(NPCHit2, i, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, 100, -1, VictimPos, NULL_VECTOR, true, 0.0);
						}
					}
				}
			}
		}
	}
}

// = Shudder Settings =

//-> ANIMATION SET :
#define shudder_idle "idle"
#define shudder_attack "charge_hit"
#define shudder_hurt "pain"
#define shudder_move "charge_loop"

//-> INFORMATION SETTINGS:
#define shudder_classname "shudder" //used for dmg classname too

//-> PER LEVEL SETTINGS:
new ShudderHealth[5]={0,300,600,900,1500};
new Float:ShudderRange[5]={0.0,250.0,500.0,600.0,1500.0};
new Float:ShudderAtkRadius[5]={0.0,50.0,60.0,80.0,150.0};

//-> DAMAGE SETTINGS
new SHUDMIN = 40;//60;
new SHUDMAX = 60;//80;

//new ShudderMove[MAXEDICT+1];
//new ShudderFocus[MAXEDICT+1];
new bool:IsNPC[MAXEDICT+1];
public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
		new ult_level=War3_GetSkillLevel(client,race,ULT);
		if(ult_level>0)
		{
			if(!Silenced(client) && War3_SkillNotInCooldown(client,thisRaceID,ULT,true))
			{
				if(!bShudderSpawnd[client])
				{
					if(!(GetEntityFlags(client) & FL_ONGROUND )){
						PrintHintText(client,"Failed to Summon Shudder:\nYou need to be on the stable floor!");
					}
					else {
						bShudderSpawnd[client]=true;
						PrintHintText(client,"Summoning Shudder...");
						new Float:actualpos[3];
						GetClientAbsOrigin(client,actualpos);
						//CreateNPC(actualpos, 60.0, 500.0, client, ShudderHealth[ult_level], GetClientTeam(client), 10, 20, "models/antlion_guard.mdl", "npc_shudder",true,true,true,NPC_ANTLIONGUARD);
						new npc_ent = CreateEntityByName("prop_dynamic_override");
						if (npc_ent > 0 && IsValidEdict(npc_ent))
						{
							new npcteam = GetClientTeam(client);
							decl String:entname[16];
							Format(entname, sizeof(entname), "shudder%i_team%i",client,npcteam);
							//SetEntityModel(npc_ent, "models/antlion_guard.mdl");
							DispatchKeyValue(npc_ent, "StartDisabled", "false");
							if (DispatchSpawn(npc_ent))
							{
								if(npcteam==3) {
								SetEntityRenderColor(npc_ent, 120, 120, 255);
								} else {
									SetEntityRenderColor(npc_ent, 200, 120, 120);
								}						
								SetEntProp(npc_ent, Prop_Data, "m_takedamage", 2);
								SetEntProp(npc_ent, Prop_Send, "m_usSolidFlags", 152);
								TeleportEntity(npc_ent, actualpos, NULL_VECTOR, NULL_VECTOR);
								DispatchKeyValue(npc_ent, "targetname", entname);
								DispatchKeyValue(npc_ent, "classname", shudder_classname);

								SetEntProp(npc_ent, Prop_Data, "m_MoveCollide", 1);
								SetEntProp(npc_ent, Prop_Send, "m_iTeamNum", npcteam, 4);
								SetEntProp(npc_ent, Prop_Send, "m_CollisionGroup", 5);
								
								SetEntPropEnt(npc_ent, Prop_Data, "m_hLastAttacker", client);
								SetEntPropEnt(npc_ent, Prop_Data, "m_hPhysicsAttacker", client);
								SetEntPropEnt(npc_ent, Prop_Send, "m_hOwnerEntity", client);
								DispatchKeyValue(npc_ent, "ExplodeRadius", "100");
								DispatchKeyValue(npc_ent, "ExplodeDamage", "60");
								SetVariantString(shudder_idle);
								AcceptEntityInput(npc_ent, "SetAnimation", -1, -1, 0);
								SetEntProp(npc_ent, Prop_Data, "m_iHealth", ShudderHealth[ult_level]);
								HookSingleEntityOutput(npc_ent, "OnTakeDamage", OnShudderDamage, false);
								SDKHook(npc_ent, SDKHook_StartTouch, OnShudderTouch);
								HookSingleEntityOutput(npc_ent, "OnBreak", OnShudderKilled, true);
								IsNPC[npc_ent]=true;
								CreateTimer(0.5, Shudder_Think, npc_ent);
							}
						}
						MasterLevel[client]=ult_level;
						//EmitSoundToAll(Spawn,client,SNDCHAN_AUTO);
					}
				}
				else
				{
					PrintHintText(client,"Failed to Summon Shudder:\nYou allready summoned shudder this round!");
				}
			}
		}
		else
		{
			W3MsgUltNotLeveled(client);
		}
	}
}

//Shudder ----

/// Set View Angles
public SetEntityAimToClient( edict, target)
{
	new Float:spos[3],  Float:epos[3], Float:vecles[3], Float:angles[3];
	GetEntPropVector(edict, Prop_Send, "m_vecOrigin", spos);
	GetClientAbsOrigin( target, epos );
	SubtractVectors( epos, spos, vecles );
	GetVectorAngles( vecles, angles );
	angles[2] = 0.0;
	TeleportEntity( edict, NULL_VECTOR, angles, NULL_VECTOR );
}

/// Animation
new bool:InAnimation[MAXEDICT+1];
public Action:Shudder_Animate(entity,const String:animation[],Float:duration)
{
	if(IsNPC[entity])
	{
		if(!InAnimation[entity]) {
			InAnimation[entity]=true;
			SetVariantString(animation);
			AcceptEntityInput(entity, "SetAnimation", -1, -1, 0);
			CreateTimer(duration, Shudder_Idle, entity);
		}
	}
}

public Action:Shudder_Idle( Handle:timer, any:caller )//same as Timer_IdleAnim except the bool check
{
	if(IsValidEntity(caller) && IsNPC[caller]) {
		InAnimation[caller]=false;
		SetVariantString(shudder_idle);
		AcceptEntityInput(caller, "SetAnimation", -1, -1, 0);
	} 
}

/// Removing
public Action:Shudder_Disable(entity)
{
	SDKUnhook(entity, SDKHook_StartTouch, OnShudderTouch);
	UnhookSingleEntityOutput(entity, "OnTakeDamage", OnShudderDamage);
	//UnhookSingleEntityOutput(entity, "OnBreak", OnShudderKilled); <- the hook removes itself ->
	IsNPC[entity]=false;
}

public Action:Shudder_Slay(entity,bool:noticeowner)
{
	if(IsNPC[entity])
	{
		Shudder_Disable(entity);
		if(noticeowner)
		AcceptEntityInput(entity, "Break");
		else
		AcceptEntityInput(entity, "Kill");
	}
}

new Float:LastHit[MAXPLAYERS];
/// Damage
public Action:Shudder_Attack(entity,owner,target,mindamage,maxdamage,bool:flashscreen,bool:animation,bool:push)
{
	if(IsNPC[entity])
	{
		if(LastHit[target]<GetGameTime()-0.50)
		{
			decl Float:AttackerPos[3];
			GetEntPropVector(target, Prop_Send, "m_vecOrigin", AttackerPos);
			decl String:classname[32]; 
			GetEdictClassname(entity, classname, sizeof(classname));		
			if(push)
			PushClientToVector( target, AttackerPos, -GetConVarFloat(CvarPushForce));		
			War3_DealDamage( target, GetRandomInt(mindamage,maxdamage), owner, DMG_BULLET, classname, _, W3DMGTYPE_PHYSICAL );
			if(flashscreen)
			W3FlashScreen(target,RGBA_COLOR_RED,0.8,_,FFADE_IN);
			if(animation)
			Shudder_Animate(entity,shudder_attack,1.2);		
			//if(GetRandomInt(0,1)==1)
			//EmitSoundToAll(NPCHit1,target);
			//EmitSoundToAll(NPCHit1, target, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, 100, -1, AttackerPos, NULL_VECTOR, true, 0.0);
			//else
			//EmitSoundToAll(NPCHit1,target);

			SetEntityAimToClient( entity, target);
			
			LastHit[target]=GetGameTime();
		}
	}
}

/// Move -.- i hate math
public Action:Shudder_Move(entity,Float:StartPos[3],Float:EndPos[3],Float:MoveSpeed)
{
	if(IsNPC[entity])
	{
		/*
		What I'm doing here?...
		new Float:Float:TargetPos[3];
		new Float:bp0, Float:bp1, Float:bp2;

		bp0 = SquareRoot( StartPos[0] -= StartPos[0] *= 2);
		bp1 = SquareRoot( StartPos[1] -= StartPos[1] *= 2);
		bp2 = SquareRoot( StartPos[2] -= StartPos[2] *= 2);
		
		TargetPos[0] = bp0;
		TargetPos[1] = bp1;
		TargetPos[2] = bp2;
		ScaleVector(TargetPos, 1.5);*/
		//mh this works and it is pretty simple xD
		StartPos[2]+=45;
		EndPos[2]+=45;
		TR_TraceRayFilter(StartPos, EndPos, MASK_SOLID, RayType_EndPoint, NpcTraceHitFilter, 0);
		if (!TR_DidHit(INVALID_HANDLE)) {
			StartPos[2]-=45;
			EndPos[2]-=45;
			//1 - move x
			if(StartPos[0] < EndPos[0]) {
				StartPos[0] += MoveSpeed;
				TeleportEntity(entity, StartPos, NULL_VECTOR, NULL_VECTOR);
			}
			else if(StartPos[0] > EndPos[0]) {
				StartPos[0] -= MoveSpeed;
				TeleportEntity(entity, StartPos, NULL_VECTOR, NULL_VECTOR);
			}
			//2 - move y
			//if npc pos smaller than target pos add
			if(StartPos[1] < EndPos[1]) {
				StartPos[1] += MoveSpeed;
				TeleportEntity(entity, StartPos, NULL_VECTOR, NULL_VECTOR);
			}
			//if npc pos bigger than target pos subtract
			else if(StartPos[1] > EndPos[1]) {
				StartPos[1] -= MoveSpeed;
				TeleportEntity(entity, StartPos, NULL_VECTOR, NULL_VECTOR);
			}
			/*3 - move x (only down I hope^^)
			if(StartPos[2] < EndPos[2]) {
				StartPos[2] += -MoveSpeed;
				TeleportEntity(entity, StartPos, NULL_VECTOR, NULL_VECTOR);
			}*/
			Shudder_Animate(entity,shudder_move,0.35);
		}
	}
}

/// Core
public Action:Shudder_Think( Handle:timer, any:caller ) {
	if(IsValidEntity(caller) && IsNPC[caller]) {
			new owner = GetEntPropEnt(caller, Prop_Send, "m_hOwnerEntity");
			if(ValidPlayer(owner,false)) {
			CreateTimer(0.1, Shudder_Think, caller);
			new SkillLevel = 4;
			new ClosestTarget;
			new Float:Distance;
			new Float:ClosestDistance = ShudderRange[SkillLevel]; //maxrange
			decl Float:StartPos[3];
			//decl Float:EndPos[3];
			GetEntPropVector(caller, Prop_Send, "m_vecOrigin", StartPos);
			for (new i = 1; i <= MaxClients; i++) {
				if(ValidPlayer(i,true) && GetClientTeam(i) != GetClientTeam(owner)) {
					decl Float:TargetPos[3];
					GetClientAbsOrigin(i, TargetPos);
					Distance = GetVectorDistance(StartPos, TargetPos);
					if (Distance < ClosestDistance) {
						/*GetClientAbsOrigin(ClosestTarget, EndPos );
						StartPos[2]+=20;
						EndPos[2]+=20;*/
						//TR_TraceRayFilter(StartPos, EndPos, MASK_SOLID, RayType_EndPoint, NpcTraceHitFilter, 0);
						//if (!TR_DidHit(INVALID_HANDLE)) {
							//StartPos[2]-=20;
							//EndPos[2]-=20;
							if(IsClientInLOSofEntity(caller,i)) {
								ClosestTarget = i;
								ClosestDistance = Distance;
							}
						//}
					}
				}
			}
			if(ValidPlayer(ClosestTarget,true)) {
				decl Float:EnemyPos[3];
				GetClientAbsOrigin(ClosestTarget, EnemyPos );
				new Float:AffectDistance = GetVectorDistance(StartPos, EnemyPos);
				SetEntityAimToClient( caller, ClosestTarget);
				if (AffectDistance <= ShudderAtkRadius[SkillLevel])
				{
					if(ValidPlayer(owner,false))
					Shudder_Attack(caller,owner,ClosestTarget,SHUDMIN,SHUDMAX,true,true,true);
					else
					Shudder_Slay(caller,false);
				}
				else {
					SetEntityAimToClient( caller, ClosestTarget);

					decl Float:Pos[3];
					GetEntPropVector(caller, Prop_Send, "m_vecOrigin", Pos);
					Shudder_Move(caller,Pos,EnemyPos,15.0);
				}
			}
		}
	}
}

public OnShudderDamage(const String:output[], caller, activator, Float:delay)
{
	if(IsValidEntity(caller))
	{
		if(IsNPC[caller])
		{
			if(ValidPlayer(activator,true)) {
				new owner = GetEntPropEnt(caller, Prop_Send, "m_hOwnerEntity");
				if(ValidPlayer(owner,false)) {
					new SkillLevel = MasterLevel[owner];
					SetEntityAimToClient( caller, activator);
					//SetEntityAimToClient( activator, caller);
					new Float:pos[3],Float:pos2[3];
					GetEntPropVector(caller, Prop_Send, "m_vecOrigin", pos);
					GetClientAbsOrigin( activator, pos2 );
					//ShudderFocus[caller] = activator;
					Shudder_Animate(caller,shudder_hurt,2.0);
					if ( GetClientTeam(activator)!=GetClientTeam(owner) && GetVectorDistance( pos, pos2 ) <= ShudderAtkRadius[SkillLevel]) {
						Shudder_Attack(caller,owner,activator,SHUDMIN,SHUDMAX,true,true,true);
					}
					pos[2]+=60;
					//new dice = GetRandomInt(1,3);
					//if(dice==1)
					//EmitSoundToAll(NPCHurt1,caller); 
					//EmitSoundToAll(NPCHurt1, caller, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, 100, -1, pos, NULL_VECTOR, true, 0.0);
					//else if(dice==2)
					//EmitSoundToAll(NPCHurt2,caller);
					//else
					//EmitSoundToAll(NPCHurt3,caller);
					//TE_SetupBeamPoints(pos,pos2,BeamSprite,BeamSprite,0,1,2.2,35.0,10.0,0,2.0,{255,255,255,220},20);
					//TE_SendToClient(owner);
				}
				else
				Shudder_Slay(caller,false);
			}
		}
	}
}

public OnShudderKilled(const String:output[], caller, activator, Float:delay)
{
	if(IsNPC[caller])
	{
		if( ValidPlayer( activator, false ))
		{
			//EmitSoundToAll(NPCDeath,caller);
			new Float:pos[3],Float:angles[3];
			GetEntPropVector(caller, Prop_Send, "m_vecOrigin", pos);
			GetVectorAngles( pos, angles );
			new owner = GetEntPropEnt(caller, Prop_Send, "m_hOwnerEntity");
			if(ValidPlayer(owner,false)) {
				PrintHintText(owner,"Shudder got killed!!!");
				if(GetConVarBool(ReUseOnDeathCvar)) {
					War3_CooldownMGR(owner,GetConVarFloat(ultCooldownCvar),thisRaceID,ULT,true,true);
					bShudderSpawnd[owner]=false;
					PrintCenterText(owner,"You can Respawn Shudder!");
				}
			}
			//spawn a ragdoll
			SpawnRagdoll(pos,angles);
			Shudder_Disable(caller);
		}
	}
}

SpawnRagdoll(Float:Position[3],Float:Angles[3])  
{  
	new Ragdoll = CreateEntityByName("prop_ragdoll"); 
	if(IsValidEntity(Ragdoll))
	{
		//SetEntityModel(Ragdoll, "models/antlion_guard.mdl");
		SetEntityMoveType(Ragdoll, MOVETYPE_VPHYSICS);   
		SetEntProp(Ragdoll, Prop_Data, "m_CollisionGroup", 11);
		SetEntProp(Ragdoll, Prop_Data, "m_usSolidFlags", 16); 
		DispatchSpawn(Ragdoll); 
		Position[2]+=32;
		TeleportEntity(Ragdoll, Position, Angles, NULL_VECTOR);
	}
}

public OnShudderTouch(caller, activator) 
{
	if(IsValidEntity(caller)) {
		if( ValidPlayer( activator, true ) && IsNPC[caller])
		{
			new owner = GetEntPropEnt(caller, Prop_Send, "m_hOwnerEntity");
			if(ValidPlayer(owner,false)) {
				if(GetClientTeam(activator) != GetClientTeam(owner))
				{
					SetEntityAimToClient( caller, activator);
					Shudder_Attack(caller,owner,activator,SHUDMIN,SHUDMAX,true,true,true);				
				}
			}
			else 
			Shudder_Slay(caller,false);
		}
	}
}

new whitelist;
public bool:IsClientInLOSofEntity(entity,client) {
	//Pos1 = entity position | Pos2 = client position
	decl Float:Pos1[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", Pos1);
	Pos1[2]+=45;
	decl Float:Pos2[3];
	GetClientAbsOrigin(client, Pos2);
	whitelist = entity;
	TR_TraceRayFilter(Pos1,Pos2,MASK_SOLID,RayType_EndPoint,AimTargetFilter);
	if(TR_DidHit())
	{
		new collide=TR_GetEntityIndex();
		if(collide==client)
		{
			return true;
		}
	}
	return false;
}

public bool:AimTargetFilter(entity,mask)
{
	return !(entity==whitelist);
}

public bool:NpcTraceHitFilter(entity, mask, any:data)
{
	return false;
}

// ---- Shudder

public Action:Timer_IdleAnim(Handle:timer, any:i)
{
	if (i > 0 && IsValidEdict(i)) {
		SetVariantString("idle");
		AcceptEntityInput(i, "SetAnimation", -1, -1, 0);
	}
}

public Action:Timer_RemoveTrembleBuff(Handle:timer, any:i)
{
	if(ValidPlayer(i,false))
	{
		War3_SetBuff(i,fMaxSpeed,thisRaceID,1.0);
		War3_SetBuff(i,fInvisibilitySkill,thisRaceID,1.0);
	}
}

public Action:Timer_LoopSwarm(Handle:timer, any:i)
{
	if(ValidPlayer(i,true))
	{
		if(bSwarmed[i])
		{
			DoSwarm(i); //checks for nearby enemys and damage them if able
			CreateTimer(SWARMLOOP, Timer_LoopSwarm, i);
			//if(bSwarmEffect[i]) {
			bSwarmEffect[i]=false;
			CreateTimer(GetRandomFloat(1.0,1.3), Timer_ReallowEffects, i);
			new Float:effectVector1[3];
			GetClientAbsOrigin(i,effectVector1);
			decl Float:effectVector2[3];
			GetClientEyePosition(i,effectVector2);
			effectVector2[2] -= 22.0;

			new Float:fxtimer = 0.0; //start delay before first effect get displayed!
			new nBugs = GetRandomInt(2,4); //amount of bugs to be displayed!
			for(new reptimes=0;reptimes<=nBugs;reptimes++) {
				TE_SetupBubbles(effectVector1,effectVector2,900.0,Bug1,2,GetRandomFloat(28.0,150.0));
				TE_SendToAll(fxtimer);
				fxtimer += GetRandomFloat(0.1,0.2);
			}
			fxtimer = 0.3;
			nBugs = GetRandomInt(4,7);
			for(new reptimes=0;reptimes<=nBugs;reptimes++) {
				TE_SetupBubbles(effectVector1,effectVector2,500.0,Bug2,2,GetRandomFloat(28.0,150.0));
				TE_SendToAll(fxtimer);
				fxtimer += GetRandomFloat(0.1,0.2);
			}
			fxtimer = 0.5;
			nBugs = GetRandomInt(3,5);
			for(new reptimes=0;reptimes<=nBugs;reptimes++) {
				TE_SetupBubbles(effectVector1,effectVector2,500.0,Bug3,2,GetRandomFloat(28.0,150.0));
				TE_SendToAll(fxtimer);
				fxtimer += GetRandomFloat(0.1,0.2);
			}
			fxtimer = 0.8;
			nBugs = 3;
			for(new reptimes=0;reptimes<=nBugs;reptimes++) {
				TE_SetupBubbles(effectVector1,effectVector2,600.0,Bug4,2,GetRandomFloat(28.0,150.0));
				TE_SendToAll(fxtimer);
				fxtimer += GetRandomFloat(0.1,0.2);
			}
			//<player Filter> <delay> <model> <Min "X Y Z"> <Max "X Y Z"> <heigth> <count> <speed>
			//#a 0 effects/blueflare1.vmt server_var(vector2) server_var(vector1) 900 2 180
			//}
		}
	}
}

public Action:Timer_DeCastImpale(Handle:timer, any:i)
{
	if(ValidPlayer(i,false)) {
		W3ResetPlayerColor(i , thisRaceID);
		War3_SetBuff( i, fAttackSpeed, thisRaceID, 1.0 );
		War3_SetBuff( i, fSlow, thisRaceID, 1.0 );
	}
}

public Action:Timer_DeCastSwarm(Handle:timer, any:i)
{
	if(ValidPlayer(i,false))
	bSwarmed[i]=false;
}

public Action:Timer_ReallowEffects(Handle:timer, any:i)
{
	if(ValidPlayer(i,false))
	bSwarmEffect[i]=false;
	//effects granted
}

public Action:PushClientToVector( victim, Float:pos1[3], Float:power )
{
	new Float:pos2[3], Float:main_origin[3], Float:velo1[3], Float:velo2[3];
	GetClientAbsOrigin( victim, pos2 );

	main_origin[0] = pos1[0] - pos2[0], main_origin[1] = pos1[1] - pos2[1], main_origin[2] = pos1[2] - pos2[2];
	velo1[0] += 0, velo1[1] += 0, velo1[2] += 300;
	
	velo2[0] = main_origin[0] * ( 100 * power );
	velo2[1] = main_origin[1] * ( 100 * power );
	velo2[2] = main_origin[2] * ( 100 * power );

	TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, velo1);
	TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, velo2);
}

public CreateTesla(const client,Float:flifetime_min,Float:flifetime_max,Float:thick_min,Float:thick_max,Float:interval_min,Float:interval_max,Float:radiustesla,String:beamcount_min[],String:beamcount_max[],String:ColorTesla[],String:sound[],String:beammodel[],bool:spark)
{
	new point_tesla = CreateEntityByName("point_tesla");
	if(IsValidEdict(point_tesla) && IsClientInGame(client))
	{
		decl String:Name[32], Float:fPos[3];
		Format(Name, sizeof(Name), "tesla_%i", client);
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", fPos);
		fPos[2]+=42.0;
		DispatchKeyValueFloat(point_tesla, "lifetime_min", flifetime_min);
		DispatchKeyValueFloat(point_tesla, "lifetime_min", flifetime_max);
		DispatchKeyValueFloat(point_tesla, "thick_min", thick_min);
		DispatchKeyValueFloat(point_tesla, "thick_max", thick_max);
		DispatchKeyValueFloat(point_tesla, "interval_min", interval_min);
		DispatchKeyValueFloat(point_tesla, "interval_max", interval_max);
		DispatchKeyValueFloat(point_tesla, "m_flRadius", radiustesla);
		DispatchKeyValue(point_tesla, "m_Color", ColorTesla);

		DispatchKeyValue(point_tesla, "Name", Name);
		DispatchKeyValue(point_tesla, "beamcount_min", beamcount_min);
		DispatchKeyValue(point_tesla, "beamcount_max", beamcount_max);
		DispatchKeyValue(point_tesla, "m_SoundName", sound);
		DispatchKeyValue(point_tesla, "texture", beammodel);
		DispatchSpawn(point_tesla);
		ActivateEntity(point_tesla);
		TeleportEntity(point_tesla, fPos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(point_tesla, "TurnOn");
		if(spark)
		AcceptEntityInput(point_tesla, "DoSpark");
		
		CreateTimer(flifetime_max+0.2, INCTimer_RemoveEntity, point_tesla);
		return point_tesla;
	}
	else
	{
		LogError("Failed to create entity point_tesla!");
	}
	return -1;
}

public Action:INCTimer_RemoveEntity(Handle:timer, any:edict)
{
	if(IsValidEdict(edict))
	{
		AcceptEntityInput(edict, "Kill");
	}
}