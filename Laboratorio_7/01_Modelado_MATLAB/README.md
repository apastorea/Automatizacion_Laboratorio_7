# MATLAB — Laboratorio 7

Esta carpeta contiene los scripts de diseño, simulación, análisis de estabilidad y prevalidación no ideal de E1/E2.

Con MATLAB y Control System Toolbox, elegir esta carpeta y ejecutar:

```matlab
p = modelo_lab7();
d = disenar_lab7(p);
lab7_principal
evaluar_robustez_observadores_lab7
prevalidar_E2_para_PSoC_lab7
```

Los scripts guardan resultados bajo `../05_Resultados/`. Para reproducir las cuatro curvas experimentales con los CSV incluidos en la entrega, ejecutar desde la raíz `anexos/reproducir_cuatro_ensayos_lab7.m`. Algunos diagnósticos históricos requieren capturas auxiliares no incluidas en el paquete público; no equivalen al informe reproducible con los cuatro conjuntos originales de `datos/originales/`.

Las imágenes PNG son salidas complementarias obtenidas con MATLAB. Las comparaciones definitivas aparecen en `figuras/`.
