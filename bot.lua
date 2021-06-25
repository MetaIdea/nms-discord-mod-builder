--bot config--

BOT_TOKEN = ""
guildname = ""
CHANNEL = ""

local GameUpdateCheckTimeMinutes = 180
local this_dir = [[C:\Users\RaspberryPi4B\Desktop\HomeServer\Bots\Discord-NMS-Modbuilder-Bot\]]
local amumss_path = this_dir .. [[AMUMSS\]]
local ModScriptDir = amumss_path .. [[ModScript\]]

local AllowedRolesCustomMod = {}

local helptext = [[
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
]]

--bot config end--

local discordia = require("discordia")
local client = discordia.Client()
--discordia.extensions()

function Log(text,nofilelog)
	local logtext = os.date('%d-%m-%Y,%H:%M:%S') .. ": " .. text .. "\n"
	print(logtext)
	if not nofilelog then
		local serverlogfile = "log.txt"
		local filehandle = assert(io.open(serverlogfile,'a'))
		if filehandle ~= nil then
			filehandle:write(logtext)
			filehandle:flush()
			filehandle:close()
		end
	end
end

local http = require('coro-http')
function DownloadAttachment(message, filepath)
	local link = message.attachments[1].url
	local result, body = http.request("GET", link)     
	local filehandle = assert(io.open(filepath .. message.attachments[1].filename, 'wb')) --string.match(link,"([^/]+)$")
	if filehandle ~= nil then
		filehandle:write(body)
		filehandle:flush()
		filehandle:close()
	end
end

local ModArchive = {}
local ModArchiveUser = {}

function BuildAndUploadMod(message,addusermod)
	if not string.find(message.content,"mod:%(") then
		if not string.find(message.content,"mod:") then
			local filename = message.attachments[1].filename --string.sub(message.attachments[1].filename,1,string.len(message.attachments[1].filename)-1)
			--print(filename)
			Log("Mod creation request - file: " .. filename .. ", size: " ..  message.attachments[1].size/1000 .. "KB, user: " .. message.author.username .. ", URL: " .. message.attachments[1].url)
			DownloadAttachment(message, ModScriptDir)
			local backupcopy = os.date('%Y_%m_%d-%H_%M_%S') .. "-" .. message.author.username .. "-" .. filename
			os.execute([[xcopy /y /h "]] .. ModScriptDir .. filename .. [[*" "]] .. this_dir .. [[BuildHistory\]] .. backupcopy .. [[*"]])
			if addusermod then
				os.execute([[xcopy /y /h "]] .. ModScriptDir .. filename .. [[*" "]] .. this_dir .. [[ModArchiveUser\]] .. [["]])
				message:reply("Mod added to user mod database, thank you for sharing !")
				return
			end
		else
			local modarchiveindex = tonumber(string.match(message.content,"%d+"))
			if modarchiveindex and type(modarchiveindex) == "number" and modarchiveindex > 0 and modarchiveindex <= #ModArchive then
				if string.find(message.content,"usermod:") then
					if modarchiveindex <= #ModArchiveUser then
						Log("Mod archive creation request - " .. ModArchiveUser[modarchiveindex] .. " - " .. message.author.username)
						os.execute([[xcopy /s /y /h /v "]] .. [[.\ModArchiveUser\]] .. ModArchiveUser[modarchiveindex] .. [[" "]] .. ModScriptDir .. [[" 2>NUL 1>NUL]])
					else
						Log("Mod archive creation request failed - invalid mod archive index")
						return
					end
				else
					if modarchiveindex <= #ModArchive then
						Log("Mod archive creation request - " .. ModArchive[modarchiveindex] .. " - " .. message.author.username)
						os.execute([[xcopy /s /y /h /v "]] .. [[.\ModArchive\]] .. ModArchive[modarchiveindex] .. [[" "]] .. ModScriptDir .. [[" 2>NUL 1>NUL]])
					else
						Log("Mod archive creation request failed - invalid mod archive index")
						return
					end
				end
			else
				Log("Mod archive creation request failed - invalid mod archive index")
				return
			end
		end
	end
	os.execute(amumss_path .. "BUILDMOD.bat >NUL") -- >NUL
	local ModFilesPath = amumss_path .. [[CreatedModPAKs\]]
	os.execute("cd " .. ModFilesPath .. [[ & FOR %F IN (*.pak) DO ( echo %F > ..\..\modfilename.txt)]])
	local filehandle =  io.open("modfilename.txt","r")
	if filehandle then
		local line = filehandle:read("l")
		local modfilename = string.sub(line,1,string.len(line)-1) 
		local modfilepath = ModFilesPath .. modfilename
		filehandle:close()
		if string.len(modfilename) > 4 then
			message.channel:send {file = modfilepath}
			local backupcopy = os.date('%Y_%m_%d-%H_%M_%S') .. "-" .. message.author.username .. "-" .. modfilename
			os.execute([[xcopy /y /h "]] .. modfilepath .. [[*" "]] .. this_dir .. [[BuildHistory\]] .. backupcopy .. [[*"]])
			Log("Mod creation finished - mod file name: " .. modfilename)
		else
			message:reply("error: no mod file created")
			Log("error: no mod file created")
		end
	else
		message:reply("error: no mod file created")
		Log("error: no mod file created")
	end
	os.execute([[Del /f /q /s "]] .. ModScriptDir .. [[*.*"]])
end

