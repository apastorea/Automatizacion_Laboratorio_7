# Lab7 — Preparación E1 alternativo (NO habilitar control cerrado)

Fuentes: los archivos `main(2).c` y `lab7_config.h` suministrados por el usuario el 24-11-2026. Las carpetas `Originales` contienen copias sin cambios y `Propuesta` contiene las modificaciones para revisar; no se reemplaza el PSoC Creator local.

**Diseño candidato:** polos E1 `0.35 +/- j0.10` con `Lpred=[-1.31786653;0.43877046]` y `Lactual=[-1.50583491;0.42564406]`. K y Nr intactos. La arquitectura de estimadores y E2 tampoco se modifican.

**Seguridad:** la configuración propuesta inicia en modo MONITOR, `LAB7_AUTORIZAR_ESCALON=0` y todos los permisos de control cerrado = 0. Cambiar únicamente a PREDICCION o ACTUAL debe producir `#error CONTROL BLOQUEADO`. En ambos casos el firmware no está todavía autorizado para accionar la planta.

**Límite físico DAC:** al redondear el mando pedido de +120 mV a código 8, la HAL histórica de Lab5 podría aplicar nominalmente +122.963584 mV. Se limita preventivamente la solicitud a +107 mV (código 7; +107.593136 mV nominal) y -115 mV (código 11; -116.16465 mV nominal), y se verifica después de la HAL que el valor nominal no exceda ±120 mV. Se detiene con F_LIMITE ante saturación de control o superación nominal del DAC.

**Pruebas offline:** GCC C99 con interfaces PSoC simuladas, compilación sintáctica correcta en MONITOR/PREDICCION/ACTUAL (en los dos últimos casos solo al habilitar macros en copias temporales), bloqueo del control con macros sin habilitar, y aritmética de códigos 7/11. No se ha compilado en PSoC Creator ni programado hardware con estos archivos. Confirmar antes el contenido ACTIVO de `lab5_hardware.c`, `lab5_config.h` y `TopDesign` porque la HAL del repositorio podría no coincidir con el proyecto real.

Para instrucciones completas y archivo diff, utilizar el paquete ZIP adjunto en la conversación. Al mover archivos al proyecto PSoC, crear primero una copia independiente y hacer pruebas MONITOR con DAC=0. No habilitar lazo cerrado automáticamente.