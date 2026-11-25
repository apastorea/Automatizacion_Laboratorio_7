/*
 * LABORATORIO 7 — Rediseno con modelo identificado (SIN ACTIVAR).
 * Copia independiente del TopDesign del Laboratorio 5 (sin modificar original).
 * Configuracion de ESTA PROPUESTA: MONITOR, DAC=0; control bloqueado.
 * AUTORES: plantilla tecnica generada para Lab7; verificar fisicamente antes del uso.
 */
#include "project.h"
#include "lab5_hardware.h"       /* HAL historica Lab5: ADC/DAC, NO controlador */
#include "lab7_estimadores.h"
#include "lab7_config.h"
#include <float.h>
#include <stdio.h>

#if ADC_DEFAULT_RESOLUTION != 12u || ADC_DEFAULT_CONV_MODE != ADC__HARDWARE_TRIGGER
#error TopDesign no coincide: SAR 12 bits y disparo hardware requerido.
#endif
#if ADC_DEFAULT_RANGE != ADC__VSSA_TO_VDDA
#error Rango ADC distinto a calibracion historica Lab5.
#endif
#if Timer_TS_Resolution != 16u || Timer_Medicion_Resolution != 16u
#error Se requieren temporizadores de 16 bits.
#endif

typedef struct {
    float adc_V;
    float y_V;             /* Voltaje planta estimado por calibracion historica */
    float y_rel_V;         /* y_V - cero obtenido en pretrigger */
    float referencia_V;
    float u_solicitada_V;
    float u_dac_nominal_V;
    float xhat1_V;
    float xhat2_V;
    float innovacion_V;
    int16 adc_cuentas;
    uint16 intervalo_us;
    uint16 cpu_us;
    uint8 dac_pos;
    uint8 dac_neg;
    uint8 banderas;
} Lab7Muestra;

#define F_ADC     1u
#define F_LIMITE  2u
#define F_NUM     4u
#define F_CPU     8u
#define F_TIEMPO  16u
#define F_Y       32u

static Lab7Muestra memoria[LAB7_N_MUESTRAS];
static volatile uint16 cuenta = 0u;
static volatile uint8 captura_finalizada = 0u;
static uint16 tick_anterior = 0u;
static float acumulado_cero_V = 0.0f;
static float cero_V = 0.0f;
static lab7_estado_t estado;

/* MATRICES DEL MODELO IDENTIFICADO LAB5 J5-J7, Ts=2 ms.
 * Prevalidadas offline con ruido medido; el control fisico permanece
 * bloqueado en lab7_config.h hasta comprobar nuevamente el banco.
 */
static const lab7_parametros_t parametros = {
    {{0.80209531f,0.0f},{-0.24962829f,0.07557362f}},
    {-0.63161070f,0.13045908f},
    {0.0f,1.0f},
    {3.07258956f,9.33893862f},
#if LAB7_MODO == LAB7_MODO_ACTUAL
    #if LAB7_ESTIMADOR_VARIANTE == 1u
    {-1.53481428f,-0.07230205f}, /* E1 actual; z=0.25 +/- j0.05 */
    #else
    {-1.86049444f,0.17515227f},  /* E2 actual; z=0.20 +/- j0.10 */
    #endif
#else
    #if LAB7_ESTIMADOR_VARIANTE == 1u
    {-1.23106734f,0.37766894f}, /* E1 predictor; z=0.25 +/- j0.05 */
    #else
    {-1.49229387f,0.47766894f}, /* E2 predictor; z=0.20 +/- j0.10 */
    #endif
#endif
    0.55862462f, LAB7_U_MIN_V, LAB7_U_MAX_V,
#if LAB7_MODO == LAB7_MODO_ACTUAL
    LAB7_EST_ACTUAL
#else
    LAB7_EST_PREDICCION
#endif
};

CY_ISR_PROTO(Lab7MuestreoISR);

static uint8 es_finito(float a)
{
    return (uint8)(a<=FLT_MAX && a>=-FLT_MAX);
}

static uint16 leer_timer_us(void)
{
    Timer_Medicion_SoftwareCapture();
    return Timer_Medicion_ReadCapture();
}

static int32 convertir_mV(float v)
{
    float c;
    if(!es_finito(v)) return 0;
    c=Lab5Clamp(1000.0f*v,-100000.0f,100000.0f);
    return (int32)(c+((c>=0.0f)?0.5f:-0.5f));
}

static void detener_seguro(void)
{
    Timer_TS_Stop();
    Lab5HardwareZeroOutput();
    captura_finalizada=1u;
}

