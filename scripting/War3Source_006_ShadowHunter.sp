
#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>

public Plugin:myinfo = 
{
    name = "War3Source - Race - Shadow Hunter",
    author = "War3Source Team",
    description = "The Shadow Hunter race for War3Source."
};

new thisRaceID;
new LightningSprite, HaloSprite, GlowSprite, PurpleGlowSprite;
new SKILL_HEALINGWAVE, SKILL_HEX, SKILL_WARD, ULT_VOODOO;

//skill 1
new Float:HealingWaveAmountArr[]={0.0,1.0,2.0,3.0,4.0};
new Float:HealingWaveDistance=500.0;
new ParticleEffect[MAXPLAYERSCUSTOM][MAXPLAYERSCUSTOM]; // ParticleEffect[Source][Destination]

//skill 2
new Float:HexChanceArr[]={0.00,0.02,0.050,0.075,0.100};

//skill 3

#define MAXWARDS 64*4
#define WARDRADIUS 95
#define WARDDAMAGE 10
#define WARDBELOW -2.0
#define WARDABOVE 140.0

new WardStartingArr[] = { 0, 1, 2, 3, 4,};
new Float:WardLocation[MAXWARDS][3];
new CurrentWardCount[MAXPLAYERS];
new Float:LastWardRing[MAXWARDS];
new Float:LastWardClap[MAXWARDS];
new WardOwner[MAXWARDS];

new Float:LastThunderClap[MAXPLAYERSCUSTOM];

//ultimate
new Handle:ultCooldownCvar;

new Float:UltimateDuration[]={0.0,0.66,1.0,1.33,1.66}; ///big bad voodoo duration



new bool:bVoodoo[65];

//new String:ultimateSound[]="war3source/divineshield.wav";
//new String:wardDamageSound[]="war3source/thunder_clap.wav";

new String:ultimateSound[256]; //="war3source/divineshield.mp3";
new String:wardDamageSound[256]; //="war3source/thunder_clap.mp3";


new bool:particled[MAXPLAYERSCUSTOM]; //heal particle


new AuraID;

public OnPluginStart()
{

    ultCooldownCvar=CreateConVar("war3_hunter_voodoo_cooldown","20","Cooldown between Big Bad Voodoo (ultimate)");
    CreateTimer( 0.14, CalcWards, _, TIMER_REPEAT );
    
    LoadTranslations("w3s.race.hunter.phrases");
}

public OnWar3LoadRaceOrItemOrdered(num)
{
    if(num==60)
    {
        
        
        thisRaceID=War3_CreateNewRaceT("hunter");
        SKILL_HEALINGWAVE=War3_AddRaceSkillT(thisRaceID,"HealingWave",false,4);
        SKILL_HEX=War3_AddRaceSkillT(thisRaceID,"Hex",false,4);
        SKILL_WARD=War3_AddRaceSkillT(thisRaceID,"SerpentWards",false,4);
        ULT_VOODOO=War3_AddRaceSkillT(thisRaceID,"BigBadVoodoo",true,4); 
        War3_CreateRaceEnd(thisRaceID);
        AuraID=W3RegisterAura("hunter_healwave",HealingWaveDistance);
        
    }

}

public OnMapStart()
{
    War3_AddSoundFolder(wardDamageSound, sizeof(wardDamageSound), "thunder_clap.mp3");
    War3_AddSoundFolder(ultimateSound, sizeof(ultimateSound), "divineshield.mp3");
	LightningSprite = War3_PrecacheBeamSprite();
	HaloSprite =       War3_PrecacheHaloSprite();
	GlowSprite = PrecacheModel( "sprites/glow.vmt" );
	PurpleGlowSprite = PrecacheModel( "sprites/purpleglow1.vmt" );
    War3_PrecacheSound(ultimateSound);
    War3_PrecacheSound(wardDamageSound);
}

public OnWar3PlayerAuthed(client)
{
    bVoodoo[client]=false;
    LastThunderClap[client]=0.0;
}

public OnRaceChanged(client,oldrace,newrace)
{
    if(newrace==thisRaceID)
    {
        new level=War3_GetSkillLevel(client,thisRaceID,SKILL_HEALINGWAVE);
        W3SetAuraFromPlayer(AuraID,client,level>0?true:false,level);
        
    }
    else{
        //PrintToServer("deactivate aura");
        War3_SetBuff(client,bImmunitySkills,thisRaceID,false);
        W3SetAuraFromPlayer(AuraID,client,false);
		RemoveWards( client );
    }
}

