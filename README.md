# Global Positions
A mod for Don't Starve Together that adds various ways to find your friends (or spot your enemies).

Map sharing works again! However, you must be in the **A New Reign beta** for it to work. See instructions on how to join [here](http://forums.kleientertainment.com/topic/69487-how-to-opt-in-to-a-new-reign-beta-for-dont-starve-together/).

# Installation
I really recommend [subscribing on Steam](http://steamcommunity.com/sharedfiles/filedetails/?id=378160973) instead. It doesn't give me anything or cost you anything, and it will automatically update it and provide it to people joining your server. However, if you really want to install it from here, download a release and put it in your mods folder, and make sure anyone else joining has done so too.

# Features
- Show other players on the map (and hover over them to see who they are).
- Show player indicators (the bubble things on the side of the screen) when they're far away.
- Light signal fires that show up as indicators and on the map.
- Ping the map by alt+clicking, creating markers that show other players points of interest. Note that muting a player hides their pings. Controller users can ping by clicking in the right stick.
- Opt-out of sharing your your locationg with a button on the scoreboard.
- Share your map discovery with other players automatically (this has been broken for a while, but it's fixed in the A New Reign beta, which you can figure out how to opt into [here](http://forums.kleientertainment.com/topic/69487-how-to-opt-in-to-a-new-reign-beta-for-dont-starve-together/).)

# Wilderness Mode
By default, if you play in Wilderness Mode, it will ignore most of the config options. If you want to override that, set the **Wilderness Mode Override** to _Enabled_. Otherwise, it will hide player positions, but always show campfires.

# Configuration Options
Option | Description
------ | -----------
**Player Indicators** | _Always_ makes it so player indicators always show. _Scoreboard_ (default) only shows them when you bring up the scoreboard. _Disabled_ removes both the indicators and the map icons.
**Player Icons** | _Show_ (default) will show player's map icons on the map. _Hide_ will hide them.
**Show Fires** | _Always_ means they always produce smoke signals when they're lit, so show up globally regardless of fuel used. _Charcoal_ (default) means you have to fuel them with charcoal to produce smoke signals. _Disabled_ turns off smoke signals entirely.
**Fire Icons** | _Show_ (default) shows fire icons on the map when they are smoking. _Hide_ doesn't show them even if they're smoking
**Share Map** | _Enabled_ (default) makes it so that as other players explore the world, your map will update too. Note that this will only work if players or icons are set to be shown.
**Wilderness Override** | _Disabled_ (default) makes it so that in Wilderness Mode, _Show Fires_ is set to _Always_, and _Player Icons_ and _Player Indicators_ are _Disabled_. This adds some risk of discovery to making fires, so cook with caution! _Enabled_ makes it use whatever settings you have set yourself, rather than that Wilderness preset.

Most options are only used by the host; if you're joining, the only option that gets read is whether to show the player indicators at all times or only on the scoreboard.


A huge thanks to Sarcen for figuring out his very clever system for getting player icons to show on the map globally for clients! He has his own mod, Global Player Icons, but I rolled it into this one with his permission.