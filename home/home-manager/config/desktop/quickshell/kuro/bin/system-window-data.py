#!/usr/bin/env python3
"""Structured data source for the Quickshell system dashboard."""

import csv
import json
import os
import re
import subprocess
import sys
from pathlib import Path


def command(args, timeout=5):
    try:
        return subprocess.run(args, check=False, text=True, capture_output=True, timeout=timeout)
    except (OSError, subprocess.TimeoutExpired):
        return None


def read_text(path, default=""):
    try:
        return Path(path).read_text().strip()
    except OSError:
        return default


def number(value, default=0):
    try:
        return int(float(value.strip()))
    except (AttributeError, TypeError, ValueError):
        return default


def performance():
    cpu_line = read_text("/proc/stat").splitlines()[0].split()
    cpu_values = [int(value) for value in cpu_line[1:]]
    cpu = {"total": sum(cpu_values), "idle": cpu_values[3] + cpu_values[4]}

    memory = {}
    for line in read_text("/proc/meminfo").splitlines():
        key, _, value = line.partition(":")
        if key in ("MemTotal", "MemAvailable"):
            memory[key] = int(value.strip().split()[0])

    disk_read = disk_written = 0
    disk_pattern = re.compile(r"^(nvme\d+n\d+|sd[a-z]+|vd[a-z]+|xvd[a-z]+|mmcblk\d+)$")
    for line in read_text("/proc/diskstats").splitlines():
        fields = line.split()
        if len(fields) >= 14 and disk_pattern.match(fields[2]):
            disk_read += int(fields[5])
            disk_written += int(fields[9])

    interface = ""
    for line in read_text("/proc/net/route").splitlines()[1:]:
        fields = line.split()
        if len(fields) > 3 and fields[1] == "00000000":
            try:
                if int(fields[3], 16) & 0x3 == 0x3:
                    interface = fields[0]
                    break
            except ValueError:
                pass
    if not interface:
        for path in Path("/sys/class/net").glob("*"):
            if path.name != "lo" and read_text(path / "operstate") == "up":
                interface = path.name
                break
    network = {"interface": interface, "rx": 0, "tx": 0}
    if interface:
        network["rx"] = int(read_text(f"/sys/class/net/{interface}/statistics/rx_bytes", "0") or 0)
        network["tx"] = int(read_text(f"/sys/class/net/{interface}/statistics/tx_bytes", "0") or 0)

    return {
        "cpu": cpu,
        "memory": {
            "total": memory.get("MemTotal", 0),
            "available": memory.get("MemAvailable", 0),
        },
        "disk": {"readSectors": disk_read, "writtenSectors": disk_written},
        "network": network,
    }


