import subprocess
import json
import datetime
import os
import argparse
import logging
from pathlib import Path

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("SecurityAgent")

class SecurityAgent:
    def __init__(self, workspace_dir):
        self.workspace_dir = Path(workspace_dir)
        self.scans_dir = self.workspace_dir / "scans"
        self.scans_dir.mkdir(parents=True, exist_ok=True)
        
        # Define some basic known/safe ports for anomaly detection
        self.known_ports = {
            "22": "SSH",
            "80": "HTTP",
            "443": "HTTPS",
            "53": "DNS",
            "631": "IPP (Printing)",
            "8080": "HTTP Proxy"
        }
        
        # Docker-specific ports to watch out for
        self.docker_ports = {
            "2375": "Docker Socket (Unencrypted)",
            "2376": "Docker Socket (Encrypted)",
            "2377": "Docker Swarm",
            "7946": "Docker Node Comm",
            "4789": "Docker Overlay Network",
            "5000": "Docker Registry"
        }

    def run_command(self, command):
        """Execute a shell command and return output."""
        try:
            result = subprocess.run(
                command,
                shell=True,
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            return result.stdout.strip()
        except subprocess.CalledProcessError as e:
            logger.error(f"Command failed: {e.cmd}")
            logger.error(f"Error output: {e.stderr}")
            return None

    def scan_network(self, subnet):
        """Run nmap scan on the specified subnet."""
        logger.info(f"Starting network scan on {subnet}...")
        
        # -oX - : Output XML to stdout (for easier parsing if we wanted to add xml parsing later)
        # For now, we'll stick to normal output or grep-able output (-oG) for simplicity in parsing
        timestamp = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        output_file = self.scans_dir / f"scan_{timestamp}.txt"
        
        # Construct nmap command
        # --open: Only show open ports
        # Removed -F to scan default top 1000 ports (includes Docker ports like 2375, 5000)
        cmd = f"nmap --open {subnet} -oN {output_file}"
        
        output = self.run_command(cmd)
        
        if output:
            logger.info(f"Scan completed. Results saved to {output_file}")
            return self.parse_nmap_output(output, output_file)
        return None

    def parse_nmap_output(self, output, filepath):
        """Parse raw nmap output into a structured summary."""
        hosts = []
        current_host = None
        
        for line in output.splitlines():
            if "Nmap scan report for" in line:
                if current_host:
                    hosts.append(current_host)
                # Extract IP/Hostname
                parts = line.split("for")[1].strip()
                current_host = {"target": parts, "ports": []}
            
            elif "/tcp" in line and "open" in line and current_host:
                # Extract port info: 80/tcp open http
                parts = line.split()
                port_id = parts[0].split("/")[0]
                service = parts[2] if len(parts) > 2 else "unknown"
                current_host["ports"].append({"port": port_id, "service": service})

        if current_host:
            hosts.append(current_host)
            
        return {
            "timestamp": datetime.datetime.now().isoformat(),
            "file": str(filepath),
            "hosts": hosts
        }

    def analyze_security(self, scan_result):
        """Analyze scan results for potential issues."""
        alerts = []
        
        for host in scan_result.get("hosts", []):
            target = host["target"]
            for port_info in host["ports"]:
                port = port_info["port"]
                service = port_info["service"]
                
                if port not in self.known_ports:
                    alerts.append(f"UNCOMMON PORT: Host {target} has port {port} ({service}) open.")
                
                # specific checks
                if port in self.docker_ports:
                    alerts.append(f"DOCKER DETECTED: Host {target} has {self.docker_ports[port]} ({port}) open.")

                if port == "23":
                    alerts.append(f"INSECURE: Host {target} has Telnet (23) open.")
                if port == "21":
                    alerts.append(f"INSECURE: Host {target} has FTP (21) open.")

        return alerts

def main():
    parser = argparse.ArgumentParser(description="Security Agent - Network & Security Scanner")
    parser.add_argument("--scan-network", type=str, help="Subnet to scan (e.g., 192.168.0.0/24)")
    parser.add_argument("--workspace", type=str, default=os.path.expanduser("~/.openclaw/workspace"), help="Workspace directory")
    
    args = parser.parse_args()
    
    agent = SecurityAgent(args.workspace)
    
    if args.scan_network:
        result = agent.scan_network(args.scan_network)
        if result:
            alerts = agent.analyze_security(result)
            
            print(f"\n--- Scan Report ---")
            print(f"Hosts found: {len(result['hosts'])}")
            print(f"Log file: {result['file']}")
            
            if alerts:
                print("\n--- Security Alerts ---")
                for alert in alerts:
                    print(f"[!] {alert}")
            else:
                print("\nNo immediate security anomalies detected based on basic rules.")
        else:
            print("Scan failed.")

if __name__ == "__main__":
    main()