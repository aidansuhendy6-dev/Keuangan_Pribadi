import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../services/finance_provider.dart';
import '../../../services/navigation_provider.dart';

class NetWorthCard extends StatelessWidget {
  final double padding;
  final double fontSizeLabel;
  final double fontSizeAmount;
  final double fontSizePercent;
  final double borderRadius;

  const NetWorthCard({
    super.key,
    this.padding = 24,
    this.fontSizeLabel = 12,
    this.fontSizeAmount = 22,
    this.fontSizePercent = 13,
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, finance, child) {
        final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
        final isNegative = finance.netWorth < 0;
        final themeColor = isNegative ? Colors.red : Colors.green;

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              context.read<NavigationProvider>().setMenu(SidebarMenu.netWorthHistory);
            },
            child: Container(
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: themeColor.withOpacity(0.12),
                  width: 1.5,
                ),
              ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Total Kekayaan Bersih",
                style: TextStyle(
                  fontSize: fontSizeLabel, 
                  color: themeColor.withOpacity(0.6), 
                  fontWeight: FontWeight.w600
                ),
              ),
              const SizedBox(height: 8),
              Text(
                fmt.format(finance.netWorth),
                style: TextStyle(
                  fontSize: fontSizeAmount, 
                  fontWeight: FontWeight.w900, 
                  letterSpacing: -0.5,
                  color: isNegative ? Colors.red.shade800 : Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    finance.netWorthPercentage >= 0 ? Icons.trending_up : Icons.trending_down,
                    size: fontSizePercent + 2,
                    color: finance.netWorthPercentage >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    finance.formatPercentage(finance.netWorthPercentage),
                    style: TextStyle(
                      fontSize: fontSizePercent,
                      color: finance.netWorthPercentage >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "dari bulan lalu",
                    style: TextStyle(
                      fontSize: fontSizeLabel, 
                      color: finance.netWorthPercentage >= 0 
                          ? Colors.green.shade700.withOpacity(0.7) 
                          : Colors.red.shade700.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  },
    );
  }
}
