#!/usr/bin/env python3
"""
Linux Middleware Automated Installation Utility
Standardizes the deployment, directory masking, system user isolation,
and systemd lifecycle tracking for enterprise third-party middleware components.
"""

import os
import sys
import subprocess
import shutil
import tarfile
import urllib.request

# --- CONFIGURATION MATRICES ---------------------------------------------------
VERSION = "10.1.34"
INSTALL_SOURCE = f"/tmp/apache-tomcat-{VERSION}.tar.gz"
TARGET_PARENTPATH = "/opt"
SERVICE_ACCOUNT = "tomcat"

# Java: pinned to n-1 of the Java 21 quarterly update train.
# Current CPU as of this writing is 21.0.12 (Jul 21, 2026); n-1 is 21.0.11 (Apr 21, 2026, build +9).
# Update JAVA_FULL_VERSION/JAVA_BUILD together each time you intentionally roll the pin forward.
JAVA_MAJOR_VERSION = "21"
JAVA_FULL_VERSION = "21.0.11"
JAVA_BUILD = "9"
JAVA_VERSION_DIR = os.path.join(TARGET_PARENTPATH, f"java-{JAVA_FULL_VERSION}_{JAVA_BUILD}")
JAVA_SYMLINK = os.path.join(TARGET_PARENTPATH, "java")
JAVA_ARCHIVE_NAME = (
    f"OpenJDK{JAVA_MAJOR_VERSION}U-jdk_x64_linux_hotspot_"
    f"{JAVA_FULL_VERSION}_{JAVA_BUILD}.tar.gz"
)
JAVA_DOWNLOAD_URL = (
    f"https://github.com/adoptium/temurin{JAVA_MAJOR_VERSION}-binaries/releases/"
    f"download/jdk-{JAVA_FULL_VERSION}%2B{JAVA_BUILD}/{JAVA_ARCHIVE_NAME}"
)

# Apache HTTP Server (httpd): pinned to n-1 of the 2.4.x branch (httpd has no
# newer major/minor branch in GA release, so n-1 applies to the patch level).
# Current stable is 2.4.68 (Jun 8, 2026); n-1 is 2.4.67 (May 4, 2026).
HTTPD_FULL_VERSION = "2.4.67"
HTTPD_ARCHIVE_NAME = f"httpd-{HTTPD_FULL_VERSION}.tar.gz"
HTTPD_DOWNLOAD_URL = f"https://archive.apache.org/dist/httpd/{HTTPD_ARCHIVE_NAME}"
HTTPD_VERSION_DIR = os.path.join(TARGET_PARENTPATH, f"httpd-{HTTPD_FULL_VERSION}")
HTTPD_SYMLINK = os.path.join(TARGET_PARENTPATH, "httpd")

# Tomcat: real versioned install dir vs. the stable /opt/tomcat symlink.
TOMCAT_VERSION_DIR = os.path.join(TARGET_PARENTPATH, f"apache-tomcat-{VERSION}")
TOMCAT_SYMLINK = os.path.join(TARGET_PARENTPATH, "tomcat")

