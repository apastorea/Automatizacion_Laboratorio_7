# Informe IEEE de Laboratorio 7

Formato de artículo académico a dos columnas, coherente con el informe propio
del Laboratorio 5.

- Principal: `main.tex`.
- Secciones editables: `secciones/01_introduccion.tex` a
  `secciones/08_conclusiones.tex`.
- Bibliografía integrada: `secciones/09_bibliografia.tex`.
- Resultados reproducibles:
  `../01_Modelado_MATLAB/validar_resultados_integrados_lab7.m`.
- Tablas y figuras:
  `../05_Resultados/Validacion_Integrada_20261124/`.
- Capturas físicas identificadas:
  `../04_Ensayos/Capturas_Sincronizadas/20261124_221144_972_pred_E1_identificado`,
  `20261124_221418_036_actual_E1_identificado`,
  `20261124_221547_931_pred_E2_identificado` y
  `20261124_221705_548_actual_E2_identificado`.

Para compilar en Overleaf, subir el repositorio conservando su estructura y
usar pdfLaTeX. Localmente:

```bash
pdflatex -interaction=nonstopmode main.tex
pdflatex -interaction=nonstopmode main.tex
pdflatex -interaction=nonstopmode main.tex
```

El informe incorpora el diseño basado en el modelo identificado, la comparación directa
cálculo--simulación--experimento, los estados y errores de las cuatro
configuraciones, el análisis de convergencia, la cuantización del DAC y la
evidencia física J5/J7. También incluye la referencia ideal con estados
conocidos, convergencia teórica al 2 %, esfuerzo RMS, dispersión estacionaria del
error observable y margen temporal del PSoC. Los datos numéricos proceden de MATLAB o de las capturas
del banco; no se utilizaron resultados de informes ajenos.