public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
    
    if(race==thisRaceID && War3_GetRace(client)==thisRaceID)
    {
        if(skill==SKILL_HEALINGWAVE) //1
        {
            W3SetAuraFromPlayer(AuraID,client,newskilllevel>0?true:false,newskilllevel);
        }
    }
}

public OnUltimateCommand(client,race,bool:pressed)
{
    new userid=GetClientUserId(client);
    if(race==thisRaceID && pressed && userid>1 && IsPlayerAlive(client) )
    {
        new ult_level=War3_GetSkillLevel(client,race,ULT_VOODOO);
        if(ult_level>0)
        {
            if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULT_VOODOO,true))
            {
                bVoodoo[client]=true;
                
                W3SetPlayerColor(client,thisRaceID,255,200,0,_,GLOW_ULTIMATE); //255,200,0);
                CreateTimer(UltimateDuration[ult_level],EndVoodoo,client);
                new Float:cooldown=    GetConVarFloat(ultCooldownCvar);
                War3_CooldownMGR(client,cooldown,thisRaceID,ULT_VOODOO,_,_);
                W3MsgUsingVoodoo(client);
                W3EmitSoundToAll(ultimateSound,client);
                W3EmitSoundToAll(ultimateSound,client);
            }

        }
        else
        {
            W3MsgUltNotLeveled(client);
        }
    }
}

public Action:EndVoodoo(Handle:timer,any:client)
{
    bVoodoo[client]=false;
    W3ResetPlayerColor(client,thisRaceID);
    if(ValidPlayer(client,true))
    {
        W3MsgVoodooEnded(client);
    }
}


public OnAbilityCommand( client, ability, bool:pressed )
{
	if( War3_GetRace( client ) == thisRaceID && ability == 0 && pressed && IsPlayerAlive( client ) )
	{
		new skill_level = War3_GetSkillLevel( client, thisRaceID, SKILL_WARD );
		if( skill_level > 0 )
		{
			if( !Silenced( client ) && CurrentWardCount[client] < WardStartingArr[skill_level] )
			{
				CreateWard( client );
				CurrentWardCount[client]++;
				W3MsgCreatedWard( client, CurrentWardCount[client], WardStartingArr[skill_level] );
			}
			else
			{
				W3MsgNoWardsLeft( client );
			}
		}
	}
}

public CreateWard( client )
{
	for( new i = 0; i < MAXWARDS; i++ )
	{
		if( WardOwner[i] == 0 )
		{
			WardOwner[i] = client;
			GetClientAbsOrigin( client, WardLocation[i] );
			break;
		}
	}
}


public OnWar3EventSpawn( client )
{
	RemoveWards( client );
}
public RemoveWards( client )
{
	for( new i = 0; i < MAXWARDS; i++ )
	{
		if( WardOwner[i] == client )
		{
			WardOwner[i] = 0;
			LastWardRing[i] = 0.0;
			LastWardClap[i] = 0.0;
		}
	}
	CurrentWardCount[client] = 0;
}

public Action:CalcWards( Handle:timer, any:userid )
{
	new client;
	for( new i = 0; i < MAXWARDS; i++ )
	{
		if( WardOwner[i] != 0 )
		{
			client = WardOwner[i];
			if( !ValidPlayer( client, true ) )
			{
				WardOwner[i] = 0;
				--CurrentWardCount[client];
			}
			else
			{
				WardEffectAndDamage( client, i );
			}
		}
	}
}

