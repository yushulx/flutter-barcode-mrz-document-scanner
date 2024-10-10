import asyncio
import websockets
import socket
import pyautogui
import signal

from zeroconf import ServiceBrowser, ServiceInfo, ServiceListener, Zeroconf

import subprocess
import re
import sys


connected = set()
isShutdown = False

class MyListener(ServiceListener):

    def update_service(self, zc: Zeroconf, type_: str, name: str) -> None:
        print(f"Service {name} updated")

    def remove_service(self, zc: Zeroconf, type_: str, name: str) -> None:
        print(f"Service {name} removed")

    def add_service(self, zc: Zeroconf, type_: str, name: str) -> None:
        info = zc.get_service_info(type_, name)
        print(f"Service {name} added, service info: {info}")


async def handle_message(websocket, path):
    async for message in websocket:
        if isinstance(message, str):
            if message != '':
                # Handle a text message
                print(f'Received text message: {message}')
                if message == 'backspace':
                    pyautogui.press('backspace')
                elif message == 'enter':
                    pyautogui.press('enter')
                else:
                    pyautogui.typewrite(message)
                await websocket.send(message)
                
        elif isinstance(message, bytes):
            pass            
            

async def server(websocket, path):
    # Add the new client's websocket to the set of connected clients
    connected.add(websocket)
    try:
        # Start handling incoming messages from the client
        await handle_message(websocket, path)
    except:
        connected.remove(websocket)
      

def ctrl_c(signum, frame):
    global isShutdown
    isShutdown = True
    
async def main(ip_address):
    global isShutdown
    # Start the server
    s = await websockets.serve(server, ip_address, 4000)
    print(f"Server started on {ip_address}:4000")

    while not isShutdown:
        await asyncio.sleep(1)
        
    print("Shutting down server")
    s.close()
    await s.wait_closed()

def get_ip_address():
    ip_address = ''
    if sys.platform == 'win32':
        result = subprocess.run(['ipconfig', '/all'], capture_output=True, text=True)   
    else:
        result = subprocess.run(['ifconfig'], capture_output=True, text=True)

    foundEthernet = False
    for line in result.stdout.split('\n'):
        if sys.platform == 'win32':
            match = re.search(r'Ethernet adapter Ethernet:', line)
            if match:
                foundEthernet = True
            
            if foundEthernet:
                match = re.search(r'IPv4 Address.*? : (\d+\.\d+\.\d+\.\d+)', line)
                if match:
                    ip_address = match.group(1)
                    break
        else:
            if sys.platform == "linux" or sys.platform == "linux2":
                match = re.search(r'eth0:', line)
            else:
                match = re.search(r'en0:', line)
            if match:
                foundEthernet = True
            
            if foundEthernet:
                match = re.search(r'(\d+\.\d+\.\d+\.\d+)', line)
                if match:
                    ip_address = match.group(1)
                    break

    return ip_address

if __name__ == '__main__':
    # ip_address_str = "192.168.8.72"
    ip_address_str = get_ip_address()
    # Convert the IP address string to a binary representation
    ip_address = socket.inet_aton(ip_address_str)

    info = ServiceInfo("_bonsoirdemo._tcp.local.", socket.gethostname().split('.')[0] +
                    " Web Socket Server._bonsoirdemo._tcp.local.",
                    port=7000, addresses=[ip_address])

    zeroconf = Zeroconf()
    # Register the Bonjour service
    zeroconf.register_service(info)
    listener = MyListener()
    browser = ServiceBrowser(zeroconf, "_bonsoirdemo._tcp.local.", listener)
    
    # Start the web socket server
    signal.signal(signal.SIGINT, ctrl_c)
    asyncio.run(main(ip_address_str))

    # Unregister the Bonjour service
    print("Unregistering Bonjour service")
    zeroconf.unregister_service(info)
    zeroconf.close()