import 'package:flutter/material.dart';
import 'package:elios/widgets/custom_app_bar_widget.dart';
import 'package:elios/widgets/custom_drawer.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

class MonthlyUsageScreen extends StatefulWidget {
  const MonthlyUsageScreen({super.key});

  @override
  State<MonthlyUsageScreen> createState() => _MonthlyUsageScreenState();
}

class _MonthlyUsageScreenState extends State<MonthlyUsageScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<double> monthlyUnits =
      List.generate(12, (index) => (index % 6 + 1) * 2.5);
  final double ratePerUnit = 50.0;
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF03112E),
      appBar: CustomAppBarWidget(
        onDrawerPressed: () => _scaffoldKey.currentState?.openDrawer(),
        onToolbarPressed: () {},
        title: 'Monthly Usage',
        logoPath: 'assets/images/elios-logo.png',
      ),
      drawer: const CustomDrawer(),
      body: Column(
        children: [
          const Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LegendItem(color: Colors.blue, label: "Cost (Rs)"),
                  SizedBox(width: 8),
                  LegendItem(color: Colors.white, label: "Units (kWh)"),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 180,
                  barTouchData: BarTouchData(
                    enabled: true,
                    handleBuiltInTouches: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipMargin: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        if (touchedIndex != groupIndex) return null;
                        final double units = monthlyUnits[group.x.toInt()];
                        final double cost = units * ratePerUnit;
                        return BarTooltipItem(
                          rodIndex == 0
                              ? '   Rs ${cost.toStringAsFixed(2)}   '
                              : '   ${units.toStringAsFixed(2)} kWh   ',
                          GoogleFonts.orbitron(
                            color:
                                rodIndex == 0 ? Colors.blue[200] : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      },
                      fitInsideVertically: true,
                      fitInsideHorizontally: true,
                      tooltipRoundedRadius: 10,
                    ),
                    touchCallback: (event, response) {
                      setState(() {
                        touchedIndex = response?.spot?.touchedBarGroupIndex;
                      });
                    },
                  ),
                  barGroups: _buildBarGroups(),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const months = [
                            'Jan',
                            'Feb',
                            'Mar',
                            'Apr',
                            'May',
                            'Jun',
                            'Jul',
                            'Aug',
                            'Sep',
                            'Oct',
                            'Nov',
                            'Dec'
                          ];
                          return Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              months[value.toInt()],
                              style: GoogleFonts.orbitron(
                                  fontSize: 10, color: Colors.white),
                            ),
                          );
                        },
                        reservedSize: 42,
                        interval: 1,
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    //final double maxUnits = monthlyUnits.reduce((a, b) => a > b ? a : b);
    //final double maxCost = maxUnits * ratePerUnit;

    const double maxAllowedHeight = 25; // same as BarChartData maxY
    const double minVisibleHeight = 1.5;

    // Scale to fit maxUnits = 3000, maxCost = 180000
    const double unitScaleFactor = maxAllowedHeight / 3000;
    const double costScaleFactor = maxAllowedHeight / 180000;

    return List.generate(12, (index) {
      final double units = monthlyUnits[index];
      final double cost = units * ratePerUnit;

      final double scaledUnits =
          (units * unitScaleFactor).clamp(minVisibleHeight, maxAllowedHeight);
      final double scaledCost =
          (cost * costScaleFactor).clamp(minVisibleHeight, maxAllowedHeight);

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: scaledCost,
            width: 12,
            color: Colors.blue,
            borderRadius: BorderRadius.circular(4),
            backDrawRodData: BackgroundBarChartRodData(show: false),
          ),
          BarChartRodData(
            toY: scaledUnits,
            width: 12,
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            backDrawRodData: BackgroundBarChartRodData(show: false),
          ),
        ],
        barsSpace: 6,
      );
    });
  }
}

class LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 16,
            height: 16,
            color: color,
            margin: const EdgeInsets.only(right: 4)),
        Text(label,
            style: GoogleFonts.orbitron(fontSize: 12, color: Colors.white)),
      ],
    );
  }
}
