/**
* File: War3Source_Vagalion.sp
* Description: The Vagalion race for War3Source.
* Author(s): Vogon 
* Thanks to all that helped
*/

#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks> 
#include <sdkhooks>



new thisRaceID;


new Handle:ultCooldownCvar;

new String:teleportSound[]="war3source/blinkarrival.mp3";

new Float:vagalionSpeed[7]={1.0,1.1,1.2,1.3,1.4,1.5,1.6};

new Float:LevitationGravity[7]={1.0,0.95,0.90,0.85,0.80,0.75,0.7};

new Float:TeleportDistance[7]={0.0,200.0,300.0,400.0,500.0,600.0,700.0};

new Float:InvisibilityAlpha[7]={1.0,0.75,0.65,0.60,0.55,0.50,0.45};

new MyWeaponsOffset;

/* new g_GameType; */

new SKILL_FLICKER,SKILL_ADRENALINE,SKILL_LEVITATION,ULT_VTELEPORT;


public Plugin:myinfo = 
{
	name = "War3Source Race - Vagalion",
	author = "VoGon",
	description = "The Vagalion race for War3Source.",
	version = "1.0.0.2",
	url = "http://www.twkgaming.com"
};

public OnPluginStart()
{

	/** g_GameType = War3_GetGame(); **/

	MyWeaponsOffset=FindSendPropOffs("CBaseCombatCharacter","m_hMyWeapons");
	
	ultCooldownCvar=CreateConVar("war3_vagalion_teleport_cooldown","10","Cooldown between teleports");


}

public OnWar3LoadRaceOrItemOrdered2(num)

if(num==25)
{
	thisRaceID=War3_CreateNewRace("Vagalion","vagalion");
	SKILL_ADRENALINE=War3_AddRaceSkill(thisRaceID,"Adrenaline","Your speed will be increased",false,6);
	SKILL_LEVITATION=War3_AddRaceSkill(thisRaceID,"Levitation","You can jump much higher",false,6);
	SKILL_FLICKER=War3_AddRaceSkill(thisRaceID,"Shimmering Shadow","Makes you invisible",false,6);
	ULT_VTELEPORT=War3_AddRaceSkill(thisRaceID,"Teleport","Teleports you to where tselites",true,6);
	
	War3_CreateRaceEnd(thisRaceID);
}


public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			new race_attacker=War3_GetRace(attacker);
			if(race_attacker==thisRaceID && !W3HasImmunity(victim,Immunity_Ultimates))
			{
				War3_DamageModPercent(1.4);
			}
		}
	}
}



public OnMapStart()
{
	////War3_PrecacheSound(teleportSound);
	
	
}


public Action:LoadSounds(Handle:h)
{
	new String:longsound[512];
	
	Format(longsound,sizeof(longsound), "sound/%s", teleportSound);
	AddFileToDownloadsTable(longsound); 
	
	if(PrecacheSound(teleportSound, true))
	{
		PrintToServer("TPrecacheSound %s",longsound);
	}
	else
	{
		PrintToServer("Failed: PrecacheSound %s",longsound);
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID) ///new race aint ours!!!!! cancel his buffs
	{
		W3ResetAllBuffRace(client,thisRaceID);
	}
	else   ///ok then he is our race, grant powers if any
	{

		if(IsPlayerAlive(client))
		{
			InitSkills(client);
		}
		for(new s=0;s<10;s++)
		{
			new ent=GetEntDataEnt2(client,MyWeaponsOffset+(s*4));
			if(ent>0 && IsValidEdict(ent))
			{
				new String:ename[64];
				GetEdictClassname(ent,ename,64);
				if(StrEqual(ename,"weapon_c4") || StrEqual(ename,"weapon_knife"))
				{
					continue; // don't think we need to delete these
				}
				UTIL_Remove(ent);
			}
		}		
		
	}
}


public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

public Action:OnWeaponCanUse(client, weapon)
{
	if (War3_GetRace(client)== thisRaceID)
	{
		decl String:name[64];
		GetEdictClassname(weapon, name, sizeof(name));

		//if(StrEqual(name, "weapon_knife", false))
		if (IsEquipmentMelee(name))
     	 		return Plugin_Continue;
     	 	return Plugin_Handled;
	}

	return Plugin_Continue;
}

public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		InitSkills(client);
	}
}


