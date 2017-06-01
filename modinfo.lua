--The name of the mod displayed in the 'mods' screen.
name = "Global Positions"

--A description of the mod.
description = "By default, shows player arrows when the scoreboard is up, player icons on the minimap globally, and the same for campfires or firepits fueled by charcoal."

--Who wrote this awesome mod?
author = "rezecib, Sarcen"

--A version number so you can ask people if they are running an old version of your mod.
--In DST this is also used to determine compatibility for joining servers
version = "1.6.6"

forumthread = ""

--This lets other players know if your mod is out of date, update it to match the current version in the game
api_version = 10

--Can specify a custom icon for this mod!
icon_atlas = "GlobalPositionsIcon.xml"
icon = "GlobalPositionsIcon.tex"

--Specify compatibility with versions of the game!
dont_starve_compatible = true
reign_of_giants_compatible = true
dst_compatible = true

--This lets clients know if they need to get the mod from the Steam Workshop to join the game
all_clients_require_mod = true

--This determines whether it causes a server to be marked as modded (and shows in the mod list)
client_only_mod = false

--This determines when this mod is loaded relative to other mods
--#rezecib I set this to -1000 to make it load last, or at least later than character mods
priority = -1000

--This lets people search for servers with this mod by these tags
server_filter_tags = {"global player icons", "global player indicators", "smoke signals"}

configuration_options =
{
	{
		name = "SHOWPLAYERSOPTIONS",
		label = "Player Indicators",
		hover = "The arrow things that show players past the edge of the screen.",
		options =	{
						{description = "Always", data = 3},
						{description = "Scoreboard", data = 2},
						{description = "Never", data = 1},
					},
		default = 2,
	},
	{
		name = "SHOWPLAYERICONS",
		label = "Player Icons",
		hover = "The player icons on the map.",
		options =	{
						{description = "Show", data = true},
						{description = "Hide", data = false},
					},
		default = true,
	},
	{
		name = "FIREOPTIONS",
		label = "Show Fires",
		hover = "Show fires with indicators like players." ..
				"\nThey will smoke when they are visible this way.",
		options =	{
						{description = "Always", data = 1},
						{description = "Charcoal", data = 2},
						{description = "Disabled", data = 3},
					},
		default = 2,
	},
	{
		name = "SHOWFIREICONS",
		label = "Fire Icons",
		hover = "Show fires globally on the map (this will only work if fires are set to show)." ..
				"\nThey will smoke when they are visible this way.",
		options =	{
						{description = "Show", data = true},
						{description = "Hide", data = false},
					},
		default = true,
	},
	{
		name = "SHAREMINIMAPPROGRESS",
		label = "Share Map",
		hover = "Share map exploration between players. This will only work if" .. 
				"\n'Player Indicators' and 'Player Icons' are not both disabled.",
		options =	{
						{description = "Enabled", data = true},
						{description = "Disabled", data = false},
					},
		default = true,
	},
	{
		name = "OVERRIDEMODE",
		label = "Wilderness Override",
		hover = "If enabled, it will use the other options you set in Wilderness mode." ..
				"\nOtherwise, it will not show players, but all fires will smoke and be visible.",
		options =	{
						{description = "Enabled", data = true},
						{description = "Disabled", data = false},
					},
		default = false,
	},
	{
		name = "ENABLEPINGS",
		label = "Pings",
		hover = "Whether to allow players to ping (alt+click) the map.",
		options =	{
						{description = "Enabled", data = true},
						{description = "Disabled", data = false},
					},
		default = true,
	},
}