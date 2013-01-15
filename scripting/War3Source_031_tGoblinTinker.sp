    /**
    * File: War3Source_GoblinTinker.sp
    * Description: The Giblin Tinker race for War3Source.
    * Author(s): [Oddity]TeacherCreature
    */
     
    #pragma semicolon 1
     
    #include <sourcemod>
    #include "W3SIncs/War3Source_Interface"
    #include <sdkhooks>
    #include <sdktools>
    #include <sdktools_functions>
    #include <sdktools_tempents>
    #include <sdktools_tempents_stocks>
     
    //native War3_GetAimEndPoint(client,Float:returnvector[3]);
     
    new thisRaceID;
     
    new String:sOldModel[MAXPLAYERS][256];
     
    //skill 1
    new Float:FactoryChance[9]={0.0,0.35,0.40,0.45,0.50,0.55,0.60,0.65,0.70};
    new String:facsnd[]="vo/trainyard/ba_backup.mp3";
    new g_offsCollisionGroup;
     
    //skill 2
    new String:missilesnd[]="weapons/mortar/mortar_explode2.mp3";
    new BeamSprite;
    new Float:MissileMaxDistance[9]={0.00,2000.0,3000.0,4000.0,5000.0,6000.0,7000.0,8000.0,9000.0};
    new bool:bIsBashed[66];
     
    //skill 3
    new Float:SkillFacBuff[9]={0.00,0.02,0.04,0.06,0.08,0.10,0.12,0.14,0.16};
    new Float:SkillMisBuff[9]={0.0,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5};
    new SkillRobBuff[9]={0,80,90,100,110,120,130,140,150};
     
    //skill 4
    new Float:RoboDuration[9]={0.0,6.5,7.0,7.5,8.0,8.5,9.0,9.5,10.0};
    new String:robosnd0[]="hl1/fvox/targetting_system.mp3";
    new String:robosnd1[]="weapons/physcannon/physcannon_charge.mp3";
    new String:robosnd2[]="weapons/cguard/charging.mp3";
    new String:robosnd3[]="music/npc/attack_helicopter/aheli_charge_up.mp3";
    new String:robosnd4[]="weapons/physcannon/physcannon_tooheavy.mp3";
     
    new bool:bRobot[MAXPLAYERS];
     
    new SKILL_FACTORY, SKILL_CLUSTERROCKET, SKILL_ENGINEERING, ULT_ROBOGOBLIN;
     
    public Plugin:myinfo =
    {
            name = "War3Source Race - Goblin Tinker",
            author = "[Oddity]TeacherCreature",
            description = "The Goblin Tinker race for War3Source.",
            version = "1.0.0.0",
            url = "warcraft-source.net"
    }
     
    public OnWar3LoadRaceOrItemOrdered(num)
    {
            if(num==35)
            {
                    thisRaceID=War3_CreateNewRaceT("gtinker");
                    SKILL_FACTORY=War3_AddRaceSkillT(thisRaceID,"PocketFactory",false,8);
                    SKILL_CLUSTERROCKET=War3_AddRaceSkillT(thisRaceID,"ClusterRocket",false,8);
                    SKILL_ENGINEERING=War3_AddRaceSkillT(thisRaceID,"EngineeringUpgrade",false,8);
                    ULT_ROBOGOBLIN=War3_AddRaceSkillT(thisRaceID,"RoboGoblin",true,8);
                    War3_CreateRaceEnd(thisRaceID);
            }
    }
     
    public OnPluginStart()
    {
            g_offsCollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");    
           
            LoadTranslations("w3s.race.gtinker.phrases");
    }
     
    public OnMapStart()
    {
            BeamSprite=PrecacheModel("sprites/physbeam.vmt");
            ////War3_PrecacheSound(missilesnd);
            ////War3_PrecacheSound(facsnd);
            ////War3_PrecacheSound(robosnd0);
            ////War3_PrecacheSound(robosnd1);
            ////War3_PrecacheSound(robosnd2);
            ////War3_PrecacheSound(robosnd3);
            ////War3_PrecacheSound(robosnd4);
			//PrecacheModel("models/player/bigleft/counter_terrorist/special_01/dog.mdl", true);
    }
     
    public OnRaceChanged(client,oldrace,newrace)
    {
            if(newrace!=thisRaceID)
            {
                    War3_WeaponRestrictTo(client,thisRaceID,"");
					W3ResetAllBuffRace(client,thisRaceID);
            }
            if(newrace==thisRaceID)
            {
                    War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
            }
    }
     
    public Action:UnfreezePlayer(Handle:timer,any:userid)
    {
            new client=GetClientOfUserId(userid);
            if(client>0)
            {
                    //PrintHintText(client,"NO LONGER BASHED");
                    War3_SetBuff(client,bBashed,thisRaceID,false);
                    SetEntityMoveType(client,MOVETYPE_WALK);
                    bIsBashed[client]=false;
            }
    }
     
    public OnAbilityCommand(client,ability,bool:pressed)
    {
            if(!Silenced(client))
            {
                    if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
                    {
                            new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_CLUSTERROCKET);
                            if(skill_level>0)
                            {
                                   
                                    if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_CLUSTERROCKET,true))
                                    {
                                            new Float:origin[3];
                                            new Float:targetpos[3];
                                            War3_GetAimEndPoint(client,targetpos);
                                            GetClientAbsOrigin(client,origin);
                                            origin[2]+=30;
                                            origin[1]+=20;
                                            TE_SetupBeamPoints(origin, targetpos, BeamSprite, BeamSprite, 0, 5, 1.0, 4.0, 5.0, 2, 2.0, {255,128,35,255}, 70);  
                                            TE_SendToAll();
                                            origin[1]-=40;
                                            TE_SetupBeamPoints(origin, targetpos, BeamSprite, BeamSprite, 0, 5, 1.0, 4.0, 5.0, 2, 2.0, {255,128,35,255}, 70);  
                                            TE_SendToAll();
                                            //EmitSoundToAll(missilesnd,client);
                                            War3_CooldownMGR(client,3.0,thisRaceID,SKILL_CLUSTERROCKET,_,_);
                                            new target = War3_GetTargetInViewCone(client,MissileMaxDistance[skill_level],false,5.0);
                                            new RobotDamage = 20;
                                            if (bRobot[client])
                                                    RobotDamage = 40;
                                            if(target>0 && !W3HasImmunity(target,Immunity_Skills))
                                            {
                                                    new engi_level=War3_GetSkillLevel(client,thisRaceID,SKILL_ENGINEERING);
                                                    War3_DealDamage(target,RobotDamage,client,_,"cluster_missile",W3DMGORIGIN_SKILL,W3DMGTYPE_TRUEDMG);
                                                    IgniteEntity(target,SkillMisBuff[engi_level]);
                                                    War3_SetBuff(target,bBashed,thisRaceID,true);
                                                    W3FlashScreen(target,RGBA_COLOR_RED, 0.3, 0.4, FFADE_OUT);
                                                    CreateTimer(1.5,UnfreezePlayer,GetClientUserId(target));
                                                    bIsBashed[target]=true;
                                                   
                                            }
                                    }
                            }
                    }
     
                    if(War3_GetRace(client)==thisRaceID && ability==1 && pressed && IsPlayerAlive(client))
                    {
                            new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_FACTORY);
                            if(skill_level>0)
                            {
                                    if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_FACTORY,true))
                                    {
                                            new skill_factory=War3_GetSkillLevel(client,thisRaceID,SKILL_FACTORY);
                                            new skill_engineering=War3_GetSkillLevel(client,thisRaceID,SKILL_ENGINEERING);
                                   
                                            if(GetRandomFloat(0.0,1.0)<=FactoryChance[skill_factory]+SkillFacBuff[skill_engineering])
                                            {
                                                    new clockrace=War3_GetRaceIDByShortname("clockwerk");
                                                    new possibletargets[MAXPLAYERS];
                                                    new possibletargetsfound;
                                                    for(new i=1;i<=MaxClients;i++)
                                                    {
                                                            if(ValidPlayer(i))
                                                            {
                                                                    //new onetarget=0;
                                                                    new summonteam=GetClientTeam(i);
                                                                    new summonerteam=GetClientTeam(client);
                                                                    if(War3_GetRace(i)==clockrace && IsPlayerAlive(i)==false && summonteam==summonerteam)
                                                                    {
                                                                            possibletargets[possibletargetsfound]=i;
                                                                            possibletargetsfound++;
                                                                    }
                                                            }
                                                    }
                                                    new onetarget;
                                                    if(possibletargetsfound>0)
                                                    {
                                                            onetarget=possibletargets[GetRandomInt(0, possibletargetsfound-1)]; //i hope random 0 0 works to zero
                                                            if(onetarget>0)
                                                            {
                                                                    War3_CooldownMGR(client,15.0,thisRaceID,SKILL_FACTORY,_,_);
                                                                    new Float:ang[3];
                                                                    new Float:pos[3];
                                                                    War3_SpawnPlayer(onetarget);
                                                                    GetClientEyeAngles(client,ang);
                                                                    GetClientAbsOrigin(client,pos);
                                                                    TeleportEntity(onetarget,pos,ang,NULL_VECTOR);
                                                                    //EmitSoundToAll(facsnd,client);
                                                                    SetEntData(onetarget, g_offsCollisionGroup, 2, 4, true);
                                                                    SetEntData(client, g_offsCollisionGroup, 2, 4, true);
                                                                    CreateTimer(3.0,normal,onetarget);
                                                                    CreateTimer(3.0,normal,client);
                                                            }
                                                    }
                                            }
                                    }
                            }
                    }
            }
            else
            {
                    PrintHintText(client,"%T","Silenced: Can not cast",client);
            }
    }
     
    public Action:normal(Handle:timer,any:client)
    {
            if(ValidPlayer(client,true))
            {
                    new Float:end_dist=50.0;
                    new Float:end_pos[3];
                    GetClientAbsOrigin(client,end_pos);
                    for(new i=1;i<=MaxClients;i++)
                    {
                            if(ValidPlayer(i,true)&&i!=client)
                            {
                                    new Float:pos[3];
                                    GetClientAbsOrigin(i,pos);
                                    new Float:dist=GetVectorDistance(end_pos,pos);
                                    if(dist<=end_dist)
                                    {
                                            CreateTimer(1.0,normal,client);
                                            break;
                                    }
                                    else{
                                            SetEntData(client, g_offsCollisionGroup, 5, 4, true);
                                    }
                            }
                    }
            }
    }
     
    public OnUltimateCommand(client,race,bool:pressed)
    {
            if(race==thisRaceID && pressed && IsPlayerAlive(client))
            {
                    new skill=War3_GetSkillLevel(client,race,ULT_ROBOGOBLIN);
                    if(skill>0)
                    {
                            if(War3_SkillNotInCooldown(client,thisRaceID,ULT_ROBOGOBLIN,true))
                            {
                                    if(!Silenced(client))
                                    {
                                            new engi_robo=War3_GetSkillLevel(client,race,SKILL_ENGINEERING);
                                            SetEntityHealth(client,GetClientHealth(client)+SkillRobBuff[engi_robo]);
                                            //EmitSoundToAll(robosnd0,client);
                                            GetClientModel(client,sOldModel[client],256);
                                            //SetEntityModel(client, "models/player/bigleft/counter_terrorist/special_01/dog.mdl");
											//SetEntityModel(client, "models/player/bigleft/counter_terrorist/special_01/dog.mdl");
                                            //ServerCommand("wcs_setmodel %d \"%s\" %d",GetClientUserId(client), RoboModel_CT, 1);
                                           
                                            bRobot[client] = true;
                                           
                                            CreateTimer(RoboDuration[skill],normalmodel,client);
                                            CreateTimer(0.1,robo1,client);
                                            CreateTimer(2.0,robo2,client);
                                            CreateTimer(3.0,robo3,client);
                                            War3_CooldownMGR(client,30.0,thisRaceID,ULT_ROBOGOBLIN,_,_);
                                    }
                                    else
                                    {
                                            PrintHintText(client,"%T","Silenced: Can not cast",client);
                                    }
                            }
                    }
            }
    }
     
    public Action:robo1(Handle:h,any:client){
            //EmitSoundToAll(robosnd1,client);
    }
    public Action:robo2(Handle:h,any:client){
            //EmitSoundToAll(robosnd2,client);
    }
    public Action:robo3(Handle:h,any:client){
            //EmitSoundToAll(robosnd3,client);
    }
     
    public Action:normalmodel(Handle:h,any:client)
    {
            if(ValidPlayer(client,true))
            {
                    SetEntityHealth(client,100);
                    //EmitSoundToAll(robosnd4,client);
                    //SetEntityModel(client,sOldModel[client]);
                    bRobot[client] = false;
            }
    }
     
    public OnWar3EventSpawn(client)
    {
            bRobot[client] = false;
    }