def hardware():
    os_info = {}
    for line in read_text("/etc/os-release").splitlines():
        key, separator, value = line.partition("=")
        if separator and key in ("PRETTY_NAME",):
            os_info[key] = value.strip().strip('"')

    cpu_model = ""
    for line in read_text("/proc/cpuinfo").splitlines():
        if line.lower().startswith(("model name", "hardware")):
            cpu_model = line.split(":", 1)[-1].strip()
            break

    monitors = []
    result = command(["hyprctl", "-j", "monitors"])
    if result and result.returncode == 0:
        try:
            for monitor in json.loads(result.stdout):
                monitors.append({
                    "name": monitor.get("name", ""),
                    "resolution": f"{monitor.get('width', 0)}×{monitor.get('height', 0)}",
                    "scale": monitor.get("scale", 1),
                    "refresh": round(monitor.get("refreshRate", 0)),
                })
        except (ValueError, TypeError):
            pass

    platform = {}
    dmi = Path("/sys/devices/virtual/dmi/id")
    for key in ("sys_vendor", "product_name", "board_vendor", "board_name", "bios_vendor", "bios_version"):
        value = read_text(dmi / key)
        if value:
            platform[key] = value

    gpus = []
    nvidia = command([
        "nvidia-smi",
        "--query-gpu=name,driver_version,memory.total,memory.used,utilization.gpu,temperature.gpu",
        "--format=csv,noheader,nounits",
    ], timeout=8)
    if nvidia and nvidia.returncode == 0:
        for row in csv.reader(nvidia.stdout.splitlines()):
            if len(row) >= 6:
                gpus.append({
                    "vendor": "NVIDIA", "kind": "Discrete GPU", "name": row[0].strip(),
                    "driver": row[1].strip(), "memoryTotal": number(row[2]),
                    "memoryUsed": number(row[3]),
                    "utilization": number(row[4]),
                    "temperature": number(row[5]),
                })

    pci = command(["lspci", "-mm", "-nn"])
    if pci and pci.returncode == 0:
        pattern = re.compile(r'^\S+ "([^"]+)" "([^"]+)" "([^"]+)"')
        for line in pci.stdout.splitlines():
            if not any(kind in line for kind in ("VGA compatible controller", "3D controller", "Display controller")):
                continue
            match = pattern.match(line)
            if not match:
                continue
            kind, vendor, name = (
                re.sub(r"\s*\[[0-9a-fA-F]{4}\]", "", part).strip()
                for part in match.groups()
            )
            if "nvidia" in vendor.lower() and any(gpu["vendor"] == "NVIDIA" for gpu in gpus):
                continue
            gpus.append({"vendor": vendor, "kind": kind, "name": name})

    disks = []
    lsblk = command(["lsblk", "-J", "-d", "-o", "NAME,MODEL,SIZE,TYPE"])
    if lsblk and lsblk.returncode == 0:
        try:
            disks = [
                {
                    key.lower(): device.get(key.lower()) or ""
                    for key in ("NAME", "MODEL", "SIZE", "TYPE")
                }
                for device in json.loads(lsblk.stdout).get("blockdevices", [])
            ]
        except (ValueError, TypeError):
            pass

    uptime_seconds = 0
    try:
        uptime_seconds = int(float(read_text("/proc/uptime").split()[0]))
    except (ValueError, IndexError):
        pass
    meminfo = {}
    for line in read_text("/proc/meminfo").splitlines():
        key, _, value = line.partition(":")
        if key in ("MemTotal", "MemAvailable"):
            meminfo[key] = int(value.strip().split()[0])

    version = command(["hyprctl", "version"])
    platform.update({
        "architecture": os.uname().machine,
        "logical_threads": os.cpu_count() or 0,
    })
    return {
        "host": read_text("/proc/sys/kernel/hostname", "localhost"),
        "uptimeSeconds": uptime_seconds,
        "kernel": os.uname().release,
        "os": os_info.get("PRETTY_NAME", ""),
        "architecture": os.uname().machine,
        "logicalThreads": os.cpu_count() or 0,
        "cpu": cpu_model,
        "memoryTotal": meminfo.get("MemTotal", 0),
        "memoryAvailable": meminfo.get("MemAvailable", 0),
        "compositor": version.stdout.splitlines()[0] if version and version.stdout else "",
        "monitors": monitors,
        "platform": platform,
        "gpus": gpus,
        "disks": disks,
    }


def storage():
    result = command(["df", "-h", "--output=source,fstype,size,used,avail,pcent,target"])
    if not result or result.returncode != 0:
        return {"error": result.stderr.strip() if result else "df is unavailable"}
    rows = []
    for line in result.stdout.splitlines()[1:]:
        fields = line.split(None, 6)
        if len(fields) == 7:
            # Keep real filesystems plus the root mount; hide the dozens of
            # container/runtime tmpfs and credential mounts from the table.
            if not fields[0].startswith("/dev/") and fields[6] != "/":
                continue
            rows.append({
                "device": fields[0], "type": fields[1], "size": fields[2],
                "used": fields[3], "available": fields[4],
                "percent": int(fields[5].rstrip("%") or 0), "mount": fields[6],
            })
    return {"filesystems": rows}


def logs():
    result = command(["journalctl", "-b", "-n", "150", "--no-pager", "-o", "short-iso"], timeout=8)
    if not result:
        return {"error": "journalctl is unavailable"}
    if result.returncode != 0:
        return {"error": result.stderr.strip() or "Could not read the boot journal"}
    return {"logs": result.stdout.rstrip()}


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "hardware"
    handlers = {"performance": performance, "hardware": hardware, "storage": storage, "logs": logs}
    handler = handlers.get(mode)
    if handler is None:
        result = {"error": f"Unknown data view: {mode}"}
    else:
        try:
            result = handler()
        except Exception as error:  # keep malformed/unavailable host data from breaking QML
            result = {"error": str(error)}
    print(json.dumps(result, ensure_ascii=False))


if __name__ == "__main__":
    main()
