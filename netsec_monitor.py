
import xml.etree.ElementTree as ET
import json
import os

BASELINE_FILE = 'memory/netsec-baseline.json'
SCAN_FILE = 'nmap_scan.xml'

def load_baseline():
    if os.path.exists(BASELINE_FILE):
        with open(BASELINE_FILE, 'r') as f:
            return json.load(f)
    return {"open_ports": []}

def save_baseline(data):
    with open(BASELINE_FILE, 'w') as f:
        json.dump(data, f, indent=2)

def parse_nmap_xml(xml_data):
    root = ET.fromstring(xml_data)
    open_ports = []
    for host_element in root.findall('host'):
        for ports_element in host_element.findall('ports'):
            for port_element in ports_element.findall('port'):
                if port_element.find('state').get('state') == 'open':
                    port_info = {
                        "port": int(port_element.get('portid')),
                        "protocol": port_element.get('protocol'),
                        "service": port_element.find('service').get('name') if port_element.find('service') is not None else 'unknown'
                    }
                    open_ports.append(port_info)
    return {"open_ports": open_ports}

def compare_scans(baseline_data, current_scan_data):
    baseline_ports_set = set()
    for p in baseline_data['open_ports']:
        baseline_ports_set.add((p['port'], p['protocol'], p['service']))

    current_ports_set = set()
    for p in current_scan_data['open_ports']:
        current_ports_set.add((p['port'], p['protocol'], p['service']))

    new_open_ports = current_ports_set - baseline_ports_set
    closed_ports = baseline_ports_set - current_ports_set

    risks_found = False
    message_to_send = []

    if new_open_ports:
        risks_found = True
        message_to_send.append("🚨 **NetSec Alert: New Open Ports Detected!** 🚨")
        for port, protocol, service in new_open_ports:
            message_to_send.append(f"- Port: {port}/{protocol}, Service: {service}")

    if closed_ports:
        if risks_found:
            message_to_send.append("\nPorts Closed:")
        else:
            message_to_send.append("Ports Closed:") # Start new section if no risks
        for port, protocol, service in closed_ports:
            message_to_send.append(f"- Port: {port}/{protocol}, Service: {service}")

    return risks_found, "\n".join(message_to_send)

if __name__ == "__main__":
    baseline = load_baseline()

    try:
        with open(SCAN_FILE, 'r') as f:
            nmap_xml_data = f.read()
    except FileNotFoundError:
        print(json.dumps({'error': f'{SCAN_FILE} not found'}))
        exit(1)

    current_scan_results = parse_nmap_xml(nmap_xml_data)

    risks, alert_message = compare_scans(baseline, current_scan_results)

    if risks:
        print(json.dumps({"action": "send_alert", "message": alert_message}))
    else:
        # Check if baseline needs update (even if no risks, if ports closed, update it)
        if set([(p['port'], p['protocol'], p['service']) for p in baseline['open_ports']]) != \
           set([(p['port'], p['protocol'], p['service']) for p in current_scan_results['open_ports']]):
            save_baseline(current_scan_results)
            print(json.dumps({"action": "silent_update"})) # Indicate silent update
        else:
            print(json.dumps({"action": "no_change"})) # Indicate no change and no alert
