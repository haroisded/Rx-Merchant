import 'package:flutter/services.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

// The receipt printer over Bluetooth (05-invoices-and-receipts INV-R22): the
// only file that talks to print_bluetooth_thermal. It moves bytes; the
// commands come from logic/escpos.dart.

enum PrinterState { ready, noPermission, bluetoothOff }

typedef Printer = ({String name, String address});

/// The printers paired in Android's settings, or why none can be listed.
Future<(PrinterState, List<Printer>)> pairedPrinters() async {
  try {
    if (!await PrintBluetoothThermal.isPermissionBluetoothGranted) {
      return (PrinterState.noPermission, const <Printer>[]);
    }
    if (!await PrintBluetoothThermal.bluetoothEnabled) {
      return (PrinterState.bluetoothOff, const <Printer>[]);
    }
    return (
      PrinterState.ready,
      [
        for (final p in await PrintBluetoothThermal.pairedBluetooths)
          (name: p.name, address: p.macAdress),
      ],
    );
  } on PlatformException {
    return (PrinterState.noPermission, const <Printer>[]);
  }
}

/// Sends [bytes] to the printer at [address]; false when it cannot be
/// reached. A print failure never touches the sale, which is saved.
// ponytail: one connection per job; keep it open if printing feels slow.
Future<bool> sendRaw(String address, List<int> bytes) async {
  try {
    if (!await PrintBluetoothThermal.isPermissionBluetoothGranted) return false;
    if (!await PrintBluetoothThermal.connect(macPrinterAddress: address)) {
      return false;
    }
    return await PrintBluetoothThermal.writeBytes(bytes);
  } on Exception {
    return false;
  } finally {
    try {
      await PrintBluetoothThermal.disconnect;
    } on Exception {
      // Nothing was connected.
    }
  }
}

const _settings = MethodChannel('rx_merchant/settings');

/// Opens Android's Bluetooth settings, or this app's permission settings.
Future<void> openSystemSettings({required bool bluetooth}) =>
    _settings.invokeMethod<void>(bluetooth ? 'bluetooth' : 'app');
