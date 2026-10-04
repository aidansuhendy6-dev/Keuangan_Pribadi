import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/responsive.dart';

class SummaryCard extends StatefulWidget {
  final String title;
  final String amount;
  final String percentage;
  final bool isPositive;
  final IconData icon;
  final Color iconColor;
  final List<Color>? gradientColors;
  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback? onAddPressed;
  final Widget? customRightWidget;

  const SummaryCard({
    super.key,
    required this.title,
    required this.amount,
    required this.percentage,
    required this.isPositive,
    required this.icon,
    required this.iconColor,
    this.gradientColors,
    this.isActive = false,
    this.onTap,
    this.onAddPressed,
    this.customRightWidget,
  });

  @override
  State<SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<SummaryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          transform: _isHovered ? Matrix4.translationValues(0.0, -4.0, 0.0) : Matrix4.identity(),
          decoration: BoxDecoration(
            gradient: widget.isActive 
              ? LinearGradient(
                  colors: widget.gradientColors ?? [widget.iconColor, widget.iconColor.withOpacity(0.8)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
            color: widget.isActive ? null : Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: widget.isActive 
                  ? widget.iconColor.withOpacity(_isHovered ? 0.4 : 0.2)
                  : Colors.black.withOpacity(_isHovered ? 0.08 : 0.04),
                blurRadius: _isHovered ? 25 : 15,
                offset: Offset(0, _isHovered ? 12 : 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.all(Responsive.isMobile(context) ? 16.0 : 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          color: widget.isActive ? Colors.white.withOpacity(0.9) : Colors.black54,
                          fontSize: Responsive.isMobile(context) ? 10 : 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.amount,
                          style: TextStyle(
                            fontSize: Responsive.isMobile(context) ? 20 : 26,
                            fontWeight: FontWeight.w800,
                            color: widget.isActive ? Colors.white : Colors.black,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            widget.isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                            size: Responsive.isMobile(context) ? 12 : 14,
                            color: widget.isActive ? Colors.white.withOpacity(0.9) : (widget.isPositive ? Colors.green : Colors.red),
                          ),
                          Text(
                            widget.percentage,
                            style: TextStyle(
                              fontSize: Responsive.isMobile(context) ? 11 : 13,
                              fontWeight: FontWeight.bold,
                              color: widget.isActive ? Colors.white : (widget.isPositive ? Colors.green : Colors.red),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "dari bulan lalu",
                            style: TextStyle(
                              fontSize: Responsive.isMobile(context) ? 10 : 12, 
                              color: widget.isActive 
                                  ? Colors.white.withOpacity(0.7) 
                                  : (widget.isPositive ? Colors.green.withOpacity(0.7) : Colors.red.withOpacity(0.7)),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: Responsive.isMobile(context) ? 14 : 24,
                  right: Responsive.isMobile(context) ? 14 : 24,
                  child: Row(
                    children: [
                      if (widget.onAddPressed != null)
                        Padding(
                          padding: EdgeInsets.only(right: Responsive.isMobile(context) ? 6 : 8),
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: InkWell(
                              onTap: widget.onAddPressed,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: EdgeInsets.all(Responsive.isMobile(context) ? 8 : 6),
                                decoration: BoxDecoration(
                                  color: widget.isActive ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.add,
                                  size: Responsive.isMobile(context) ? 20 : 18,
                                  color: widget.isActive ? Colors.white : Colors.black54,
                                ),
                              ),
                            ),
                          ),
                        ),
                      widget.customRightWidget ?? Container(
                        width: Responsive.isMobile(context) ? 36 : 48,
                        height: Responsive.isMobile(context) ? 36 : 48,
                        decoration: BoxDecoration(
                          color: widget.isActive 
                            ? Colors.white.withOpacity(0.15) 
                            : widget.iconColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(Responsive.isMobile(context) ? 10 : 14),
                        ),
                        child: Icon(
                          widget.icon, 
                          color: widget.isActive ? Colors.white : widget.iconColor, 
                          size: Responsive.isMobile(context) ? 18 : 24
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