public InitSkills(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		new skilllevel_speed=War3_GetSkillLevel(client,thisRaceID,SKILL_ADRENALINE);
		if(skilllevel_speed)
		{
			new Float:speed=vagalionSpeed[skilllevel_speed];
			War3_SetBuff(client,fMaxSpeed,thisRaceID,speed);
		}
		new skilllevel_levi=War3_GetSkillLevel(client,thisRaceID,SKILL_LEVITATION);
		if(skilllevel_levi)
		{
			new Float:gravity=LevitationGravity[skilllevel_levi];
			War3_SetBuff(client,fLowGravitySkill,thisRaceID,gravity);
		}
		new skilllevel=War3_GetSkillLevel(client,thisRaceID,SKILL_FLICKER);
		new Float:alpha=(War3_GetGame()==Game_CS)?InvisibilityAlpha[skilllevel]:InvisibilityAlpha[skilllevel];
		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,alpha);


	}
}


public OnUltimateCommand(client,race,bool:pressed)
{
	new userid=GetClientUserId(client);
	if(race==thisRaceID && pressed && userid>1 && IsPlayerAlive(client) && GetEntityMoveType(client)!=MOVETYPE_NONE)
	{
		new ult_level=War3_GetSkillLevel(client,race,ULT_VTELEPORT);
		if(ult_level>0)
		{
			
			if(War3_SkillNotInCooldown(client,thisRaceID,3,true))
			{
				TeleportPlayerView(client,TeleportDistance[ult_level]);
				War3_SetBuff(client,fInvisibilitySkill,thisRaceID,0);
				CreateTimer(2.0,Invis1,client);
			}
		}
		else
		{
			PrintHintText(client,"Boost your first level of Ulta");
		}
	}
}

public Action:Invis1(Handle:timer,any:client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		new skilllevel=War3_GetSkillLevel(client,thisRaceID,SKILL_FLICKER);
		new Float:alpha=(War3_GetGame()==Game_CS)?InvisibilityAlpha[skilllevel]:InvisibilityAlpha[skilllevel];
		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,alpha);
	}
}


public Action:RespawnPlayer(Handle:timer,any:client)
{
	
		for(new s=0;s<10;s++)
		{
			new ent=GetEntDataEnt2(client,MyWeaponsOffset+(s*4));
			if(ent>0 && IsValidEdict(ent))
			{
				new String:ename[64];
				GetEdictClassname(ent,ename,64);
				if(StrEqual(ename,"weapon_c4") || StrEqual(ename,"weapon_knife"))
				{
					continue; // don't think we need to delete these
				}
				UTIL_Remove(ent);
			}
		}	
	
}





/**
 * Weapons related functions.
 */
#tryinclude <sc/weapons>
#if !defined _weapons_included
    stock bool:IsEquipmentMelee(const String:weapon[])
    {
        switch (War3_GetGame())
        {
            case Game_CS:
            {
                return StrEqual(weapon,"weapon_knife");
            }
            case Game_DOD:
            {
                return (StrEqual(weapon,"weapon_amerknife") ||
                        StrEqual(weapon,"weapon_spade"));
            }
            case Game_TF:
            {
                return (StrEqual(weapon,"tf_weapon_knife") ||
                        StrEqual(weapon,"tf_weapon_shovel") ||
                        StrEqual(weapon,"tf_weapon_wrench") ||
                        StrEqual(weapon,"tf_weapon_bat") ||
                        StrEqual(weapon,"tf_weapon_bat_wood") ||
                        StrEqual(weapon,"tf_weapon_bonesaw") ||
                        StrEqual(weapon,"tf_weapon_bottle") ||
                        StrEqual(weapon,"tf_weapon_club") ||
                        StrEqual(weapon,"tf_weapon_fireaxe") ||
                        StrEqual(weapon,"tf_weapon_fists") ||
                        StrEqual(weapon,"tf_weapon_sword"));
            }
        }
        return false;
    }
#endif

