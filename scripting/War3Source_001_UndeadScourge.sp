#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Race - Undead Scourge",
    author = "War3Source Team",
    description = "The Undead Scourge race for War3Source"
};

new thisRaceID;

new Float:SuicideBomberRadius[5] = {0.0, 250.0, 290.0, 310.0, 333.0}; 
new Float:SuicideBomberDamage[5] = {0.0, 166.0, 200.0, 233.0, 266.0};
new Float:SuicideBomberDamageTF[5] = {0.0, 133.0, 175.0, 250.0, 300.0}; 

new Float:UnholySpeed[5] = {1.0, 1.1, 1.2, 1.3, 1.35};
new Float:LevitationGravity[5] = {1.0, 0.85, 0.7, 0.6, 0.5};
new Float:VampirePercent[5] = {0.0, 0.15, 0.22, 0.29, 0.35};

new SKILL_LEECH, SKILL_SPEED, SKILL_LOWGRAV, SKILL_SUICIDE;

public OnPluginStart()
{
    LoadTranslations("w3s.race.undead.phrases");
}

public OnWar3LoadRaceOrItemOrdered(num)
{
    if(num == 10)
    {
        thisRaceID = War3_CreateNewRaceT("undead");
        SKILL_LEECH = War3_AddRaceSkillT(thisRaceID, "VampiricAura", false, 4, "35%");
        SKILL_SPEED = War3_AddRaceSkillT(thisRaceID, "UnholyAura", false, 4, "35%");
        SKILL_LOWGRAV = War3_AddRaceSkillT(thisRaceID, "Levitation", false, 4, "0.5");
        SKILL_SUICIDE = War3_AddRaceSkillT(thisRaceID, "SuicideBomber", true, 4); 
        
        War3_CreateRaceEnd(thisRaceID);
        
        War3_AddSkillBuff(thisRaceID, SKILL_LEECH, fVampirePercent, VampirePercent);
        War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fMaxSpeed, UnholySpeed);
        War3_AddSkillBuff(thisRaceID, SKILL_LOWGRAV, fLowGravitySkill, LevitationGravity);
    }
}

public OnUltimateCommand(client, race, bool:pressed)
{
    if(pressed && War3_GetRace(client) == thisRaceID && IsPlayerAlive(client) && !Silenced(client))
    {
        new ult_level = War3_GetSkillLevel(client, race, SKILL_SUICIDE);
        ult_level > 0 ? ForcePlayerSuicide(client) : W3MsgUltNotLeveled(client);
    }
}

public OnWar3EventDeath(victim, attacker)
{
    new race = W3GetVar(DeathRace);
    new skill = War3_GetSkillLevel(victim, thisRaceID, SKILL_SUICIDE);
    if(race == thisRaceID && skill > 0 && !Hexed(victim))
    {
        decl Float:fVictimPos[3];
        GetClientAbsOrigin(victim, fVictimPos);
        
        War3_SuicideBomber(victim, fVictimPos, GameTF() ? SuicideBomberDamageTF[skill] : SuicideBomberDamage[skill], SKILL_SUICIDE, SuicideBomberRadius[skill]);        
    } 
}
