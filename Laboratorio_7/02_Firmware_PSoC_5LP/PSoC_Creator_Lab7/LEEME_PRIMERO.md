# LABORATORIO 7 — PSoC Creator 4.4

Proyecto CLONADO de Lab5: **Lab7.cywrk**, carpeta **Lab7.cydsn/**.

## Lo que hace hoy

- Conserva TopDesign y pinout del Lab5, sin modificar ADC, DAC_P, DAC_N, UART_Debug, Timer_TS, isr ni registro.
- El nombre del proyecto y del workspace pasa a **Lab7**, y se añade código fuente independiente (main.c y lab7_estimadores.c/.h, lab7_config.h).
- El modo predeterminado es **MONITOR**, salida digital de DAC a cero, sin realimentación.
- Incorpora **LAZO_ABIERTO** con escalón de +50mV, bloqueo de autorización, y modos PREDICCION/ACTUAL E1/E2 que permanecerán bloqueados hasta validar la planta física.
- El Timer usa 200 cuentas con Clock_1 histórico de 100kHz, **Ts nominal=2ms**, verificar con Rigol.

## PROCEDIMIENTO EN WINDOWS (sin conectar la planta al DAC en la primera programación)

1. Con la alimentación de la PCB APAGADA, desconectá **temporalmente J8–J5**. Dejás J5 referenciado a GND por una resistencia apropiada si necesitás una medición de reposo; no energices con entrada flotante.
2. Copiá este directorio al destino `...\Automatizacion\git\Laboratorio_7\02_Firmware_PSoC_5LP\PSoC_Creator_Lab7\` o realizá `git pull` si ya se publicó.
3. En PSoC Creator 4.4, **File → Open → Project/Workspace**, abrí `Lab7.cywrk` y comprobá que la solución se llame Lab7.
4. Abrí `TopDesign.cysch` y verificá que el microcontrolador seleccionado se corresponda con tu placa; no renombres componentes periféricos internos todavía.
5. Abrí `lab7_config.h`; confirmá `LAB7_MODO = LAB7_MODO_MONITOR` y los enclavamientos en 0.
6. Ejecutá **Build → Generate Application** y luego **Build → Build Lab7**. No tengo PSoC Creator disponible aquí para verificar la generación real; si aparece un error, enviame el texto del primer error de compilación.
7. Programa la PSoC mientras J8–J5 permanece aislado. Confirmá por UART COM4 (57600, 8N1): `# LAB7 inicio` y encabezado `modo=MONITOR`.
8. El sistema almacena 256 muestras a 2ms (512ms), luego envía CSV y deja los DAC en código cero. Los valores de planta se deducen de calibración histórica y NO están revalidados.
9. Confirmá tensión J5/J7 y el tiempo real de muestreo sin activar el lazo. Reconectá J8–J5 solo después de verificar que la salida es de valor seguro y con el equipo apagado.

## Ensayo de respuesta en lazo abierto (siguiente etapa)

- Solo tras confirmación física, en `lab7_config.h` cambiar:
  `LAB7_MODO LAB7_MODO_LAZO_ABIERTO` y `LAB7_AUTORIZAR_ESCALON (1u)`.
- Compilar, programar y medir CH1/J5 y CH2/J7.
- Escalón solicitado de 0 a +0.05V en k=32 (t=64ms), retorno a cero en k=128 (t=256ms), Ts=2ms. El DAC real se cuantiza y el offset de J5 puede ser diferente; usar la **tensión efectiva J5**, no 50mV ideales, para comparar con el modelo.
- No habilitar PREDICCION/ACTUAL hasta obtener una identificación física razonable y revisar la calibración de los convertidores.

## Nota sobre nombres de componentes

Las instancias **ADC**, **DAC_P**, **DAC_N**, **Timer_TS**, **UART_Debug**, etc., mantienen sus nombres originales para preservar las APIs de Cypress y evitar fallas. Si querés etiquetas visuales "Lab7", agregalas como *Annotations* en TopDesign; renombrar las instancias requiere refactorizar todo el código C y regenerar componentes.

## Alcance de la validación

Se comprobó estructura XML (parseo), referencias a archivos, y se compiló el núcleo matemático con GCC de forma aislada. La compilación de PSoC Creator y la ejecución sobre hardware se deben realizar en tu computadora.
