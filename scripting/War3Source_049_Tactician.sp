#pragma semicolon 1    ///WE RECOMMEND THE SEMICOLON

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"  

public Plugin:myinfo = 
{
    name = "War3Source Race - Tactician",
    author = "Ted Theodore Logan",
    description = "The Tactician race for War3Source.",
    version = "1.2",
};

new thisRaceID;
new SKILL_DEFENSIVE, SKILL_OFFENSIVE, SKILL_RUNNER, SKILL_SWITCH;
new Handle:HudMessage;

enum ACTIVESTANCE{
    DefensiveStance,
    OffensiveStance,
    RunnerStance,
    }
    
new ACTIVESTANCE:CurrentStance[MAXPLAYERS];

// Defensive stance
new Float:DefArmor[5]={1.0,0.9,0.8,0.7,0.6};
new Float:DefMove[5]={1.0,0.9,0.8,0.7,0.6};

// Offensive Stance
new Float:OffDamage[5]={1.0,1.1,1.2,1.3,1.4};

// Runner Stance
new Float:RunSpeed[5]={1.0,1.1,1.2,1.3,1.4};
new Float:RunDamage[5]={1.0,0.95,0.85,0.75,0.7};

// Switch Stance
new Float:SwitchCD[5]={40.0,35.0,25.0,15.0,5.0};


public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num==3)
	{
	    thisRaceID=War3_CreateNewRaceT("tactician");
	    SKILL_DEFENSIVE=War3_AddRaceSkillT(thisRaceID,"DefensiveStance",false,4);
	    SKILL_OFFENSIVE=War3_AddRaceSkillT(thisRaceID,"OffensiveStance",false,4);
	    SKILL_RUNNER=War3_AddRaceSkillT(thisRaceID,"RunnerStance",false,4);
	    SKILL_SWITCH=War3_AddRaceSkillT(thisRaceID,"SwitchStances",false,4); 
	    War3_CreateRaceEnd(thisRaceID); ///DO NOT FORGET THE END!!!
	}
}

public OnPluginStart()
{
	HudMessage = CreateHudSynchronizer();
	CreateTimer(15.0,BotSwitcher,_,TIMER_REPEAT);
	
	LoadTranslations("w3s.race.tactician.phrases");
}

public OnMapStart() 
{
	CreateTimer(0.1,Timer_UpdateInfo,_,TIMER_REPEAT);
}

public OnRaceChanged(client,oldrace,newrace)
{
    if(War3_GetRace(client)==thisRaceID)
    {
		CurrentStance[client]=DefensiveStance;
		InitPassiveSkills(client);
    }
	else
	{
		RemovePassiveSkills(client);
	}
}

public OnWar3EventSpawn(client)
{
	BotSwitchStance(client);
	InitPassiveSkills(client);
}

public BotSwitchStance(client)
{
	if((ValidPlayer(client,true))&&(War3_GetRace(client)==thisRaceID)&&(IsFakeClient(client)))
	{
		new Stance = GetRandomInt(0,2);
		if(Stance==0)
		{
			CurrentStance[client]=DefensiveStance;
		}
		else
		{
			if(Stance==1)
			{
				CurrentStance[client]=OffensiveStance;
			}
			else
			{
				CurrentStance[client]=RunnerStance;
			}
		}
	}
}

// Randomly changes the stance of bots
public Action:BotSwitcher(Handle:timer,any:userid)
{
    if(thisRaceID>0)
    {
        for(new i=1;i<=MaxClients;i++)
        {
            if((ValidPlayer(i,true))&&(War3_GetRace(i)==thisRaceID)&&(IsFakeClient(i)))
            {
                new Stance = GetRandomInt(0,2);
                if(Stance==0)
                {
                    CurrentStance[i]=DefensiveStance;
                }
                else
                {
                    if(Stance==1)
                    {
                        CurrentStance[i]=OffensiveStance;
                    }
                    else
                    {
                        CurrentStance[i]=RunnerStance;
                    }
                }
            }
        }
    }
}

public Action:Timer_UpdateInfo(Handle:timer) 
{
    for (new i = 1, iClients = GetClientCount(); i <= iClients; i++) 
	{
        if (IsClientInGame(i) && !IsFakeClient(i) && (War3_GetRace(i)==thisRaceID)) 
		{
			SetHudTextParams(0.04, 0.05, 5.0, 255, 255, 0, 255);
			new String:message[64];
			Format(message,64,"%T","No Stance",i);
			if(CurrentStance[i]==DefensiveStance)
			{
				Format(message,64,"%T","DEFENSIVE",i);
			}
			else
			{
				if(CurrentStance[i]==OffensiveStance)
				{
					Format(message,64,"%T","OFFENSIVE",i);
				}
				else
				{
					Format(message,64,"%T","RUNNER",i);
				}
			}
			ShowSyncHudText(i,HudMessage,"%T","Current Stance: {message}",i,message);
		}
	}
}

public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
	InitPassiveSkills(client);
}

