# Laboratorio 7 — Estimadores de estado de predicción y actual

**Guía rectora:** `00_Enunciado/Lab6_Estimadores_Enunciado.pdf`. El encabezado es erróneo pero la consigna es válida para este Laboratorio 7.

## Requisitos tomados de la guía oficial

1. Elegir y justificar el periodo de muestreo antes de discretizar.
2. Obtener el espacio de estados continuo y discreto; verificar observabilidad desde la salida medida.
3. Diseñar el controlador por realimentación de estados estimados con estimador de predicción y estimador actual.
4. Seleccionar polos de lazo cerrado y comparar **dos** ubicaciones de polos para cada tipo de estimador.
5. Implementar ambos compensadores en el PSoC usando exclusivamente estimaciones de estados.
6. Comparar dinámica del estimador, esfuerzo y diferencia MATLAB–experimento, con discusión y conclusiones.

## Estado de ejecución

- [x] Recuperación estructurada del Lab5 e instrumentación.
- [x] Guía oficial, estructura de proyecto, plan de ensayos y borrador LaTeX.
- [x] Núcleo genérico C de predictor y estimador actual (no conectado a hardware).
- [x] Script MATLAB de diseño/simulación preparado.
- [x] Modelo nominal conservado como referencia y modelo identificado adoptado para el diseño.
- [x] Muestreo de 2 ms verificado en cuatro ensayos; modelo identificado contrastado en lazo abierto.
- [x] Cadena ADC/DAC y polaridad verificadas en lazo abierto antes del cierre.
- [x] K, Nr, L_pred y L_actual rediseñadas directamente con el modelo identificado.
- [x] E1 seleccionado mediante 35 candidatas y prevalidación con ruido medido y cuantización.
- [x] Las cuatro ramas identificadas compilan en PSoC Creator 4.4; entrega final en MONITOR.
- [x] Cuatro ensayos identificados comparados contra cálculo ideal y simulación no ideal.
- [x] Estados estimados, errores observables y cuantización DAC documentados para los cuatro casos.
- [x] Cuatro ensayos físicos repetidos con los coeficientes del modelo identificado.
- [x] TopDesign, ADC, DAC, Timer, ISR y UART integrados y compilados para Lab7.
- [x] Ensayos en PSoC de ambas arquitecturas y ambos juegos de polos.
- [x] Datos crudos, gráficos, tablas, métricas e informe final reproducible.

## Consideraciones de implementación

El firmware final conserva límites de mando, detección de saturación, control de período y retorno a salida nula. Para repetir un ensayo debe verificarse primero el modo MONITOR, el cableado J5/J7, la masa común y la alimentación bipolar. La ley implementada es `u[k] = -K x_est[k] + Nr r[k]`.

La función matemática del observador actual usa la medición **de la misma muestra** para corregir la predicción antes de computar el control; la del predictor aplica la innovación para construir la estimación de **la muestra siguiente**.

## Modelo identificado para diseño

`modelo_lab7()` carga el modelo identificado por defecto. `modelo_lab7("nominal")` se reserva para comparaciones históricas. Ejecutar `lab7_principal` con Control System Toolbox para reproducir el diseño.

## Validación integrada

Ejecutar `01_Modelado_MATLAB/validar_resultados_integrados_lab7.m`. El script genera en `05_Resultados/Validacion_Integrada_20261124/`:

- comparación calculada, simulada y experimental de las cuatro configuraciones;
- coeficientes calculados sobre el modelo identificado;
- evolución experimental de `xhat1`, `xhat2` y `e_y=y-xhat2` para los cuatro casos;
- convergencia simulada del diseño identificado;
- análisis de cuántas solicitudes diferentes terminan en el mismo nivel del DAC.

La prevalidación se ejecuta con `prevalidar_rediseno_identificado_lab7`; terminó sin abortos operativos con E1 = 0.25 +/- j0.05. Las capturas físicas finales se encuentran en `04_Ensayos/Capturas_Sincronizadas/` y corresponden a Predictor E1, Actual E1, Predictor E2 y Actual E2. El PDF compilado de entrega se conserva en `output/pdf/`.
