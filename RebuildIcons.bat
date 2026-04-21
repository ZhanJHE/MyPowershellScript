@echo off
taskkill /f /im explorer.exe
timeout /t 2 /nobreak >nul
cd /d %localappdata%
del /f /q IconCache.db
del /f /q ThumbCache_*.db
timeout /t 2 /nobreak >nul
start explorer.exe
echo 图标缓存已重建，按任意键退出...
pause