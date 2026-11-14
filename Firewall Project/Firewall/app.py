"""
Safe-Layer - Professional Network Firewall Application
Features: Packet Capture, Ping, NSLookup, IP Block/Unblock, Website Blocking, Network Interfaces
"""

from flask import Flask, render_template, jsonify, request
import subprocess
import socket
import psutil
import threading
import time
import re
import platform
import os
from datetime import datetime
from collections import deque

app = Flask(__name__)

# Global state for packet capture
packet_capture_state = {
    'is_capturing': False,
    'packets': deque(maxlen=500),
    'capture_thread': None,
    'total_packets': 0,
    'start_time': None
}

# Blocked IPs, websites, and protocols storage
blocked_ips = set()
blocked_websites = set()
blocked_protocols = set()

# Lock for thread safety
capture_lock = threading.Lock()

# Hosts file path
HOSTS_PATH = r"C:\Windows\System32\drivers\etc\hosts"
HOSTS_MARKER_START = "# === FIREWALL BLOCKED WEBSITES START ==="
HOSTS_MARKER_END = "# === FIREWALL BLOCKED WEBSITES END ==="


def get_network_interfaces():
    """Get all network interfaces with their details"""
    interfaces = []
    try:
        net_if_addrs = psutil.net_if_addrs()
        net_if_stats = psutil.net_if_stats()
        net_io = psutil.net_io_counters(pernic=True)
        
        for iface_name, addrs in net_if_addrs.items():
            iface_info = {
                'name': iface_name,
                'ipv4': None,
                'ipv6': None,
                'mac': None,
                'netmask': None,
                'is_up': False,
                'speed': 0,
                'mtu': 0,
                'bytes_sent': 0,
                'bytes_recv': 0,
                'packets_sent': 0,
                'packets_recv': 0
            }
            
            for addr in addrs:
                if addr.family == socket.AF_INET:
                    iface_info['ipv4'] = addr.address
                    iface_info['netmask'] = addr.netmask
                elif addr.family == socket.AF_INET6:
                    iface_info['ipv6'] = addr.address
                elif addr.family == psutil.AF_LINK:
                    iface_info['mac'] = addr.address
            
            if iface_name in net_if_stats:
                stats = net_if_stats[iface_name]
                iface_info['is_up'] = stats.isup
                iface_info['speed'] = stats.speed
                iface_info['mtu'] = stats.mtu
            
            if iface_name in net_io:
                io = net_io[iface_name]
                iface_info['bytes_sent'] = io.bytes_sent
                iface_info['bytes_recv'] = io.bytes_recv
                iface_info['packets_sent'] = io.packets_sent
                iface_info['packets_recv'] = io.packets_recv
            
            interfaces.append(iface_info)
    except Exception as e:
        print(f"Error getting interfaces: {e}")
    
    return interfaces


def capture_packets_thread():
    """Background thread for packet capture using netstat polling"""
    global packet_capture_state
    
    while packet_capture_state['is_capturing']:
        try:
            result = subprocess.run(
                ['netstat', '-n'],
                capture_output=True,
                text=True,
                timeout=5,
                creationflags=subprocess.CREATE_NO_WINDOW if platform.system() == 'Windows' else 0
            )
            
            lines = result.stdout.strip().split('\n')
            timestamp = datetime.now().strftime('%H:%M:%S.%f')[:-3]
            
            for line in lines:
                if not packet_capture_state['is_capturing']:
                    break
                    
                parts = line.split()
                if len(parts) >= 4 and parts[0] in ['TCP', 'UDP']:
                    protocol = parts[0]
                    local_addr = parts[1]
                    foreign_addr = parts[2]
                    state = parts[3] if len(parts) > 3 else 'N/A'
                    
                    packet_info = {
                        'timestamp': timestamp,
                        'protocol': protocol,
                        'source': local_addr,
                        'destination': foreign_addr,
                        'state': state,
                        'length': '-'
                    }
                    
                    with capture_lock:
                        packet_capture_state['packets'].append(packet_info)
                        packet_capture_state['total_packets'] += 1
            
            time.sleep(1)
            
        except Exception as e:
            print(f"Capture error: {e}")
            time.sleep(1)


