import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:syncfusion_flutter_gauges/gauges.dart';

void main() {
  runApp(MaterialApp(
    home: BluetoothPage(),
  ));
}

class BluetoothPage extends StatefulWidget {
  @override
  _BluetoothPageState createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  FlutterBluetoothSerial bluetooth = FlutterBluetoothSerial.instance;
  List<BluetoothDevice> devices = [];
  BluetoothDevice? selectedDevice;
  BluetoothConnection? connection;
  bool isScanning = false;
  String temperature = '0';

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
                      title: Text(device.name ?? ''),
                      subtitle: Text(device.address),
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
            SfRadialGauge(
              axes: <RadialAxis>[
                RadialAxis(
                  minimum: 0,
                  maximum: 100,
                  ranges: <GaugeRange>[
                    GaugeRange(startValue: 0, endValue: 100, color: Colors.green)
                  ],
                  pointers: <GaugePointer>[
                    NeedlePointer(value: double.parse(temperature)) // Actualizamos el valor del puntero con la temperatura actual
                  ],
                )
              ],
            ),
            SizedBox(height: 20),
            Text(
              'Temperature: $temperature °C',
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

    bluetooth.startDiscovery().listen((BluetoothDiscoveryResult result) {
      setState(() {
        devices.add(result.device);
      });
    });

    Future.delayed(Duration(seconds: 4), () {
      stopScan();
    });
  }

  void stopScan() {
    bluetooth.cancelDiscovery();
    setState(() {
      isScanning = false;
    });
  }

  void connectToDevice(BluetoothDevice device) async {
    try {
      BluetoothConnection connection = await BluetoothConnection.toAddress(device.address);
      setState(() {
        selectedDevice = device;
        this.connection = connection;
      });
      _startListening();
    } catch (e) {
      print('Error connecting to Bluetooth device: $e');
    }
  }

  void _startListening() {
    connection!.input!.listen((Uint8List data) {
      String receivedData = String.fromCharCodes(data);
      if (_isValidTemperature(receivedData)) {
        setState(() {
          temperature = receivedData.replaceAll(RegExp(r'[^0-9.]'), '');
        });
      } else {
        print('Received invalid temperature data: $receivedData');
      }
    });
  }

  bool _isValidTemperature(String data) {
    try {
      double.parse(data.replaceAll(RegExp(r'[^0-9.]'), ''));
      return true;
    } catch (e) {
      return false;
    }
  }
}
