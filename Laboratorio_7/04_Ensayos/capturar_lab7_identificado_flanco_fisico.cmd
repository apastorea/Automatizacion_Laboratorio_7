@echo off
setlocal
cd /d "%~dp0..\.."
echo ================================================================
echo LABORATORIO 7 - CUATRO CASOS IDENTIFICADOS - TRIGGER FISICO
echo ================================================================
echo CH1=J5, CH2=J7, sondas 10X/DC y GND comun.
echo Requiere banco supervisado y el firmware del caso ya programado.
echo No usa TFOR: una captura sin flanco fisico sera rechazada.
echo Cierre MATLAB y otras terminales que tengan COM4 abierto.
echo.
set "CASO=pred_E1"
set /p "CASO=Caso (pred_E1/actual_E1/pred_E2/actual_E2) [pred_E1]: "
if not defined CASO set "CASO=pred_E1"
set "MODO="
set "ESTIMADOR="
if /i "%CASO%"=="pred_E1" (
 set "MODO=PREDICCION"
 set "ESTIMADOR=E1"
)
if /i "%CASO%"=="actual_E1" (
 set "MODO=ACTUAL"
 set "ESTIMADOR=E1"
)
if /i "%CASO%"=="pred_E2" (
 set "MODO=PREDICCION"
 set "ESTIMADOR=E2"
)
if /i "%CASO%"=="actual_E2" (
 set "MODO=ACTUAL"
 set "ESTIMADOR=E2"
)
if not defined MODO (
 echo ERROR: caso no reconocido; no se realizo captura.
 pause
 exit /b 2
)
echo.
echo Caso solicitado: %CASO% ^(modo %MODO%, estimador %ESTIMADOR%^).
echo Confirme en lab7_config.h el mismo modo/estimador ANTES de programar.
echo Al aparecer LISTO, pulse SW3 una sola vez.
echo Detenga el banco ante oscilacion anormal o exceso de corriente.
echo.
python -u ".\Herramientas_Comunes\Rigol_y_UART\lab7_ensayo_sincronizado.py" --resource "USB0::0x1AB1::0x0517::DS1ZE275014864::INSTR" --modo-esperado "%MODO%" --label "%CASO%_identificado" --demora-armado 2.25 --instante-rearme 2.85 --instante-respaldo 3.025 --estrategia fisica --nivel-trigger 0.035 --sin-respaldo
if errorlevel 1 goto captura_error
for /f "delims=" %%D in ('powershell -NoProfile -Command "Get-ChildItem -LiteralPath '.\Laboratorio_7\04_Ensayos\Capturas_Sincronizadas' -Directory ^| Sort-Object LastWriteTime -Descending ^| Select-Object -First 1 -ExpandProperty FullName"') do set "CAPTURA=%%D"
if not defined CAPTURA goto captura_error
python -u ".\Laboratorio_7\04_Ensayos\validar_captura_identificada_lab7.py" "%CAPTURA%" --modo "%MODO%" --estimador "%ESTIMADOR%"
if errorlevel 1 goto validacion_error
echo.
echo RESULTADO: captura identificada aceptada por las comprobaciones automaticas.
echo Revise tambien pantalla.png y la conexion fisica de las sondas.
goto fin

:captura_error
echo.
echo RESULTADO: captura incompleta. Conservar la carpeta solo como diagnostico.
goto fallo

:validacion_error
echo.
echo RESULTADO: captura rechazada. No usarla en tablas ni conclusiones.

:fallo
echo Corrija la causa antes de avanzar al caso siguiente.
pause
exit /b 1

:fin
echo.
pause
exit /b 0
