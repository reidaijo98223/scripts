# SCRIPTS
Collection of scripts throughout my technical career.

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

## 📋 Architecture Workflow

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

# Production Application Webcheck & Alerting Engine

A production-ready Bash monitoring script designed to perform multi-stage health checks on application endpoints and VIP URLs. It evaluates both the HTTP response status code and response payload regex validation while implementing smart rate-limiting logic to prevent alert spamming.

---

## 🚀 Features

* **Dual-Stage Content Verification** – Verifies that endpoints return an `HTTP 200 OK` status and checks response bodies against specific text strings using regex patterns.
* **Intelligent Anti-Spam Logic** – Utilizes a sliding time-window matrix file counter to ensure failures must breach 3 distinct validation drops over a rolling 15-minute timeframe before an alert fires.
* **Dual-Channel Alerting** – Simulates operational updates by building dynamic payload bodies distributed across both Email (`mailx`) digests and **Microsoft Teams Incoming Webhooks**.
* **Automated Failure Debouncing** – Suppresses recurring notifications via internal local state tracking tags once an active error condition has been successfully broadcast.
* **Self-Healing State & Recovery Notification** – Tracks down states silently using persistent flag boundaries, automatically dispatching a **Recovery Email** and clearing counters once endpoints return to a healthy status.
* **Autonomous Log Management** – Prunes background execution records continuously, truncating history tracking files to 0 blocks once they exceed `3MB` in footprint size.

---

## 📋 Architecture Workflow

```text
[Start Script Sweep]
         │
         ▼
[Load URL Target Lists]
         │
         ▼
[Execute curl HTTP & Body Checks]
         │
 ┌───────┴───────┐
 ▼               ▼
[Validation OK] [Validation Failed]
 │               │
 │               ▼
 │      [Has Failure Limit Been Met?] (3 Drops within 15 mins)
 │       ├─── No  ──► [Log Counter State] ──► [Process Finished]
 │       └─── Yes ──► [Is State File Active?]
 │                     ├─── Yes ──► [Mute Alert Spam] ──► [Process Finished]
 │                     └─── No  ──► [Send Email & Teams Alerts]
 │                                   │
 │                                   ▼
 │                                  [Generate .status State Flag] ──► [Process Finished]
 ▼
[Does .status Flag Exist?]
 ├─── No  ──► [Process Finished]
 └─── Yes ──► [Send Recovery Email Notification]
               │
               ▼
              [Purge Counter & .status Flag Files] ──► [Process Finished]
```

---

## 💻 Quick Start

### Prerequisites
* **Operating System**: Linux/Unix environment.
* **Utilities**: `curl`, `mailx`, and standard POSIX command tools installed.
* **Network Paths**: Outbound proxy configurations specified for corporate network webhooks (`http://proxy.abc.ei:8080`).

### Configuration & Infrastructure Setup

1. Map the expected folder layout inside the server hosting environment:
   ```text
   \$HOME/cxp_expnow_menu_jumpserver/webchecks/
   ├── <appname-lowercase>/
   │   └── prod/
   │       ├── log/
   │       └── temp/
   └── urls/
       ├── <appname-lowercase>-url.txt       <-- Add Line-separated standard URLs here
       └── <appname-lowercase>-vip-url.txt   <-- Add Line-separated VIP URLs here
   ```

2. Open the script file and configure the target identity variables:
   ```bash
   APPNAME="YOUR_APP_CAPS"                  # e.g., "PLATFORMAPI"
   APPNAME2="your_app_lowercase"            # e.g., "platformapi"
   APP_SERVICE_ACCOUNT_USER="accounts"      # e.g., "gqlrouterint, kongint"
   DEV_TEAM="Your-Dev-Team"                 # e.g., "Windsock"
   WEBCHECK_PHRASE="primary_regex"          # e.g., "auth0.*Available"
   WEBCHECK_PHRASE2="secondary_regex"       # e.g., "EXP NOW"
   SEND_TO="team-inbox@yourdomain.com"      # Primary destination target
   ```

### Execution
Provide executable access flags and launch the verification sequence manually or link it to a system-wide automated scheduling job (`cron`):

```bash
chmod +x webcheck_monitor.sh
./webcheck_monitor.sh
```

---

## 🔧 Technical Specification Notes