def execute_ping(target, count=4):
    """Execute ping command"""
    try:
        if platform.system() == 'Windows':
            cmd = ['ping', '-n', str(count), target]
        else:
            cmd = ['ping', '-c', str(count), target]
        
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=30,
            creationflags=subprocess.CREATE_NO_WINDOW if platform.system() == 'Windows' else 0
        )
        
        output = result.stdout + result.stderr
        success = result.returncode == 0
        
        return {
            'success': success,
            'output': output,
            'target': target
        }
    except subprocess.TimeoutExpired:
        return {'success': False, 'output': 'Ping request timed out', 'target': target}
    except Exception as e:
        return {'success': False, 'output': str(e), 'target': target}


def execute_nslookup(target):
    """Execute nslookup command"""
    try:
        result = subprocess.run(
            ['nslookup', target],
            capture_output=True,
            text=True,
            timeout=15,
            creationflags=subprocess.CREATE_NO_WINDOW if platform.system() == 'Windows' else 0
        )
        
        output = result.stdout + result.stderr
        success = result.returncode == 0
        
        return {
            'success': success,
            'output': output,
            'target': target
        }
    except subprocess.TimeoutExpired:
        return {'success': False, 'output': 'NSLookup request timed out', 'target': target}
    except Exception as e:
        return {'success': False, 'output': str(e), 'target': target}


def block_ip_windows(ip_address):
    """Block an IP address using Windows Firewall"""
    try:
        socket.inet_aton(ip_address)
        
        rule_name = f"Firewall_Block_{ip_address.replace('.', '_')}"
        
        cmd_inbound = [
            'netsh', 'advfirewall', 'firewall', 'add', 'rule',
            f'name={rule_name}_IN',
            'dir=in',
            'action=block',
            f'remoteip={ip_address}',
            'enable=yes'
        ]
        
        cmd_outbound = [
            'netsh', 'advfirewall', 'firewall', 'add', 'rule',
            f'name={rule_name}_OUT',
            'dir=out',
            'action=block',
            f'remoteip={ip_address}',
            'enable=yes'
        ]
        
        result_in = subprocess.run(
            cmd_inbound,
            capture_output=True,
            text=True,
            creationflags=subprocess.CREATE_NO_WINDOW if platform.system() == 'Windows' else 0
        )
        
        subprocess.run(
            cmd_outbound,
            capture_output=True,
            text=True,
            creationflags=subprocess.CREATE_NO_WINDOW if platform.system() == 'Windows' else 0
        )
        
        if 'Ok' in result_in.stdout or result_in.returncode == 0:
            blocked_ips.add(ip_address)
            return {'success': True, 'message': f'Successfully blocked IP: {ip_address}'}
        else:
            return {'success': False, 'message': f'Failed to block IP: {result_in.stderr}'}
            
    except socket.error:
        return {'success': False, 'message': 'Invalid IP address format'}
    except Exception as e:
        return {'success': False, 'message': str(e)}


def unblock_ip_windows(ip_address):
    """Unblock an IP address by removing Windows Firewall rules"""
    try:
        rule_name = f"Firewall_Block_{ip_address.replace('.', '_')}"
        
        cmd_inbound = [
            'netsh', 'advfirewall', 'firewall', 'delete', 'rule',
            f'name={rule_name}_IN'
        ]
        
        cmd_outbound = [
            'netsh', 'advfirewall', 'firewall', 'delete', 'rule',
            f'name={rule_name}_OUT'
        ]
        
        subprocess.run(
            cmd_inbound,
            capture_output=True,
            text=True,
            creationflags=subprocess.CREATE_NO_WINDOW if platform.system() == 'Windows' else 0
        )
        
        subprocess.run(
            cmd_outbound,
            capture_output=True,
            text=True,
            creationflags=subprocess.CREATE_NO_WINDOW if platform.system() == 'Windows' else 0
        )
        
        blocked_ips.discard(ip_address)
        return {'success': True, 'message': f'Successfully unblocked IP: {ip_address}'}
        
    except Exception as e:
        return {'success': False, 'message': str(e)}


def normalize_domain(domain):
    """Normalize domain name by removing protocol and trailing slashes"""
    domain = domain.lower().strip()
    domain = re.sub(r'^https?://', '', domain)
    domain = re.sub(r'/.*$', '', domain)
    domain = re.sub(r'^www\.', '', domain)
    return domain


