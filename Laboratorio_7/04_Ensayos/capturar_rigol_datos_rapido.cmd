@echo off
setlocal
cd /d "%~dp0..\.."
echo =========================================================
echo   LAB7 - RIGOL DS1202Z-E - CAPTURA RAPIDA PNG + CSV
echo =========================================================
echo Compruebe antes: Rigol en STOP tras SINGLE; CH1=J5, CH2=J7.
echo Se guardaran pantalla.png, chan1.csv, chan2.csv y metadatos.json.
echo.
python -u ".\Herramientas_Comunes\Rigol_y_UART\rigol_ds1202ze.py" bundle --quick --only all --label lab7_png_csv --root ".\Laboratorio_7\04_Ensayos\Capturas_Rigol"
if errorlevel 1 (
  echo.
  echo ERROR: no se pudo completar la captura. Revise el mensaje anterior.
) else (
  echo.
  echo Captura terminada. El PNG y los CSV estan en 04_Ensayos\Capturas_Rigol.
)
echo.
pause
endlocal
