# Lab7: captura sincronizada PSoC 5LP + Rigol DS1202Z-E

Este script reutiliza la logica de lab4_ensayo_sincronizado.py y lab5_captura_monitor_rigol.m, adaptada al protocolo UART real de Lab7. No programa el PSoC, no cambia el firmware y no desactiva protecciones.

## Preparacion

1. PSoC programado con modo ABIERTO para el primer ensayo. Preparar la alimentacion analogica y el cableado de planta como en el ensayo anterior con 256 muestras y flags=0.
2. CH1 del Rigol en J5, CH2 en J7 y ambas masas en el GND comun de PCB. Sondas fisicas 10X.
3. Conectar USB-TMC Rigol y KitProg/PSoC a la PC; cerrar MATLAB, terminales o programas que tengan abierto COM4. Python debe tener pyserial, pyvisa y numpy. Si falta algun modulo, instalarlo en el entorno correspondiente: python -m pip install pyserial pyvisa numpy.
4. Desde la raiz de git, ejecutar git pull --ff-only origin main.
5. Abrir Laboratorio_7/04_Ensayos/capturar_lab7_sincronizado.cmd mediante doble clic. Responder la etiqueta del ensayo, o usar la predeterminada 'abierto'.
6. Esperar el mensaje LISTO y pulsar SW3 una vez. No es necesario tocar SINGLE: el script lo hace automaticamente despues de detectar el arranque del PSoC.

## Comando alternativo desde PowerShell

    python -u ".\Herramientas_Comunes\Rigol_y_UART\lab7_ensayo_sincronizado.py" --modo-esperado ABIERTO --label abierto

Para observadores, tras compilar/programar por separado el firmware correspondiente, usar respectivamente:
- --modo-esperado PREDICCION --label pred_E1
- --modo-esperado PREDICCION --label pred_E2
- --modo-esperado ACTUAL --label actual_E1
- --modo-esperado ACTUAL --label actual_E2

El archivo CMD convierte estas etiquetas al modo esperado, pero no elige la variante de firmware: esa seleccion sigue haciendose en lab7_config.h, con compilacion y programacion explicitas.

## Sincronizacion exacta

El firmware Lab7 anuncia `# LAB7 inicio; ... espera 3s` antes de iniciar el temporizador. Al detectar ese aviso, Python arma `:SING` aproximadamente **2.25 s** después, para evitar el transitorio del RESET. A los **2.85 s** comprueba si ocurrió un disparo espurio temprano y, de ser así, vuelve a armar. A los **3.15 s** (cuando el pulso de k=32 ya comenzó), si el Rigol sigue `WAIT`/`RUN`/`AUTO`, manda **`:TFOR`** como respaldo temporizado, a la manera del Lab5. Si ya indica `STOP` o `TD`, conserva el disparo físico sin forzarlo. En ABIERTO el pulso va de 64 ms a 256 ms desde el inicio de adquisición, equivalente a 3.064-3.256 s después del anuncio. Con 50 ms/div se cubren aproximadamente 600 ms alrededor del disparo.

Configura CH1/CH2 a 20 mV/div y 50 ms/div horizontal, con flanco ascendente CH1 a 35 mV. El tiempo programado de `:TFOR` se registra en `sincronizacion.instante_TFOR_s`. Para evitar forzar el disparo usar `--sin-respaldo`. Si cambia el nivel de reposo, ajustar el umbral con `--nivel-trigger` (voltios absolutos), por ejemplo `0.045`.

## Archivos generados

Dentro de Laboratorio_7/04_Ensayos/Capturas_Sincronizadas/<fecha>_<etiqueta>/:
- pantalla.png: imagen original Rigol.
- chan1.csv y chan2.csv: muestras fisicas por canal y tiempos.
- psoc_uart.txt: salida UART completa, incluidas cabeceras.
- psoc_uart.csv: 256 filas esperadas, con columnas de tiempo, ADC, DAC, estados estimados y flags.
- metadatos.json: modo solicitado/detectado, filas, errores, tiempos, estado de trigger y evaluacion preliminar.

VALIDACION PRELIMINAR: True significa que coincidió el modo, llegaron 256 filas con flags=0, `SINGLE` terminó en STOP y, en ABIERTO, se detectó en CH1 **una meseta de al menos 20 mV durante 100 ms**. El método se guarda explícitamente como `sincronizacion.disparo_forzado` y `configuracion_rigol.trigger_forzado`. Con `:TFOR` el campo `trigger_fisico_confirmado` debe ser falso, aunque se haya medido un pulso válido. No equivale a validación metrológica completa; el operador debe verificar CH1=J5, CH2=J7 y rangos físicos.

Si no hay flanco y se utiliza :TFOR, el script guarda el evento *si aparece físicamente en la ventana*. Si no hay meseta, lo marca no válido y lo conserva como diagnóstico. No declarar ganancia ni constantes de tiempo a partir de capturas que solo contienen ruido. El script no puede comprobar por sí solo el nodo al que conectaste la sonda.

El capturador base fue ejercitado con simulaciones de COM4/Rigol y con capturas físicas históricas. Para las cuatro repeticiones del rediseño identificado usar `capturar_lab7_identificado_flanco_fisico.cmd`, que añade la comprobación estricta de modelo, firmware, diseño y trigger físico.

## Comprobaciones previas al uso

