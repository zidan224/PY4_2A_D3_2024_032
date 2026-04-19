import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import 'image_filter_service.dart';

/// FilterPreviewPage ditampilkan setelah user mengambil foto.
///
/// Fitur:
/// - Menampilkan foto original di atas
/// - Strip filter di bawah (scrollable horizontal)
/// - Tap filter → preview real-time dengan loading indicator
/// - Tombol simpan untuk menyimpan hasil filter
/// - Slider threshold untuk filter binarisasi
class FilterPreviewPage extends StatefulWidget {
  final File imageFile;

  const FilterPreviewPage({super.key, required this.imageFile});

  @override
  State<FilterPreviewPage> createState() => _FilterPreviewPageState();
}

class _FilterPreviewPageState extends State<FilterPreviewPage>
    with TickerProviderStateMixin {
  // ─── State ──────────────────────────────────────────────────────────────────
  img.Image? _originalImage;
  Uint8List? _displayBytes;
  ImageFilter _activeFilter = ImageFilter.original;
  bool _isProcessing = false;
  double _thresholdValue = 128;
  String? _errorMessage;

  // Animation controller untuk transisi filter
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _loadImage();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    setState(() => _isProcessing = true);

    final loaded = await ImageFilterService.loadFromFile(widget.imageFile);
    if (loaded == null) {
      setState(() {
        _errorMessage = 'Gagal memuat gambar.';
        _isProcessing = false;
      });
      return;
    }

    _originalImage = loaded;
    final raw = await widget.imageFile.readAsBytes();

    setState(() {
      _displayBytes = raw;
      _isProcessing = false;
    });

    _fadeController.forward();
  }

  Future<void> _applyFilter(ImageFilter filter) async {
    if (_originalImage == null) return;

    setState(() {
      _activeFilter = filter;
      _isProcessing = true;
    });

    _fadeController.reset();

    // Proses di luar frame agar UI tidak freeze
    final processed = await _processFilter(filter);

    if (!mounted) return;

    final bytes = await ImageFilterService.toBytes(processed);

    setState(() {
      _displayBytes = bytes;
      _isProcessing = false;
    });

    _fadeController.forward();
  }

  Future<img.Image> _processFilter(ImageFilter filter) async {
    final src = _originalImage!;
    switch (filter) {
      case ImageFilter.original:
        return src.clone();
      case ImageFilter.inverse:
        return ImageFilterService.applyInverse(src);
      case ImageFilter.histogramEqualization:
        return ImageFilterService.applyHistogramEqualization(src);
      case ImageFilter.lowpass:
        return ImageFilterService.applyLowpass(src);
      case ImageFilter.highpass:
        return ImageFilterService.applyHighpass(src);
      case ImageFilter.medianFilter:
        return ImageFilterService.applyMedianFilter(src);
      case ImageFilter.threshold:
        return ImageFilterService.applyThreshold(
          src,
          threshold: _thresholdValue.toInt(),
        );
    }
  }

  Future<void> _saveImage() async {
    if (_displayBytes == null) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filterName = _activeFilter.name;
      final savePath = '${dir.path}/patrol_${filterName}_$timestamp.png';

      final file = File(savePath);
      await file.writeAsBytes(_displayBytes!);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1A2332),
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF4CFFB3)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Disimpan: patrol_${filterName}_$timestamp.png',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red[900],
          content: Text('Gagal menyimpan: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1A),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Image preview area
          Expanded(child: _buildImagePreview()),

          // Threshold slider — hanya muncul saat filter threshold aktif
          if (_activeFilter == ImageFilter.threshold) _buildThresholdSlider(),

          // Filter info bar
          _buildFilterInfo(),

          // Filter strip
          _buildFilterStrip(),

          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0D1421),
      foregroundColor: Colors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Citra',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          Text(
            _activeFilter.displayName,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF4CFFB3),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      actions: [
        // Save button
        TextButton.icon(
          onPressed: _isProcessing ? null : _saveImage,
          icon: const Icon(Icons.save_alt, size: 18),
          label: const Text('Simpan'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF4CFFB3),
            disabledForegroundColor: Colors.grey,
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildImagePreview() {
    if (_errorMessage != null) {
      return Center(
        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
      );
    }

    if (_displayBytes == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4CFFB3)),
      );
    }

    return Stack(
      children: [
        // Main image with fade transition
        Positioned.fill(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Image.memory(
              _displayBytes!,
              fit: BoxFit.contain,
              gaplessPlayback: true,
            ),
          ),
        ),

        // Processing overlay
        if (_isProcessing)
          Positioned.fill(
            child: Container(
              color: Colors.black45,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF4CFFB3)),
                    SizedBox(height: 12),
                    Text(
                      'Memproses filter...',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Filter badge overlay kanan atas
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF4CFFB3).withOpacity(0.15),
              border: Border.all(color: const Color(0xFF4CFFB3), width: 1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _activeFilter.icon,
                  color: const Color(0xFF4CFFB3),
                  size: 14,
                ),
                const SizedBox(width: 5),
                Text(
                  _activeFilter.displayName,
                  style: const TextStyle(
                    color: Color(0xFF4CFFB3),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThresholdSlider() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: const Color(0xFF0D1421),
      child: Row(
        children: [
          const Icon(Icons.tonality, color: Color(0xFF4CFFB3), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF4CFFB3),
                inactiveTrackColor: Colors.white12,
                thumbColor: const Color(0xFF4CFFB3),
                overlayColor: const Color(0xFF4CFFB3).withOpacity(0.15),
                trackHeight: 3,
              ),
              child: Slider(
                value: _thresholdValue,
                min: 0,
                max: 255,
                divisions: 255,
                onChanged: (val) => setState(() => _thresholdValue = val),
                onChangeEnd: (val) {
                  _thresholdValue = val;
                  _applyFilter(ImageFilter.threshold);
                },
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              _thresholdValue.toInt().toString(),
              style: const TextStyle(
                color: Color(0xFF4CFFB3),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF0D1421),
      width: double.infinity,
      child: Text(
        _activeFilter.description,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
    );
  }

  Widget _buildFilterStrip() {
    return Container(
      height: 96,
      color: const Color(0xFF0D1421),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        itemCount: ImageFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = ImageFilter.values[index];
          final isActive = filter == _activeFilter;

          return GestureDetector(
            onTap: () => _applyFilter(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 72,
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF4CFFB3).withOpacity(0.12)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive ? const Color(0xFF4CFFB3) : Colors.white12,
                  width: isActive ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    filter.icon,
                    color: isActive ? const Color(0xFF4CFFB3) : Colors.white38,
                    size: 22,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    filter.displayName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isActive
                          ? const Color(0xFF4CFFB3)
                          : Colors.white38,
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
