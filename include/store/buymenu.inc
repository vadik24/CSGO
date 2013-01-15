//Author: [NotD] l0calh0st
//Website: www.notdelite.com
/*
	20 hrs -> color
	25 hrs -> tracer color
	100 hrs -> tracer type

	1200 credits per color
	3000 credits per tracer color
	6000 credits per tracer type
*/

public MenuHandlerBuy(Handle:menu, MenuAction:action, param1, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		if (StrEqual(info, "tracer"))
		{
			BuildTracerBuyMenu(param1);
		}
		else if (StrEqual(info, "tracertype"))
		{
			BuildTracerTypeBuyMenu(param1);
		}
		else if (StrEqual(info, "glow"))
		{
			BuildGlowBuyMenu(param1);
		}
		//else if (StrEqual(info, "hat"))
		//{
		//	BuildHatBuyMenu(param1);
		//}
		else if (StrEqual(info, "back"))
		{
			Menu_Store(param1);
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
 
public Menu_Buy(client)
{
	new String:creditDisplay[15];
	Format(creditDisplay, sizeof(creditDisplay), "Credits:%d", credits[client]);
	new Handle:menu = CreateMenu(MenuHandlerBuy);
	SetMenuTitle(menu, "Buy Menu:");
	AddMenuItem(menu, " ", creditDisplay, ITEMDRAW_DISABLED);
	AddMenuItem(menu, "glow", "Buy Glow Colors");
	AddMenuItem(menu, "tracer", "Buy Tracer Colors");
	AddMenuItem(menu, "tracertype", "Buy Tracer Types");
	//AddMenuItem(menu, "hat", "Buy Hats");
	AddMenuItem(menu, "back", "Back");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 20);
}

public Menu_BuyTracer(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
 
		/* Get item info */
		GetMenuItem(menu, param2, info, sizeof(info));
		new colorID = StringToInt(info);
		PrintToServer("The buyglow colorid: %d, the info: %s", colorID, info);

		/* Tell the client */
		//PrintToConsole(param1, "You selected item: %d (found? %d info: %s)", param2, found, info);

		/* Check if client can buy */
		if (credits[param1] >= TRACER_COST)
		{
			credits[param1] -= TRACER_COST;
			BuyItem(param1, "tracer", colorID);
			PrintToChat(param1, "\x04[STORE]\x01 You have bought a %s tracer color for %d credits!", g_ColorNames[colorID], TRACER_COST);

			Save(param1);
		}
		else
		{
			PrintToChat(param1, "\x04[STORE]\x01 Sorry, you cannot afford this. You need %d more credits.", (credits[param1] - TRACER_COST) * -1);
		}
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

BuildTracerBuyMenu(client)
{ 
	new String:auth[25];
	decl String:query[255];
	
	GetClientAuthString(client, auth, sizeof(auth));
	
	/*
	* Checks if the player owns the item and if true, removes the item from the list.
	*/
	Format(query, sizeof(query), "SELECT * FROM items WHERE steamid = '%s' AND item = 'hat'", auth);
	SQL_TQuery(hDatabase, T_BuyTracerMenu, query, client);
}

public Menu_BuyTracerType(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
 
		/* Get item info */
		GetMenuItem(menu, param2, info, sizeof(info));
 
		/* Tell the client */
		//PrintToConsole(param1, "You selected item: %d (found? %d info: %s)", param2, found, info);

		/* Check if client can buy */
		if (credits[param1] >= TRACERTYPE_COST)
		{
			new tracerID = StringToInt(info);
			credits[param1] -= TRACERTYPE_COST;
			BuyItem(param1, "tracertype", tracerID);
			PrintToChat(param1, "\x04[STORE]\x01 You have bought a %s tracer type for %d credits!", g_TracerNames[tracerID], TRACERTYPE_COST);

			Save(param1);
		}
		else
		{
			PrintToChat(param1, "\x04[STORE]\x01 Sorry, you cannot afford this. You need %d more credits.", (credits[param1] - TRACERTYPE_COST) * -1);
			Menu_Buy(param1);
		}
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

BuildTracerTypeBuyMenu(client)
{ 
	new String:auth[25];
	decl String:query[255];
	
	GetClientAuthString(client, auth, sizeof(auth));
	
	/*
	* Checks if the player owns the item and if true, removes the item from the list.
	*/
	Format(query, sizeof(query), "SELECT * FROM items WHERE steamid = '%s' AND item = 'tracertype'", auth);
	SQL_TQuery(hDatabase, T_BuyTracerTypeMenu, query, client);
}

public Menu_BuyGlow(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
 
		/* Get item info */
		GetMenuItem(menu, param2, info, sizeof(info));
		new colorID = StringToInt(info);
		PrintToServer("The buyglow colorid: %d, the info: %s", colorID, info);
 
		/* Tell the client */
		//PrintToConsole(param1, "You selected item: %d (found? %d info: %s)", param2, found, info);

		/* Check if client can buy */
		if (credits[param1] >= GLOW_COST)
		{
			credits[param1] -= GLOW_COST;
			PrintToChat(param1, "\x04[STORE]\x01 You have bought a %s glow color for %d credits!", g_ColorNames[colorID], GLOW_COST);
			BuyItem(param1, "glow", colorID);

			Save(param1);
		}
		else
		{
			PrintToChat(param1, "\x04[STORE]\x01 Sorry, you cannot afford this. You need %d more credits.", (credits[param1] - GLOW_COST) * -1);
			Menu_Buy(param1);
		}
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

BuildGlowBuyMenu(client)
{ 
	new String:auth[25];
	decl String:query[255];
	
	GetClientAuthString(client, auth, sizeof(auth));
	
	/*
	* Checks if the player owns the item and if true, removes the item from the list.
	*/
	Format(query, sizeof(query), "SELECT * FROM items WHERE steamid = '%s' AND item = 'glow'", auth);
	SQL_TQuery(hDatabase, T_BuyGlowMenu, query, client);
}

BuyItem(client, const String:item[25], number)
{
	new String:query[255], String:auth[25];
	
	GetClientAuthString(client, auth, sizeof(auth));
	
	Format(query, sizeof(query), "INSERT INTO items (steamid, item, number) VALUES ('%s', '%s', %d)", auth, item, number); 
	PrintToServer(query);
	SQL_TQuery(hDatabase, T_BuyItem, query, client);
}
