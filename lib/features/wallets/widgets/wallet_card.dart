import 'package:flutter/material.dart';

class WalletCard extends StatelessWidget {
  final String name;
  final String balance;
  final String logoAsset;
  final Color backgroundColor;
  final List<Color> gradientColors;
  final double logoHeight;
  final VoidCallback? onEdit;

  const WalletCard({
    super.key,
    required this.name,
    required this.balance,
    required this.logoAsset,
    required this.backgroundColor,
    required this.gradientColors,
    this.logoHeight = 32,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Glossy Effect
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.transparent,
                    Colors.black.withOpacity(0.05),
                  ],
                ),
              ),
            ),
          ),
          if (onEdit != null)
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, color: Colors.white70, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Image.asset(
                    logoAsset,
                    height: logoHeight,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_balance_wallet, color: Colors.white, size: 32),
                  ),
                ),
                Text(
                  balance,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
