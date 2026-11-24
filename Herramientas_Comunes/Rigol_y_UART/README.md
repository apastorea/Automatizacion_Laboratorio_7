# Herramientas de adquisición Rigol y UART

- `lab7_ensayo_sincronizado.py`: sincroniza el PSoC UART con el Rigol y guarda metadatos.
- `rigol_ds1202ze.py`: acceso SCPI/VISA al osciloscopio.
- `visa32_bridge.cs`: auxiliar de compatibilidad en Windows.

Dependencias Python:

```powershell
python -m pip install -r Herramientas_Comunes/Rigol_y_UART/requirements.txt
```

Requiere además una instalación VISA compatible y la conexión física al equipo. Ejecutar los lanzadores de `Laboratorio_7/04_Ensayos/` desde una computadora conectada al banco. Las capturas no programan el PSoC ni activan por sí mismas el lazo cerrado.
