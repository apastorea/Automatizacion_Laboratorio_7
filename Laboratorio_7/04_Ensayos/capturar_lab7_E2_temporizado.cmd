@echo off
setlocal
cd /d "%~dp0..\.."
echo ================================================================
echo   LABORATORIO 7 - E2 - CAPTURA TEMPORIZADA RIGOL + PSOC
echo ================================================================
echo   Este metodo busca evitar disparos prematuros por ruido en CH1.
echo   CH1=J5, CH2=J7; 10X/DC, GND comun.
echo   SOLO para firmware E2 ya programado. No programa PSoC.
echo   Confirmar alimentacion y limites de corriente; banco supervisado.
echo   Cerrar MATLAB/terminales que tengan COM4 abierto.
echo   ESPERAR "LISTO" y recien entonces pulsar SW3 una vez.
echo   Umbral 85 mV y TFOR 3.025 s si el disparo no sucedio.
echo.
set "NOMBRE=pred_E2"
set /p "NOMBRE=Etiqueta (pred_E2/actual_E2) [pred_E2]: "
if not defined NOMBRE set "NOMBRE=pred_E2"
set "MODO="
if /i "%NOMBRE%"=="pred_E2" set "MODO=PREDICCION"
if /i "%NOMBRE%"=="actual_E2" set "MODO=ACTUAL"
if not defined MODO (
 echo ERROR: elegir pred_E2 o actual_E2.
 pause
 exit /b 2
)
echo.
python -u ".\Herramientas_Comunes\Rigol_y_UART\lab7_ensayo_sincronizado.py" --resource "USB0::0x1AB1::0x0517::DS1ZE275014864::INSTR" --modo-esperado "%MODO%" --label "%NOMBRE%" --demora-armado 2.25 --instante-rearme 2.85 --instante-respaldo 3.025 --estrategia temporizada --nivel-temporizado 0.085
if errorlevel 1 (
 echo.
 echo ATENCION: captura incompleta o no validada. Revisar metadatos.json.
) else (
 echo.
 echo Captura finalizada. Verificar pulso_ch1_detectado en metadatos.json.
)
echo.
pause
endlocal
