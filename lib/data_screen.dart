import 'package:flutter/material.dart';
import 'package:elios/widgets/custom_app_bar_widget.dart';
import 'package:elios/widgets/custom_drawer.dart';
import 'package:elios/widgets/data_box.dart';
import 'package:google_fonts/google_fonts.dart';

class DataScreen extends StatelessWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Text buildText(String value,
      {double size = 14,
      FontWeight weight = FontWeight.normal,
      Color color = Colors.white}) {
    return Text(
      value,
      style: GoogleFonts.orbitron(
          fontSize: size, fontWeight: weight, color: color),
      textAlign: TextAlign.center,
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
        logoPath: 'assets/images/elios-logo.png',
      ),
      drawer: const CustomDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDataBox('Compressor', [
              buildText('Pstop'),
              const SizedBox(height: 6),
              buildText('0',
                  size: 40, weight: FontWeight.bold, color: Colors.white),
              const SizedBox(height: 6),
              buildText('RPM'),
            ]),
            _buildDataBox('Power', [
              buildText('Volt: 0.00'),
              const SizedBox(height: 6),
              buildText('Amp: 0.00'),
              const SizedBox(height: 6),
              buildText('DCV: 0.00'),
              const SizedBox(height: 6),
              buildText('DCA: 0.00'),
            ]),
            _buildDataBox('Temperature', [
              buildText('Set: 0.00'),
              const SizedBox(height: 6),
              buildText('Room: 0.00'),
              const SizedBox(height: 6),
              buildText('Coil: 0.00'),
              const SizedBox(height: 6),
              buildText('Delta: 0.00'),
              const SizedBox(height: 6),
              buildText('DA: No'),
            ]),
            _buildDataBox('Outdoor', [
              buildText('ODM: LCOF'),
              const SizedBox(height: 6),
              buildText('Motor: Off'),
              const SizedBox(height: 6),
              buildText('Inv: Off'),
              const SizedBox(height: 6),
              buildText('RVF: Off'),
            ]),
            _buildDataBox('Energy', [
              buildText('Hour Rs: 0.00'),
              const SizedBox(height: 6),
              buildText('Current Rs: 0.00'),
              const SizedBox(height: 6),
              buildText('Current Power: 0.00'),
              const SizedBox(height: 6),
              buildText('Unit Price: 0.00'),
            ]),
            _buildDataBox('Refrigeration', [
              buildText('AT: 0.00'),
              const SizedBox(height: 6),
              buildText('L Line: 0.00'),
              const SizedBox(height: 6),
              buildText('S Line: 0.00'),
              const SizedBox(height: 6),
              buildText('D Line: 0.00'),
              const SizedBox(height: 6),
              buildText('SP: Calibrating'),
              const SizedBox(height: 6),
              buildText('DP: Calibrating'),
            ]),
          ],
        ),
      ),
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
}
