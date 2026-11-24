@echo off
setlocal
cd /d "%~dp0..\.."
echo ================================================================
echo LABORATORIO 7 - E2 - RIGOL + PSOC, DISPARO FISICO
echo ================================================================
echo Preparar CH1=J5, CH2=J7, ambas sondas 10X, DC, GND comun.
echo REQUIERE el firmware E2 correctamente programado, banco supervisado.
echo Cierre MATLAB y otras terminales que tengan COM4 abierto.
echo Este modo usa umbral inicial de 35 mV y respaldo TFOR.
echo Si los niveles absolutos de CH1 cambian, revisar antes de usar.
echo.
set "NOMBRE=pred_E2"
set /p "NOMBRE=Etiqueta (pred_E2/actual_E2) [pred_E2]: "
if not defined NOMBRE set "NOMBRE=pred_E2"
set "MODO="
if /i "%NOMBRE%"=="pred_E2" set "MODO=PREDICCION"
if /i "%NOMBRE%"=="actual_E2" set "MODO=ACTUAL"
if not defined MODO (
 echo ERROR: Elija pred_E2 o actual_E2; no se realizo captura.
 pause
 exit /b 2
)
echo.
echo Primero debe aparecer LISTO. En ese momento pulse SW3 una vez.
echo Si hay oscilacion anormal o exceso de corriente, detenga el ensayo.
echo La carpeta queda en 04_Ensayos\Capturas_Sincronizadas.
echo.
python -u ".\Herramientas_Comunes\Rigol_y_UART\lab7_ensayo_sincronizado.py" --resource "USB0::0x1AB1::0x0517::DS1ZE275014864::INSTR" --modo-esperado "%MODO%" --label "%NOMBRE%" --demora-armado 2.25 --instante-respaldo 3.025 --estrategia fisica --nivel-trigger 0.035
if errorlevel 1 (
 echo.
 echo AVISO: error o captura no verificada. Revisar mensajes y metadatos.json.
) else (
 echo.
 echo Captura terminada: verificar modo UART y etiqueta diseno_E2=ORIG_Z020_J010.
)
echo.
pause
endlocal
