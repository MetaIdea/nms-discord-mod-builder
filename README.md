# nms-discord-mod-builder
A fully automatic discord chat based bot that can update amumss/lua based mods (pak/lua) and reply with a updated mod file.

# Configuration

- In bot.lua change BOT_TOKEN, guildname, CHANNEL, this_dir, AllowedRolesCustomMod
- In steamcmd/UpdateGame.bat change STEAM_USERNAME, STEAM_PASSWORD and the path
- Use start.bat to start the bot

# Usage

Upload your .pak or .lua mods in this channel to receive a automatically updated version.
To add your amumss script based mod to the user mod list write "add" as message when uploading your user mod.
You can also quick build mods based on single value changes, you just need 3 things - file,valuename,newvalue: "mod:(GCDEBUGOPTIONS.GLOBAL.MBIN,GodMode,True)"

Commands:
.help
.mods
.usermods
mod:index
mod:(file,valuename,newvalue)
add (with file upload to add to user database)
