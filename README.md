# Laboratorio 7 — Automatización

**Control digital por realimentación de estados estimados: observadores de predicción y de estado actual**

**Autor:** Aldo Pastore  
**Carrera:** Ingeniería Electrónica  
**Facultad de Ciencias y Tecnología — Universidad Católica «Nuestra Señora de la Asunción»**

## Informe

[**Abrir Informe_Lab7_Automatizacion_Pastore_v1.pdf**](Informe_Lab7_Automatizacion_Pastore_v1.pdf)

Este repositorio independiente reúne la entrega académica del Laboratorio 7: modelo de planta, ubicación de polos, implementación de los estimadores en PSoC 5LP y evaluación de cuatro configuraciones sobre un mismo montaje experimental.

Se utilizó una referencia común de **50 mV** y un período de muestreo de **2 ms**. El informe distingue las simulaciones del modelo, la salida muestreada registrada por UART y las señales físicas adquiridas mediante el Rigol DS1202Z-E.

## Materiales

| Carpeta o archivo | Contenido |
|---|---|
| [`Informe_Lab7_Automatizacion_Pastore_v1.pdf`](Informe_Lab7_Automatizacion_Pastore_v1.pdf) | Informe académico completo, formato de dos columnas |
| [`main.tex`](main.tex), [`referencias.bib`](referencias.bib) | Fuentes editables para Overleaf y bibliografía |
| [`figuras/`](figuras/) | Gráficas de respuestas, mandos y comparaciones instrumentales |
| [`datos/comparacion_cuatro_ensayos.csv`](datos/comparacion_cuatro_ensayos.csv) | Síntesis numérica de las cuatro pruebas |
| [`datos/originales/`](datos/originales/) | Datos UART, canales físicos CH1/CH2 y metadatos originales de adquisición |
| [`anexos/reproducir_cuatro_ensayos_lab7.m`](anexos/reproducir_cuatro_ensayos_lab7.m) | Script MATLAB para reproducir la comparación de las cuatro salidas muestreadas |
| [`README_OVERLEAF.md`](README_OVERLEAF.md) | Instrucciones de compilación del informe |

## Cómo reproducir la comparación

En MATLAB, abrí `anexos/reproducir_cuatro_ensayos_lab7.m` y ejecutá el script desde el editor. La rutina localizará los CSV almacenados en `datos/originales/` y mostrará las cuatro respuestas, el sobrepasamiento, el tiempo de pico y la media final.

Para compilar el informe en Overleaf, cargá los archivos del repositorio como proyecto y seleccioná **pdfLaTeX** con `main.tex` como documento principal.

## Alcance de los resultados

Se estudiaron cuatro ejecuciones: Predictor E1 alternativo, Actual E1 alternativo, Predictor E2 original y Actual E2 original. Cada registro contiene 256 muestras, con cero banderas de error durante la ventana observada. Las capturas del osciloscopio usaron respaldo de disparo temporizado; los datos instrumentales se conservan tal como fueron registrados, incluidos los metadatos de sincronización.

La comparación es representativa de estas ejecuciones y no constituye una demostración de robustez global. Las curvas no se reescalaron para forzar coincidencia.

## Fuentes MATLAB y proyectos PSoC

- [**MATLAB: modelado, diseño, simulación y robustez**](Laboratorio_7/01_Modelado_MATLAB/README.md). Contiene todos los scripts `.m` propios de la práctica.
- [**PSoC 5LP y proyectos PSoC Creator**](Laboratorio_7/02_Firmware_PSoC_5LP/README.md). Incluye los dos proyectos, esquemáticos, archivos C/H, configuraciones y estimadores.
- [**Capturadores de los ensayos**](Laboratorio_7/04_Ensayos/). Comandos Windows para UART y Rigol.
- [**Herramientas Python USB/VISA y UART**](Herramientas_Comunes/Rigol_y_UART/README.md).

Las configuraciones de trabajo principales se entregan en MONITOR con las autorizaciones de control deshabilitadas. Los respaldos históricos conservan su configuración de origen y no deben programarse directamente. Los registros reales de los cuatro ensayos están en `datos/originales/`. Se conservan los nombres técnicos internos de las bibliotecas de hardware para no romper las referencias de los proyectos.
