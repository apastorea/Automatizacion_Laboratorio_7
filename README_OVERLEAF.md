# Laboratorio 7 — Proyecto editable para Overleaf

1. Crear un proyecto nuevo en Overleaf mediante «Upload Project» e importar el archivo ZIP completo.
2. Compilador: **pdfLaTeX**. Archivo principal: `main.tex`.
3. El proyecto integra el encabezado institucional de Aldo Pastore, el desarrollo matemático, el diseño de observadores y las mediciones de las cuatro configuraciones del Laboratorio 7.
4. Las gráficas PNG están incluidas en `figuras/` y la tabla resumida de resultados en `datos/`. No sustituir las imágenes por capturas de pantalla escaladas sin ajustar las referencias.
5. Los cálculos y las cifras provienen de los CSV instrumentales guardados en el paquete de comparación, no de los resultados de otro estudiante.
6. Los CSV instrumentales originales están en `datos/originales/`, y el script de `anexos/` reproduce las curvas a partir de esos registros.

## Consideraciones de interpretación

- La etiqueta de modo esperado de algunas capturas se configuró erróneamente y no coincide con el modo ejecutado según UART. Se documenta esa limitación en el texto.
- Todas las capturas de osciloscopio relevantes usaron el disparo forzado TFOR; las figuras alineadas por CH1 son comparaciones aproximadas, no sincronización física submilisegundo.
- Las conclusiones son válidas para una ejecución por caso y un escalón de 50 mV; no implican estabilidad global ni superioridad definitiva.


## Identificación de esta versión

Archivo final: `Informe_Lab7_Automatizacion_Pastore_v1.pdf`. La firma `SDG` figura exclusivamente en el pie derecho de la última página, conservando la numeración de páginas. La fuente principal para Overleaf es `main.tex`.
