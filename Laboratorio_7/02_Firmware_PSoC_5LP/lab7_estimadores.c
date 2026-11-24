#include "lab7_estimadores.h"

static float lab7_limitar(float u, float inferior, float superior)
{
    if (u < inferior) return inferior;
    if (u > superior) return superior;
    return u;
}

void lab7_reiniciar(lab7_estado_t *e, float x0_est1, float x0_est2)
{
    if (e == 0) return;
    e->x_mem[0] = x0_est1;
    e->x_mem[1] = x0_est2;
    e->x_utilizado[0] = x0_est1;
    e->x_utilizado[1] = x0_est2;
    e->u_aplicado_V = 0.0f;
    e->u_solicitado_V = 0.0f;
    e->innovacion_V = 0.0f;
    e->saturaciones = 0u;
}

float lab7_calcular_paso(const lab7_parametros_t *p,
                        lab7_estado_t *e,
                        float referencia_V, float salida_medida_V)
{
    float xp0, xp1, xe0, xe1, innov, us, ua;
    if (p == 0 || e == 0 || p->u_max_V <= p->u_min_V) return 0.0f;

    xp0 = e->x_mem[0];
    xp1 = e->x_mem[1];
    innov = salida_medida_V - (p->C[0]*xp0 + p->C[1]*xp1);

    if (p->tipo == LAB7_EST_ACTUAL) {
        /* Corregir ANTES del control con la medicion y[k] actual. */
        xe0 = xp0 + p->L[0]*innov;
        xe1 = xp1 + p->L[1]*innov;
    } else {
        /* Prediccion: xhat[k] aun NO corrige con y[k] para u[k]. */
        xe0 = xp0;
        xe1 = xp1;
    }
    us = p->Nr*referencia_V - p->K[0]*xe0 - p->K[1]*xe1;
    ua = lab7_limitar(us, p->u_min_V, p->u_max_V);
    if (ua != us) ++e->saturaciones;

    e->x_utilizado[0] = xe0;
    e->x_utilizado[1] = xe1;
    e->u_solicitado_V = us;
    e->u_aplicado_V = ua;
    e->innovacion_V = innov;

    /* Predecir la muestra siguiente usando el MANDO APLICADO, no el ideal. */
    e->x_mem[0] = p->A[0][0]*xe0 + p->A[0][1]*xe1 + p->B[0]*ua;
    e->x_mem[1] = p->A[1][0]*xe0 + p->A[1][1]*xe1 + p->B[1]*ua;
    if (p->tipo == LAB7_EST_PREDICCION) {
        e->x_mem[0] += p->L[0]*innov;
        e->x_mem[1] += p->L[1]*innov;
    }
    return ua;
}
