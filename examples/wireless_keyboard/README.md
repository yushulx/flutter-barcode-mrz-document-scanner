# Flutter Wireless Keyboard and Barcode Scanner

The project demonstrates how to turn a Flutter mobile app into a wireless keyboard and barcode scanner to input data into PCs.

https://github.com/user-attachments/assets/a0600ec0-3244-414f-8aa3-b11e048f8f31


## Setting Up the Python Server
1. Install [pyautogui](https://pypi.org/project/PyAutoGUI/), [websockets](https://pypi.org/project/websockets/) and [zeroconf](https://pypi.org/project/zeroconf/) using pip:
    ```bash
    pip install pyautogui websockets zeroconf
    ```
2. Change the port numbers for Bonjour service and web socket server if they are already in use.
    ```python
    # Bonjour
    info = ServiceInfo("_bonsoirdemo._tcp.local.",
                    "Python Web Socket Server._bonsoirdemo._tcp.local.",
                    port=7000, addresses=[ip_address])

    # Web Socket Server
    s = await websockets.serve(server, ip_address, 4000)
    ```

    If you change the web socket port in the server, you also need to change the port in the Flutter app.
    ```dart
    _connect('${widget.service.ip}:4000');
    ```

3. Run the server:
    ```bash
    python server.py
    ```

## Setting Up the Flutter Mobile App
1. Apply for a trial license key of Dynamsoft Barcode Reader SDK from [here](https://www.dynamsoft.com/customer/license/trialLicense/?product=dcv&package=cross-platform).
2. Replace the license key in the `scanner_screen.dart` file.
    ```dart
    await DCVBarcodeReader.initLicense(
          'DLS2eyJoYW5kc2hha2VDb2RlIjoiMjAwMDAxLTE2NDk4Mjk3OTI2MzUiLCJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSIsInNlc3Npb25QYXNzd29yZCI6IndTcGR6Vm05WDJrcEQ5YUoifQ==');
    ```
3. Run the app on your mobile device.
    ```bash
    flutter run
    ```
    
    