// Teleport Stuff
// By: stinkyfax
// Much thanks, this would be a nightmare without him.
new ClientTracer;
new Float:emptypos[3];
new Float:oldpos[66][3];
new Float:teleportpos[66][3];
bool:TeleportPlayerView(client,Float:distance)
{
	if(client>0)
	{
		if(IsPlayerAlive(client))
		{
			new Float:angle[3];
			GetClientEyeAngles(client,angle);
			new Float:endpos[3];
			new Float:startpos[3];
			GetClientEyePosition(client,startpos);
			new Float:dir[3];
			GetAngleVectors(angle, dir, NULL_VECTOR, NULL_VECTOR);
			
			ScaleVector(dir, distance);
			//PrintToChatAll("DIR %f %f %f",dir[0],dir[1],dir[2]);
			
			AddVectors(startpos, dir, endpos);
			
			GetClientAbsOrigin(client,oldpos[client]);
			
			
			//PrintToChatAll("1");
			
			ClientTracer=client;
			TR_TraceRayFilter(startpos,endpos,MASK_SOLID,RayType_EndPoint,AimTargetFilter);
			TR_GetEndPosition(endpos);
			
			
			//new Float:normal[3];
			//TR_GetPlaneNormal(INVALID_HANDLE,normal);
			
			//ScaleVector(normal, 20.0);
			
			
			if(enemyImmunityInRange(client,endpos)){
				PrintHintText(client,"Enemies immune");
				return false;
			}
			
			//PrintToChatAll("1endpos %f %f %f",endpos[0],endpos[1],endpos[2]);
			distance=GetVectorDistance(startpos,endpos);
			GetAngleVectors(angle, dir, NULL_VECTOR, NULL_VECTOR);///get dir again
			ScaleVector(dir, distance-33.0);
			
			AddVectors(startpos,dir,endpos);
			//PrintToChatAll("DIR %f %f %f",dir[0],dir[1],dir[2]);
			
			//PrintToChatAll("2endpos %f %f %f",endpos[0],endpos[1],endpos[2]);
			
			//endpos[1]=(startpos[1]+(distance*Sine(DegToRad(angle[1]))));
			//endpos[0]=(startpos[0]+(distance*Cosine(DegToRad(angle[1]))));
			//if(!CheckPlayerBox(endpos,startpos,client))
			//	return false;
			emptypos[0]=0.0;
			emptypos[1]=0.0;
			emptypos[2]=0.0;
			
			endpos[2]-=30.0;
			getEmptyLocationHull(client,endpos);
			
			//PrintToChatAll("emptypos %f %f %f",emptypos[0],emptypos[1],emptypos[2]);
			if(GetVectorLength(emptypos)<1.0){
				PrintHintText(client,"Not found free ranging");
				return false; //it returned 0 0 0
			}
			
			
			TeleportEntity(client,emptypos,NULL_VECTOR,NULL_VECTOR);
			//EmitSoundToAll(teleportSound,client);
			//EmitSoundToAll(teleportSound,client);
			
			
			
			teleportpos[client][0]=emptypos[0];
			teleportpos[client][1]=emptypos[1];
			teleportpos[client][2]=emptypos[2];
			
			CreateTimer(0.1,checkTeleport,client);
			
			
			
			
			
			
			return true;
		}
	}
	return false;
}
public Action:checkTeleport(Handle:h,any:client){
	new Float:pos[3];
	
	GetClientAbsOrigin(client,pos);
	if(GetVectorDistance(teleportpos[client],pos)<0.1)//he didnt move in this 0.1 second
	{
		TeleportEntity(client,oldpos[client],NULL_VECTOR,NULL_VECTOR);
		PrintHintText(client,"You can not teleport there!");
	}
	else{
		
		
		PrintHintText(client,"Deported!");
		
		new Float:cooldown=GetConVarFloat(ultCooldownCvar);
		War3_CooldownMGR(client,cooldown,thisRaceID,3,_,_);
	}
}
public bool:AimTargetFilter(entity,mask)
{
	return !(entity==ClientTracer);
}
/*
bool:CheckPlayerBox(Float:bottom[3],Float:start[3],client)
{
	new Float:edge[3][8];
	//point A
	edge[2][0]=bottom[2];
	edge[0][0]=bottom[0]+12.5;
	edge[1][0]=bottom[1]+12.5;
	//point B
	edge[2][1]=edge[2][0];
	edge[0][1]=edge[0][0]+25.0;
	edge[1][1]=edge[1][0];
	//point C
	edge[2][2]=edge[2][1];
	edge[0][2]=edge[0][1];
	edge[1][2]=edge[1][1]+25.0;
	//point D
	edge[2][3]=edge[2][2];
	edge[0][3]=edge[0][2]-25.0;
	edge[1][3]=edge[1][2];
	//other buttons
	for(new i=0;i<4;i++)
	{
		for(new x=0;x<2;x++)
		{
			edge[x][i+4]=edge[x][i];
		}
		edge[2][i+4]=edge[2][i]+67.0;
	}
	for(new i=0;i<4;i++)
	{
		decl Float:point[3];
		point[0]=edge[0][i];
		point[1]=edge[1][i];
		point[2]=edge[2][i];
		decl Float:endpoint[3];
		endpoint[0]=edge[0][i+4];
		endpoint[1]=edge[1][i+4];
		endpoint[2]=edge[2][i+4];
		TR_TraceRayFilter(point,endpoint,MASK_PLAYERSOLID,RayType_EndPoint,AimTargetFilter);
		if(TR_DidHit())
		{
			return false;
		}
	}
	for(new i=0;i<7;i++)
	{
		decl Float:point[3];
		point[0]=edge[0][i];
		point[1]=edge[1][i];
		point[2]=edge[2][i];
		decl Float:endpoint[3];
		endpoint[0]=edge[0][i+1];
		endpoint[1]=edge[1][i+1];
		endpoint[2]=edge[2][i+1];
		TR_TraceRayFilter(point,endpoint,MASK_PLAYERSOLID,RayType_EndPoint,AimTargetFilter);
		if(TR_DidHit())
		{
			return false;
		}
	}
	new Float:top[3];
	top=bottom;
	top[2]+=90;
	ClientTracer=client;
	TR_TraceRayFilter(top,bottom,MASK_PLAYERSOLID,RayType_EndPoint,AimTargetFilter);
	new bool:temp;
	temp=TR_DidHit();
	if(temp)
	{
		return false;
	}
	ClientTracer=client;
	TR_TraceRayFilter(start,top,MASK_PLAYERSOLID,RayType_EndPoint,AimTargetFilter);
	temp=TR_DidHit();
	if(temp)
	{
		return false;
	}
	return true;
}  */


