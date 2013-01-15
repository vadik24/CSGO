//Author: [NotD] l0calh0st
//Website: www.notdelite.com
public MenuHandlerStore(Handle:menu, MenuAction:action, param1, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		if (StrEqual(info, "buy"))
		{
			Menu_Buy(param1);
		}
		else if (StrEqual(info, "tracer"))
		{
			BuildTracerMenu(param1);
		}
		else if (StrEqual(info, "tracertype"))
		{
			BuildTracerTypeMenu(param1);
		}
		//else if (StrEqual(info, "hat"))
		//{
		//	BuildHatMenu(param1);
		//}
		else if (StrEqual(info, "glow"))
		{
			BuildGlowMenu(param1);
		}
		else if (StrEqual(info, "custom"))
		{
			Menu_Trail(param1);
		}
	}
	/* If the menu was cancelled, print a message to the server about it. */
	else if (action == MenuAction_Cancel)
	{
		PrintToServer("Client %d's menu was cancelled.  Reason: %d", param1, param2);
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
 
public Menu_Store(client)
{
	new String:creditDisplay[15];
	Format(creditDisplay, sizeof(creditDisplay), "Credits:%d", credits[client]);
	new Handle:menu = CreateMenu(MenuHandlerStore);
	SetMenuTitle(menu, "Store Menu:");
	AddMenuItem(menu, " ", creditDisplay, ITEMDRAW_DISABLED);
	AddMenuItem(menu, "buy", "Buy Items");
	AddMenuItem(menu, "glow", "Glow Colors");
	AddMenuItem(menu, "tracer", "Tracer Colors");
	AddMenuItem(menu, "tracertype", "Tracer Types");
	//AddMenuItem(menu, "hat", "Hats");
	AddMenuItem(menu, "custom", "Customize Tracer");
	/*
	if (isVip[client])
		AddMenuItem(menu, "weapon", "[VIP] Weapon Enhancements");
	else
		AddMenuItem(menu, "", "[VIP] Weapon Enhancements", ITEMDRAW_DISABLED);
	*/
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 20);
}

/*
public Menu_Hat(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
 
		
		GetMenuItem(menu, param2, info, sizeof(info));
 
		
		////PrintToConsole(param1, "You selected item: %d (found? %d info: %s)", param2, found, info);
 
		
		hat[param1] = StringToInt(info);
		
		if (IsValidEntity(g_Hat[param1]))
		{
			RemoveEdict(g_Hat[param1]);
		}
		g_Hat[param1] = -1;
		
		if (g_Hat[param1] != 0)
		{
			Hat(param1);
		}
		Save(param1);
		//PrintToServer("Tracer: %d , Info: %s", tracer[param1], info);
		return;
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

*/

BuildHatMenu(client)
{ 
	new String:auth[25];
	decl String:query[255];
	
	GetClientAuthString(client, auth, sizeof(auth));
	
	Format(query, sizeof(query), "SELECT * FROM items WHERE steamid = '%s' AND item = 'hat'", auth);
	
	SQL_TQuery(hDatabase, T_BuildHat, query, client);
}

