#ifndef LAB7_ESTIMADORES_H
#define LAB7_ESTIMADORES_H
/* Nucleo MATEMATICO portable para dos estados y una unica salida medida.
 * No incluye ADC, DAC, ISR, calibraciones ni funciones PSoC Creator.
 * No habilitar lazo fisico sin validar primero las ganancias y escalas.
 */
typedef enum {
    LAB7_EST_PREDICCION = 0,
    LAB7_EST_ACTUAL = 1
} lab7_tipo_estimador_t;

typedef struct {
    float A[2][2], B[2], C[2];
    float K[2], L[2], Nr;
    float u_min_V, u_max_V;
    lab7_tipo_estimador_t tipo;
} lab7_parametros_t;

typedef struct {
    float x_mem[2]; /* prediccion o estimacion para la proxima muestra */
    float x_utilizado[2];
    float u_aplicado_V;
    float u_solicitado_V;
    float innovacion_V;
    unsigned int saturaciones;
} lab7_estado_t;

/* Inicializar SIEMPRE con salida segura y estimacion inicial documentada. */
void lab7_reiniciar(lab7_estado_t *estado, float x0_est1, float x0_est2);
/* Retorna u[k] ACTUALMENTE aplicado (despues de limitacion). */
float lab7_calcular_paso(const lab7_parametros_t *p,
                        lab7_estado_t *estado,
                        float referencia_V, float salida_medida_V);
#endif