public InitPassiveSkills(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		if(CurrentStance[client]==DefensiveStance)
		{
			new skilllevel_defensive=War3_GetSkillLevel(client,thisRaceID,SKILL_DEFENSIVE);
			War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
			War3_SetBuff(client,fSlow,thisRaceID,DefMove[skilllevel_defensive]);
		}
		else
		{
			if(CurrentStance[client]==OffensiveStance)
			{
			War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
			War3_SetBuff(client,fSlow,thisRaceID,1.0);
			
			}
			if(CurrentStance[client]==RunnerStance)
			{
				new skilllevel_runner=War3_GetSkillLevel(client,thisRaceID,SKILL_RUNNER);
				War3_SetBuff(client,fSlow,thisRaceID,1.0);
				War3_SetBuff(client,fMaxSpeed,thisRaceID,RunSpeed[skilllevel_runner]);
			}
		}
	}
}

public RemovePassiveSkills(client)
{
	W3ResetAllBuffRace(client,thisRaceID);
}

// Switch stances on ability
// Ability:
// Defensive -> Offensive -> Runner
public OnAbilityCommand(client,ability,bool:pressed)
{
    if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
    {
        // Check if skill is not in cooldown
        if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_SWITCH,true)&&!Silenced(client))
        {
            // Do cooldown
            new cooldown_stance=War3_GetSkillLevel(client,thisRaceID,SKILL_SWITCH);
            War3_CooldownMGR(client,SwitchCD[cooldown_stance],thisRaceID,SKILL_SWITCH,_,_);
            if(CurrentStance[client]==OffensiveStance)
            {
                PrintHintText(client,"%T","Ultimate: Offensive | RUNNING STANCE | Ability: Defensive",client);
                CurrentStance[client]=RunnerStance;
            }
            else
            {
				if(CurrentStance[client]==DefensiveStance)
				{
					PrintHintText(client,"%T","Ultimate: Defensive | OFFENSIVE STANCE | Ability: Runner",client);
					CurrentStance[client]=OffensiveStance;
				}
				else
                {
                    PrintHintText(client,"%T","Ultimate: Runner | DEFENSIVE STANCE | Ability: Offensive",client);
                    CurrentStance[client]=DefensiveStance;
                }
            }
            InitPassiveSkills(client);
        }
    }
}

// Switch stances on ultimate
// Ultimate:
// Runner -> Offensive -> Defensive
public OnUltimateCommand(client,race,bool:pressed)
{
    if(race==thisRaceID && pressed && IsPlayerAlive(client))
    {
        // Check if skill is not in cooldown
        if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_SWITCH,true)&&!Silenced(client))
        {
            // Do cooldown
            new cooldown_stance=War3_GetSkillLevel(client,thisRaceID,SKILL_SWITCH);
            War3_CooldownMGR(client,SwitchCD[cooldown_stance],thisRaceID,SKILL_SWITCH,_,_);
            if(CurrentStance[client]==OffensiveStance)
            {
                PrintHintText(client,"%T","Ultimate: Runner | DEFENSIVE STANCE | Ability: Offensive",client);
                CurrentStance[client]=DefensiveStance;
            }
            else
            {
                if(CurrentStance[client]==DefensiveStance)
                {
                    PrintHintText(client,"%T","Ultimate: Offensive | RUNNING STANCE | Ability: Defensive",client);
                    CurrentStance[client]=RunnerStance;
                }
                else
                {
                    PrintHintText(client,"%T","Ultimate: Defensive | OFFENSIVE STANCE | Ability: Runner",client);
                    CurrentStance[client]=OffensiveStance;
                }
            }
            InitPassiveSkills(client);
        }
    }
}

// Apply damage related stances
public OnW3TakeDmgBulletPre(victim,attacker,Float:damage){
    if(ValidPlayer(victim,true)&&ValidPlayer(attacker,false)&&GetClientTeam(victim)!=GetClientTeam(attacker))
    {
        // Victim is a Tactician
        if(War3_GetRace(victim)==thisRaceID)
        {
            if(CurrentStance[victim]==DefensiveStance)
            {
                new skill_defensive_vict=War3_GetSkillLevel(victim,thisRaceID,SKILL_DEFENSIVE);
                War3_DamageModPercent(DefArmor[skill_defensive_vict]);
            }
            else
            {
                if(CurrentStance[victim]==OffensiveStance)
                {
                    new skill_offensive_vict=War3_GetSkillLevel(victim,thisRaceID,SKILL_OFFENSIVE);
                    War3_DamageModPercent(OffDamage[skill_offensive_vict]);
                }
            }
        }
        // Attacker is a Tactician
        if(War3_GetRace(attacker)==thisRaceID)
        {
            if(CurrentStance[attacker]==OffensiveStance)
            {
                new skill_offensive_attack=War3_GetSkillLevel(attacker,thisRaceID,SKILL_OFFENSIVE);
                War3_DamageModPercent(OffDamage[skill_offensive_attack]);
            }
            else
            {
                if(CurrentStance[attacker]==RunnerStance)
                {
                    new skill_runner_attack=War3_GetSkillLevel(attacker,thisRaceID,SKILL_RUNNER);
                    War3_DamageModPercent(RunDamage[skill_runner_attack]);
                }
            }
        }
    }
}
