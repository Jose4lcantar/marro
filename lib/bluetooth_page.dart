import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'dart:convert';

class BluetoothPage extends StatefulWidget {
  @override
  _BluetoothPageState createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  List<BluetoothDevice> devices = [];
  BluetoothDevice? selectedDevice;
  BluetoothCharacteristic? characteristic;
  bool isScanning = false;
  String temperature = '0 °C';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (isScanning)
              CircularProgressIndicator()
            else if (devices.isEmpty)
              Text('No se encontraron dispositivos Bluetooth cercanos')
            else
              Expanded(
                child: ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return ListTile(
                      title: Text(device.name),
                      subtitle: Text(device.id.toString()),
                      onTap: () {
                        connectToDevice(device);
                      },
                    );
                  },
                ),
              ),
            ElevatedButton(
              onPressed: isScanning ? stopScan : startScan,
              child: Text(isScanning ? 'Detener búsqueda' : 'Buscar Dispositivos'),
            ),
            SizedBox(height: 20),
            Text(
              'Temperature: $temperature',
            ),
          ],
        ),
      ),
    );
  }

  void startScan() {
    setState(() {
      isScanning = true;
      devices.clear();
    });

    flutterBlue.startScan(timeout: Duration(seconds: 4)).then((_) {
      setState(() {
        isScanning = false;
      });
    });

    flutterBlue.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        if (!devices.contains(result.device)) {
          setState(() {
            devices.add(result.device);
          });
        }
      }
    });
  }

  void stopScan() {
    flutterBlue.stopScan();
    setState(() {
      isScanning = false;
    });
  }

  void connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(autoConnect: false, timeout: Duration(seconds: 10));
      setState(() {
        selectedDevice = device;
      });
      discoverServices(device);
    } catch (e) {
      print('Error connecting to Bluetooth device: $e');
    }
  }

  void discoverServices(BluetoothDevice device) async {
    try {
      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic c in service.characteristics) {
          if (c.properties.notify) {
            setState(() {
              characteristic = c;
            });

            // Escucha por nuevos valores
            characteristic!.setNotifyValue(true);
            characteristic!.value.listen((value) {
              setState(() {
                String data = utf8.decode(value);
                // Procesa los datos
                temperature = data;
              });
            });
            break;
          }
        }
      }
    } catch (e) {
      print('Error discovering services: $e');
    }
  }
}

void main() {
  runApp(MaterialApp(
    home: BluetoothPage(),
  ));
}