- El programa no modifica firmware. Los modos `PREDICCION` y `ACTUAL` solo se ensayan después de compilar y programar el PSoC para cada variante, manteniendo límites y protecciones.
- Cerrar MATLAB o cualquier cliente que ocupe COM4/USB VISA antes de ejecutar. Si parece detenido en «Conectando RIGOL USB VISA...», cerrar el proceso anterior con Ctrl+C y comprobar que ningún otro programa use el instrumento.
- Ejecución explícita con recurso exacto y respaldo activado:

```powershell
python -u ".\Herramientas_Comunes\Rigol_y_UART\lab7_ensayo_sincronizado.py" --resource "USB0::0x1AB1::0x0517::DS1ZE275014864::INSTR" --modo-esperado ABIERTO --label abierto_respaldo
```

- Prueba aislada sin respaldo (solo flanco real): agregar `--sin-respaldo`.

## Pruebas de regresión sin hardware

La lógica de sincronización se ejercitó con un puerto serie simulado y un Rigol simulado: escenario con flanco físico (no debe emitir TFOR) y sin flanco (debe emitir un solo TFOR a 3.15 s). El detector separó correctamente las dos trazas reales subidas por el usuario: pulso anterior de aproximadamente 45 mV y captura posterior solo con ruido. La versión con respaldo publicada requiere todavía una ejecución instrumental real.

## 2026-11-24 — Actualización: ventana temporizada y reducción de ruido

Ante la evidencia de que el Rigol se detenía en STOP sin un pulso válido mientras UART sí mostraba las 256 muestras, el **modo predeterminado ahora es `--estrategia temporizada`**. Configura `:ACQ:TYPE HRES` para reducir ruido aleatorio en la traza única, y un umbral de 85 mV en CH1 (mayor que el escalón ABIERTO esperado en J5, menor que el rango de disparo de ±5 divisiones a 20 mV/div). No depende de cruces espurios del umbral cercano a 35 mV.

Temporización basada en el anuncio `# LAB7 inicio` (que precede la espera de 3 s):

- A 2,25 s: `:SING`, el Rigol queda esperando.
- A 2,85 s: si terminó por ruido, rearma.
- A 3,025 s: si sigue WAIT, envía `:TFOR`; el pulso ABIERTO inicia aprox. 3,064 s y termina en 3,256 s. La ventana del Rigol de ±300 ms alrededor del disparo contiene ambas transiciones, si no hay desfase inesperado.

**Nunca confundir `:TFOR` con un escalón físico generado por el instrumento:** `:TFOR` solo detiene la adquisición; el pulso lo genera el PSoC. El script continúa exigiendo pulso sostenido en CH1, 256 muestras y banderas en cero.

Si es necesario volver a la estrategia anterior por flanco, usar `--estrategia fisica --nivel-trigger 0.035 --instante-respaldo 3.025`. El lanzador CMD de Lab7 usa la estrategia temporizada por defecto. Importante: si el programa informa STOP antes de 3,025 s y no guarda el escalón, comprobar la posición CH1=J5, el cableado y las escalas; aumentar más el umbral podría superar el rango del trigger de 20 mV/div.

La implementación de captura está revisada en el repositorio. La campaña física identificada se ejecuta siguiendo `PROCEDIMIENTO_CIERRE_IDENTIFICADO_20261124.md`; mientras no existan sus cuatro carpetas válidas, las capturas nominales previas se conservan únicamente como línea de base.

## 2026-11-24 — Contraste y ruido: comparación cuantitativa Lab5/Lab7

Revisados los CSV originales de Lab5, ensayo `lab5_identificado_TS1_deadbeat_50mV_zerocorr_final_20261121_175752` (ventana 40–80ms), y captura Lab7 `20261124_004102` (meseta estable 65–180ms).

- Lab5 CH1 8.44mV desviación estándar; CH2 5.79mV. Configuración Lab5: CH1=50mV/div, CH2=20mV/div y HRES, BW20M.
- Lab7 CH1 3.00mV; CH2 11.57mV. Antes del ajuste, CH1 y CH2 = 20mV/div, HRES, BW20M. Ambos conjuntos comparados son de modos diferentes (control en Lab5 vs abierto Lab7); las desviaciones incluyen posibles variaciones reales de la señal, no son por sí solas una medida metrológica de ruido de osciloscopio.
- La nueva versión del script usa de forma predeterminada CH1=50mV/div, CH2=20mV/div y **no sobrescribe el offset vertical** durante la configuración. Separar las trazas con las perillas POSITION del Rigol y conservar la disposición entre capturas. El límite de banda y HRES ya coincidían con Lab5, por lo que su mera activación no explica el ruido residual CH2.
- Prueba de aislamiento sin barrido de calibración: con la alimentación apagada mover la punta de CH2 de J7 a GND del mismo punto de la PCB, mantener clip de masa en GND, reencender y observar la dispersión. Si el ruido disminuye mucho, está en J7/la ruta de medida/cableado; si persiste, investigar sonda/masa/USB/masa compartida. Volver a J7 con la alimentación apagada.
- Evitar afirmar que PNG filtrado o gráficos suavizados reflejan una mejora física; conservar siempre la traza cruda. Los CSV de pantalla solo contienen 1200 puntos cada uno, y el ruido rápido puede estar submuestreado/aliased; no adjudicar su frecuencia sin adquisición más rápida.
