/**
 * File: War3Source_Alien.sp
 * Description: The Spy Hunter race for War3Source.
 * Author(s): ZI & Schmarotzer
 */
 
#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_tempents_stocks>

new thisRaceID;



new m_vecVelocity_0, m_vecVelocity_1, m_vecBaseVelocity;
// СДЕЛАТЬ ВСЕ ШЕСТЫМ УРОВНЕМ!!!!!!!
// skill 1
new const InfectionInitialDamage=20;
new const InfectionTrailingDamage=5;
new Float:InfectionChance[6]={0.0, 0.05, 0.1, 0.15, 0.2, 0.25};
new InfectionTimes[6]={0, 2, 3, 4, 5, 6};
new BeingInfectedBy[MAXPLAYERS];
new InfectionRemaining[MAXPLAYERS];
new String:PoisonSound[]={"npc/roller/mine/rmine_blades_out2.mp3"};

// skill 2
new SkinHealth[6]={0, 20, 40, 60, 80, 100};

// skill 3 
new Float:ToxicChance[6]={0.0, 0.06, 0.10, 0.15, 0.20, 0.25};
new Float:ToxicTime[6]={0.0, 0.2, 0.4, 0.6, 0.8, 1.0};
new bool:bIsStunned[MAXPLAYERS];

// skill 4
new Float:DisarmChance[6]={0.0, 0.1, 0.2, 0.3, 0.4, 0.5};

// ultimate
new Float:ShadowDuration[6]={1.0, 3.0, 3.5, 4.0, 4.5, 5.0};

// Effects
new BeamSprite, HaloSprite;

// Convars
new Handle:cvDelay = INVALID_HANDLE;
new Handle:cvType = INVALID_HANDLE;

new SKILL_POISON,SKILL_SKIN,SKILL_TOXIC,SKILL_SLASH,ULT_SHADOW;

public Plugin:myinfo = 
{
	name = "War3Source Race - Alien",
	author = "ZI & Schmarotzer",
	description = "The Alien race for War3Source.",
	version = "1.0.0.0",
	url = "http://css.bashtel.ru"
};

public OnPluginStart()
{  
	m_vecVelocity_0 = FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
	m_vecVelocity_1 = FindSendPropOffs("CBasePlayer","m_vecVelocity[1]");
	m_vecBaseVelocity = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
	HookEvent("player_jump",PlayerJumpEvent);
	LoadTranslations("w3s.race.alien.phrases");
	cvDelay = CreateConVar("war3_alien_dissolve_delay","2");
	cvType = CreateConVar("war3_alien_dissolve_type", "0");
}  


public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num==30)
	{
	
		
		thisRaceID=War3_CreateNewRaceT("alien");
		SKILL_POISON	=	War3_AddRaceSkillT(thisRaceID,"skill1",false,5); //ГОТОВО
		SKILL_SKIN		=	War3_AddRaceSkillT(thisRaceID,"skill2",false,5); //ГОТОВО
		SKILL_TOXIC		=	War3_AddRaceSkillT(thisRaceID,"skill3",false,5);//============
		SKILL_SLASH		=	War3_AddRaceSkillT(thisRaceID,"skill4",false,5); //ГОТОВО
		ULT_SHADOW		=	War3_AddRaceSkillT(thisRaceID,"skill5",true,5); //TEST
		
		
		War3_CreateRaceEnd(thisRaceID);
	
	}
}

public OnMapStart()
{
	
	// PrecacheModel("models/player/slow/aliendrone_v3/slow_alien_head.mdl", true);
	// PrecacheModel("models/player/slow/aliendrone_v3/slow_alien_hs.mdl", true);
	
	BeamSprite=War3_PrecacheBeamSprite();
	HaloSprite=War3_PrecacheHaloSprite();
}


//==========================================2 skill===================================
public OnWar3EventSpawn(client)	
{
	War3_SetBuff(client,bStunned,thisRaceID,false);
	bIsStunned[client]=false;
	
	new race=War3_GetRace(client);
	if(race==thisRaceID) 
	{
		W3ResetBuffRace(client,fInvisibilitySkill,thisRaceID); 
		ActivateSkills(client);
		GivePlayerItem(client, "weapon_knife");
		new ClientTeam = GetClientTeam(client);
		switch(ClientTeam)
		{
			case 3:
				W3SetPlayerColor(client,thisRaceID,255,255,255);
			case 2:
				W3SetPlayerColor(client,thisRaceID,220,50,0);
		}
	}
}