* **Proxy Isolation Rules**: The script overrides environment variables locally inside the messaging logic to direct Microsoft Teams webhook connectivity packets through internal proxies while whitelisting target internal endpoints via `NO_PROXY=*.office.com`.
* **String Normalization Execution**: Uses POSIX parameter expansions (`${server_name//[^a-zA-Z0-9]/_}`) to sanitize raw extracted domains dynamically. This formats your system variables safely for file creations on the disk substrate.

## ⏰ Automation with Crontab

To ensure continuous health monitoring, configure the script to run automatically every **5 minutes** using the Linux native cron daemon.

### 1. Open the Crontab Editor
Log into the execution server as the user that owns the script repository and open the cron configuration table:

```bash
crontab -e
```

### 2. Add the Cron Entry
Scroll to the bottom of the file and paste the following line. 

> ⚠️ **Important:** Make sure to replace `/path/to/your/script/` with the absolute path to your actual script file (e.g., `/home/serviceuser/scripts/webcheck_monitor.sh`).

```cron
*/5 * * * * /bin/bash /path/to/your/script/webcheck_monitor.sh > /dev/null 2>&1
```

### 3. Verify the Configuration
Save and close the editor (if using `nano`, press `Ctrl+O`, `Enter`, then `Ctrl+X`). Verify that the cron job was successfully registered by listing your active cron entries:

```bash
crontab -l
```

---

## 🔍 Automation Best Practices & Troubleshooting

* **Absolute Paths Rule**: Crontab operates in a highly restricted shell environment and does not inherit your personal `.bashrc` profiles or custom environment variables. The script handles this internally for its temporary directories by using `$HOME`, but you must specify the **exact absolute path** to the script file itself in the crontab configuration line.
* **Execution Permissions**: Ensure the script has proper executable permissions beforehand, otherwise crontab will fail to launch the process:
  ```bash
  chmod +x /path/to/your/script/webcheck_monitor.sh
  ```
* **Log Verification**: If you want to check if the cron job is actually firing, you can inspect your system's authorization logs:
  ```bash
  # For RHEL / CentOS / Rocky Linux:
  tail -f /var/log/cron | grep webcheck_monitor.sh

  # For Ubuntu / Debian systems:
  tail -f /var/log/syslog | grep CRON
  ```
* **Output Redirection**: The `> /dev/null 2>&1` flag at the end of the cron entry safely silences standard output streams. This prevents your server's local root mail file from filling up with generic console log dumps every 5 minutes.

---

# Lightweight Disk Space Monitor

A lightweight, single-purpose Bash script that proactively scans local disk partitions and alerts system administrators when storage usage breaches a designated percentage threshold. 

## 📋 Features
* **Explicit Column Filtering**: Locks output to specific parameters to completely avoid standard spacing errors caused by long mount point paths.
* **Auto-Sanitization**: Strips trailing percentage signs dynamically on the fly.
* **Color-Coded Feedback**: Outputs clean `CRITICAL` (red) or `OK` (green) terminal metrics for rapid scanning.
* **Zero Dependencies**: Relies exclusively on standard POSIX commands (`df`, `grep`, `bash`).

## ⚙️ Architecture Workflow

```text
[Start Script Sweep] ➔ Load URL Target Lists ➔ Execute curl HTTP & Body Checks
│
┌─────────────────────────┴────────────────────────┐
▼                                                  ▼
[Validation = OK]                                  [Validation = Failed]
Does .status Flag Exist?                           Has Failure Limit Been Met? (3 Drops / 15 mins)
│                       │                          │
▼ (No)                  ▼ (Yes)                    ▼ (No)                   ▼ (Yes)
[Process Finished]      [Send Recovery Email]      [Log Counter State]      Is State File Active?
                        │                                                   │                  │
                        ▼                                                   ▼ (Yes)            ▼ (No)
                        [Purge Counter & Flag Files]                        [Mute Alert Spam]  [Send Email & Teams Alerts]
                        │                                                   │                  │
                        │                                                   │                  ▼
                        │                                                   │                  [Generate .status Flag]
                        │                                                   │                  │
                        └───────────────────────────┬───────────────────────┴──────────────────┘
                                                    ▼
                                            [Process Finished]
```

## 🛠️ Configuration
Open the script file and update the variables at the top of the script according to your infrastructure requirements:

```bash
# Target percentage threshold to trigger warning alerts (Integer value only)
THRESHOLD=75
```

## 🚀 Usage Guide

### 1. Download and Apply Permissions
Clone or place the script on your host machine, then grant executable capabilities:
```bash
chmod +x disk_check.sh
```

### 2. Manual Execution
Run the monitor instantly directly from your terminal console:
```bash
./disk_check.sh
```

### 3. Automated Scheduling (Cron)
To continuously monitor production environments, automate the script check via system `crontab` utilities. 

Open your cron configuration profile:
```bash
crontab -e
```

Add the following rule to execute the validation every hour on the hour, routing output logs to a centralized diagnostic track:
```cron
0 * * * * /path/to/disk_check.sh >> /var/log/disk_monitor.log 2>&1
```

## 🖥️ Sample Console Output

**When threshold is breached:**
```text
Checking disk space on [prod-web-server-01] (Threshold: 75%)...
--------------------------------------------------------
CRITICAL: Partition '/' is at 84% capacity!
--------------------------------------------------------
```

**When system is healthy:**
```text
Checking disk space on [prod-web-server-01] (Threshold: 75%)...
--------------------------------------------------------
OK: All scanned partitions are below 75% capacity.
--------------------------------------------------------
```

---

# PROD Elastic Beats Service Checker & Automated Auto-Restarter

This Bash script provides automated monitoring, health validation, and self-healing remediation for Elastic Beats engines across target infrastructure hosts. 

## ⚙️ Core Logic Flow

```text
[Start Engine Check] ➔ Load Production Server List ➔ Batch SSH Process Check (pgrep)
│
┌─────────────────────────┴────────────────────────┐
▼                                                  ▼
[SSH Status = 0 (Success)]                         [SSH Status = 255 (Failure)]
Evaluate: Metricbeat, Filebeat, & Heartbeat        Log Connection Timeout Exception
│                       │                          │
▼ (All Processes OK)    ▼ (Any Process Down)       ▼
Log Active PIDs         Queue Target Host          Skip Restart Workflow
│                       │                          │
│                       ▼                          │
│                       Execute Remotely:          │
│                       `sudo -iu <beat> start.sh` │
│                       │                          │
└───────────────────────┼──────────────────────────┘
                        ▼
          [Format & Mail Summary Report]
```

## 🚀 Key Features

* **Parallel Process Inspection:** Executes a single combined SSH connection per server to check Metricbeat, Filebeat, and Heartbeat simultaneously, significantly reducing execution overhead and network chatter.
* **Automated Self-Healing:** Instantly isolates down processes and triggers specialized, non-root user remote context application starts (`sudo -iu <service_user>`).
* **Log Rotation Management:** Automatically monitors run histories and clips logs down using size-based threshold optimization rules (`+3MB`).
* **Cross-Platform Mail Alerts:** Standardizes generated failure attachments with target Windows line-ending formatting (`CRLF`) before blasting system notifications via `mail`.

## 📁 System Requirements & Directories

The system searches and manages internal state indicators within these localized structures:

* **Base Path:** `$HOME/abc_expnow_menu_jumpserver/servicechecks/beats/prod`
* **Inventory Host List:** `inventory/prod-server-list.txt` (newline separated server strings)
* **Temporary Storage File:** `temp/failed-exponow-prod-beats-report.txt`
* **Append Execution Log:** `log/beats-prod-servicechecks-run-history`

## 🛠️ Usage Instructions

### 1. Configure the Target Inventory
Populate your environment destinations inside your inventory file structure:
```bash
cat << 'EOF' > ~/abc_expnow_menu_jumpserver/servicechecks/beats/prod/inventory/prod-server-list.txt
prod-app-server-01.domain.lan
prod-app-server-02.domain.lan
EOF
```

### 2. Execution Run
Ensure executable permissions are granted and trigger the check engine directly or via systematic Cron schedules:
```bash
chmod +x check_beats.sh
./check_beats.sh
```
## ⏰ Automated Scheduling (Crontab)

To ensure high availability, configure the script to execute automatically every **5 minutes** using the system cron daemon. 

### 1. Open the Crontab Editor
Log into the jump server as the deployment user and access your user schedule:
```bash
crontab -e
```

