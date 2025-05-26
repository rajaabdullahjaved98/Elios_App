import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:elios/widgets/custom_app_bar_widget.dart';
import 'package:elios/widgets/custom_drawer.dart';
import 'package:elios/widgets/data_box.dart';
import 'package:elios/services/websocket_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class DataScreen extends StatefulWidget {
  @override
  _DataScreenState createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Parsed data values
  int compressorRpm = 0;
  double volt = 0;
  double amp = 0;
  double dcv = 0;
  double dca = 0;
  double setTemp = 0;
  double roomTemp = 0;
  double coilTemp = 0;
  double delta = 0;
  String da = 'No';
  String odm = 'LCOF';
  String motor = 'Off';
  String inverter = 'Off';
  String rvf = 'Off';
  double hourRs = 0;
  double currentRs = 0;
  double currentPower = 0;
  double unitPrice = 0;
  double at = 0;
  double lLine = 0;
  double sLine = 0;
  double dLine = 0;
  double sp = 0;
  double dp = 0;
  String compressorMode = 'P Stop Mode';
  String odmStatus = 'C LAC OFF';

  @override
  void initState() {
    super.initState();
    final wsService = Provider.of<WebSocketService>(context, listen: false);

    wsService.onBinaryDataReceived = (Uint8List data) {
      if (data.length >= 125) {
        final int rpm = _getCompressorRpm(data);
        setState(() {
          volt = _getFloat(data, 55);
          amp = _getFloat(data, 63);
          dcv = _getFloat(data, 59);
          dca = _getFloat(data, 71);
          setTemp = _getFloat(data, 15);
          roomTemp = _getFloat(data, 23);
          coilTemp = _getFloat(data, 19);
          delta = _getFloat(data, 27);
          da = (data[8] & 0x04) != 0 ? 'Yes' : 'No';
          // You can extract odm, motor, inverter, rvf from specific bits if defined
          hourRs = _getFloat(data, 107);
          currentRs = _getFloat(data, 111);
          currentPower = _getFloat(data, 115);
          unitPrice = _getFloat(data, 119);
          at = _getFloat(data, 51);
          lLine = _getFloat(data, 39);
          sLine = _getFloat(data, 31);
          dLine = _getFloat(data, 43);
          sp = _getFloat(data, 35);
          dp = _getFloat(data, 47);
          compressorMode = _getCompressorMode(data);
          compressorRpm = rpm;
          odm = _getODMStatus(data);
          motor = (data[9] & 0x01) != 0 ? 'ON' : 'OFF';
          inverter = _getOutdoorInv(data);
          rvf = (data[11] & 0x01) != 0 ? 'ON' : 'OFF';
          // sp/dp may need parsing from enums or values
        });
      }
    };
  }

  double _getFloat(Uint8List data, int start) {
    try {
      ByteData bd = ByteData.sublistView(data, start, start + 4);
      return bd.getFloat32(0, Endian.little);
    } catch (_) {
      return 0;
    }
  }

  String _getCompressorMode(Uint8List data) {
    if (data.length <= 10) return 'Unknown';
    int value = (data[10] >> 5) & 0x07;
    switch (value) {
      case 0:
        return 'P Stop Mode';
      case 1:
        return 'Defrosting';
      case 2:
        return 'Master Stop Error';
      case 3:
        return 'Delta Achieved';
      case 4:
        return 'Mode Achieved';
      case 5:
        return 'Control Center';
      case 6:
        return 'Normal Mode';
      case 7:
        return 'First Time';
      default:
        return 'Unknown';
    }
  }

  String _getODMStatus(Uint8List data) {
    if (data.length <= 10) return 'Unknown';
    int value = (data[9] >> 5) & 0x07;
    switch (value) {
      case 0:
        return 'C LAC OFF';
      case 1:
        return 'C LAC ON';
      case 2:
        return 'H ON';
      case 3:
        return 'H OFF';
      case 4:
        return 'MC OFF';
      case 5:
        return 'E OFF';
      default:
        return 'Unknown';
    }
  }

  String _getOutdoorInv(Uint8List data) {
    if (data.length <= 12) return 'Unknown';
    int value = (data[12] >> 5) & 0x03;
    switch (value) {
      case 0:
        return 'OFF';
      case 1:
        return 'C';
      case 2:
        return 'H';
      default:
        return 'Unknown';
    }
  }

  int _getCompressorRpm(Uint8List data) {
    if (data.length <= 77) return 0;
    // Assuming Big Endian encoding
    return (data[75] << 8) | data[76];
  }

  Text _buildText(String value,
      {double size = 14,
      FontWeight weight = FontWeight.normal,
      Color color = Colors.white}) {
    return Text(
      value,
      style: GoogleFonts.orbitron(
        fontSize: size,
        fontWeight: weight,
        color: color,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDataBox(String title, List<Widget> children) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DataBox(
              title: title,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: children,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF03112E),
      appBar: CustomAppBarWidget(
        onDrawerPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
        onToolbarPressed: () {},
        title: 'Data Screen',
        logoPath: 'assets/images/sabro_white.png',
      ),
      drawer: const CustomDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDataBox('Compressor', [
              _buildText(compressorMode),
              const SizedBox(height: 6),
              _buildText(compressorRpm.toString(),
                  size: 40, weight: FontWeight.bold),
              const SizedBox(height: 6),
              _buildText('RPM'),
            ]),
            _buildDataBox('Power', [
              _buildText('Volt: ${volt.toStringAsFixed(2)}'),
              const SizedBox(height: 6),
              _buildText('Amp: ${amp.toStringAsFixed(2)}'),
              const SizedBox(height: 6),
              _buildText('DCV: ${dcv.toStringAsFixed(2)}'),
              const SizedBox(height: 6),
              _buildText('DCA: ${dca.toStringAsFixed(2)}'),
            ]),
            _buildDataBox('Temperature', [
              _buildText('Set: ${setTemp.toStringAsFixed(2)}'),
              const SizedBox(height: 6),
              _buildText('Room: ${roomTemp.toStringAsFixed(2)}'),
              const SizedBox(height: 6),
              _buildText('Coil: ${coilTemp.toStringAsFixed(2)}'),
              const SizedBox(height: 6),
              _buildText('Delta: ${delta.toStringAsFixed(2)}'),
              const SizedBox(height: 6),
              _buildText('DA: $da'),
            ]),
            _buildDataBox('Outdoor', [
              _buildText('ODM: $odm'),
              const SizedBox(height: 6),
              _buildText('Motor: $motor'),
              const SizedBox(height: 6),
              _buildText('Inv: $inverter'),
              const SizedBox(height: 6),
              _buildText('RVF: $rvf'),
            ]),
            _buildDataBox('Energy', [
              _buildText('Hour Rs: ${hourRs.toStringAsFixed(2)}'),
              const SizedBox(height: 6),
              _buildText('Current Rs: ${currentRs.toStringAsFixed(2)}'),
              const SizedBox(height: 6),
              _buildText('Current Power: ${currentPower.toStringAsFixed(2)}'),
              const SizedBox(height: 6),
              _buildText('Unit Price: ${unitPrice.toStringAsFixed(2)}'),
            ]),
            _buildDataBox('Refrigeration', [
              _buildText('AT: ${at.toStringAsFixed(2)}'),
              const SizedBox(height: 6),
              _buildText('L Line: ${lLine.toStringAsFixed(2)}'),
              const SizedBox(height: 6),
              _buildText('S Line: ${sLine.toStringAsFixed(2)}'),
              const SizedBox(height: 6),
              _buildText('D Line: ${dLine.toStringAsFixed(2)}'),
              const SizedBox(height: 6),
              _buildText('SP: ${sp.toStringAsFixed(2)}'),
              const SizedBox(height: 6),
              _buildText('DP: ${dp.toStringAsFixed(2)}'),
            ]),
          ],
        ),
      ),
    );
  }
}
