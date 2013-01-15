//Author: [NotD] l0calh0st
//Website: www.notdelite.com

#define GLOW_COST 1200
#define HAT_COST 6000
#define TRACER_COST 1500
#define TRACERTYPE_COST 6000
public T_Load(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (!IsClientInGame(client))
		return;
	
	if (hndl == INVALID_HANDLE)
	{
		PrintToServer("SQL Load failed.");
		return;
	}
	
	if (SQL_GetRowCount(hndl) == 0)
	{
		new String:query[300], String:auth[MAX_STEAMID];
		GetClientAuthString(client, auth, sizeof(auth));
		Format(query, sizeof(query), "INSERT IGNORE INTO settings (steamid) VALUES ('%s')", auth);
		SQL_TQuery(hDatabase, T_CreateAccount, query, client);
	}
	else
	{
		SQL_FetchRow(hndl);
		credits[client] = SQL_FetchInt(hndl, 1);
		badge[client] = SQL_FetchInt(hndl, 2);
		tracer[client] = SQL_FetchInt(hndl, 3);
		tracerType[client] = SQL_FetchInt(hndl, 4);
		glow[client] = SQL_FetchInt(hndl, 5);
		weapon[client] = SQL_FetchInt(hndl, 6);
		width[client] = SQL_FetchInt(hndl, 7);
		render[client] = SQL_FetchInt(hndl, 8);
	}
	PrintToChat(client, "\x04[STORE]\x01 Your account has been loaded. You can now access !store.");
	isLoaded[client] = true;
	
	if (IsPlayerAlive(client))
		CreateTimer(1.0, GiveTrail, client);
}

public T_CreateAccount(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (!IsClientConnected(client))
	{
		return;
	}
	if (!IsClientInGame(client))
	{
		return;
	}
	PrintToChat(client, "\x04[STORE]\x01 Your account has been loaded. You can now access !store.");
	isLoaded[client] = true;
}

public T_CheckVIP(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed! %s", error);
	}
	else if (SQL_GetRowCount(hndl)) 
	{
		isVip[client] = true;
	}
}

public T_Queue(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	new String:auth[25];
	GetClientAuthString(client, auth, sizeof(auth));
	decl String:query[255];

	Format(query, sizeof(query), "UPDATE settings SET queue = 0 WHERE steamid = '%s'", auth);
	SQL_TQuery(hDatabase, T_Save, query, client);
}

public T_Save(Handle:owner, Handle:hndl, const String:error[], any:client)
{
}

