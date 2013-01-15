#include <cstrike>
//#include "W3SIncs/War3Source_Interface"

/**
 * Get random player.
 *
 * @param type	      		Team id. CT - #ct, T - #t, All - #a
 * @param check_alive 		Check for alive or not
 * @param check_immunity	Check for ultimate immunity or not
 * @return			  		client
 */
stock War3_GetRandomPlayer( const String:type[] = "#a", bool:check_alive = false, bool:check_immunity = false )
{
	new targettable[MaxClients];
	new target = 0;
	new bool:all;
	new x = 0;
	new team;
	if( StrEqual( type, "#t" ) )
	{
		team = CS_TEAM_T;
		all = false;
	}
	else if( StrEqual( type, "#ct" ) )
	{
		team = CS_TEAM_CT;
		all = false;
	}
	else if( StrEqual( type, "#a" ) )
	{
		team = 0;
		all = true;
	}
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( i > 0 && i <= MaxClients && IsClientConnected( i ) && IsClientInGame( i ) )
		{
			if( check_alive && !IsPlayerAlive( i ) )
				continue;
			if( check_immunity && W3HasImmunity( i, Immunity_Ultimates ) )
				continue;
			if( !all && GetClientTeam( i ) != team )
				continue;
			targettable[x] = i;
			x++;
		}
	}
	for( new y = 0; y <= x; y++ )
	{
		if( target == 0 )
		{
			target = targettable[GetRandomInt( 0, x - 1 )];
		}
		else if( target != 0 && target > 0 )
		{
			return target;
		}
	}
	return 0;
}

/**
 * Make a player aim at another player.
 *
 * @param client		client
 * @param aim_at 		Client to aim
 * @param add 			Add to z
 * @return			  	No return
 */
stock SetAim( client, aim_at, Float:add )
{
	if( ValidPlayer( client ) && ValidPlayer( aim_at ) )
	{
		new Float:pos1[3];
		new Float:pos2[3];
		new Float:vecang[3];
		new Float:ang[3];
		
		GetClientAbsOrigin( client, pos1 );
		GetClientAbsOrigin( aim_at, pos2 );
		
		pos2[2] += add;
		
		SubtractVectors( pos2, pos1, vecang );
		
		GetVectorAngles( vecang, ang );
		
		ang[2] = 0.0;
		
		TeleportEntity( client, NULL_VECTOR, ang, NULL_VECTOR );
	}
}

/**
 * Make a player aim at pos.
 *
 * @param client		client
 * @param pos 			position for aim
 * @return			  	No return
 */
stock SetAimPos( client, const Float:pos[3] )
{
	if( ValidPlayer( client ) )
	{
		new Float:client_pos[3];
		new Float:vecang[3];
		new Float:ang[3];
		
		GetClientAbsOrigin( client, client_pos );
		
		SubtractVectors( pos, client_pos, vecang );
		
		GetVectorAngles( vecang, ang );
		
		ang[2] = 0.0;
		
		TeleportEntity( client, NULL_VECTOR, ang, NULL_VECTOR );
	}
}

/**
 * Strip weapons from client.
 *
 * @param client		client
 * @param slot 			slot for strip
 * @return			  	No return
 */
stock StripWeaponFromClient( client, slot = 0 )
{
	if( ValidPlayer( client ) )
	{
		if( slot == 0 )
		{
			for( new x = 0; x < 10; x++ )
			{		
				new wpn = GetPlayerWeaponSlot( client, x );
				new String:ename[64];
				if( IsValidEdict( wpn ) )
				{
					GetEdictClassname( wpn, ename, 64 );
					if( StrEqual( ename, "weapon_c4" ) || StrEqual( ename, "weapon_knife" ) )
						continue;
						
					UTIL_Remove( wpn );
				}
			}
			UTIL_EquipKnife( client );
		}
		else if( slot == 1 )
		{
			new wep1 = GetPlayerWeaponSlot( client, CS_SLOT_PRIMARY );
			
			UTIL_Remove( wep1 );
			UTIL_EquipKnife( client );
		}
		else if( slot == 2 )
		{
			new wep2 = GetPlayerWeaponSlot( client, CS_SLOT_SECONDARY );
			
			UTIL_Remove( wep2 );
			UTIL_EquipKnife( client );
		}
	}
}

stock UTIL_EquipKnife( client )
{
	if( ValidPlayer( client, true ) )
	{
		new knife = GetPlayerWeaponSlot( client, 2 );
		if( IsValidEdict( knife ) )
		{
			FakeClientCommand( client, "use weapon_knife" );
		}
		else
		{
			CreateTimer( 0.1, GiveKnife, client );
		}
	}
}

public Action:GiveKnife( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		GivePlayerItem( client, "weapon_knife" );
	}
}