public ActivateSkills(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
	
		new skill_level_skin=War3_GetSkillLevel(client,thisRaceID,SKILL_SKIN);
		if(skill_level_skin)
		{
			new hpadd=SkinHealth[skill_level_skin];
			new Float:vec[3];
			GetClientAbsOrigin(client,vec);
			vec[2]+=25.0;
			new ringColor[4]={0,0,0,0};
			new team=GetClientTeam(client);
			if(team==2)
			{
				ringColor={255,0,0,255};
			}
			else if(team==3)
			{
				ringColor={0,0,255,255};
			}
			TE_SetupBeamRingPoint(vec,40.0,10.0,BeamSprite,HaloSprite,0,15,1.0,15.0,0.0,ringColor,10,0);
			TE_SendToAll();

			War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,hpadd);
			
		}
	}
}
//================================================1 3 4 skill===================================================

public OnW3TakeDmgAll(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim)&&ValidPlayer(attacker)&&victim!=attacker)
	{
		new vteam=GetClientTeam(victim); 
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam) 
		{
			new race_attacker=War3_GetRace(attacker);
			// new race_victim=War3_GetRace(victim);
			if(race_attacker==thisRaceID && !Hexed(attacker)) 
			{
				// =============== ЯДОВИТЫЕ КОГТИ ===========================
				new skill_level_poison = War3_GetSkillLevel(attacker,thisRaceID,SKILL_POISON);
				if(skill_level_poison>0 && InfectionRemaining[victim]==0 && GetRandomFloat(0.0,1.0)<=InfectionChance[skill_level_poison]&&!Silenced(attacker))
				{
					if(W3HasImmunity(victim,Immunity_Skills))
					{
						W3MsgEnemyHasImmunity(attacker,true);
					}
					else
					{
						PrintHintText(victim,"%T","String_01",victim);
						PrintHintText(attacker,"%T","String_02",attacker);
						BeingInfectedBy[victim]=attacker;
						InfectionRemaining[victim]=InfectionTimes[skill_level_poison];
						War3_DealDamage(victim,InfectionInitialDamage,attacker,DMG_BULLET,"poison_claws");
						W3FlashScreen(victim,RGBA_COLOR_RED);
						
						//EmitSoundToAll(PoisonSound,attacker);
						//EmitSoundToAll(PoisonSound,victim);
						CreateTimer(1.0,InfectionLoop,victim);
					}
				}
				// ==========================================================
				
				// ================= ОСТРЫЕ КОГТИ ===========================
				new skill_level_slash = War3_GetSkillLevel(attacker,race_attacker,SKILL_SLASH);
				if(skill_level_slash>0)
				{
					if(GetRandomFloat(0.0,1.0)<=DisarmChance[skill_level_slash] && !W3HasImmunity(victim,Immunity_Skills))
					{
						PrintHintText(victim,"%T","String_03",victim);
						PrintHintText(attacker,"%T","String_04",attacker);
					}
				}
				// ==========================================================
				
				// =============== ЯДОВИТЫЕ КОГТИ ===========================
				new skill_level_toxic = War3_GetSkillLevel(attacker,race_attacker,SKILL_TOXIC);
				if(skill_level_toxic>0)
				{
					if(!bIsStunned[victim] && !W3HasImmunity(victim,Immunity_Skills) && IsPlayerAlive(victim))
					{
						if(GetRandomFloat(0.0,1.0)<=ToxicChance[skill_level_toxic])
						{
							War3_SetBuff(victim,bStunned,thisRaceID,true);
							bIsStunned[victim]=true;
							new Float:Time = ToxicTime[skill_level_toxic];
							CreateTimer(Time,UnToxic,victim);
							W3FlashScreen(victim,RGBA_COLOR_GREEN);
							PrintHintText(victim,"%T","String_05",victim);
							PrintHintText(attacker,"%T","String_06",attacker);
						}
					}
				}
				// ==========================================================
				
			}
		}
	}
}

public Action:UnToxic(Handle:timer,any:victim)
{
	if(ValidPlayer(victim,true))
	{
		War3_SetBuff(victim,bStunned,thisRaceID,false);
		bIsStunned[victim]=false;
	}
}

public Action:InfectionLoop(Handle:timer,any:victim)
{
	if(InfectionRemaining[victim]>0 && ValidPlayer(BeingInfectedBy[victim]) && ValidPlayer(victim,true))
	{
		War3_DealDamage(victim,InfectionTrailingDamage,BeingInfectedBy[victim],_,"poison_claws",W3DMGORIGIN_ULTIMATE,W3DMGTYPE_TRUEDMG);
		InfectionRemaining[victim]--;
		W3FlashScreen(victim,RGBA_COLOR_RED, 0.3, 0.4);
		CreateTimer(1.0,InfectionLoop,victim);
	}
}


