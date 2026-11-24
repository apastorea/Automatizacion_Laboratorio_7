/* Prueba de algebra C aislada; NO programa la placa PSoC. */
#include "lab7_estimadores.h"
#include <assert.h>
#include <math.h>
int main(void)
{
    lab7_parametros_t p = {
        {{0.9f,0.1f},{0.0f,0.8f}},
        {0.01f,0.02f},
        {1.0f,0.0f},
        {1.0f,2.0f},
        {0.2f,0.1f},
        0.6f,
        -1.0f,1.0f,
        LAB7_EST_PREDICCION
    };
    lab7_estado_t e;
    float u;
    lab7_reiniciar(&e,0.0f,0.0f);
    u=lab7_calcular_paso(&p,&e,0.05f,0.0f);
    assert(fabsf(u-0.03f)<1e-6f);
    assert(e.saturaciones==0u);
    p.tipo=LAB7_EST_ACTUAL;
    lab7_reiniciar(&e,0.0f,0.0f);
    u=lab7_calcular_paso(&p,&e,0.05f,0.1f);
    assert(fabsf(u-(-0.01f))<1e-6f); /* 0.03-1*0.02-2*0.01 */
    return 0;
}
