#!/usr/bin/env python3
"""
Cross-Platform System Specification Gathering Tool
Queries operating system cores and hardware registries to output CPU,
RAM, architecture, and platform configurations into a single profile.
"""

import platform
import sys
import os
import subprocess

# --- 1. CORE CROSS-PLATFORM GATHERING -----------------------------------------
def get_base_os_specifications():
    """Extracts platform-agnostic operating system metadata and runtime data."""
    return {
        "Host Name": platform.node(),
        "Operating System": platform.system(),
        "OS Release Version": platform.release(),
        "OS Architecture": platform.machine(),
        "Python Runtime Build": sys.version.split()[0]
    }

# --- 2. WINDOWS PLATFORM REGISTRY ENGINE -------------------------------------
def query_windows_hardware():
    """Queries Windows Management Instrumentation (WMIC) engine for details."""
    hardware_profile = {"CPU Architecture": platform.processor(), "Total System Memory": "N/A"}
    try:
        # Query total capacity of physical memory blocks via command line
        mem_command = ["wmic", "ComputerSystem", "get", "TotalPhysicalMemory"]
        raw_output = subprocess.run(mem_command, text=True, capture_output=True, check=True)
        
        # Clean output string and convert raw bytes into Gigabytes
        lines = [line.strip() for line in raw_output.stdout.split("\n") if line.strip()]
        if len(lines) > 1 and lines[1].isdigit():
            total_bytes = int(lines[1])
            total_gb = round(total_bytes / (1024 ** 3), 2)
            hardware_profile["Total System Memory"] = f"{total_gb} GB"
    except Exception:
        hardware_profile["Total System Memory"] = "Unknown (WMIC Query Interrupted)"
        
    return hardware_profile

# --- 3. LINUX PLATFORM KERNEL ENGINE -----------------------------------------
def query_linux_hardware():
    """Parses native Linux virtual filesystems (/proc) for hardware parameters."""
    hardware_profile = {"CPU Model": "Unknown Linux CPU", "Total System Memory": "N/A"}
    
    # 1. Isolate CPU Model from /proc/cpuinfo
    if os.path.exists("/proc/cpuinfo"):
        try:
            with open("/proc/cpuinfo", "r") as f:
                for line in f:
                    if "model name" in line:
                        hardware_profile["CPU Model"] = line.split(":")[1].strip()
                        break
        except Exception:
            pass

    # 2. Isolate Physical RAM limits from /proc/meminfo
    if os.path.exists("/proc/meminfo"):
        try:
            with open("/proc/meminfo", "r") as f:
                for line in f:
                    if "MemTotal" in line:
                        # Extract the numeric Kilobyte value string
                        kb_val = int(line.split(":")[1].replace("kB", "").strip())
                        total_gb = round(kb_val / (1024 ** 2), 2)
                        hardware_profile["Total System Memory"] = f"{total_gb} GB"
                        break
        except Exception:
            pass

    return hardware_profile

# --- 4. MAIN ORCHESTRATION CONSOLE -------------------------------------------
def main():
    print("=== Commencing Internal Hardware and OS Spec Scan ===")
    
    # Run core system diagnostics
    specs = get_base_os_specifications()
    
    # Pivot resource parsing algorithms depending on target machine type
    if specs["Operating System"] == "Windows":
        win_specs = query_windows_hardware()
        specs.update(win_specs)
    elif specs["Operating System"] == "Linux":
        linux_specs = query_linux_hardware()
        specs.update(linux_specs)
    else:
        specs["Hardware Architecture Note"] = "Generic platform profile tier reached."

    # Render results nicely to the screen
    print("\n--- Gathered PC Specifications Profile ---")
    for property_key, property_value in specs.items():
        print(f"  {property_key:<25}: {property_value}")
    print("------------------------------------------")
    print("=== Diagnostics Execution Terminated Successfully ===")

if __name__ == "__main__":
    main()