def read_hosts_file():
    """Read the current hosts file content"""
    try:
        with open(HOSTS_PATH, 'r', encoding='utf-8') as f:
            return f.read()
    except Exception as e:
        print(f"Error reading hosts file: {e}")
        return ""


def write_hosts_file(content):
    """Write content to hosts file"""
    try:
        with open(HOSTS_PATH, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    except PermissionError:
        return False
    except Exception as e:
        print(f"Error writing hosts file: {e}")
        return False


def update_hosts_file():
    """Update the hosts file with blocked websites"""
    try:
        content = read_hosts_file()
        
        # Remove existing firewall entries
        pattern = f"{re.escape(HOSTS_MARKER_START)}.*?{re.escape(HOSTS_MARKER_END)}"
        content = re.sub(pattern, '', content, flags=re.DOTALL)
        content = content.strip()
        
        # Add new blocked websites section
        if blocked_websites:
            blocked_entries = [HOSTS_MARKER_START]
            for website in sorted(blocked_websites):
                blocked_entries.append(f"127.0.0.1 {website}")
                blocked_entries.append(f"127.0.0.1 www.{website}")
            blocked_entries.append(HOSTS_MARKER_END)
            
            content = content + "\n\n" + "\n".join(blocked_entries)
        
        return write_hosts_file(content)
    except Exception as e:
        print(f"Error updating hosts file: {e}")
        return False


def flush_dns_cache():
    """Flush the DNS cache to apply changes immediately"""
    try:
        subprocess.run(
            ['ipconfig', '/flushdns'],
            capture_output=True,
            creationflags=subprocess.CREATE_NO_WINDOW if platform.system() == 'Windows' else 0
        )
    except Exception as e:
        print(f"Error flushing DNS: {e}")


def load_blocked_websites():
    """Load blocked websites from hosts file on startup"""
    global blocked_websites
    try:
        content = read_hosts_file()
        pattern = f"{re.escape(HOSTS_MARKER_START)}(.*?){re.escape(HOSTS_MARKER_END)}"
        match = re.search(pattern, content, flags=re.DOTALL)
        
        if match:
            entries = match.group(1).strip().split('\n')
            for entry in entries:
                if entry.strip() and not entry.strip().startswith('#'):
                    parts = entry.split()
                    if len(parts) >= 2:
                        domain = parts[1]
                        if not domain.startswith('www.'):
                            blocked_websites.add(domain)
    except Exception as e:
        print(f"Error loading blocked websites: {e}")


def block_protocol_windows(protocol):
    """Block a network protocol using Windows Firewall"""
    try:
        protocol = protocol.upper().strip()
        valid_protocols = ['TCP', 'UDP', 'ICMP', 'ICMPV6']
        
        if protocol not in valid_protocols:
            return {'success': False, 'message': f'Invalid protocol. Supported: {", ".join(valid_protocols)}'}
        
        rule_name = f"Firewall_Block_{protocol}"
        
        # For ICMP/ICMPV6, we need different approach
        if protocol in ['ICMP', 'ICMPV6']:
            cmd = [
                'netsh', 'advfirewall', 'firewall', 'add', 'rule',
                f'name={rule_name}',
                'dir=in',
                'action=block',
                f'protocol={protocol}',
                'enable=yes'
            ]
        else:
            # For TCP/UDP, block both directions
            cmd_inbound = [
                'netsh', 'advfirewall', 'firewall', 'add', 'rule',
                f'name={rule_name}_IN',
                'dir=in',
                'action=block',
                f'protocol={protocol}',
                'enable=yes'
            ]
            
            cmd_outbound = [
                'netsh', 'advfirewall', 'firewall', 'add', 'rule',
                f'name={rule_name}_OUT',
                'dir=out',
                'action=block',
                f'protocol={protocol}',
                'enable=yes'
            ]
            
            # Execute both commands
            result_in = subprocess.run(
                cmd_inbound,
                capture_output=True,
                text=True,
                creationflags=subprocess.CREATE_NO_WINDOW if platform.system() == 'Windows' else 0
            )
            
            subprocess.run(
                cmd_outbound,
                capture_output=True,
                text=True,
                creationflags=subprocess.CREATE_NO_WINDOW if platform.system() == 'Windows' else 0
            )
            
            if 'Ok' in result_in.stdout or result_in.returncode == 0:
                blocked_protocols.add(protocol)
                return {'success': True, 'message': f'Successfully blocked protocol: {protocol}'}
            else:
                return {'success': False, 'message': f'Failed to block protocol: {result_in.stderr}'}
        
        # For ICMP protocols
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            creationflags=subprocess.CREATE_NO_WINDOW if platform.system() == 'Windows' else 0
        )
        
        if 'Ok' in result.stdout or result.returncode == 0:
            blocked_protocols.add(protocol)
            return {'success': True, 'message': f'Successfully blocked protocol: {protocol}'}
        else:
            return {'success': False, 'message': f'Failed to block protocol: {result.stderr}'}
            
    except Exception as e:
        return {'success': False, 'message': str(e)}


