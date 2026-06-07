import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme/app_theme.dart';
import '../shelf/shelf_provider.dart';
import 'scan_provider.dart';
import 'widgets/manual_input_dialog.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.ean13, BarcodeFormat.ean8],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;
    _handled = true;
    _controller.stop();
    ref.read(scanProvider.notifier).onIsbnDetected(code);
  }

  Future<void> _openDetail(String userBookId) async {
    ref.invalidate(shelfBooksProvider);
    ref.read(scanProvider.notifier).reset();
    if (mounted) context.pushReplacement('/book/$userBookId');
  }

  Future<void> _manual(String? isbn) async {
    final input = await showDialog<ManualBookInput>(
      context: context,
      builder: (_) => ManualInputDialog(isbn: isbn),
    );
    if (input == null) {
      // Cancelled → allow scanning again.
      _handled = false;
      ref.read(scanProvider.notifier).reset();
      _controller.start();
      return;
    }
    await ref.read(scanProvider.notifier).addManual(
          title: input.title,
          author: input.author,
          isbn: isbn,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ScanState>(scanProvider, (_, next) {
      switch (next) {
        case ScanSuccess(:final userBookId):
        case ScanDuplicate(userBookId: final userBookId):
          _openDetail(userBookId);
        case ScanNotFound(:final isbn):
          _manual(isbn);
        case ScanError(:final message):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: AppColors.coral),
          );
          _handled = false;
          ref.read(scanProvider.notifier).reset();
          _controller.start();
        case ScanIdle():
        case ScanLoading():
          break;
      }
    });

    final state = ref.watch(scanProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Scan ISBN')),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => _PermissionError(error: error),
          ),
          // Yellow corner frame.
          IgnorePointer(
            child: Container(
              width: 260,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.yellow, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          if (state is ScanLoading)
            Container(
              color: Colors.black54,
              alignment: Alignment.center,
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 12),
                  Text('Looking up…',
                      style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PermissionError extends StatelessWidget {
  final MobileScannerException error;
  const _PermissionError({required this.error});

  @override
  Widget build(BuildContext context) {
    final denied =
        error.errorCode == MobileScannerErrorCode.permissionDenied;
    return Container(
      color: AppColors.navy,
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.no_photography_outlined,
              color: Colors.white, size: 56),
          const SizedBox(height: 16),
          Text(
            denied
                ? 'Camera access is needed to scan barcodes.\n'
                    'Enable it in Settings → My Shelf → Camera, then come back.'
                : 'Camera error: ${error.errorCode.name}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
