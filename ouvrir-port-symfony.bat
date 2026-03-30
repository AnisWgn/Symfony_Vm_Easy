@echo off
REM Garantir System32 dans le PATH (certaines sessions "admin" ont un PATH minimal :
REM sinon chcp / net ne sont pas reconnus et le test d'elevation echoue a tort.)
set "PATH=%SystemRoot%\System32;%SystemRoot%;%PATH%"
"%SystemRoot%\System32\chcp.com" 65001 >nul 2>&1
setlocal EnableDelayedExpansion

title Symfony VM Easy - Pare-feu et serveur
cls

REM Ouvre le pare-feu, demande le chemin du projet ^(dossier du .bat ou saisie^), puis lance :
REM   symfony server:start --allow-all-ip --port=...
REM Usage : ouvrir-port-symfony.bat [PORT]
REM Exemple : ouvrir-port-symfony.bat 8080
REM A lancer en administrateur sur la VM Windows pour autoriser le trafic entrant.

set "PORT=%~1"
if "%PORT%"=="" set "PORT=8000"

set "RULE_NAME=Symfony dev - TCP !PORT!"
REM Barre de cadre (62 caracteres)
set "BAR==============================================================="

echo.
echo   +!BAR!+
echo   ^|  Symfony VM Easy                                          ^|
echo   ^|  Pare-feu Windows  +  Symfony CLI  ^(developpement VM^)   ^|
echo   +!BAR!+
echo.
echo   Port ecoute / pare-feu ...........  !PORT!
echo   Regle Windows ....................  !RULE_NAME!
echo.

echo   ------------------------------------------------------------------
echo    Etape 1 / 3   Pare-feu Windows
echo   ------------------------------------------------------------------
echo.

"%SystemRoot%\System32\net.exe" session >nul 2>&1
if errorlevel 1 (
    echo   [!]  Droits administrateur requis.
    echo       Clic droit sur ce fichier ^> Executer en tant qu'administrateur.
    echo.
    pause
    exit /b 1
)

"%SystemRoot%\System32\netsh.exe" advfirewall firewall delete rule name="!RULE_NAME!" >nul 2>&1
"%SystemRoot%\System32\netsh.exe" advfirewall firewall add rule name="!RULE_NAME!" dir=in action=allow protocol=TCP localport=!PORT!
if errorlevel 1 (
    echo   [!]  Impossible de creer la regle pare-feu ^(netsh^).
    echo.
    pause
    exit /b 1
)

echo   [ok]  Trafic TCP entrant autorise sur le port !PORT!.
echo.
call :attendre_ok

echo   ------------------------------------------------------------------
echo    Etape 2 / 3   Adresses IP de cette machine
echo   ------------------------------------------------------------------
echo   ^(utilisez celle du reseau partage avec l'hote^)
echo.
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /i "IPv4"') do echo          %%a
echo.
call :attendre_ok

echo   ------------------------------------------------------------------
echo    Etape 3 / 3   Projet Symfony
echo   ------------------------------------------------------------------
echo.

:etape_projet_chemin
echo   [1]  Utiliser le dossier ou se trouve ce fichier ^(.bat^)
echo   [2]  Saisir le chemin du projet ^(dossier contenant "public"^)
echo.
set /p CHOIX_PROJ=   Votre choix ^(1 ou 2, defaut 2^) : 
if "!CHOIX_PROJ!"=="" set "CHOIX_PROJ=2"
if /i "!CHOIX_PROJ!"=="1" (
    for %%I in ("%~dp0.") do set "SYMFONY_PROJECT=%%~fI"
    echo.
    echo   [i]  Chemin derive du fichier .bat ^: !SYMFONY_PROJECT!
) else if /i "!CHOIX_PROJ!"=="2" (
    set /p SYMFONY_PROJECT=   Chemin racine du projet ^(dossier contenant "public"^) : 
) else (
    echo.
    echo   [!]  Choix invalide ^(utilisez 1 ou 2^).
    echo.
    pause
    endlocal
    exit /b 1
)
if "!SYMFONY_PROJECT!"=="" (
    echo.
    echo   [!]  Aucun chemin saisi.
    echo.
    goto etape_projet_chemin
)
set "SYMFONY_PROJECT=!SYMFONY_PROJECT:"=!"
for %%I in ("!SYMFONY_PROJECT!") do set "SYMFONY_PROJECT=%%~fI"

:confirmer_chemin
echo.
echo   Chemin retenu ^(normalise^) :
echo       !SYMFONY_PROJECT!
set /p CONF_CHEMIN=   Ce chemin est-il correct ^(O^=oui / N^=non, rechoisir^) : 
if /i "!CONF_CHEMIN!"=="N" goto etape_projet_chemin
if /i "!CONF_CHEMIN!"=="NON" goto etape_projet_chemin
if /i "!CONF_CHEMIN!"=="O" goto chemin_confirme
if /i "!CONF_CHEMIN!"=="OUI" goto chemin_confirme
if /i "!CONF_CHEMIN!"=="Y" goto chemin_confirme
if /i "!CONF_CHEMIN!"=="YES" goto chemin_confirme
echo   [!]  Reponse attendue : O ^(oui^) ou N ^(non^).
goto confirmer_chemin

:chemin_confirme
if not exist "!SYMFONY_PROJECT!\public\" (
    echo.
    echo   [!]  Dossier "public" introuvable sous :
    echo       !SYMFONY_PROJECT!
    echo.
    pause
    endlocal
    exit /b 1
)

where symfony >nul 2>&1
if errorlevel 1 (
    echo.
    echo   [!]  Commande "symfony" introuvable dans le PATH.
    echo       Installez le Symfony CLI ^: https://symfony.com/download
    echo.
    pause
    endlocal
    exit /b 1
)

cd /d "!SYMFONY_PROJECT!" 2>nul
if errorlevel 1 (
    echo.
    echo   [!]  Acces impossible au dossier :
    echo       !SYMFONY_PROJECT!
    echo.
    pause
    endlocal
    exit /b 1
)

call :attendre_ok

echo.
echo   ------------------------------------------------------------------
echo    Demarrage du serveur
echo   ------------------------------------------------------------------
echo.
echo   Repertoire .... !CD!
echo   Commande ...... symfony server:start --allow-all-ip --port=!PORT!
echo   Depuis l'hote . http://^<IP_VM^>:!PORT!
echo   Arret ......... Ctrl+C dans cette fenetre
echo.
echo   +!BAR!+
echo.

symfony server:start --allow-all-ip --port=!PORT!

endlocal
exit /b 0

:attendre_ok
set "REP_OK="
set /p REP_OK=   Tapez OK pour passer a l'etape suivante : 
if /i not "!REP_OK!"=="OK" (
    echo   [!]  Reponse attendue : OK ^(sans guillemets^)
    goto attendre_ok
)
exit /b 0
