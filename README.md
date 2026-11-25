# Laboratorio 7 — Automatización

**Control digital por realimentación de estados estimados: observadores de predicción y de estado actual**

**Autor:** Aldo Pastore  
**Carrera:** Ingeniería Electrónica  
**Universidad Católica «Nuestra Señora de la Asunción»**

## Informe

[**Abrir el informe compilado**](Informe_Lab7_Automatizacion_Aldo_Pastore_v2.pdf)

El trabajo estudia cuatro configuraciones de control digital sobre la misma
planta de segundo orden: Predictor E1, Actual E1, Predictor E2 y Actual E2.
El controlador y los estimadores se diseñaron con el modelo identificado de la
planta, con período de muestreo de **2 ms** y referencia común de **50 mV**.

El informe presenta en forma conjunta los resultados calculados, simulados y
experimentales; la evolución de los estados estimados y de sus errores; la
convergencia de los observadores; el esfuerzo de control; la cuantización del
DAC y las mediciones físicas de J5 y J7.

## Contenido del repositorio

| Ruta | Contenido |
|---|---|
| [`main.tex`](main.tex) y [`secciones/`](secciones/) | Fuente LaTeX editable del informe principal |
| [`Laboratorio_7/01_Modelado_MATLAB/`](Laboratorio_7/01_Modelado_MATLAB/) | Modelado, diseño, simulación y validación en MATLAB |
| [`Laboratorio_7/02_Firmware_PSoC_5LP/`](Laboratorio_7/02_Firmware_PSoC_5LP/) | Proyectos PSoC Creator, esquemáticos y fuentes C/H |
| [`Laboratorio_7/04_Ensayos/`](Laboratorio_7/04_Ensayos/) | Procedimientos, capturadores y datos primarios del banco |
| [`Laboratorio_7/05_Resultados/`](Laboratorio_7/05_Resultados/) | Tablas, métricas y figuras reproducibles |
| [`Laboratorio_7/06_Informe_IEEE/`](Laboratorio_7/06_Informe_IEEE/) | Copia estructurada de las fuentes del informe |
| [`Laboratorio_7/output/pdf/`](Laboratorio_7/output/pdf/) | PDF compilado dentro del árbol de trabajo |

## Evidencia experimental

Las capturas sincronizadas definitivas están disponibles en:

- [`Predictor E1`](Laboratorio_7/04_Ensayos/Capturas_Sincronizadas/20261124_221144_972_pred_E1_identificado/)
- [`Actual E1`](Laboratorio_7/04_Ensayos/Capturas_Sincronizadas/20261124_221418_036_actual_E1_identificado/)
- [`Predictor E2`](Laboratorio_7/04_Ensayos/Capturas_Sincronizadas/20261124_221547_931_pred_E2_identificado/)
- [`Actual E2`](Laboratorio_7/04_Ensayos/Capturas_Sincronizadas/20261124_221705_548_actual_E2_identificado/)

Cada carpeta conserva los CSV originales de **CH1/J5** y **CH2/J7**, la
pantalla del Rigol, los metadatos de adquisición y la telemetría UART del PSoC.
Las capturas independientes de diagnóstico y del escalón abierto se mantienen
en [`Capturas_Rigol/`](Laboratorio_7/04_Ensayos/Capturas_Rigol/).

## Reproducción

En MATLAB, ejecutar:

```matlab
cd Laboratorio_7/01_Modelado_MATLAB
validar_resultados_integrados_lab7
```

La rutina reconstruye las tablas y figuras de
[`Validacion_Integrada_20261124`](Laboratorio_7/05_Resultados/Validacion_Integrada_20261124/).

El proyecto principal de PSoC Creator se encuentra en
[`PSoC_Creator_Lab7`](Laboratorio_7/02_Firmware_PSoC_5LP/PSoC_Creator_Lab7/).
Los artefactos automáticos de compilación no se versionan; los proyectos,
esquemáticos y fuentes necesarios para recompilar sí están incluidos.

Para compilar el informe desde la raíz:

```bash
pdflatex -interaction=nonstopmode main.tex
pdflatex -interaction=nonstopmode main.tex
```

También puede importarse el repositorio completo en Overleaf conservando su
estructura de carpetas.