def unblock_protocol_windows(protocol):
    """Unblock a network protocol by removing Windows Firewall rules"""
    try:
        protocol = protocol.upper().strip()
        
        rule_name = f"Firewall_Block_{protocol}"
        
        if protocol in ['ICMP', 'ICMPV6']:
            cmd = [
                'netsh', 'advfirewall', 'firewall', 'delete', 'rule',
                f'name={rule_name}'
            ]
            subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                creationflags=subprocess.CREATE_NO_WINDOW if platform.system() == 'Windows' else 0
            )
        else:
            # Delete both inbound and outbound rules
            cmd_inbound = [
                'netsh', 'advfirewall', 'firewall', 'delete', 'rule',
                f'name={rule_name}_IN'
            ]
            
            cmd_outbound = [
                'netsh', 'advfirewall', 'firewall', 'delete', 'rule',
                f'name={rule_name}_OUT'
            ]
            
            subprocess.run(
                cmd_inbound,
                capture_output=True,
                text=True,
                creationflags=subprocess.CREATE_NO_WINDOW if platform.system() == 'Windows' else 0
            )
            
            subprocess.run(
                cmd_outbound,
                capture_output=True,
                text=True,
                creationflags=subprocess.CREATE_NO_WINDOW if platform.system() == 'Windows' else 0
            )
        
        blocked_protocols.discard(protocol)
        return {'success': True, 'message': f'Successfully unblocked protocol: {protocol}'}
        
    except Exception as e:
        return {'success': False, 'message': str(e)}


def get_network_stats():
    """Get overall network statistics"""
    try:
        net_io = psutil.net_io_counters()
        return {
            'bytes_sent': net_io.bytes_sent,
            'bytes_recv': net_io.bytes_recv,
            'packets_sent': net_io.packets_sent,
            'packets_recv': net_io.packets_recv,
            'errin': net_io.errin,
            'errout': net_io.errout,
            'dropin': net_io.dropin,
            'dropout': net_io.dropout
        }
    except Exception as e:
        return {'error': str(e)}


def get_active_connections():
    """Get active network connections"""
    connections = []
    try:
        for conn in psutil.net_connections(kind='inet'):
            conn_info = {
                'fd': conn.fd,
                'family': 'IPv4' if conn.family == socket.AF_INET else 'IPv6',
                'type': 'TCP' if conn.type == socket.SOCK_STREAM else 'UDP',
                'local_addr': f"{conn.laddr.ip}:{conn.laddr.port}" if conn.laddr else '-',
                'remote_addr': f"{conn.raddr.ip}:{conn.raddr.port}" if conn.raddr else '-',
                'status': conn.status,
                'pid': conn.pid
            }
            connections.append(conn_info)
    except Exception as e:
        print(f"Error getting connections: {e}")
    
    return connections[:100]


# Flask Routes
@app.route('/')
def index():
    return render_template('index.html')


@app.route('/api/interfaces')
def api_interfaces():
    return jsonify(get_network_interfaces())


@app.route('/api/stats')
def api_stats():
    return jsonify(get_network_stats())


@app.route('/api/connections')
def api_connections():
    return jsonify(get_active_connections())


