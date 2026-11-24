#!/usr/bin/env python3
"""Adquisicion reproducible para el osciloscopio RIGOL DS1202Z-E por USB-TMC."""

from __future__ import annotations

import argparse
import csv
import json
import re
import sys
from datetime import datetime
from pathlib import Path
from time import perf_counter

import numpy as np
import pyvisa


RIGOL_VENDOR_ID = "0X1AB1"
DEFAULT_TIMEOUT_MS = 10_000
MEASUREMENT_ITEMS = (
    "VMAX",
    "VMIN",
    "VPP",
    "VAVG",
    "VRMS",
    "VAMP",
    "PERIOD",
    "FREQUENCY",
    "RTIME",
    "FTIME",
    "OVERSHOOT",
    "PRESHOOT",
)


def discover_resource(resource: str | None = None) -> tuple[pyvisa.ResourceManager, str]:
    manager = pyvisa.ResourceManager()
    if resource:
        # Ahorra el barrido VISA cuando el recurso exacto ya fue identificado.
        return manager, resource
    resources = manager.list_resources()

    candidates = [item for item in resources if RIGOL_VENDOR_ID in item.upper()]
    if len(candidates) != 1:
        manager.close()
        raise RuntimeError(
            "Se esperaba exactamente un RIGOL por USB. "
            f"Recursos encontrados: {resources or 'ninguno'}"
        )
    return manager, candidates[0]


def connect(resource: str | None = None):
    manager, resource_name = discover_resource(resource)
    instrument = manager.open_resource(resource_name)
    instrument.timeout = DEFAULT_TIMEOUT_MS
    instrument.chunk_size = 1_048_576
    instrument.read_termination = "\n"
    instrument.write_termination = "\n"
    return manager, instrument, resource_name


def query_optional(instrument, command: str):
    try:
        return instrument.query(command).strip()
    except Exception:
        return None


def drain_system_errors(instrument, limit: int = 16) -> list[str]:
    errors = []
    for _ in range(limit):
        response = instrument.query(":SYST:ERR?").strip()
        if response.startswith("0,"):
            break
        errors.append(response)
    return errors


def finite_measurement(instrument, item: str, channel: str):
    value = query_optional(instrument, f":MEAS:ITEM? {item},{channel}")
    if value is None:
        return None
    try:
        number = float(value)
    except ValueError:
        return value
    return number if np.isfinite(number) and abs(number) < 1e30 else None


def instrument_metadata(instrument, resource_name: str) -> dict:
    metadata = {
        "timestamp_local": datetime.now().astimezone().isoformat(timespec="seconds"),
        "resource": resource_name,
        "idn": instrument.query("*IDN?").strip(),
        "system_errors_before_capture": drain_system_errors(instrument),
        "run_state": query_optional(instrument, ":TRIG:STAT?"),
        "timebase_scale_s_div": query_optional(instrument, ":TIM:SCAL?"),
        "timebase_offset_s": query_optional(instrument, ":TIM:OFFS?"),
        "sample_rate_sa_s": query_optional(instrument, ":ACQ:SRAT?"),
        "memory_depth_points": query_optional(instrument, ":ACQ:MDEP?"),
    }
    for channel in ("CHAN1", "CHAN2"):
        metadata[channel] = {
            "display": query_optional(instrument, f":{channel}:DISP?"),
            "coupling": query_optional(instrument, f":{channel}:COUP?"),
            "probe_ratio": query_optional(instrument, f":{channel}:PROB?"),
            "scale_v_div": query_optional(instrument, f":{channel}:SCAL?"),
            "offset_v": query_optional(instrument, f":{channel}:OFFS?"),
            "bandwidth_limit": query_optional(instrument, f":{channel}:BWL?"),
        }
    return metadata


def save_screenshot(instrument, output_path: Path) -> Path:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    data = instrument.query_binary_values(
        ":DISP:DATA? ON,OFF,PNG", datatype="B", container=bytes
    )
    output_path.write_bytes(data)
    if not data.startswith(b"\x89PNG\r\n\x1a\n"):
        raise RuntimeError("La respuesta recibida no es una imagen PNG valida.")
    return output_path


def parse_preamble(text: str) -> list[float]:
    fields = [item.strip() for item in re.split(r"[,;]", text.strip()) if item.strip()]
    if len(fields) != 10:
        raise RuntimeError(f"Preambulo inesperado: {text!r}")
    return [float(item) for item in fields]


def acquire_screen_waveform(instrument, channel: str) -> tuple[np.ndarray, np.ndarray, dict]:
    instrument.write(f":WAV:SOUR {channel}")
    instrument.write(":WAV:MODE NORM")
    instrument.write(":WAV:FORM BYTE")
    preamble_text = instrument.query(":WAV:PRE?").strip()
    preamble = parse_preamble(preamble_text)
    raw = instrument.query_binary_values(
        ":WAV:DATA?", datatype="B", container=np.array
    ).astype(np.float64)

    _, _, points, count, xinc, xorigin, xreference, yinc, yorigin, yreference = preamble
    index = np.arange(raw.size, dtype=np.float64)
    time_s = (index - xreference) * xinc + xorigin
    voltage_v = (raw - yorigin - yreference) * yinc
    info = {
        "channel": channel,
        "points_reported": int(points),
        "points_received": int(raw.size),
        "average_count": int(count),
        "x_increment_s": xinc,
        "x_origin_s": xorigin,
        "x_reference": xreference,
        "y_increment_v": yinc,
        "y_origin": yorigin,
        "y_reference": yreference,
        "preamble": preamble_text,
    }
    return time_s, voltage_v, info