CY_ISR(Lab7MuestreoISR)
{
    uint16 k=cuenta, tic_ini, intervalo=0u, cpu_us;
    uint8 banderas=0u, positivo=0u, negativo=0u, saturado=0u;
#if LAB7_MODO == LAB7_MODO_PREDICCION || LAB7_MODO == LAB7_MODO_ACTUAL
    unsigned int saturaciones_antes=estado.saturaciones;
#endif
    int16 adc_raw=0;
    float adc_V=0.0f, salida_V, salida_rel_V, ref_V=0.0f;
    float u_solicitada_V=0.0f, u_nominal_V=0.0f;
    Lab7Muestra *m;

    registro_Write(1u);
    if(captura_finalizada || k>=LAB7_N_MUESTRAS) {
        detener_seguro(); registro_Write(0u); return;
    }
    tic_ini=leer_timer_us();
    if(k>0u) {
        intervalo=(uint16)(tick_anterior-tic_ini);
        if(intervalo<(LAB7_TS_US-LAB7_TOLERANCIA_US) ||
           intervalo>(LAB7_TS_US+LAB7_TOLERANCIA_US)) banderas|=F_TIEMPO;
    }
    tick_anterior=tic_ini;
    salida_V=Lab5HardwareReadPlant(&adc_raw,&adc_V);
    if(!es_finito(salida_V) || !es_finito(adc_V)) {
        salida_V=0.0f; banderas|=F_NUM;
    }
    if(adc_raw<=2 || adc_raw>=4093) banderas|=F_ADC;
    if(k<LAB7_PRETRIGGER) {
        acumulado_cero_V+=salida_V;
        if(k+1u==LAB7_PRETRIGGER)
            cero_V=acumulado_cero_V/(float)LAB7_PRETRIGGER;
    }
    /* Monitorizar sobre el valor crudo/calibrado Y sobre la desviacion. */
    salida_rel_V=(k>=LAB7_PRETRIGGER)?salida_V-cero_V:salida_V;
    if(salida_rel_V>LAB7_Y_FALLO_V || salida_rel_V<-LAB7_Y_FALLO_V)
        banderas|=F_Y;

#if LAB7_MODO == LAB7_MODO_LAZO_ABIERTO
    if(k>=LAB7_PRETRIGGER && k<LAB7_FIN_ESCALON)
        u_solicitada_V=LAB7_ESCALON_ABIERTO_V;
#elif LAB7_MODO == LAB7_MODO_PREDICCION || LAB7_MODO == LAB7_MODO_ACTUAL
    if(k>=LAB7_PRETRIGGER) {
        ref_V=LAB7_REFERENCIA_V;
        u_solicitada_V=lab7_calcular_paso(&parametros,&estado,
                                          ref_V,salida_rel_V);
        /* Si la ley pidio mas que el limite conservador, abortar ensayo. */
        if(estado.saturaciones>saturaciones_antes) banderas|=F_LIMITE;
    } else lab7_reiniciar(&estado,0.0f,0.0f);
#else
    /* MONITOR: no genera escalon ni utiliza el controlador anterior. */
    u_solicitada_V=0.0f;
#endif

    if(!es_finito(u_solicitada_V)) {u_solicitada_V=0.0f; banderas|=F_NUM;}
    /* F_LIMITE incluye saturacion solicitada por el controlador.
     * No dejar que un mando saturado sea aplicado ni una muestra adicional.
     */
    if((banderas&(F_ADC|F_LIMITE|F_NUM|F_TIEMPO|F_Y))!=0u)
        u_solicitada_V=0.0f;

    /* HAL heredada cuantiza el DAC. Estado del observador se ajusta
     * por diferencia entre u discreta solicitada y aplicada nominal.
     */
    u_nominal_V=Lab5HardwareWriteOutput(u_solicitada_V,
                                         &positivo,&negativo,&saturado);
    if(saturado ||
       u_nominal_V>LAB7_U_LIMITE_FISICO_V ||
       u_nominal_V<(-LAB7_U_LIMITE_FISICO_V)) {
        /* Proteccion posterior a la conversion a codigos DAC. */
        banderas|=F_LIMITE;
        Lab5HardwareZeroOutput();
        u_nominal_V=0.0f; positivo=0u; negativo=0u;
    }
#if LAB7_MODO == LAB7_MODO_PREDICCION || LAB7_MODO == LAB7_MODO_ACTUAL
    if(k>=LAB7_PRETRIGGER) {
        float diferencia=u_nominal_V-estado.u_aplicado_V;
        estado.x_mem[0]+=parametros.B[0]*diferencia;
        estado.x_mem[1]+=parametros.B[1]*diferencia;
        estado.u_aplicado_V=u_nominal_V;
    }
#endif
    m=&memoria[k];
    m->adc_V=adc_V;
    m->y_V=salida_V;
    m->y_rel_V=salida_rel_V;
    m->referencia_V=ref_V;
    m->u_solicitada_V=u_solicitada_V;
    m->u_dac_nominal_V=u_nominal_V;
    m->adc_cuentas=adc_raw;
    m->dac_pos=positivo;
    m->dac_neg=negativo;
    m->intervalo_us=intervalo;
#if LAB7_MODO == LAB7_MODO_PREDICCION || LAB7_MODO == LAB7_MODO_ACTUAL
    m->xhat1_V=estado.x_utilizado[0];
    m->xhat2_V=estado.x_utilizado[1];
    m->innovacion_V=estado.innovacion_V;
#else
    m->xhat1_V=0.0f; m->xhat2_V=0.0f; m->innovacion_V=0.0f;
#endif
    cpu_us=(uint16)(tic_ini-leer_timer_us());
    m->cpu_us=cpu_us;
    if(cpu_us>=LAB7_TS_US) banderas|=F_CPU;
    m->banderas=banderas;
    cuenta=k+1u;
    if(banderas!=0u || cuenta>=LAB7_N_MUESTRAS) detener_seguro();
    registro_Write(0u);
}

