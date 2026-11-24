@echo off
setlocal
cd /d "%~dp0..\.."
echo ================================================================
echo      LABORATORIO 7 - CAPTURA SINCRONIZADA RIGOL + PSOC
echo ================================================================
echo  CH1=J5, CH2=J7; masa comun; configuracion de Lab7.
echo  Cierre MATLAB/terminales que tengan COM4 abierto.
echo  Al ver LISTO pulse una vez SW3 del KitProg.
echo  Armado: 2.25 s despues del anuncio. TFOR programado: 3.025 s.
echo.
set "NOMBRE=abierto"
set /p "NOMBRE=Etiqueta (abierto/pred_E1/pred_E2/actual_E1/actual_E2) [abierto]: "
if not defined NOMBRE set "NOMBRE=abierto"
set "MODO=ABIERTO"
if /i "%NOMBRE%"=="pred_E1" set "MODO=PREDICCION"
if /i "%NOMBRE%"=="pred_E2" set "MODO=PREDICCION"
if /i "%NOMBRE%"=="actual_E1" set "MODO=ACTUAL"
if /i "%NOMBRE%"=="actual_E2" set "MODO=ACTUAL"
python -u ".\Herramientas_Comunes\Rigol_y_UART\lab7_ensayo_sincronizado.py" --resource "USB0::0x1AB1::0x0517::DS1ZE275014864::INSTR" --modo-esperado "%MODO%" --label "%NOMBRE%" --demora-armado 2.25 --instante-respaldo 3.025 --estrategia temporizada
if errorlevel 1 (
 echo.
 echo Error o captura incompleta. Ver mensajes y metadatos.json.
) else (
 echo.
 echo Captura finalizada. Revise el aviso de validacion.
)
echo.
pause
endlocal