//==========================================сброс навыков==============================
public OnRaceChanged(client,oldrace,newrace) 
{
	if(newrace!=thisRaceID) 
	{
		War3_WeaponRestrictTo(client,thisRaceID,"");
		W3ResetAllBuffRace(client,thisRaceID);	}
	else 
	{
		ActivateSkills(client); 
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
		if(IsPlayerAlive(client))
		{
			GivePlayerItem(client, "weapon_knife");
			new ClientTeam = GetClientTeam(client);
			switch(ClientTeam)
			{
				case 3:
					W3SetPlayerColor(client,thisRaceID,255,255,255);
				case 2:
					W3SetPlayerColor(client,thisRaceID,220,50,0);
			}
		}	
	}
}







public OnUltimateCommand(client,race,bool:pressed) // событие при ульте (клиент, раса, нажато)
{
	if(race==thisRaceID && pressed && IsPlayerAlive(client)){ // если раса = нужная нам и ульта нажата и игрок клиент живой то
		if(!Silenced(client)){ // если чары не наложены то
			new ult_level_shadow=War3_GetSkillLevel(client,thisRaceID,ULT_SHADOW); // уровень ульты маскировки = получаем уровень кача ульты
			if(ult_level_shadow>0) // если ульта качнута
			{
				new Float:time = ShadowDuration[ult_level_shadow]; // время = время в зависимости от уровня
				if(War3_SkillNotInCooldown(client,thisRaceID,ULT_SHADOW,true)){ // если ульта не в кулдауне (время отката)
					War3_SetBuff(client,fInvisibilitySkill,thisRaceID,0.0); // делаем невидимость 0 - то есть полностью невидим
					War3_CooldownMGR(client,20.0,thisRaceID,ULT_SHADOW,_,_); // задаем время кулдауна (время отката)
					
					CreateTimer(time,unhide,client); // создаем таймер после которого запустим функцию для того чтобы сделать видимым ((включаем функцию для видимости)
					PrintHintText(client,"%T","String_07",client,time); // пишим внизу в центре экрана клинту
				}
			}
			else // иначе (то есть ульта не качнута)
			{
				W3MsgUltNotLeveled(client); // пишим в чат сообщение о том что ульта не качнута
			}
		}
		// else
		// {
			// PrintHintText(client,"Безмолвие!");
		// }
	}
}


public Action:unhide(Handle:timer,any:client) // делаем видимым обратно
{
	if(ValidPlayer(client,true)){ // проверка валидности
		W3ResetBuffRace(client,fInvisibilitySkill,thisRaceID); // сбрасываем невидимость
		// War3_SetBuff(client,fInvisibilitySkill,thisRaceID,Shadow[skill]);
		W3MsgNoLongerDisguised(client); // пишим в центр внизу экрана
	}
}

public PlayerJumpEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event,"userid"));
	new ClientRace = War3_GetRace(client);
	if(ClientRace==thisRaceID)
	{
		new Float:velocity[3]={0.0,0.0,0.0};
		velocity[0]= GetEntDataFloat(client,m_vecVelocity_0);
		velocity[1]= GetEntDataFloat(client,m_vecVelocity_1);
		velocity[0]*=1.0;
		velocity[1]*=1.0;
		SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
	}
}

public Action:Dissolve(Handle:timer, any:client)
{
	if (!IsValidEntity(client))
	return;

	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll<0)
	{
		PrintToServer("[DISSOLVE] Could not get ragdoll for player!");  
		return;
	}

	new String:dname[32], String:dtype[32];
	Format(dname, sizeof(dname), "dis_%d", client);
	Format(dtype, sizeof(dtype), "%d", GetConVarInt(cvType));

	new ent = CreateEntityByName("env_entity_dissolver");
	if (ent>0)
	{
		DispatchKeyValue(ragdoll, "targetname", dname);
		DispatchKeyValue(ent, "dissolvetype", dtype);
		DispatchKeyValue(ent, "target", dname);
		AcceptEntityInput(ent, "Dissolve");
		AcceptEntityInput(ent, "kill");
	}
}

public OnWar3EventDeath(victim,attacker)
{
	new race=War3_GetRace(victim);
	if(race==thisRaceID)
	{
		new Float:delay = GetConVarFloat(cvDelay);
		if (delay>0.0)
		{
			CreateTimer(delay, Dissolve, victim); 
		}
		else
		{
			Dissolve(INVALID_HANDLE, victim);
		}
		// return Plugin_Continue;
	}
}