### 2. Append the Cron Entry
Add the following line at the bottom of the file. This profile handles explicit paths and pipes console standard errors straight into your localized history log:

```text
*/5 * * * * /bin/bash \(HOME/abc_expnow_menu_jumpserver/servicechecks/beats/prod/check_beats.sh >>\)HOME/abc_expnow_menu_jumpserver/servicechecks/beats/prod/log/beats-prod-servicechecks-run-history 2>&1
```

### 3. Verify Active Engine Schedules
Confirm your automated check rule is active inside your profile engine:
```bash
crontab -l
```
---

# Linux Middleware Automated Installation Utility

An enterprise-grade Python automation utility designed to standardize the deployment, lifecycle tracking, and permission hardening of third-party open-source middleware stacks (OpenJDK, Apache HTTP Server, and Apache Tomcat). 

## ⚙️ Architecture Workflow

```text
[Start Script Execution]
           │
           ▼
[Enforce Root Privileges] (Requires sudo)
           │
   ┌───────┴───────┐
   ▼               ▼
[Root Active?] [Access Denied] ──► Exit 1
   │
   ▼
[Download N-1 Stable Artifacts]
   ├─── OpenJDK 21 (Temurin Long-Term Support train)
   ├─── Apache HTTP Server 2.4.x (Source Build compiled with native libraries)
   └─── Apache Tomcat 10.1.x
   │
   ▼
[Deploy to Isolated Versioned Targets] (/opt/java-*, /opt/httpd-*, /opt/tomcat-*)
   │
   ▼
[Apply Atomic Symbolic Masking Links] (/opt/java, /opt/httpd, /opt/tomcat)
   │
   ▼
[Execute OS Hardening & User Separation Tasks]
   ├─── Infrastructure Isolation ──► Shared Read/Execute Access (root:root)
   └─── Application Isolation    ──► Service Account Sandbox (tomcat:tomcat)
   │
   ▼
[Finalize Systemd Service Contexts] ──► [Process Finished]
```

## 🚀 Key Features

* **Deterministic Version Pinning (N-1 Rule):** Mitigates production regressions by locking runtime elements exactly one minor/patch cycle behind the latest GA line.
* **Zero-Downtime Atomic Symlinking:** Extracts packages directly into isolated, timestamped/versioned directories inside `/opt` before swapping structural symlinks. This ensures swift rollbacks without file system fragmentation.
* **Granular Privilege Layering:** 
  * Hardens shared components (`/opt/java`) under strict `root:root` custody with standard global read-execute boundaries (`755` directories, `644`/`755` files).
  * Sandboxes application runtimes (`/opt/tomcat`) under dedicated, unprivileged operating system users (`tomcat`).
* **Automated Native Compilations:** Dynamically interrogates local host environments for package managers (`dnf`, `yum`, `apt-get`) to bootstrap compilers and native platform development libraries (`APR`, `PCRE`, `OpenSSL`) needed to compile Apache HTTPD cleanly from source.

## 📦 Runtime Environment Target Layout

The script establishes and enforces the following architectural hierarchy on target nodes:

```text
/opt/
├── java-21.0.11_9/       <-- Actual Versioned Archive Extracted Path (Root Protected)
├── java --------─-------─► Symbolic Pointer Link referencing /opt/java-21.0.11_9
├── httpd-2.4.67/         <-- Source Compiled Output Tree (Target Root Guarded)
├── httpd ---------------─► Symbolic Pointer Link referencing /opt/httpd-2.4.67
├── apache-tomcat-10.1.34/ <-- Isolated App Server Container Workspace (Tomcat Owned)
└── tomcat --------------─► Symbolic Pointer Link referencing /opt/apache-tomcat-10.1.34
```

## 🛠️ Usage Instructions

### 1. Prerequisites
Ensure target machines have outbound HTTPS access enabled to hit the designated artifact distribution mirroring hubs:
* `github.com` (Adoptium Temurin OpenJDK binaries)
* `archive.apache.org` (Apache Softwares distributions)

### 2. Execution Run
The provisioning engine manipulates operating system configurations and requires elevated root permissions to bind services. Run the utility using explicit administrative contexts:

```bash
# Set file operational execute permissions
chmod +x middleware_installer.py

# Launch automation via sudo execution boundaries
sudo ./middleware_installer.py
```
---




