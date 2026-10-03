#!/usr/bin/env python3
import datetime
import json
import time


def collect_metrics():
    metrics = {"timestamp": int(time.time())}

    # Parse /proc/loadavg
    try:
        with open("/proc/loadavg", "r") as f:
            parts = f.read().split()
            metrics["cpu_load_1m"] = float(parts[0])
            metrics["cpu_load_5m"] = float(parts[1])
            metrics["cpu_load_15m"] = float(parts[2])
    except IOError as err:
        metrics["cpu_error"] = str(err)

    # Parse /proc/meminfo
    try:
        with open("/proc/meminfo", "r") as f:
            mem = {}
            for line in f:
                parts = line.split(":")
                if len(parts) == 2:
                    mem[parts[0].strip()] = int(parts[1].strip().split()[0])

            metrics["mem_total_mb"] = round(mem.get("MemTotal", 0) / 1024, 2)
            metrics["mem_free_mb"] = round(mem.get("MemFree", 0) / 1024, 2)
            metrics["mem_available_mb"] = round(
                mem.get("MemAvailable", 0) / 1024, 2
            )
    except IOError as err:
        metrics["mem_error"] = str(err)

    # Parse /proc/uptime
    try:
        with open("/proc/uptime", "r") as f:
            metrics["uptime_seconds"] = int(float(f.read().split()[0]))
    except IOError as err:
        metrics["uptime_error"] = str(err)

    return metrics


def main():
    date_str = datetime.datetime.now().strftime("%y-%m-%d")
    log_path = f"/var/log/{date_str}-awesome-monitoring.log"

    payload = collect_metrics()

    with open(log_path, "a") as log_file:
        log_file.write(json.dumps(payload) + "\n")


if __name__ == "__main__":
    main()
