#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Engine - Notifications",
    author = "War3Source Team",
    description = "Centralize some notifications"
};

new iMaskSoundDelay[MAXPLAYERSCUSTOM];
new String:sMaskSound[256];

public bool:InitNativesForwards()
{
    CreateNative("War3_EvadeDamage", Native_EvadeDamage);
    CreateNative("War3_EffectReturnDamage", Native_EffectReturnDamage);
    CreateNative("War3_VampirismEffect", Native_VampirismEffect);
    CreateNative("War3_BashEffect", Native_BashEffect);

    return true;
}

public OnPluginStart()
{
    // Yes, this should be a "skilleffects" translation file later ;)
    LoadTranslations("w3s.race.undead.phrases");
    LoadTranslations("w3s.race.human.phrases");
    
    for(new i=1; i <= MaxClients; i++)
    {
        iMaskSoundDelay[i] = War3_RegisterDelayTracker();
    }
}

public OnMapStart()
{
    War3_AddSoundFolder(sMaskSound, sizeof(sMaskSound), "mask.mp3");
    War3_PrecacheSound(sMaskSound);
}

public Native_EvadeDamage(Handle:plugin, numParams)
{
    new victim = GetNativeCell(1);
    new attacker = GetNativeCell(2);

    War3_DamageModPercent(0.0);

    if (ValidPlayer(victim))
    {
        W3FlashScreen(victim, RGBA_COLOR_BLUE);
        W3Hint(victim, HINT_SKILL_STATUS, 1.0, "%T", "You Evaded a Shot", victim);

        if(War3_GetGame() == Game_TF)
        {
            decl Float:pos[3];
            GetClientEyePosition(victim, pos);
            pos[2] += 4.0;
            War3_TF_ParticleToClient(0, "miss_text", pos);
        }
    }
    
    if (ValidPlayer(attacker))
    {
        W3Hint(attacker, HINT_SKILL_STATUS, 1.0, "%T", "Enemy Evaded", attacker);
    }
}

public Native_EffectReturnDamage(Handle:plugin, numParams)
{
    // Victim: The guy getting shot
    // Attacker: The guy who takes damage
    new victim = GetNativeCell(1);
    new attacker = GetNativeCell(2);
    new damage = GetNativeCell(3);
    new skill = GetNativeCell(4);

    if (attacker == ATTACKER_WORLD)
    {
        return;
    }
    
    new beamSprite = War3_PrecacheBeamSprite();
    new haloSprite = War3_PrecacheHaloSprite();
    
    decl Float:f_AttackerPos[3];
    decl Float:f_VictimPos[3];

    if (ValidPlayer(attacker))
    {
        GetClientAbsOrigin(attacker, f_AttackerPos);
    }
    else if (IsValidEntity(attacker))
    {
        GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", f_AttackerPos);
    }
    else
    {
        War3_LogError("Invalid attacker for EffectReturnDamage: %i", attacker);
        return;
    }
    
    GetClientAbsOrigin(victim, f_VictimPos);
    
    f_AttackerPos[2] += 35.0;
    f_VictimPos[2] += 40.0;
    
    TE_SetupBeamPoints(f_AttackerPos, f_VictimPos, beamSprite, beamSprite, 0, 45, 0.4, 10.0, 10.0, 0, 0.5, {255, 35, 15, 255}, 30);
    TE_SendToAll();
    
    f_VictimPos[0] = f_AttackerPos[0];
    f_VictimPos[1] = f_AttackerPos[1];
    f_VictimPos[2] = 80.0 + f_AttackerPos[2];
    
    TE_SetupBubbles(f_AttackerPos, f_VictimPos, haloSprite, 35.0, GetRandomInt(6, 8), 8.0);
    TE_SendToAll();
    
    War3_NotifyPlayerTookDamageFromSkill(victim, attacker, damage, skill);
}

public Native_VampirismEffect(Handle:plugin, numParams)
{
    new victim = GetNativeCell(1);
    new attacker = GetNativeCell(2);
    new leechhealth = GetNativeCell(3);
        
    if (leechhealth <= 0)
    {
        return;
    }
    
    W3FlashScreen(victim, RGBA_COLOR_RED);
    W3FlashScreen(attacker, RGBA_COLOR_GREEN);
    
    // Team Fortress shows HP gained in the HUD already
    if(!GameTF())
    {
        W3Hint(attacker, HINT_SKILL_STATUS, 1.0, "%T", "Leeched +{amount} HP", attacker, leechhealth);
    }
    
    if(War3_TrackDelayExpired(iMaskSoundDelay[attacker]))
    {
        EmitSoundToAll(sMaskSound, attacker);
        War3_TrackDelay(iMaskSoundDelay[attacker], 0.25);
    }
    
    if(War3_TrackDelayExpired(iMaskSoundDelay[victim]))
    {
        EmitSoundToAll(sMaskSound, victim);
        War3_TrackDelay(iMaskSoundDelay[victim], 0.25);
    }
    
    PrintToConsole(attacker, "%T", "Leeched +{amount} HP", attacker, leechhealth);
}

public Native_BashEffect(Handle:plugin, numParams)
{
    new victim = GetNativeCell(1);
    new attacker = GetNativeCell(2);
    
    W3FlashScreen(victim, RGBA_COLOR_RED);

    W3Hint(victim, HINT_SKILL_STATUS, 1.0, "%T", "RcvdBash", victim);
    W3Hint(attacker, HINT_SKILL_STATUS, 1.0, "%T", "Bashed", attacker);
}