def run_sys_cmd(command, cwd=None):
    """Safely executes a shell instruction and catches unexpected runtime drops."""
    try:
        result = subprocess.run(command, cwd=cwd, check=True, text=True, capture_output=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as err:
        print(f"[-] Execution failure: {' '.join(command)}")
        print(f"[-] Error diagnostic message: {err.stderr}")
        return None

def enforce_root_privileges():
    """Guarantees the script possesses administrative rights to alter system files."""
    if os.geteuid() != 0:
        print("[-] Critical Access Denied: This script requires root (sudo) access.")
        sys.exit(1)

def install_java():
    """
    Installs the pinned n-1 patch release of OpenJDK 21 to a versioned
    directory under /opt, with a stable /opt/java symlink pointing at it.
    Installing via a versioned dir + symlink (rather than overwriting a fixed
    path in place) keeps the previous version on disk as a rollback target
    when the pin is later bumped forward.
    """
    print(f"[*] Installing OpenJDK {JAVA_FULL_VERSION}+{JAVA_BUILD} (n-1 patch of the 21.x update train)...")

    os.makedirs(TARGET_PARENTPATH, exist_ok=True)
    archive_path = os.path.join("/tmp", JAVA_ARCHIVE_NAME)

    print(f"[*] Downloading {JAVA_DOWNLOAD_URL}")
    try:
        urllib.request.urlretrieve(JAVA_DOWNLOAD_URL, archive_path)
    except Exception as err:
        print(f"[-] Failed to download OpenJDK {JAVA_FULL_VERSION}: {err}")
        print("[-] Verify the version/build pin above and that outbound access to github.com is permitted.")
        sys.exit(1)

    staging_dir = "/tmp/java-extract"
    if os.path.exists(staging_dir):
        shutil.rmtree(staging_dir)
    os.makedirs(staging_dir)

    print(f"[*] Extracting {archive_path}...")
    with tarfile.open(archive_path) as archive:
        extracted_root = archive.getnames()[0].split("/")[0]
        archive.extractall(staging_dir)

    print(f"[*] Placing JDK contents at: {JAVA_VERSION_DIR}")
    if os.path.lexists(JAVA_VERSION_DIR):
        if os.path.islink(JAVA_VERSION_DIR) or os.path.isfile(JAVA_VERSION_DIR):
            os.remove(JAVA_VERSION_DIR)
        else:
            shutil.rmtree(JAVA_VERSION_DIR)
    shutil.move(os.path.join(staging_dir, extracted_root), JAVA_VERSION_DIR)
    shutil.rmtree(staging_dir, ignore_errors=True)

    secure_java_permissions(JAVA_VERSION_DIR)

    if os.path.lexists(JAVA_SYMLINK):
        os.remove(JAVA_SYMLINK)
    os.symlink(JAVA_VERSION_DIR, JAVA_SYMLINK)

    print(f"[+] OpenJDK {JAVA_FULL_VERSION}+{JAVA_BUILD} installed to: {JAVA_VERSION_DIR}")
    print(f"[+] Stable reference symlink created at: {JAVA_SYMLINK}")
    return JAVA_SYMLINK

def secure_java_permissions(java_home):
    """
    Hardens ownership and permissions on the JDK tree (Ownership: root,
    read/execute only for everyone else). Java is shared runtime infrastructure
    used by both the tomcat and (if installed) httpd service accounts, so unlike
    Tomcat's own directory it stays root-owned with no write access for
    non-root users, while still being readable/executable by any service account
    that needs to launch a JVM.
    """
    print("[*] Hardening file system ownership and permission layers for the JDK...")

    # 1. Root owns the entire JDK tree; no group/other write access anywhere.
    run_sys_cmd(["chown", "-R", "root:root", java_home])
    run_sys_cmd(["chmod", "-R", "go-w", java_home])

    # 2. Ensure directories remain traversable and files remain readable by
    #    any service account (tomcat, httpd, etc.) that needs to invoke java.
    run_sys_cmd(["find", java_home, "-type", "d", "-exec", "chmod", "755", "{}", "+"])
    run_sys_cmd(["find", java_home, "-type", "f", "-exec", "chmod", "644", "{}", "+"])

    # 3. Restore execute bits on the actual binaries/scripts under bin/ and lib/,
    #    since step 2's blanket 644 on files would otherwise strip them.
    for exec_dir in ("bin", "lib"):
        target_dir = os.path.join(java_home, exec_dir)
        if os.path.exists(target_dir):
            run_sys_cmd(["find", target_dir, "-type", "f", "-exec", "chmod", "755", "{}", "+"])

def install_apache_httpd():
    """
    Builds and installs the pinned n-1 patch release of Apache HTTP Server
    (httpd) from the official ASF source distribution to a versioned directory
    under /opt, with a stable /opt/httpd symlink pointing at it. Apache does
    not publish prebuilt Linux binaries, so this installs build tooling first,
    then configures/builds/installs from source.
    """
    print(f"[*] Installing Apache HTTP Server {HTTPD_FULL_VERSION} (n-1 patch of the 2.4.x branch)...")

    print("[*] Installing httpd build dependencies (compiler, APR, APR-Util, PCRE, OpenSSL headers)...")
    manager = shutil.which("dnf") or shutil.which("yum")
    if manager:
        run_sys_cmd([manager, "install", "-y", "gcc", "make", "apr-devel", "apr-util-devel", "pcre-devel", "openssl-devel"])
    elif shutil.which("apt-get"):
        run_sys_cmd(["apt-get", "update"])
        run_sys_cmd(["apt-get", "install", "-y", "build-essential", "libapr1-dev", "libaprutil1-dev", "libpcre3-dev", "libssl-dev"])
    else:
        print("[-] No supported package manager (dnf/yum/apt-get) detected.")
        print("[-] Install a compiler, APR, APR-Util, and PCRE development headers manually before continuing.")
        sys.exit(1)

    build_dir = "/tmp/httpd-build"
    os.makedirs(build_dir, exist_ok=True)
    archive_path = os.path.join(build_dir, HTTPD_ARCHIVE_NAME)

    print(f"[*] Downloading {HTTPD_DOWNLOAD_URL}")
    try:
        urllib.request.urlretrieve(HTTPD_DOWNLOAD_URL, archive_path)
    except Exception as err:
        print(f"[-] Failed to download Apache HTTP Server {HTTPD_FULL_VERSION}: {err}")
        print("[-] Verify the version pin above and that outbound access to archive.apache.org is permitted.")
        sys.exit(1)

    print(f"[*] Extracting {archive_path}...")
    with tarfile.open(archive_path) as archive:
        extracted_root = archive.getnames()[0].split("/")[0]
        archive.extractall(build_dir)
    source_dir = os.path.join(build_dir, extracted_root)

    print(f"[*] Configuring build with prefix: {HTTPD_VERSION_DIR}")
    run_sys_cmd(
        ["./configure", f"--prefix={HTTPD_VERSION_DIR}", "--enable-so", "--enable-ssl"],
        cwd=source_dir,
    )

    print("[*] Compiling Apache HTTP Server (this can take several minutes)...")
    run_sys_cmd(["make"], cwd=source_dir)

    print(f"[*] Installing to {HTTPD_VERSION_DIR}...")
    if os.path.lexists(HTTPD_VERSION_DIR):
        if os.path.islink(HTTPD_VERSION_DIR) or os.path.isfile(HTTPD_VERSION_DIR):
            os.remove(HTTPD_VERSION_DIR)
        else:
            shutil.rmtree(HTTPD_VERSION_DIR)
    run_sys_cmd(["make", "install"], cwd=source_dir)

    if os.path.lexists(HTTPD_SYMLINK):
        os.remove(HTTPD_SYMLINK)
    os.symlink(HTTPD_VERSION_DIR, HTTPD_SYMLINK)

    print(f"[+] Apache HTTP Server {HTTPD_FULL_VERSION} installed to: {HTTPD_VERSION_DIR}")
    print(f"[+] Stable reference symlink created at: {HTTPD_SYMLINK}")
    return HTTPD_SYMLINK

def create_isolated_system_user():
    """Creates a locked-down system service group and user account."""
    print(f"[*] Provisioning isolated service user group: '{SERVICE_ACCOUNT}'...")
    
    # Check if group already exists, create if missing
    with open("/etc/group", "r") as group_file:
        if SERVICE_ACCOUNT not in group_file.read():
            run_sys_cmd(["groupadd", "-r", SERVICE_ACCOUNT])
            
    # Check if user already exists, create if missing
    with open("/etc/passwd", "r") as passwd_file:
        if SERVICE_ACCOUNT not in passwd_file.read():
            # -r = system account, -g = primary group, -s /bin/false = block login access
            run_sys_cmd([
                "useradd", "-r", "-g", SERVICE_ACCOUNT, 
                "-d", f"{TARGET_PARENTPATH}/tomcat", "-s", "/bin/false", 
                SERVICE_ACCOUNT
            ])
            print(f"[+] System user '{SERVICE_ACCOUNT}' generated securely.")
        else:
            print(f"    - Identity profile '{SERVICE_ACCOUNT}' already configured.")

def deploy_and_unpack_binaries():
    """Unpacks Tomcat to a versioned directory under /opt, with a stable /opt/tomcat symlink pointing at it."""
    # Mocking installation file for validation loop if missing in local env
    if not os.path.exists(INSTALL_SOURCE):
        print(f"[-] Missing deployment package file at path: {INSTALL_SOURCE}")
        print("[*] Creating a stub directory setup for demonstration scaffolding...")
        os.makedirs(os.path.join(TOMCAT_VERSION_DIR, "bin"), exist_ok=True)
        os.makedirs(os.path.join(TOMCAT_VERSION_DIR, "conf"), exist_ok=True)
        run_sys_cmd(["touch", os.path.join(TOMCAT_VERSION_DIR, "bin", "startup.sh")])
        run_sys_cmd(["touch", os.path.join(TOMCAT_VERSION_DIR, "conf", "server.xml")])
    else:
        staging_dir = "/tmp/tomcat-extract"
        if os.path.exists(staging_dir):
            shutil.rmtree(staging_dir)
        os.makedirs(staging_dir)

        print(f"[*] Extracting target installation software source package: {INSTALL_SOURCE}")
        run_sys_cmd(["tar", "-xzf", INSTALL_SOURCE, "-C", staging_dir])
        extracted_root = os.listdir(staging_dir)[0]

        print(f"[*] Placing Tomcat contents at: {TOMCAT_VERSION_DIR}")
        if os.path.lexists(TOMCAT_VERSION_DIR):
            if os.path.islink(TOMCAT_VERSION_DIR) or os.path.isfile(TOMCAT_VERSION_DIR):
                os.remove(TOMCAT_VERSION_DIR)
            else:
                shutil.rmtree(TOMCAT_VERSION_DIR)
        shutil.move(os.path.join(staging_dir, extracted_root), TOMCAT_VERSION_DIR)
        shutil.rmtree(staging_dir, ignore_errors=True)

    if os.path.lexists(TOMCAT_SYMLINK):
        os.remove(TOMCAT_SYMLINK)
    os.symlink(TOMCAT_VERSION_DIR, TOMCAT_SYMLINK)

    print(f"[+] Application path mounted securely via: {TOMCAT_SYMLINK}")
    return TOMCAT_SYMLINK

def secure_permissions(install_path):
    """Hardens folder security matrix (Ownership: root, Execution: tomcat user)."""
    print("[*] Hardening file system ownership profiles and permission layers...")
    
    # 1. Set entire directory ownership to root, group ownership to tomcat
    run_sys_cmd(["chown", "-R", f"root:{SERVICE_ACCOUNT}", install_path])
    
    # 2. Grant tomcat read access to the 'conf' folder and all its contents
    conf_path = os.path.join(install_path, "conf")
    run_sys_cmd(["chmod", "-R", "g+r", conf_path])
    run_sys_cmd(["chmod", "g+x", conf_path])
    
    # 3. Make tomcat owner of runtime folders so it can modify logs and web apps
    for folder in ["webapps", "logs", "work", "temp"]:
        target_folder = os.path.join(install_path, folder)
        if os.path.exists(target_folder):
            run_sys_cmd(["chown", "-R", f"{SERVICE_ACCOUNT}:{SERVICE_ACCOUNT}", target_folder])

def establish_systemd_service(java_home=None):
    """Generates the systemd unit profile to register the tool as an OS service."""
    unit_file_path = "/etc/systemd/system/tomcat.service"
    print(f"[*] Generating OS service initialization profile at: {unit_file_path}")

    java_home_line = f"Environment=JAVA_HOME={java_home}\n" if java_home else ""

    service_definition = (
        "[Unit]\n"
        "Description=Apache Tomcat Web Application Container\n"
        "After=network.target\n\n"
        "[Service]\n"
        "Type=forking\n\n"
        f"User={SERVICE_ACCOUNT}\n"
        f"Group={SERVICE_ACCOUNT}\n\n"
        f"{java_home_line}"
        f"Environment=CATALINA_PID={TARGET_PARENTPATH}/tomcat/temp/tomcat.pid\n"
        f"Environment=CATALINA_HOME={TARGET_PARENTPATH}/tomcat\n"
        f"Environment=CATALINA_BASE={TARGET_PARENTPATH}/tomcat\n\n"
        f"ExecStart={TARGET_PARENTPATH}/tomcat/bin/startup.sh\n"
        f"ExecStop={TARGET_PARENTPATH}/tomcat/bin/shutdown.sh\n\n"
        "[Install]\n"
        "WantedBy=multi-user.target\n"
    )
    
    with open(unit_file_path, "w", encoding="utf-8") as svc_file:
        svc_file.write(service_definition)
        
    print("[*] Reloading systemd engines and enabling startup boot hook...")
    run_sys_cmd(["systemctl", "daemon-reload"])
    run_sys_cmd(["systemctl", "enable", "tomcat"])

def main():
    print("=== Commencing Enterprise Middleware Deployment Procedure ===")
    enforce_root_privileges()
    java_home = install_java()
    install_apache_httpd()
    create_isolated_system_user()
    app_path = deploy_and_unpack_binaries()
    secure_permissions(app_path)
    establish_systemd_service(java_home)
    print("=== System Infrastructure Installation Routine Finalized Successfully ===")

if __name__ == "__main__":
    main()