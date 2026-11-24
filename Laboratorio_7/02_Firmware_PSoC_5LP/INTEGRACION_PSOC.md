# Integración pendiente con PSoC Creator 4.4

`lab7_estimadores.c/.h` implementan matemáticamente **los dos estimadores** y una ley común `u=-K*x_estimado+Nr*r`. El código no contiene referencias a bibliotecas Cypress ni acciones de E/S: puede compilarse con GCC para comprobar operaciones, pero **no es un firmware programable por sí solo**.

## Orden sugerido dentro de la ISR de tiempo de muestreo

1. Adquirir `salida_medida_V` desde la conversión ADC completada y convertir a unidades físicas con la **calibración vigente de Lab7**.
2. Ejecutar `lab7_calcular_paso()` usando la arquitectura de estimador y las matrices A,B,C,K,L,Nr diseñadas y **exportadas desde MATLAB**.
3. Convertir `u_aplicado_V` a códigos DAC (dos ramas si corresponde) y mantener límites adecuados. La salida física real puede diferir del código solicitado: incluir calibración del actuador.
4. Registrar `(k, Ts, referencia, y_raw, y_cal, xhat_1, xhat_2, u_solicitado, u_aplicado, innovacion, saturaciones, ISR_us)` en búfer de telemetría; no bloquear la ISR transmitiendo UART.
5. Confirmar tiempos de ISR con pin externo y osciloscopio Rigol DS1202Z-E; detener por error de ADC, muestras vencidas o saturación repetitiva.

## Arquitecturas y sincronización

**Predicción:** el control de la muestra k usa `xhat[k]` proveniente del instante anterior. La innovación de `y[k]` entra a `xhat[k+1]`.

**Actual:** primero corrige la predicción con la medición actual `y[k]`, después calcula el control de esa muestra y genera la predicción siguiente. El modelo de cálculo debe caber en el periodo muestreado.

## Compilación opcional del núcleo sin PSoC

```bash
gcc -std=c99 -Wall -Wextra -pedantic -o test_portable test_portable.c lab7_estimadores.c -lm
./test_portable
```

**Advertencia:** el ejemplo `test_portable.c` usa números artificiales para comprobar aritmética; no son coeficientes ni resultados físicos del Lab7. No conectar al actuador antes de implementar el proyecto PSoC completo y realizar las pruebas de seguridad.
