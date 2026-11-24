#ifndef LAB7_CONFIG_H
#define LAB7_CONFIG_H
/* Lab7: seleccionar el modo ANTES de compilar y revisar los enclavamientos.
 * MONITOR se entrega de fabrica como modo inicial seguro (DAC=0).
 * La planta y las calibraciones NO se han verificado fisicamente en Lab7.
 */
#define LAB7_MODO_MONITOR          (0u)
#define LAB7_MODO_LAZO_ABIERTO     (1u)
#define LAB7_MODO_PREDICCION       (2u)
#define LAB7_MODO_ACTUAL          (3u)

#define LAB7_MODO LAB7_MODO_MONITOR
#define LAB7_ESTIMADOR_VARIANTE   (1u)   /* 1=E1; 2=E2 */

/* Cambiar a 1 SOLO después de completar cada ensayo previo. */
#define LAB7_AUTORIZAR_ESCALON (0u)
#define LAB7_PLANTA_VERIFICADA         (0u)
#define LAB7_ADC_DAC_REVALIDADOS       (0u)
#define LAB7_AUTORIZAR_LAZO_CERRADO   (0u)

#if LAB7_MODO > LAB7_MODO_ACTUAL
#error Modo de laboratorio 7 invalido.
#endif
#if LAB7_ESTIMADOR_VARIANTE < 1u || LAB7_ESTIMADOR_VARIANTE > 2u
#error Variante de estimador invalida.
#endif
#if LAB7_MODO == LAB7_MODO_LAZO_ABIERTO && LAB7_AUTORIZAR_ESCALON != 1u
#error No se autoriza escalon abierto hasta revalidar alimentacion y modo seguro.
#endif
#if LAB7_MODO >= LAB7_MODO_PREDICCION && \
 (LAB7_PLANTA_VERIFICADA != 1u || LAB7_ADC_DAC_REVALIDADOS != 1u || \
  LAB7_AUTORIZAR_LAZO_CERRADO != 1u)
#error CONTROL BLOQUEADO: validar planta, ADC/DAC y habilitar explicitamente.
#endif

/* Mantener las instancias originales del TopDesign.
 * Clock_1 historico = 100kHz -> 200 cuentas = Ts=2 ms.
 * Period = cuentas - 1, sujeto a verificacion con Rigol.
 */
#define LAB7_TS_CUENTAS          (200u)
#define LAB7_TS_US               (LAB7_TS_CUENTAS*10u)
#define LAB7_TOLERANCIA_US       (LAB7_TS_US/10u)
#define LAB7_N_MUESTRAS          (256u)
#define LAB7_PRETRIGGER          (32u)
#define LAB7_FIN_ESCALON         (128u)
#define LAB7_INICIO_MS           (3000u)
#define LAB7_ESCALON_ABIERTO_V   (0.050f)
#define LAB7_REFERENCIA_V       (0.050f)
/* Esta limitacion aplica a la accion pedida; el DAC fisico es cuantizado. */
#define LAB7_U_MIN_V            (-0.120f)
#define LAB7_U_MAX_V            (0.120f)
#define LAB7_Y_FALLO_V          (0.500f)
#endif
