# Etapa 1 — Modelo nominal de la guía

**Fuente:** Figura 1, página 2 de `Laboratorio_7/00_Enunciado/Lab6_Estimadores_Enunciado.pdf`. El encabezado “Laboratorio 6” es erróneo: esta práctica es **Laboratorio 7**.

## Estados, unidades y circuito

La planta es el bloque **central**, distinto de los acondicionadores DAC y ADC. `u(t)` es la tensión física aplicada a R6, `x1(t)` la salida de la primera etapa inversora, `x2(t)` la segunda salida, y `y(t)=x2(t)` es la única medición permitida.

- Primera etapa: `C1*dx1/dt + x1/R5 = -u/R6`.
- Segunda etapa: `C3*dx2/dt + x2/R1 = -x1/R2`.
- Guía: R5=150kΩ, R6=47kΩ, R1=15kΩ, R2=47kΩ, C1=C3=100nF.

Matrices nominales:

```
F = [-66.66666667, 0; -212.76595745, -666.66666667]
G = [-212.76595745; 0]
H = [0 1], J = 0
Gp(s) = 45269.35/(s^2 + 733.3333s + 44444.4444)
```

La ganancia DC es 1.0185604, polos -66.6667 y -666.6667 rad/s; fBW≈10.482 Hz.

## Diseño preliminar y criterios

Ts=2ms → fs=500Hz y fs/fBW≈47.70; valor **preliminar** que excede 30fBW. El reloj de Lab5 era 100kHz: 200 cuentas/2ms, `Period=199` solo si TopDesign confirma esa configuración. Medir el tiempo con Rigol DS1202Z-E.

```
A = [0.87517332, 0; -0.21687099, 0.26359714]
B = [-0.39838302; 0.05792937], C=[0 1]
rango(controlabilidad)=rango(observabilidad)=2
Polos de control = 0.80 +/- 0.25j
K = [2.15692217 6.87132640], Nr=1.09474803
E1 = 0.40 +/- 0.25j: Lp=[-1.32931421;0.33877046], La=[-1.51891537;0.03551549]
E2 = 0.20 +/- 0.10j: Lp=[-2.14809283;0.73877046], La=[-2.45447706;0.78326191]
```

**Procedencia:** cálculos nominales reproducidos independientemente con SciPy. No presentarlos como resultados experimentales. En Lab5 también aparece un modelo identificado con K=1.002941, tau_lenta=9.06915ms y tau_rapida=0.774399ms, distinto del nominal (15ms, 1.5ms). Revalidar en Lab7 antes de poner en funcionamiento el lazo.

Ejecutar en MATLAB: `validar_nominal_lab7`, luego `lab7_principal`. `p.validado=false` permanece así para impedir que una simulación nominal sea interpretada como autorización de hardware.