def save_waveform_csv(output_path: Path, time_s, voltage_v) -> Path:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.writer(stream)
        writer.writerow(("time_s", "voltage_v"))
        writer.writerows(zip(time_s, voltage_v))
    return output_path


def collect_measurements(instrument) -> dict:
    result = {}
    for channel in ("CHAN1", "CHAN2"):
        result[channel] = {
            item: finite_measurement(instrument, item, channel)
            for item in MEASUREMENT_ITEMS
        }
    return result


def save_json(output_path: Path, data: dict) -> Path:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")
    return output_path


def timestamped_folder(root: Path, label: str) -> Path:
    stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    safe_label = re.sub(r"[^A-Za-z0-9_-]+", "_", label.strip()).strip("_") or "ensayo"
    return root / f"{stamp}_{safe_label}"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--resource", help="Recurso VISA; se autodetecta si se omite.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    subparsers.add_parser("info", help="Muestra identificacion y configuracion actual.")

    screenshot = subparsers.add_parser("screenshot", help="Guarda la pantalla en PNG.")
    screenshot.add_argument("output", type=Path)

    waveform = subparsers.add_parser("waveform", help="Guarda la forma de onda visible en CSV.")
    waveform.add_argument("channel", choices=("CHAN1", "CHAN2"))
    waveform.add_argument("output", type=Path)

    bundle = subparsers.add_parser("bundle", help="Captura PNG, CSV de ambos canales y metadatos.")
    bundle.add_argument("--label", default="lab4")
    bundle.add_argument("--root", type=Path, default=Path("capturas_rigol"))
    bundle.add_argument("--quick", action="store_true", help="Omite consultas lentas; guarda formas de onda visibles de 1200 puntos.")
    bundle.add_argument("--only", choices=("all", "data", "screen"), default="all",
                        help="all=PNG+dos CSV; data=solo CSV CH1/CH2; screen=solo PNG. Usar con --quick.")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    manager = instrument = None
    inicio_total = perf_counter()
    try:
        print("Conectando con el Rigol por USB VISA...", flush=True)
        manager, instrument, resource_name = connect(args.resource)
        print(f"Recurso detectado: {resource_name} | conexion {perf_counter()-inicio_total:.2f} s", flush=True)
        metadata = (
            {
                "timestamp_local": datetime.now().astimezone().isoformat(timespec="seconds"),
                "resource": resource_name,
                "modo_captura": "quick",
            }
            if args.command == "bundle" and args.quick
            else instrument_metadata(instrument, resource_name)
        )

        if args.command == "info":
            metadata["measurements"] = collect_measurements(instrument)
            metadata["system_errors_after_capture"] = drain_system_errors(instrument)
            print(json.dumps(metadata, indent=2, ensure_ascii=False))

        elif args.command == "screenshot":
            path = save_screenshot(instrument, args.output.resolve())
            print(path)

        elif args.command == "waveform":
            time_s, voltage_v, info = acquire_screen_waveform(instrument, args.channel)
            path = save_waveform_csv(args.output.resolve(), time_s, voltage_v)
            metadata["system_errors_after_capture"] = drain_system_errors(instrument)
            save_json(path.with_suffix(".json"), {**metadata, "waveform": info})
            print(path)

        elif args.command == "bundle":
            folder = timestamped_folder(args.root.resolve(), args.label)
            folder.mkdir(parents=True, exist_ok=False)
            print(f"Carpeta de captura: {folder}", flush=True)
            metadata["capture_selection"] = args.only
            metadata["waveforms"] = {}
            if args.only in ("all", "screen"):
                inicio = perf_counter()
                print("Descargando imagen de pantalla...", flush=True)
                save_screenshot(instrument, folder / "pantalla.png")
                print(f"Pantalla guardada: pantalla.png ({perf_counter()-inicio:.2f} s)", flush=True)
            if args.only in ("all", "data"):
                for channel in ("CHAN1", "CHAN2"):
                    inicio = perf_counter()
                    print(f"Descargando forma de onda {channel}...", flush=True)
                    time_s, voltage_v, info = acquire_screen_waveform(instrument, channel)
                    save_waveform_csv(folder / f"{channel.lower()}.csv", time_s, voltage_v)
                    metadata["waveforms"][channel] = info
                    print(f"{channel}: {len(time_s)} puntos ({perf_counter()-inicio:.2f} s)", flush=True)
            if not args.quick:
                print("Consultando mediciones y diagnostico SCPI...", flush=True)
                inicio = perf_counter()
                metadata["measurements"] = collect_measurements(instrument)
                metadata["system_errors_after_capture"] = drain_system_errors(instrument)
                print(f"Consultas adicionales: {perf_counter()-inicio:.2f} s", flush=True)
            metadata["elapsed_seconds"] = round(perf_counter()-inicio_total, 3)
            save_json(folder / "metadatos.json", metadata)
            print(f"CAPTURA COMPLETA en {metadata['elapsed_seconds']:.2f} s: {folder}", flush=True)

        return 0
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1
    finally:
        if instrument is not None:
            instrument.close()
        if manager is not None:
            manager.close()


if __name__ == "__main__":
    raise SystemExit(main())
