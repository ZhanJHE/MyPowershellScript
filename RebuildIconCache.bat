@echo off
echo This script will rebuild the icon cache.
echo It will close and restart Windows Explorer.
echo.
pause
echo Closing Windows Explorer...
taskkill /f /im explorer.exe
echo Deleting icon cache files...
del /a /q "%USERPROFILE%\AppData\Local\Microsoft\Windows\Explorer\iconcache_*.db"
echo Starting Windows Explorer...
start explorer.exe
echo Icon cache has been rebuilt.
exit