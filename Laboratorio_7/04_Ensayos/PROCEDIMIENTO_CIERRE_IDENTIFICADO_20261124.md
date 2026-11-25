# Procedimiento de cierre experimental del rediseño identificado

Este procedimiento completa la única evidencia que todavía no puede producirse sin el banco: las cuatro capturas físicas con el modelo identificado. El diseño, la prevalidación no ideal y la compilación de las cuatro configuraciones ya fueron completados. No reutilizar como si fueran nuevas las capturas nominales anteriores.

## Estado seguro inicial

- El fuente versionado queda en `LAB7_MODO_MONITOR`, variante E1 y con las cuatro autorizaciones en cero.
- Conectar y revisar la planta, la fuente, el límite de corriente, GND común, CH1=J5 y CH2=J7. Usar sondas 10X/DC.
- Confirmar que KitProg/PSoC y Rigol USB-TMC aparecen en la PC. Cerrar MATLAB y cualquier terminal que ocupe COM4.
- No habilitar lazo cerrado si alimentación, ADC/DAC, polaridad de J5/J7 o límites no fueron comprobados físicamente.

## Secuencia por cada caso

Ejecutar, en este orden, `pred_E1`, `actual_E1`, `pred_E2` y `actual_E2`. No avanzar si el caso anterior no resulta válido.

1. En `lab7_config.h`, seleccionar el modo (`PREDICCION` o `ACTUAL`) y la variante (E1 o E2). Poner en uno solamente `LAB7_PLANTA_VERIFICADA`, `LAB7_ADC_DAC_REVALIDADOS` y `LAB7_AUTORIZAR_LAZO_CERRADO` después de las verificaciones físicas. `LAB7_AUTORIZAR_ESCALON` no es necesario para estos cuatro casos.
2. Compilar el proyecto PSoC Creator y comprobar `Build Succeeded`. Programar la placa únicamente con el banco supervisado y la salida limitada.
3. Ejecutar `capturar_lab7_identificado_flanco_fisico.cmd`, elegir exactamente el caso programado, esperar `LISTO` y pulsar SW3 una vez.
4. El lanzador exige trigger físico sin `TFOR` y valida: modelo `LAB5_J5_J7`, firmware `ID_PREVALIDADO_OFFLINE`, diseño E1/E2 correcto, modo correcto, 256 filas, banderas cero, periodo mediano de 2 ms y CPU dentro del periodo.
5. Inspeccionar además `pantalla.png`, las formas de onda crudas y el cableado. Una validación automática no demuestra por sí sola que la punta estuviera en el nodo correcto.

Detener inmediatamente ante exceso de corriente, saturación repetida, oscilación anormal, `flags != 0` o una acción incompatible con el límite de ±120 mV. Toda captura rechazada se conserva solo como diagnóstico y no se incorpora al informe.

## Cierre y evidencia

Para cada caso válido, conservar la carpeta completa de `Capturas_Sincronizadas`: `pantalla.png`, `chan1.csv`, `chan2.csv`, `psoc_uart.txt`, `psoc_uart.csv` y `metadatos.json`. Después del cuarto ensayo, restaurar `LAB7_MODO_MONITOR`, variante E1 y autorizaciones en cero; recompilar para que el binario final también sea seguro.

Con las cuatro carpetas válidas ya se pueden regenerar las tablas y figuras experimental/simulado/calculado y reemplazar en el informe la declaración de límite experimental por los resultados medidos. Hasta entonces, eliminar esa salvedad sería afirmar evidencia que aún no existe.