public WardEffectAndDamage( owner, wardindex )
{
	new ownerteam = GetClientTeam( owner );
	new beamcolor[] = { 0, 0, 200, 255 };
	if( ownerteam == 2 )
	{
		beamcolor[0] = 255;
		beamcolor[1] = 0;
		beamcolor[2] = 0;
		beamcolor[3] = 255;
	}

	new Float:start_pos[3];
	new Float:end_pos[3];
	new Float:tempVec1[] = { 0.0, 0.0, WARDBELOW };
	new Float:tempVec2[] = { 0.0, 0.0, WARDABOVE };

	AddVectors( WardLocation[wardindex], tempVec1, start_pos );
	AddVectors( WardLocation[wardindex], tempVec2, end_pos );

	TE_SetupBeamPoints( start_pos, end_pos, LightningSprite, LightningSprite, 0, GetRandomInt( 30, 100 ), 0.17, 20.0, 20.0, 0, 0.0, beamcolor, 0 );
	TE_SendToAll();

	if( LastWardRing[wardindex] < GetGameTime() - 0.25 )
	{
		LastWardRing[wardindex] = GetGameTime();
		TE_SetupBeamRingPoint( start_pos, 20.0, float( WARDRADIUS * 2 ), LightningSprite, LightningSprite, 0, 15, 1.0, 20.0, 1.0, { 255, 150, 70, 100 }, 10, FBEAM_ISACTIVE );
		TE_SendToAll();
	}

	TE_SetupGlowSprite( end_pos, PurpleGlowSprite, 1.0, 1.25, 50 );
	TE_SendToAll();

	new Float:BeamXY[3];
	for( new x = 0; x < 3; x++ ) BeamXY[x] = start_pos[x];
	new Float:BeamZ = BeamXY[2];
	BeamXY[2] = 0.0;

	new Float:VictimPos[3];
	new Float:tempZ;
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( ValidPlayer( i, true ) && GetClientTeam(i) != ownerteam )
		{
			GetClientAbsOrigin( i, VictimPos );
			tempZ = VictimPos[2];
			VictimPos[2] = 0.0;

			if( GetVectorDistance( BeamXY, VictimPos ) < WARDRADIUS )
			{
				if( tempZ > BeamZ + WARDBELOW && tempZ < BeamZ + WARDABOVE )
				{
					if(W3HasImmunity(i,Immunity_Wards))
					{
						W3MsgSkillBlocked(i,_,"Wards");
					}
					else
					{
						if( LastWardClap[wardindex] < GetGameTime() - 1 )
						{
							new DamageScreen[4];
							new Float:pos[3];

							GetClientAbsOrigin( i, pos );

							DamageScreen[0] = beamcolor[0];
							DamageScreen[1] = beamcolor[1];
							DamageScreen[2] = beamcolor[2];
							DamageScreen[3] = 50;

							W3FlashScreen( i, DamageScreen );

							War3_DealDamage( i, WARDDAMAGE, owner, DMG_ENERGYBEAM, "wards", _, W3DMGTYPE_MAGIC );

							War3_SetBuff( i, fSlow, thisRaceID, 0.7 );

							CreateTimer( 2.0, StopSlow, i );

							pos[2] += 40;

							TE_SetupBeamPoints( start_pos, pos, LightningSprite, LightningSprite, 0, 0, 1.0, 10.0, 20.0, 0, 0.0, { 255, 150, 70, 255 }, 0 );
							TE_SendToAll();

							PrintToChat( i, "\x03You've come to the Kingdom of Raiden" );

							LastWardClap[i] = GetGameTime();
						}
					}
				}
			}
		}
	}
}

public Action:StopSlow( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		War3_SetBuff( client, fSlow, thisRaceID, 1.0 );
	}
}




public OnW3TakeDmgAllPre(victim,attacker,Float:damage)
{
    if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0) //block self inflicted damage
    {
        if(bVoodoo[victim]&&attacker==victim){
            War3_DamageModPercent(0.0);
            return;
        }
        new vteam=GetClientTeam(victim);
        new ateam=GetClientTeam(attacker);
        
        
        if(vteam!=ateam)
        {
            if(bVoodoo[victim])
            {
                if(!W3HasImmunity(attacker,Immunity_Ultimates))
                {
                    if(War3_GetGame()==Game_TF){
                        decl Float:pos[3];
                        GetClientEyePosition(victim, pos);
                        pos[2] += 4.0;
                        War3_TF_ParticleToClient(0, "miss_text", pos); //to the attacker at the enemy pos
                    }
                    War3_DamageModPercent(0.0);
                }
                else
                {
                    W3MsgEnemyHasImmunity(victim,true);
                }
            }
        }
    }
    return;
}

public OnW3PlayerAuraStateChanged(client,aura,bool:inAura,level)
{
    if(aura==AuraID)
    {
        War3_SetBuff(client,fHPRegen,thisRaceID,inAura?HealingWaveAmountArr[level]:0.0);
    }
}
