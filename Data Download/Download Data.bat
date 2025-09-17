@echo off
setlocal

:: Fecha 
for /f %%i in ('powershell -command "Get-Date -Format yyyy-MM-dd"') do set FECHA=%%i

:: Detectar nombre del hotspot
for /f "tokens=2 delims=:" %%a in ('netsh wlan show interfaces ^| findstr /C:"SSID" ^| findstr /V "BSSID"') do set REACH=%%a
set REACH=%REACH:~1%

:: Carpeta destino
set DESTINO=C:\Users\varga\Documents\Proyectos\Horizontes\%REACH%\%FECHA%
if not exist "%DESTINO%" mkdir "%DESTINO%"

:: Script temporal para WinSCP
set WINSCP_SCRIPT=%TEMP%\script_winscp.txt
echo open sftp://reach:emlidreach@192.168.42.1 > "%WINSCP_SCRIPT%"
echo lcd "%DESTINO%" >> "%WINSCP_SCRIPT%"
echo cd /data/logs/ >> "%WINSCP_SCRIPT%"
echo get *.* >> "%WINSCP_SCRIPT%"
echo exit >> "%WINSCP_SCRIPT%"

:: Ejecutar transferencia
"C:\Program Files (x86)\WinSCP\WinSCP.com" /script="%WINSCP_SCRIPT%"

echo ===== Transferencia finalizada =====
echo Archivos guardados en: %DESTINO%
pause
