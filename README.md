# Laboratorio 7 — Automatización

**Control digital mediante realimentación de estados estimados: observadores de predicción y de estado actual**

**Autor:** Aldo Pastore  
**Carrera:** Ingeniería Electrónica  
**Facultad de Ciencias y Tecnología — Universidad Católica «Nuestra Señora de la Asunción»**

## Informe

[**Abrir Informe_Lab7_Automatizacion_Pastore_v1.pdf**](Informe_Lab7_Automatizacion_Pastore_v1.pdf)

Este repositorio independiente contiene exclusivamente la entrega académica del Laboratorio 7: fundamentos matemáticos, diseño de observadores, experimentación con PSoC 5LP y comparación de cuatro configuraciones a partir de señales adquiridas por UART y Rigol DS1202Z-E.

El ensayo emplea una referencia de 50 mV y un período de muestreo de 2 ms.

## Archivos de entrega

| Ruta | Descripción |
|---|---|
| `Informe_Lab7_Automatizacion_Pastore_v1.pdf` | Informe final en formato académico |
| `main.tex`, `referencias.bib` | Fuentes LaTeX para Overleaf |
| `figuras/` | Gráficas experimentales y comparativas |
| `datos/comparacion_cuatro_ensayos.csv` | Indicadores numéricos de los cuatro ensayos |
| `datos/originales/` | CSV y metadatos de las adquisiciones originales |
| `anexos/reproducir_cuatro_ensayos_lab7.m` | Script MATLAB de reproducción |
| `README_OVERLEAF.md` | Instrucciones para compilar el informe |

## Reproducibilidad y alcance

Se preservan los registros instrumentales originales de Predictor E1, Actual E1, Predictor E2 y Actual E2. Las gráficas del informe distinguen las señales registradas de las simuladas. Las conclusiones corresponden al alcance de los ensayos efectuados y no constituyen una certificación de robustez para cualquier condición operativa.