public Menu_Tracer(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
 
		/* Get item info */
		GetMenuItem(menu, param2, info, sizeof(info));
 
		/* Tell the client */
		////PrintToConsole(param1, "You selected item: %d (found? %d info: %s)", param2, found, info);
 
		/* Assign the value */
		tracer[param1] = StringToInt(info);
		
		if (IsValidEntity(g_SpriteModel[param1]))
		{
			RemoveEdict(g_SpriteModel[param1]);
		}
		g_SpriteModel[param1] = -1;
		
		if (tracerType[param1] != 0)
		{
			SpriteTrail(param1);
		}
		Save(param1);
		//PrintToServer("Tracer: %d , Info: %s", tracer[param1], info);
		return;
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

BuildTracerMenu(client)
{ 
	new String:auth[25];
	decl String:query[255];
	
	GetClientAuthString(client, auth, sizeof(auth));
	
	Format(query, sizeof(query), "SELECT * FROM items WHERE steamid = '%s' AND item = 'tracer'", auth);
	
	SQL_TQuery(hDatabase, T_BuildTracer, query, client);
}

public Menu_TracerType(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
 
		/* Get item info */
		GetMenuItem(menu, param2, info, sizeof(info));
 
		/* Tell the client */
		//PrintToConsole(param1, "You selected item: %d (found? %d info: %s)", param2, found, info);
 
		/* Assign the value */
		tracerType[param1] = StringToInt(info);
		if (IsValidEntity(g_SpriteModel[param1]))
		{
			RemoveEdict(g_SpriteModel[param1]);
		}
		g_SpriteModel[param1] = -1;
		if (tracerType[param1] != 0)
		{
			SpriteTrail(param1);
		}
		Save(param1);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

BuildTracerTypeMenu(client)
{ 
	new String:auth[25];
	decl String:query[255];
	
	GetClientAuthString(client, auth, sizeof(auth));
	
	Format(query, sizeof(query), "SELECT * FROM items WHERE steamid = '%s' AND item = 'tracertype'", auth);
	
	SQL_TQuery(hDatabase, T_BuildTracerType, query, client);
}

public Menu_Glow(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
 
		/* Get item info */
		GetMenuItem(menu, param2, info, sizeof(info));
 
		/* Tell the client */
		//PrintToConsole(param1, "You selected item: %d (found? %d info: %s)", param2, found, info);
 
		/* Assign the value */
		glow[param1] = StringToInt(info);
		SetEntityRenderMode(param1, RENDER_TRANSCOLOR);
		SetEntityRenderColor(param1, g_Colors[glow[param1]][0], g_Colors[glow[param1]][1], g_Colors[glow[param1]][2], g_Colors[glow[param1]][3]);
		Save(param1);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

Handle:BuildGlowMenu(client)
{ 
	new String:auth[25];
	decl String:query[255];
	
	GetClientAuthString(client, auth, sizeof(auth));
	
	Format(query, sizeof(query), "SELECT * FROM items WHERE steamid = '%s' AND item = 'glow'", auth);
	
	SQL_TQuery(hDatabase, T_BuildGlow, query, client);
}

public MenuHandlerTrail(Handle:menu, MenuAction:action, param1, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		if (StrEqual(info, "width"))
		{
			Menu_SetWidth(param1);
		}
		else if (StrEqual(info, "render"))
		{
			Menu_Render(param1);
		}
	}
	/* If the menu was cancelled, print a message to the server about it. */
	else if (action == MenuAction_Cancel)
	{
		PrintToServer("Client %d's menu was cancelled.  Reason: %d", param1, param2);
	}
	/* If the menu has `	ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
 
public Menu_Trail(client)
{
	new Handle:menu = CreateMenu(MenuHandlerTrail);
	SetMenuTitle(menu, "Trail Customize Menu:");
	AddMenuItem(menu, "width", "Change Width");
	AddMenuItem(menu, "render", "Change Render");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 20);
}

public MenuHandlerSetWidth(Handle:menu, MenuAction:action, param1, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		width[param1] = StringToInt(info);
		if (tracerType[param1] != 0)
		{
			if (IsValidEntity(g_SpriteModel[param1]))
			{
				RemoveEdict(g_SpriteModel[param1]);
			}
			g_SpriteModel[param1] = -1;
			SpriteTrail(param1);
			Save(param1);
		}
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
 
public Menu_SetWidth(client)
{
	new Handle:menu = CreateMenu(MenuHandlerSetWidth);
	SetMenuTitle(menu, "Trail Width Menu:");
	AddMenuItem(menu, "5", "5");
	AddMenuItem(menu, "10", "10 'Default'");
	AddMenuItem(menu, "15", "15");
	AddMenuItem(menu, "20", "20");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 20);
}

public MenuHandlerRender(Handle:menu, MenuAction:action, param1, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		render[param1] = StringToInt(info);
		if (tracerType[param1] != 0)
		{
			if (IsValidEntity(g_SpriteModel[param1]))
			{
				RemoveEdict(g_SpriteModel[param1]);
			}
			g_SpriteModel[param1] = -1;
			SpriteTrail(param1);
			Save(param1);
		}
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
 
public Menu_Render(client)
{
	new Handle:menu = CreateMenu(MenuHandlerRender);
	SetMenuTitle(menu, "Trail Render Menu:");
	AddMenuItem(menu, "0", "Normal");
	AddMenuItem(menu, "4", "Solid");
	AddMenuItem(menu, "5", "Transparent");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 20);
}