@app.route('/api/capture/start', methods=['POST'])
def start_capture():
    global packet_capture_state
    
    if packet_capture_state['is_capturing']:
        return jsonify({'success': False, 'message': 'Capture already running'})
    
    packet_capture_state['is_capturing'] = True
    packet_capture_state['packets'].clear()
    packet_capture_state['total_packets'] = 0
    packet_capture_state['start_time'] = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    
    capture_thread = threading.Thread(target=capture_packets_thread, daemon=True)
    capture_thread.start()
    packet_capture_state['capture_thread'] = capture_thread
    
    return jsonify({'success': True, 'message': 'Packet capture started'})


@app.route('/api/capture/stop', methods=['POST'])
def stop_capture():
    global packet_capture_state
    
    packet_capture_state['is_capturing'] = False
    
    return jsonify({
        'success': True, 
        'message': 'Packet capture stopped',
        'total_packets': packet_capture_state['total_packets']
    })


@app.route('/api/capture/status')
def capture_status():
    return jsonify({
        'is_capturing': packet_capture_state['is_capturing'],
        'total_packets': packet_capture_state['total_packets'],
        'start_time': packet_capture_state['start_time']
    })


@app.route('/api/capture/packets')
def get_captured_packets():
    with capture_lock:
        packets = list(packet_capture_state['packets'])
    return jsonify({
        'packets': packets[-100:],
        'total': packet_capture_state['total_packets']
    })


@app.route('/api/ping', methods=['POST'])
def api_ping():
    data = request.get_json()
    target = data.get('target', '')
    count = data.get('count', 4)
    
    if not target:
        return jsonify({'success': False, 'output': 'No target specified'})
    
    result = execute_ping(target, count)
    return jsonify(result)


@app.route('/api/nslookup', methods=['POST'])
def api_nslookup():
    data = request.get_json()
    target = data.get('target', '')
    
    if not target:
        return jsonify({'success': False, 'output': 'No target specified'})
    
    result = execute_nslookup(target)
    return jsonify(result)


@app.route('/api/block', methods=['POST'])
def api_block_ip():
    data = request.get_json()
    ip_address = data.get('ip', '')
    
    if not ip_address:
        return jsonify({'success': False, 'message': 'No IP address specified'})
    
    result = block_ip_windows(ip_address)
    return jsonify(result)


@app.route('/api/unblock', methods=['POST'])
def api_unblock_ip():
    data = request.get_json()
    ip_address = data.get('ip', '')
    
    if not ip_address:
        return jsonify({'success': False, 'message': 'No IP address specified'})
    
    result = unblock_ip_windows(ip_address)
    return jsonify(result)


@app.route('/api/blocked')
def api_blocked_ips():
    return jsonify(list(blocked_ips))


@app.route('/api/website/block', methods=['POST'])
def api_block_website():
    data = request.get_json()
    website = data.get('website', '')
    
    if not website:
        return jsonify({'success': False, 'message': 'No website specified'})
    
    website = normalize_domain(website)
    
    if not website or '.' not in website:
        return jsonify({'success': False, 'message': 'Invalid website domain'})
    
    if website in blocked_websites:
        return jsonify({'success': False, 'message': f'Website {website} is already blocked'})
    
    blocked_websites.add(website)
    
    if update_hosts_file():
        flush_dns_cache()
        return jsonify({'success': True, 'message': f'Successfully blocked website: {website}'})
    else:
        blocked_websites.discard(website)
        return jsonify({'success': False, 'message': 'Failed to update hosts file. Run as Administrator.'})


@app.route('/api/website/unblock', methods=['POST'])
def api_unblock_website():
    data = request.get_json()
    website = data.get('website', '')
    
    if not website:
        return jsonify({'success': False, 'message': 'No website specified'})
    
    website = normalize_domain(website)
    
    if website not in blocked_websites:
        return jsonify({'success': False, 'message': f'Website {website} is not blocked'})
    
    blocked_websites.discard(website)
    
    if update_hosts_file():
        flush_dns_cache()
        return jsonify({'success': True, 'message': f'Successfully unblocked website: {website}'})
    else:
        blocked_websites.add(website)
        return jsonify({'success': False, 'message': 'Failed to update hosts file. Run as Administrator.'})


@app.route('/api/websites/blocked')
def api_blocked_websites():
    return jsonify(list(blocked_websites))


@app.route('/api/protocol/block', methods=['POST'])
def api_block_protocol():
    data = request.get_json()
    protocol = data.get('protocol', '')
    
    if not protocol:
        return jsonify({'success': False, 'message': 'No protocol specified'})
    
    result = block_protocol_windows(protocol)
    return jsonify(result)


