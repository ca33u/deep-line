#!/usr/bin/env python3
"""Собирает матрицу устройств из установленного Connect IQ SDK.

Факты берутся из `compiler.json` каждого скачанного устройства, а не из
интернета: разрешения, лимиты памяти и типы экранов в форумных пересказах
регулярно расходятся с реальностью.

    python3 scripts/device-matrix.py            # только круглые экраны
    python3 scripts/device-matrix.py --all      # все формы
    python3 scripts/device-matrix.py --json     # машинно читаемый вывод

Колонка COLOR — глубина цвета: 64-цветные MIP и полноцветные AMOLED требуют
разных палитр. Колонка BURN выводится из SDK-поля `displayType`; в рантайме игра
использует эквивалентный публичный признак `requiresBurnInProtection`.
"""

import argparse
import json
import os
import sys

DEVICES = os.path.expanduser(
    "~/Library/Application Support/Garmin/ConnectIQ/Devices"
)


def watch_app_memory(data):
    """Лимит watch-app из документированного массива appTypes."""
    for app_type in data.get("appTypes", []):
        if app_type.get("type") == "watchApp":
            return app_type.get("memoryLimit")
    return None


def newest_api(data):
    """Самая новая Connect IQ version среди аппаратных part numbers."""
    versions = [
        part.get("connectIQVersion")
        for part in data.get("partNumbers", [])
        if part.get("connectIQVersion")
    ]
    if not versions:
        return None
    return max(versions, key=lambda value: tuple(int(x) for x in value.split(".")))


def read_device(device_id):
    path = os.path.join(DEVICES, device_id, "compiler.json")
    if not os.path.exists(path):
        return None
    try:
        with open(path, encoding="utf-8") as handle:
            data = json.load(handle)
    except (json.JSONDecodeError, OSError) as error:
        return {"id": device_id, "error": str(error)}

    resolution = data.get("resolution", {})
    display_type = data.get("displayType")
    family = str(data.get("deviceFamily") or "")
    memory = watch_app_memory(data)
    width = resolution.get("width")
    height = resolution.get("height")
    if not isinstance(width, int) or not isinstance(height, int) or \
            width < 100 or height < 100:
        return {"id": device_id, "error": "invalid screen resolution"}
    return {
        "id": device_id,
        "name": data.get("displayName"),
        "width": width,
        "height": height,
        "shape": "round" if family.startswith("round-") else family,
        "color": data.get("bitsPerPixel"),
        # compiler.json exposes the display technology directly. Runtime code
        # still uses requiresBurnInProtection because displayType is SDK metadata.
        "burnIn": display_type == "amoled" if display_type else None,
        "api": newest_api(data),
        "memoryKb": round(memory / 1024) if isinstance(memory, (int, float)) else None,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--all", action="store_true", help="не фильтровать по форме")
    parser.add_argument("--json", action="store_true", help="вывести JSON")
    args = parser.parse_args()

    if not os.path.isdir(DEVICES):
        sys.exit(
            "Не найден каталог устройств SDK:\n  " + DEVICES +
            "\nОткройте SDK Manager и скачайте хотя бы одно устройство."
        )

    devices = []
    for device_id in sorted(os.listdir(DEVICES)):
        device = read_device(device_id)
        if device is None:
            continue
        shape = str(device.get("shape") or "").lower()
        if not args.all and shape != "round":
            continue
        devices.append(device)

    if not devices:
        sys.exit("Устройства не найдены. Скачайте их через SDK Manager.")

    if args.json:
        print(json.dumps(devices, ensure_ascii=False, indent=2))
        return

    header = "{:<26} {:>9} {:>7} {:>6} {:>6} {:>8}  {}".format(
        "DEVICE", "SCREEN", "COLOR", "BURN", "MEM KB", "API", "NAME"
    )
    print(header)
    print("-" * len(header))

    unknown = []
    for device in devices:
        if device.get("error"):
            unknown.append(device["id"])
            continue
        screen = (
            "{}x{}".format(device["width"], device["height"])
            if device["width"] and device["height"] else "?"
        )
        print("{:<26} {:>9} {:>7} {:>6} {:>6} {:>8}  {}".format(
            device["id"],
            screen,
            str(device["color"] or "?"),
            str(device["burnIn"]) if device["burnIn"] is not None else "?",
            str(device["memoryKb"] or "?"),
            str(device["api"] or "?"),
            str(device["name"] or ""),
        ))
        if device["width"] is None or device["burnIn"] is None:
            unknown.append(device["id"])

    print("\nВсего: {}".format(len(devices)))
    if unknown:
        print(
            "Неполные данные (структура compiler.json отличается): "
            + ", ".join(unknown)
            + "\nПосмотрите ключи вручную: python3 -m json.tool "
            + "'" + os.path.join(DEVICES, unknown[0], "compiler.json") + "'"
        )
    print(
        "\nBURN=true — SDK displayType=amoled. В рантайме игра выбирает палитру "
        "по requiresBurnInProtection; ширина экрана для этого не годится."
    )


if __name__ == "__main__":
    main()
