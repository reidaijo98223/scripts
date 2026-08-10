# scripts
Compilation of Scripts throughout my Career
---

# Cross-Platform System Specification Gathering Tool

A lightweight, zero-dependency Python utility that queries operating system cores and hardware registries to generate a unified hardware and software resource profile. 

The tool handles cross-platform logic seamlessly by targeting specific platform kernels and system binaries depending on the host architecture.

---

## 🚀 Features

* **Zero External Dependencies** – Uses only native Python standard libraries (`platform`, `sys`, `os`, `subprocess`). No `pip install` required.
* **Smart OS Orchestration** – Automatically identifies the system runtime environment and branches parsing strategies dynamically.
* **Windows Registry Engine** – Queries the Windows Management Instrumentation (`WMIC`) CLI to capture total physical RAM safely.
* **Linux Virtual Filesystem Parsing** – Bypasses slow shell pipes by parsing local system arrays directly from `/proc/cpuinfo` and `/proc/meminfo`.
* **Data Normalization** – Automatically formats raw system blocks and memory fields into standard human-readable Gigabyte (`GB`) formats.

---

## 📋 Gathered Metrics

The script compiles the following variables into an organized terminal summary:

| Component | Extracted Specification |
| :--- | :--- |
| **System Identity** | Host Network Node Name |
| **Operating System** | Platform OS Family (Linux, Windows) & Core Kernel Release |
| **Processor** | Exact Hardware CPU Architecture or Model Name |
| **Memory** | Total Physical Memory Capacity |
| **Runtime Environment** | Active Core Python Interpreter Version |

---

## 💻 Quick Start

### Prerequisites
* Python 3.6 or higher installed on the machine.

### Execution
Run the script directly via your system terminal or command prompt:

```bash
python3 system_spec_gatherer.py
```

### Example Terminal Output

```text
=== Commencing Internal Hardware and OS Spec Scan ===

--- Gathered PC Specifications Profile ---
  Host Name                : PROD-NODE-ALPHA
  Operating System         : Linux
  OS Release Version       : 6.1.0-21-amd64
  OS Architecture          : x86_64
  Python Runtime Build     : 3.11.2
  CPU Model                : AMD EPYC 7763 64-Core Processor
  Total System Memory      : 62.74 GB
------------------------------------------
=== Diagnostics Execution Terminated Successfully ===
```

---

## 🔧 Technical Internals

1. **Fallback Logic**: If a platform-specific command fails (e.g., `WMIC` query restriction or permission isolation), the script leverages soft error handling blocks to report `Unknown` statuses rather than throwing a catastrophic traceback failure.
2. **Precision Management**: Floating memory bytes are normalized to mathematical gigabytes using safe power bit boundaries `(1024 ** 3)` for precise infrastructure reporting.