@app.route('/api/protocol/unblock', methods=['POST'])
def api_unblock_protocol():
    data = request.get_json()
    protocol = data.get('protocol', '')
    
    if not protocol:
        return jsonify({'success': False, 'message': 'No protocol specified'})
    
    result = unblock_protocol_windows(protocol)
    return jsonify(result)


@app.route('/api/protocols/blocked')
def api_blocked_protocols():
    return jsonify(list(blocked_protocols))


@app.route('/api/traceroute', methods=['POST'])
def api_traceroute():
    data = request.get_json()
    target = data.get('target', '')
    
    if not target:
        return jsonify({'success': False, 'output': 'No target specified'})
    
    try:
        if platform.system() == 'Windows':
            cmd = ['tracert', '-d', target]
        else:
            cmd = ['traceroute', target]
        
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=60,
            creationflags=subprocess.CREATE_NO_WINDOW if platform.system() == 'Windows' else 0
        )
        
        return jsonify({
            'success': result.returncode == 0,
            'output': result.stdout + result.stderr,
            'target': target
        })
    except subprocess.TimeoutExpired:
        return jsonify({'success': False, 'output': 'Traceroute request timed out', 'target': target})
    except Exception as e:
        return jsonify({'success': False, 'output': str(e), 'target': target})


@app.route('/api/system/info')
def api_system_info():
    """Get system information"""
    try:
        cpu_percent = psutil.cpu_percent(interval=0.1)
        memory = psutil.virtual_memory()
        
        return jsonify({
            'hostname': socket.gethostname(),
            'platform': platform.system(),
            'platform_release': platform.release(),
            'cpu_percent': cpu_percent,
            'memory_total': memory.total,
            'memory_used': memory.used,
            'memory_percent': memory.percent
        })
    except Exception as e:
        return jsonify({'error': str(e)})


def get_firewall_status():
    """Get Windows Firewall status for all profiles"""
    try:
        result = subprocess.run(
            ['netsh', 'advfirewall', 'show', 'allprofiles', 'state'],
            capture_output=True,
            text=True,
            creationflags=subprocess.CREATE_NO_WINDOW if platform.system() == 'Windows' else 0
        )
        
        output = result.stdout.lower()
        # Check if any profile has firewall ON
        is_enabled = 'on' in output and 'state' in output
        
        return {
            'enabled': is_enabled,
            'output': result.stdout
        }
    except Exception as e:
        return {'enabled': False, 'error': str(e)}


def set_firewall_state(enable):
    """Turn Windows Firewall on or off for all profiles"""
    try:
        state = 'on' if enable else 'off'
        
        # Set firewall state for all profiles (Domain, Private, Public)
        profiles = ['domainprofile', 'privateprofile', 'publicprofile']
        success = True
        
        for profile in profiles:
            result = subprocess.run(
                ['netsh', 'advfirewall', 'set', profile, 'state', state],
                capture_output=True,
                text=True,
                creationflags=subprocess.CREATE_NO_WINDOW if platform.system() == 'Windows' else 0
            )
            if result.returncode != 0:
                success = False
        
        if success:
            action = 'enabled' if enable else 'disabled'
            return {'success': True, 'message': f'Firewall {action} successfully'}
        else:
            return {'success': False, 'message': 'Failed to change firewall state. Run as Administrator.'}
            
    except Exception as e:
        return {'success': False, 'message': str(e)}


@app.route('/api/firewall/status')
def api_firewall_status():
    """Get current firewall status"""
    return jsonify(get_firewall_status())


@app.route('/api/firewall/toggle', methods=['POST'])
def api_firewall_toggle():
    """Toggle firewall on/off"""
    data = request.get_json()
    enable = data.get('enable', True)
    result = set_firewall_state(enable)
    return jsonify(result)


if __name__ == '__main__':
    # Load blocked websites from hosts file on startup
    load_blocked_websites()
    
    print("=" * 60)
    print("  Safe-Layer Firewall")
    print("  Starting on http://127.0.0.1:5000")
    print("  NOTE: Run as Administrator for full functionality")
    print("=" * 60)
    app.run(debug=True, host='127.0.0.1', port=5000, threaded=True)
