@echo off
cd %~dp0
steamcmd +login STEAM_USERNAME STEAM_PASSWORD +force_install_dir C:\Users\RaspberryPi4B\Desktop\HomeServer\Bots\Discord-NMS-Modbuilder-Bot\GAMEDATA\ "+app_update 275850 +beta experimental +betapassword 3xperimental" +quit
