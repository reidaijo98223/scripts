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

---

# PROD Apache (HTTPD) Service Check & Automated Remediation Tool

A production-grade Bash script designed to centrally monitor Apache (`httpd`) instances across multiple remote servers. The tool handles status checks, filters out network/connectivity issues, triggers automated service restarts via SSH, and emails system report digests to core engineering teams.

---

## 🚀 Features

* **Single-Pass Overhead Optimization** – Aggregates remote checking constraints into unified loop matrices to significantly reduce SSH connection overhead.
* **Intelligent Network Isolation** – Distinguishes between an Apache failure (service down) and an actual network/infrastructure drop (`SSH Exit Code 255`) to prevent false-positive remediation triggers.
* **Automated Remediation** – Instantly executes a `systemctl restart httpd` on targeted failed host pools and verifies process survival by capturing the new `PID`.
* **Integrated Log Truncation** – Automated background pruning limits history log footprint growth (`find -size` parameters) to maintain lightweight operational tracking storage.
* **Email Reporting Alert System** – Formats and ships an execution log attachment dynamically to defined incident operations groups via `mailx`.

---

## 📋 Operational Workflow

```text
[Start Engine] ➔ Reads Inventory List ➔ Iterates Hosts via SSH
│
┌─────────────────────────┴────────────────────────┐
▼                                                  ▼
[SSH Status = 0]                                   [SSH Status = 255]
Is Apache Active? (pgrep)                          Network/Auth Exception Triggered
│                       │                          │
▼ (Yes)                 ▼ (No)                     ▼
[Log OK]                [Queue Host for Restart]   [Log Connection Error]
│                       │                          │
│                       ▼                          ▼
│                       [Execute Remote Restart]   [Skip Restart Workflow]
│                       │                          │
└───────────────────────┼──────────────────────────┘
                        ▼
          [Format & Mail Summary Report]
```
---

## 💻 Quick Start

### Prerequisites
* Safe execution configuration requirements: Central manager node requires SSH key-pair mapping to the target server matrix (`chq-reinogar@$server`).
* Elevated target permissions: The automated service account user must have tailored `sudoers` rules to execute `sudo systemctl restart httpd` without terminal password prompt dependencies.

### Directory Infrastructure Mapping
The utility assumes standard path availability configuration within the runner engine footprint:
```text
\$HOME/cxp_exponow_menu_jumpserver/servicechecks/apache-httpd/prod/
├── inventory/
│   └── prod-server-list.txt   <-- Populate with line-separated remote hostnames/IPs
├── log/
│   └── apache-httpd-prod-servicechecks-run-history
└── temp/
    └── failed-exponow-prod-apache-httpd-report.txt
```

### Execution
Trigger the monitoring sweep via manual interaction or system engine scheduling hooks (`cron`):

```bash
chmod +x apache_monitor.sh
./apache_monitor.sh
```

---

## 🔧 Technical Parameters Reference

* **Connection Strictness**: Enforces rigid connection drops (`ConnectTimeout=3`) and error suppression (`LogLevel=error`) during host inventory parsing loops.
* **Format Normalization**: Employs `sed` transformations to convert output telemetry payloads into carriage return structures (`\r`), stripping empty line artifacts before report delivery.

---


