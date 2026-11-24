# Firmware y PSoC Creator — Laboratorio 7

Contiene proyectos completos para PSoC 5LP: fuentes C/H, esquemáticos `TopDesign.cysch`, archivos de recursos `.cydwr` y proyectos `.cyprj`.

- [Proyecto base](PSoC_Creator_Lab7/Lab7.cywrk), con fuentes en `PSoC_Creator_Lab7/Lab7.cydsn/`.
- [Proyecto de los observadores E1/E2](Preparacion_E1_Alternativo/Lab7_E1_Alternativo.cydsn/Lab7_E1_Alternativo.cyprj). Los archivos `main.c` y `lab7_config.h` están enlazados desde `../Propuesta/` mediante rutas relativas; **conservar el árbol de carpetas**.
- `lab7_estimadores.c/.h`: núcleo matemático del observador, más `test_portable.c`.

Se omiten archivos temporales y generados; abrir el proyecto en PSoC Creator y regenerarlos antes de compilar.

**Seguridad:** el proyecto base y la configuración de trabajo de `Propuesta/` usan `LAB7_MODO_MONITOR` y autorizaciones de control deshabilitadas. La carpeta `Originales/` conserva una configuración histórica de lazo abierto; no debe programarse directamente. No programar el lazo cerrado sin validar previamente el hardware, la calibración, los límites y las protecciones. Los nombres internos de algunas funciones HAL se conservaron para mantener compatibilidad con el proyecto realmente utilizado; cambiarlos implica actualizar el proyecto y repetir las pruebas.

Las adquisiciones físicas están archivadas bajo `../../datos/originales/`; no deben confundirse con una ejecución futura de la copia publicada.
