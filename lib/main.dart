import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;

  @override
  void initState() {
    super.initState();
    initBluetooth();
  }

  Future<void> initBluetooth() async {
    bool? isConnected = await bluetooth.isConnected;
    if (!isConnected!) {
      try {
        _devices = await bluetooth.getBondedDevices();
        setState(() {});
      } catch (e) {
        print(e);
      }
    }
  }

  void connect(BluetoothDevice device) async {
    await bluetooth.connect(device);
    setState(() {
      _selectedDevice = device;
    });
  }

  void disconnect() {
    bluetooth.disconnect();
    setState(() {
      _selectedDevice = null;
    });
  }

  Future<void> printSample() async {
    if (_selectedDevice != null) {
      // ESC/POS commands
      final profile = await CapabilityProfile.load();
      final ticket = Generator(PaperSize.mm80, profile);

      List<int> bytes = [];

      bytes += ticket.text('GROCERYLY',
          styles: PosStyles(
            align: PosAlign.center,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          ),
          linesAfter: 1);

      bytes += ticket.text('889  Watson Lane',
          styles: PosStyles(align: PosAlign.center));
      bytes += ticket.text('New Braunfels, TX',
          styles: PosStyles(align: PosAlign.center));
      bytes += ticket.text('Tel: 830-221-1234',
          styles: PosStyles(align: PosAlign.center));
      bytes += ticket.text('Web: www.example.com',
          styles: PosStyles(align: PosAlign.center), linesAfter: 1);

      bytes += ticket.hr();
      bytes += ticket.row([
        PosColumn(text: 'Qty', width: 1),
        PosColumn(text: 'Item', width: 7),
        PosColumn(
            text: 'Price', width: 2, styles: PosStyles(align: PosAlign.right)),
        PosColumn(
            text: 'Total', width: 2, styles: PosStyles(align: PosAlign.right)),
      ]);

      bytes += ticket.row([
        PosColumn(text: '2', width: 1),
        PosColumn(text: 'ONION RINGS', width: 7),
        PosColumn(
            text: '0.99', width: 2, styles: PosStyles(align: PosAlign.right)),
        PosColumn(
            text: '1.98', width: 2, styles: PosStyles(align: PosAlign.right)),
      ]);
      bytes += ticket.row([
        PosColumn(text: '1', width: 1),
        PosColumn(text: 'PIZZA', width: 7),
        PosColumn(
            text: '3.45', width: 2, styles: PosStyles(align: PosAlign.right)),
        PosColumn(
            text: '3.45', width: 2, styles: PosStyles(align: PosAlign.right)),
      ]);
      bytes += ticket.row([
        PosColumn(text: '1', width: 1),
        PosColumn(text: 'SPRING ROLLS', width: 7),
        PosColumn(
            text: '2.99', width: 2, styles: PosStyles(align: PosAlign.right)),
        PosColumn(
            text: '2.99', width: 2, styles: PosStyles(align: PosAlign.right)),
      ]);
      bytes += ticket.row([
        PosColumn(text: '3', width: 1),
        PosColumn(text: 'CRUNCHY STICKS', width: 7),
        PosColumn(
            text: '0.85', width: 2, styles: PosStyles(align: PosAlign.right)),
        PosColumn(
            text: '2.55', width: 2, styles: PosStyles(align: PosAlign.right)),
      ]);
      bytes += ticket.hr();

      bytes += ticket.row([
        PosColumn(
            text: 'TOTAL',
            width: 6,
            styles: PosStyles(
              height: PosTextSize.size2,
              width: PosTextSize.size2,
            )),
        PosColumn(
            text: '\$10.97',
            width: 6,
            styles: PosStyles(
              align: PosAlign.right,
              height: PosTextSize.size2,
              width: PosTextSize.size2,
            )),
      ]);

      bytes += ticket.hr(ch: '=', linesAfter: 1);

      bytes += ticket.row([
        PosColumn(
            text: 'Cash',
            width: 7,
            styles: PosStyles(align: PosAlign.right, width: PosTextSize.size2)),
        PosColumn(
            text: '\$15.00',
            width: 5,
            styles: PosStyles(align: PosAlign.right, width: PosTextSize.size2)),
      ]);
      bytes += ticket.row([
        PosColumn(
            text: 'Change',
            width: 7,
            styles: PosStyles(align: PosAlign.right, width: PosTextSize.size2)),
        PosColumn(
            text: '\$4.03',
            width: 5,
            styles: PosStyles(align: PosAlign.right, width: PosTextSize.size2)),
      ]);

      bytes += ticket.feed(2);
      bytes += ticket.text('Thank you!',
          styles: PosStyles(align: PosAlign.center, bold: true));

      final now = DateTime.now();
      final String timestamp = now.toString();
      bytes += ticket.text(timestamp,
          styles: PosStyles(align: PosAlign.center), linesAfter: 2);

      bluetooth.writeBytes(Uint8List.fromList(bytes));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth Printer Demo'),
      ),
      body: Column(
        children: <Widget>[
          if (_devices.isNotEmpty)
            DropdownButton<BluetoothDevice>(
              items: _devices.map((device) {
                return DropdownMenuItem<BluetoothDevice>(
                  child: Text(device.name!),
                  value: device,
                );
              }).toList(),
              onChanged: (device) {
                connect(device!);
              },
              value: _selectedDevice,
            ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _selectedDevice != null ? disconnect : null,
            child: Text('Disconnect'),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _selectedDevice != null ? printSample : null,
            child: Text('Print Sample'),
          ),
        ],
      ),
    );
  }
}
