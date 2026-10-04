import 'package:flutter/material.dart';
import 'tagihan_bulanan_stub.dart'
    if (dart.library.html) 'tagihan_bulanan_web.dart';

class TagihanBulananIframe extends StatefulWidget {
  const TagihanBulananIframe({super.key});

  @override
  State<TagihanBulananIframe> createState() => _TagihanBulananIframeState();
}

class _TagihanBulananIframeState extends State<TagihanBulananIframe> {
  final ValueNotifier<double> _heightNotifier = ValueNotifier<double>(750.0);

  @override
  void dispose() {
    _heightNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: _heightNotifier,
      builder: (context, height, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: buildWebView(_heightNotifier),
        );
      },
    );
  }
}