new absincarray[]={0,4,-4,8,-8,12,-12,18,-18,22,-22,25,-25};//,27,-27,30,-30,33,-33,40,-40}; //for human it needs to be smaller

public bool:getEmptyLocationHull(client,Float:originalpos[3]){
	
	
	new Float:mins[3];
	new Float:maxs[3];
	GetClientMins(client,mins);
	GetClientMaxs(client,maxs);
	
	//PrintToChatAll("min : %.1f %.1f %.1f MAX %.1f %.1f %.1f",mins[0],mins[1],mins[2],maxs[0],maxs[1],maxs[2]);
	new absincarraysize=sizeof(absincarray);
	
	new limit=5000;
	for(new x=0;x<absincarraysize;x++){
		if(limit>0){
			for(new y=0;y<=x;y++){
				if(limit>0){
					for(new z=0;z<=y;z++){
						new Float:pos[3]={0.0,0.0,0.0};
						AddVectors(pos,originalpos,pos);
						pos[0]+=float(absincarray[x]);
						pos[1]+=float(absincarray[y]);
						pos[2]+=float(absincarray[z]);
						
						//PrintToChatAll("hull at %.1f %.1f %.1f",pos[0],pos[1],pos[2]);
						//PrintToServer("hull at %d %d %d",absincarray[x],absincarray[y],absincarray[z]);
						TR_TraceHullFilter(pos,pos,mins,maxs,MASK_SOLID,CanHitThis,client);
						//new ent;
						if(TR_DidHit(_))
						{
							//PrintToChatAll("2");
							//ent=TR_GetEntityIndex(_);
							//PrintToChatAll("hit %d self: %d",ent,client);
						}
						else{
							//TeleportEntity(client,pos,NULL_VECTOR,NULL_VECTOR);
							AddVectors(emptypos,pos,emptypos); ///set this gloval variable
							limit=-1;
							break;
						}
					
						if(limit--<0){
							break;
						}
					}
					
					if(limit--<0){
						break;
					}
				}
			}
			
			if(limit--<0){
				break;
			}
			
		}
		
	}

} 

public bool:CanHitThis(entityhit, mask, any:data)
{
	if(entityhit == data )
	{// Check if the TraceRay hit the itself.
		return false; // Don't allow self to be hit, skip this result
	}
	if(ValidPlayer(entityhit)&&ValidPlayer(data)&&War3_GetGame()==Game_TF&&GetClientTeam(entityhit)==GetClientTeam(data)){
		return false; //skip result, prend this space is not taken cuz they on same team
	}
	return true; // It didn't hit itself
}


public bool:enemyImmunityInRange(client,Float:playerVec[3])
{
	//ELIMINATE ULTIMATE IF THERE IS IMMUNITY AROUND
	//new Float:playerVec[3];
	//GetClientAbsOrigin(client,playerVec);
	new Float:otherVec[3];
	new team = GetClientTeam(client);

	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true)&&GetClientTeam(i)!=team&&W3HasImmunity(i,Immunity_Ultimates))
		{
			GetClientAbsOrigin(i,otherVec);
			if(GetVectorDistance(playerVec,otherVec)<300)
			{
				return true;
			}
		}
	}
	return false;
}

public OnWar3EventSpawn(client)
{
	//PrintToChatAll("SPAWN %d",client);
	new race=War3_GetRace(client);
	if(race==thisRaceID)
	{
		InitSkills(client);
		
	}
}