public T_BuildTracer(Handle:owner, Handle:hndl, const String:error[], any:client)
{	
	if (!IsClientInGame(client))
		return;

	new Handle:menu = CreateMenu(Menu_Tracer);
	if (hndl == INVALID_HANDLE)
	{
		PrintToServer("Failed to query (error: %s)", error);
	} 
	else 
	{
		new index;
		new String:indexStr[5];
		
		//Default option
		AddMenuItem(menu, "0", "Default");
		
		while (SQL_FetchRow(hndl))
		{
			index = SQL_FetchInt(hndl, 2);
			IntToString(index, indexStr, sizeof(indexStr));
			AddMenuItem(menu, indexStr, g_ColorNames[index]);
		}
	}
 
	/* Finally, set the title */
	SetMenuTitle(menu, "Tracer Color:");
	//g_TracerMenu[client] = menu;
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public T_BuildTracerType(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (!IsClientInGame(client))
		return;
		
	/* Create the menu Handle */
	
	new Handle:menu = CreateMenu(Menu_TracerType);
	
	if (hndl == INVALID_HANDLE)
	{
		PrintToServer("Failed to query (error: %s)", error);
	} 
	else 
	{
		new index;
		new String:indexStr[5];
		
		//Default option
		AddMenuItem(menu, "0", "Default");
		
		while (SQL_FetchRow(hndl))
		{
			index = SQL_FetchInt(hndl, 2);
			IntToString(index, indexStr, sizeof(indexStr));
			AddMenuItem(menu, indexStr, g_TracerNames[index]);
		}
	}
	
	/* Finally, set the title */
	SetMenuTitle(menu, "Tracer Type:");
	//g_TracerTypeMenu[client] = menu;
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public T_BuildGlow(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (!IsClientInGame(client))
		return;

	/* Create the menu Handle */
	new Handle:menu = CreateMenu(Menu_Glow);
	
	if (hndl == INVALID_HANDLE)
	{
		PrintToServer("Failed to query (error: %s)", error);
	} 
	else 
	{
		new index;
		new String:indexStr[5];
		
		//Default option
		AddMenuItem(menu, "0", "Default");
		
		while (SQL_FetchRow(hndl))
		{
			index = SQL_FetchInt(hndl, 2);
			IntToString(index, indexStr, sizeof(indexStr));
			AddMenuItem(menu, indexStr, g_ColorNames[index]);
		}
	}
 
	/* Finally, set the title */
	SetMenuTitle(menu, "Glow Color:");
	//g_GlowMenu[client] = menu;
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public T_BuyTracerMenu(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (!IsClientInGame(client))
		return;

	new menuCount;
	new bool:hasItem[g_NumOfColors];
	/* Create the menu Handle */
	new Handle:menu = CreateMenu(Menu_BuyTracer);
	
	if (hndl == INVALID_HANDLE)
	{
		PrintToServer("Failed to query (error: %s)", error);
	} 
	else 
	{
		if (!SQL_GetRowCount(hndl))
			AddMenuItem(menu, "", "Store is empty!", ITEMDRAW_DISABLED);
		
		new index;
		
		while (SQL_FetchRow(hndl))
		{
			index = SQL_FetchInt(hndl, 2);
			hasItem[index] = true;
		}
	}
	/*
	* Display only the items that the player doesnt own.
	*/
	new String:indexStr[5];
	
	for (new index = 1; index < g_NumOfColors; index++)
	{
		if (!hasItem[index])
		{
			IntToString(index, indexStr, sizeof(indexStr));
			AddMenuItem(menu, indexStr, g_ColorNames[index]);
			menuCount++;
		}
	}
	
	if (menuCount == 0)
		AddMenuItem(menu, "", "Store is empty!", ITEMDRAW_DISABLED);
		
	/* Finally, set the title */
	new String:menuTitle[30];
	Format(menuTitle, sizeof(menuTitle), "Buy Tracer Color: %d EA.", TRACER_COST);
	SetMenuTitle(menu, menuTitle);
 
	//g_BuyTracerMenu[client] = menu;
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public T_BuyTracerTypeMenu(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (!IsClientInGame(client))
		return;

	new menuCount;
	/* Create the menu Handle */
	new Handle:menu = CreateMenu(Menu_BuyTracerType);
	
	//If true, remove from list.
	new bool:hasItem[g_NumOfTracers];
	
	if (hndl == INVALID_HANDLE)
	{
		PrintToServer("Failed to query (error: %s)", error);
	} 
	else 
	{
		new index;
		
		while (SQL_FetchRow(hndl))
		{
			index = SQL_FetchInt(hndl, 2);
			hasItem[index] = true;
		}
	}
	/*
	* Display only the items that the player doesnt own.
	*/
	new String:indexStr[5];
	
	for (new index = 1; index < g_NumOfTracers; index++)
	{
		if (!hasItem[index])
		{
			IntToString(index, indexStr, sizeof(indexStr));
			
			//Had to program in event tracers, damn halloween event
			if (g_TracerEvent[index])
				continue;
			
			if (g_TracerVIP[index])
			{
				if (isVip[client])
				{
					AddMenuItem(menu, indexStr, g_TracerNames[index]);
					menuCount++;
				}
			}
			else
			{
				AddMenuItem(menu, indexStr, g_TracerNames[index]);
				menuCount++;
			}
		}
	}
	
	if (menuCount == 0)
		AddMenuItem(menu, "", "Store is empty!", ITEMDRAW_DISABLED);
	
	/* Finally, set the title */
	new String:menuTitle[30];
	Format(menuTitle, sizeof(menuTitle), "Buy Tracer Type: %d EA.", TRACERTYPE_COST);
	SetMenuTitle(menu, menuTitle);
 
	//g_BuyTracerTypeMenu[client] = menu;
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public T_BuyGlowMenu(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (!IsClientInGame(client))
		return;
		
	new menuCount;
	/* Create the menu Handle */
	new Handle:menu = CreateMenu(Menu_BuyGlow);
	
	//If true, remove from list.
	new bool:hasItem[g_NumOfColors];
	
	if (hndl == INVALID_HANDLE)
	{
		PrintToServer("Failed to query (error: %s)", error);
	} 
	else 
	{
		new index;
		
		while (SQL_FetchRow(hndl))
		{
			index = SQL_FetchInt(hndl, 2);
			hasItem[index] = true;
		}
	}
	/*
	* Display only the items that the player doesnt own.
	*/
	new String:indexStr[5];
	
	for (new index = 1; index < g_NumOfColors; index++)
	{
		if (!hasItem[index])
		{
			IntToString(index, indexStr, sizeof(indexStr));
			AddMenuItem(menu, indexStr, g_ColorNames[index]);
			menuCount++;
		}
	}
	
	if (menuCount == 0)
		AddMenuItem(menu, "", "Store is empty!", ITEMDRAW_DISABLED);
	
	/* Finally, set the title */
	new String:menuTitle[30];
	Format(menuTitle, sizeof(menuTitle), "Buy Glow Color: %d EA", GLOW_COST);
	SetMenuTitle(menu, menuTitle);
 
	//g_BuyGlowMenu[client] = menu;
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public T_LoadTracers(Handle:owner, Handle:hndl, const String:error[], any:client)
{
		
	new index;
	if (hndl == INVALID_HANDLE)
	{
		PrintToServer("Failed to query (error: %s)", error);
	} 
	else 
	{
		g_NumOfTracers = 0;
		while (SQL_FetchRow(hndl))
		{
			index = SQL_FetchInt(hndl, 0);
			SQL_FetchString(hndl, 1, g_TracerNames[index], 32);
			SQL_FetchString(hndl, 2, g_TracerSprites[index], 32);
			g_TracerVIP[index] = SQL_FetchInt(hndl, 3);
			g_TracerEvent[index] = SQL_FetchInt(hndl, 4);
			g_NumOfTracers++;
		}
	}
	
	//Precache all models
	new String:tracerPath[70];
	for (index = 1; index < g_NumOfTracers; index++)
	{
		Format(tracerPath, sizeof(tracerPath), "materials/sprites/%s.vmt", g_TracerSprites[index]);
		g_Tracers[index] = PrecacheModel(tracerPath);
		//PrintToServer("Path: %s , Model Index: %d, Index: %d, NumOfTracers: %d", tracerPath, g_Tracers[index], index, g_NumOfTracers);
		//PrintToServer("g_Tracers[0] = %d, g_Tracers[1] = %d, g_Tracers[2] = %d, g_Tracers[3] = %d", g_Tracers[0], g_Tracers[1], g_Tracers[2], g_Tracers[3]);
	}
}

public T_LoadColors(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE)
	{
		PrintToServer("Failed to query (error: %s)", error);
	} 
	else 
	{
		new index;
		g_NumOfColors = 0;
		while (SQL_FetchRow(hndl))
		{
			index = SQL_FetchInt(hndl, 0);
			
			SQL_FetchString(hndl, 1, g_ColorNames[index], 32);
			PrintToServer(g_ColorNames[index]);
			g_Colors[index][0] = SQL_FetchInt(hndl, 2);
			g_Colors[index][1] = SQL_FetchInt(hndl, 3);
			g_Colors[index][2] = SQL_FetchInt(hndl, 4);
			g_Colors[index][3] = 255;
			g_NumOfColors++;
		}
	}
}

public T_BuyItem(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE)
	{
		PrintToServer("Failed to query (error: %s)", error);
	} 
}