function ModScriptQuickCreation(message)
	local modtable = {}
	local modcontent = string.sub(message.content,string.find(message.content,"%(")+1,string.find(message.content,"%)")-1)
	for component in string.gmatch(modcontent,'([^,]+)') do
		table.insert(modtable,component)
	end
	local file = modtable[1]
	local property = modtable[2]
	local newvalue = modtable[3]
	local modname = "mod_" .. property .. "_" .. newvalue
	local MODSCRIPT = [[NMS_MOD_DEFINITION_CONTAINER={["MOD_FILENAME"]="]] .. modname .. ".pak" .. [[",["MODIFICATIONS"]={{["MBIN_CHANGE_TABLE"]={{["MBIN_FILE_SOURCE"]="]] .. file .. [[",["EXML_CHANGE_TABLE"]={{["REPLACE_TYPE"]="ALL",["VALUE_CHANGE_TABLE"]={{"]] .. property .. [[","]] .. newvalue .. [["}}}}}}}}}]]
	local filehandle = assert(io.open(ModScriptDir .. modname .. ".lua",'wb'))
	if filehandle ~= nil then
		filehandle:write(MODSCRIPT)
		filehandle:flush()
		filehandle:close()
	end
end

function CreateModArchiveList()
	os.execute([[Del /f /q /s ModArchiveList.txt]])
	os.execute([[cd ModArchive]] .. [[ & FOR %F IN (*.lua *.pak) DO ( echo %F >> ..\ModArchiveList.txt)]])
	local filehandle = io.open("ModArchiveList.txt","r")
	if filehandle then
		ModArchive = {}
		local line = ""
		while line do
			line = filehandle:read("l")
			if line then
				table.insert(ModArchive, string.sub(line,1,string.len(line)-1))
			end
		end
		filehandle:close()
	end
end

function CreateUserModArchiveList()
	os.execute([[Del /f /q /s ModArchiveUserList.txt]])
	os.execute([[cd ModArchiveUser]] .. [[ & FOR %F IN (*.lua *.pak) DO ( echo %F >> ..\ModArchiveUserList.txt)]])
	local filehandle = io.open("ModArchiveUserList.txt","r")
	if filehandle then
		ModArchiveUser = {}
		local line = ""
		while line do
			line = filehandle:read("l")
			if line then
				table.insert(ModArchiveUser, string.sub(line,1,string.len(line)-1))
			end
		end
		filehandle:close()
	end
end

function GetModArchiveList(ModArchiveTable)
	local ModArchiveListStr = ""
	for i=1,#ModArchiveTable,1 do
		if string.find(ModArchiveTable[i],".lua") then
			ModArchiveListStr = ModArchiveListStr .. i .. " " .. string.gsub(ModArchiveTable[i],".lua","") .. "\n"
		elseif string.find(ModArchiveTable[i],".pak") then
			ModArchiveListStr = ModArchiveListStr .. i .. " " .. string.gsub(ModArchiveTable[i],".pak","") .. "\n"
		end
	end
	return ModArchiveListStr
end

client:on("ready", function()
	p(string.format('Logged in as %s', client.user.username))
end)

function MessageAuthorHasRole(message,rolename)
	local member = message.guild:getMember(message.author.id)
	local roleid = ""
	for role in message.guild.roles:iter() do
		if rolename == role.name then
			roleid = tostring(role.id)
			break
		end
	end
	return message.guild:getMember(message.author.id):hasRole(roleid)
end

function MessageAuthorHasAnyRoleInList(message,rolelist)
	local roleid = ""
	for i=1,#rolelist,1 do
		for role in message.guild.roles:iter() do
			if rolelist[i] == role.name and message.guild:getMember(message.author.id):hasRole(role.id) then
				return true
			end
		end
	end
	return false
end

function CheckGameUpdate()
	print("Checking for Game Updates")
	os.execute([[steamcmd\]] .. "UpdateGame.bat")
end

local timer = require('timer')
timer.setInterval(GameUpdateCheckTimeMinutes*60*1000, CheckGameUpdate)

client:on("messageCreate", function(message)
	if message.guild and string.find(message.channel.name,CHANNEL) then --message.guild.name == guildname and
		Log("Message received")
		if message.author.username ~= client.user.username and message.content then
			if string.find(message.content,"%.help") then
				message:reply(helptext)
			elseif string.find(message.content,"%.update") then
				os.execute([[steamcmd\]] .. "UpdateGame.bat")
				GameUpdateCheckStartTime = os.time()
			elseif string.find(message.content,"%.mod") then
				message:reply([[Build mods directly from the server mod archive - usage: "mod:number"]] .. "\nMod List:\n" .. GetModArchiveList(ModArchive))
			elseif string.find(message.content,"%.usermod") then
				message:reply([[Build mods directly from the server USER mod archive - usage: "mod:number"]] .. "\nMod List:\n" .. GetModArchiveList(ModArchiveUser))
			elseif string.find(message.content,"mod:") then --or "usermod:"
				if string.find(message.content,"%(") and string.find(message.content,"%)") then
					local _, count = string.gsub(message.content,",","")
					if count == 2 then
						message:reply("Building/Updating mod now.")
						ModScriptQuickCreation(message)
						BuildAndUploadMod(message)
					else
						message:reply("error: wrong syntax - use mod:(file,valuename,newvalue)")
					end
				else
					message:reply("Building/Updating mod now.")
					BuildAndUploadMod(message)
				end
			elseif message.attachments and #message.attachments > 0 and (string.find(message.attachments[1].filename,".lua") or string.find(message.attachments[1].filename,".pak")) then
				if MessageAuthorHasAnyRoleInList(message,AllowedRolesCustomMod) then
					if string.find(message.content,"add") then
						BuildAndUploadMod(message,true)
						CreateUserModArchiveList()
					else
						message:reply("Building/Updating mod now.")
						BuildAndUploadMod(message)
					end
				end
			end
			Log("Actions completed")
		end
	end
end)

CreateModArchiveList()
CreateUserModArchiveList()

client:run("Bot " .. BOT_TOKEN)