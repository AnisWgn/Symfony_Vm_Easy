@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

REM Port par défaut du serveur Symfony (symfony server:start / php -S)
REM Usage : ouvrir-port-symfony.bat [PORT]
REM Exemple : ouvrir-port-symfony.bat 8080
REM À lancer en administrateur sur la VM Windows pour autoriser le trafic entrant.

set "PORT=%~1"
if "%PORT%"=="" set "PORT=8000"

set "RULE_NAME=Symfony dev - TCP !PORT!"

echo.
echo === Ouverture du pare-feu Windows pour le port !PORT! ===
echo Règle : !RULE_NAME!
echo.

net session >nul 2>&1
if errorlevel 1 (
    echo [ERREUR] Ce script doit etre execute en tant qu'administrateur ^(clic droit ^> Executer en tant qu'administrateur^).
    pause
    exit /b 1
)

netsh advfirewall firewall delete rule name="!RULE_NAME!" >nul 2>&1
netsh advfirewall firewall add rule name="!RULE_NAME!" dir=in action=allow protocol=TCP localport=!PORT!
if errorlevel 1 (
    echo [ERREUR] Impossible d'ajouter la regle pare-feu.
    pause
    exit /b 1
)

echo [OK] Regle pare-feu ajoutee pour TCP entrant sur le port !PORT!.
echo.
echo --- Adresses IP de cette VM ^(utilisez celle du reseau partage avec l'hote^) ---
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /i "IPv4"') do echo   %%a
echo.
echo --- Rappel Symfony ---
echo Lancez le serveur en ecoutant sur toutes les interfaces, par exemple :
echo   symfony server:start --listen-ip=0.0.0.0 --port=!PORT!
echo ou :
echo   php -S 0.0.0.0:!PORT! -t public
echo.
echo Sur l'hote, ouvrez : http://^<IP_VM^>:!PORT!
echo Si l'acces echoue, configurez aussi le transfert de ports dans VirtualBox/VMware/Hyper-V.
echo.
pause
endlocal