static void volcar_uart(void)
{
    char linea[280];
    uint16 k;
    uint32 t_us=0u;
    UART_Debug_PutString(
        "# LAB7 datos modelo_identificado=LAB5_J5_J7 calibracion_historica=SI "
        "Ts_nominal_us=2000 modo="
#if LAB7_MODO == LAB7_MODO_MONITOR
        "MONITOR"
#elif LAB7_MODO == LAB7_MODO_LAZO_ABIERTO
        "ABIERTO"
#elif LAB7_MODO == LAB7_MODO_PREDICCION
        "PREDICCION"
#else
        "ACTUAL"
#endif
        "\r\n");
    /* Identificar E1 o E2 del rediseno identificado segun la variante
     * compilada; no modificar el formato de las filas CSV.
     */
    UART_Debug_PutString(
#if LAB7_ESTIMADOR_VARIANTE == 1u
        "# LAB7 diseno_E1=ID_Z025_J005 "
#else
        "# LAB7 diseno_E2=ID_Z020_J010 "
#endif
        "limite_DAC_codigo=SI firmware=ID_PREVALIDADO_OFFLINE\r\n");
    UART_Debug_PutString(
        "k,t_us,adc_counts,adc_mV,y_cal_mV,y_rel_mV,r_mV,"
        "u_solicitada_mV,u_nominal_mV,xhat1_mV,xhat2_mV,"
        "innovacion_mV,dac_pos,dac_neg,cpu_us,intervalo_us,flags\r\n");
    for(k=0u;k<cuenta;k++) {
        Lab7Muestra *m=&memoria[k];
        t_us+=m->intervalo_us;
        (void)snprintf(linea,sizeof linea,
            "%u,%lu,%d,%ld,%ld,%ld,%ld,%ld,%ld,%ld,%ld,%ld,%u,%u,%u,%u,%u\r\n",
            (unsigned)k,(unsigned long)t_us,(int)m->adc_cuentas,
            (long)convertir_mV(m->adc_V),
            (long)convertir_mV(m->y_V),
            (long)convertir_mV(m->y_rel_V),
            (long)convertir_mV(m->referencia_V),
            (long)convertir_mV(m->u_solicitada_V),
            (long)convertir_mV(m->u_dac_nominal_V),
            (long)convertir_mV(m->xhat1_V),
            (long)convertir_mV(m->xhat2_V),
            (long)convertir_mV(m->innovacion_V),
            (unsigned)m->dac_pos,(unsigned)m->dac_neg,
            (unsigned)m->cpu_us,(unsigned)m->intervalo_us,
            (unsigned)m->banderas);
        UART_Debug_PutString(linea);
    }
    UART_Debug_PutString("# LAB7 END; DAC=0; reiniciar para repetir\r\n");
}

int main(void)
{
    uint16 anterior=0u;
    uint8 intentos=0u;
    CyGlobalIntDisable;
    lab7_reiniciar(&estado,0.0f,0.0f);
    Lab5HardwareInit();    /* DAC a 0; OPAMP y SAR inicializados */
    Lab5HardwareZeroOutput();
    UART_Debug_Start();
    Clock_Medicion_Start();
    Timer_Medicion_Start();
    Timer_TS_Init();
    Timer_TS_WritePeriod((uint16)(LAB7_TS_CUENTAS-1u));
    isr_StartEx(Lab7MuestreoISR);
    isr_ClearPending();

    /* Aviso de arranque ANTES de habilitar generacion de muestras. */
    UART_Debug_PutString("\r\n# LAB7 inicio; configurar segun lab7_config.h; espera 3s\r\n");
    CyDelay(LAB7_INICIO_MS);
    CyGlobalIntEnable;
    Clock_1_Start();
    Timer_TS_Enable();
    while(!captura_finalizada) {
        CyDelay(10u);
        if(cuenta==anterior) ++intentos;
        else intentos=0u;
        anterior=cuenta;
        if(intentos>=10u) {
            uint8 estado_interrupcion=CyEnterCriticalSection();
            detener_seguro();
            CyExitCriticalSection(estado_interrupcion);
            UART_Debug_PutString("# ERROR no llegan muestras; salida a cero\r\n");
        }
    }
    volcar_uart();
    for(;;) { CyDelay(1000u); }
}
