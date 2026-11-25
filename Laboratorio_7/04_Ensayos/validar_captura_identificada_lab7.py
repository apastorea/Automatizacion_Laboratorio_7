#!/usr/bin/env python3
"""Valida la trazabilidad minima de una captura fisica identificada de Lab7."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


DISENOS = {
    "E1": "diseno_E1=ID_Z025_J005",
    "E2": "diseno_E2=ID_Z020_J010",
}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("carpeta", type=Path)
    parser.add_argument("--modo", required=True, choices=("PREDICCION", "ACTUAL"))
    parser.add_argument("--estimador", required=True, choices=tuple(DISENOS))
    args = parser.parse_args()

    carpeta = args.carpeta.resolve()
    errores: list[str] = []
    try:
        meta = json.loads((carpeta / "metadatos.json").read_text(encoding="utf-8"))
        uart = (carpeta / "psoc_uart.txt").read_text(encoding="ascii", errors="replace")
    except (OSError, json.JSONDecodeError) as exc:
        print(f"NO VALIDA: no se pudo leer la evidencia: {exc}", file=sys.stderr)
        return 2

    resumen_uart = meta.get("uart", {})
    sincronizacion = meta.get("sincronizacion", {})
    if meta.get("modo_detectado") != args.modo:
        errores.append(f"modo detectado={meta.get('modo_detectado')!r}; esperado={args.modo}")
    if resumen_uart.get("filas_uart") != 256:
        errores.append(f"filas UART={resumen_uart.get('filas_uart')!r}; esperadas=256")
    if resumen_uart.get("filas_flags_no_cero") != 0:
        errores.append(f"filas con flags!=0: {resumen_uart.get('filas_flags_no_cero')!r}")
    if sincronizacion.get("disparo_forzado") is not False:
        errores.append("el trigger fue forzado o no quedó documentado")
    if meta.get("trigger_fisico_confirmado") is not True:
        errores.append("no quedó confirmado un disparo físico en CH1")
    if "modelo_identificado=LAB5_J5_J7" not in uart:
        errores.append("falta modelo_identificado=LAB5_J5_J7 en UART")
    if "firmware=ID_PREVALIDADO_OFFLINE" not in uart:
        errores.append("falta firmware=ID_PREVALIDADO_OFFLINE en UART")
    if DISENOS[args.estimador] not in uart:
        errores.append(f"falta {DISENOS[args.estimador]} en UART")

    ts = resumen_uart.get("Ts_median_us")
    if not isinstance(ts, (int, float)) or abs(ts - 2000.0) > 200.0:
        errores.append(f"Ts mediano={ts!r} us; tolerancia permitida 2000+/-200 us")
    cpu = resumen_uart.get("max_cpu_us")
    if not isinstance(cpu, (int, float)) or cpu > 2000.0:
        errores.append(f"CPU máxima={cpu!r} us; debe ser <=2000 us")

    if errores:
        print("CAPTURA IDENTIFICADA NO VALIDA:", file=sys.stderr)
        for error in errores:
            print(f"  - {error}", file=sys.stderr)
        print(f"Evidencia conservada para diagnostico: {carpeta}", file=sys.stderr)
        return 1

    print("CAPTURA IDENTIFICADA VALIDA")
    print(f"  carpeta: {carpeta}")
    print(f"  modo: {args.modo}; estimador: {args.estimador}")
    print(f"  filas: 256; flags: 0; Ts mediano: {ts:.1f} us; CPU maxima: {cpu:.0f} us")
    print("  modelo, firmware y disparo fisico: verificados")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
