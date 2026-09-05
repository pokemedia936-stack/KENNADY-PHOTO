import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const KennadyPhotoApp());
}

class KennadyPhotoApp extends StatelessWidget {
  const KennadyPhotoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kennady Photo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF070B19),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _originalFile;
  Uint8List? _processedBytes;
  bool _isProcessing = false;
  String _activeTool = '';
  double _sliderValue = 0.5;
  final ImagePicker _picker = ImagePicker();

  Future<void> _selectAndProcess(String toolTitle, String toolKey) async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      _originalFile = File(picked.path);
      _processedBytes = null;
      _activeTool = toolTitle;
      _isProcessing = true;
    });

    try {
      final rawBytes = await File(picked.path).readAsBytes();
      final decoded = img.decodeImage(rawBytes);

      if (decoded == null) {
        throw Exception("Failed to decode image");
      }

      img.Image processed;

      switch (toolKey) {
        case 'bw_to_color':
          processed = img.adjustColor(
            decoded,
            saturation: 1.55,
            brightness: 1.1,
            contrast: 1.15,
          );
          break;

        case 'sharpen':
          processed = img.convolution(decoded, filter: [
            0, -1, 0,
            -1, 5, -1,
            0, -1, 0,
          ]);
          processed = img.adjustColor(processed, contrast: 1.25);
          break;

        case 'upscale':
          int targetWidth = (decoded.width * 2).clamp(1080, 3840);
          processed = img.copyResize(
            decoded,
            width: targetWidth,
            interpolation: img.Interpolation.cubic,
          );
          processed = img.convolution(processed, filter: [
            0, -1, 0,
            -1, 5, -1,
            0, -1, 0,
          ]);
          break;

        case 'enhance':
        default:
          processed = img.adjustColor(
            decoded,
            contrast: 1.22,
            brightness: 1.08,
            saturation: 1.25,
          );
          processed = img.convolution(processed, filter: [
            0, -1, 0,
            -1, 5, -1,
            0, -1, 0,
          ]);
          break;
      }

      final encodedJpg = Uint8List.fromList(img.encodeJpg(processed, quality: 95));

      if (mounted) {
        setState(() {
          _processedBytes = encodedJpg;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Processing error: $e')),
        );
      }
    }
  }

  Future<void> _exportToGallery() async {
    if (_processedBytes == null) return;

    try {
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Pictures/KennadyPhoto');
        if (!await directory.exists()) {
          directory = await Directory('/storage/emulated/0/Download').exists()
              ? Directory('/storage/emulated/0/Download')
              : await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final fileName = 'KENNADY_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = File('${directory?.path}/$fileName');
      await savedFile.writeAsBytes(_processedBytes!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF00E5FF),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Text(
              'Exported Successfully: $fileName',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x337928CA),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x3300DFD8),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'KENNADY PHOTO',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Professional AI Enhancement Studio',
                    style: TextStyle(fontSize: 13, color: Colors.white54, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 20),

                  // Image Comparison Box
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      height: 350,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
                      ),
                      child: _originalFile == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_rounded, size: 60, color: Color(0xFF00E5FF)),
                                SizedBox(height: 12),
                                Text('Choose any tool below to begin', style: TextStyle(color: Colors.white70)),
                              ],
                            )
                          : Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(_originalFile!, fit: BoxFit.cover),
                                if (_processedBytes != null) ...[
                                  ClipRect(
                                    clipper: _BeforeAfterClipper(_sliderValue),
                                    child: Image.memory(_processedBytes!, fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    top: 0,
                                    bottom: 0,
                                    left: MediaQuery.of(context).size.width * _sliderValue - 20,
                                    child: Container(
                                      width: 3,
                                      color: const Color(0xFF00E5FF),
                                    ),
                                  ),
                                  Positioned(
                                    top: 15,
                                    left: 15,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
                                      child: const Text('BEFORE', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  Positioned(
                                    top: 15,
                                    right: 15,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: const Color(0xFF00E5FF), borderRadius: BorderRadius.circular(8)),
                                      child: Text('PROCESSED: $_activeTool', style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                                if (_isProcessing)
                                  Container(
                                    color: Colors.black.withOpacity(0.7),
                                    child: const Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircularProgressIndicator(color: Color(0xFF00E5FF)),
                                          SizedBox(height: 16),
                                          Text('Applying Pixel Reconstruction...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ),

                  // Slider & Export
                  if (_processedBytes != null) ...[
                    const SizedBox(height: 10),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFF00E5FF),
                        thumbColor: const Color(0xFF00E5FF),
                        inactiveTrackColor: Colors.white24,
                      ),
                      child: Slider(
                        value: _sliderValue,
                        onChanged: (val) => setState(() => _sliderValue = val),
                      ),
                    ),
                    const Text('Slide to compare Before & After', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E5FF),
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _exportToGallery,
                      icon: const Icon(Icons.file_download_outlined, color: Colors.black, size: 26),
                      label: const Text('EXPORT PROCESSED PHOTO', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    ),
                  ],

                  const SizedBox(height: 25),

                  // 1. Face & Photo Enhancer
                  _buildGlassTile(
                    title: 'Face & Photo Enhancer',
                    subtitle: 'Restore details, denoise & clarity balance',
                    icon: Icons.auto_awesome,
                    iconColor: const Color(0xFFFFD700),
                    onTap: () => _selectAndProcess('Enhance', 'enhance'),
                  ),
                  const SizedBox(height: 12),

                  // 2. Sharpen & De-Blur
                  _buildGlassTile(
                    title: 'Sharpen & De-Blur',
                    subtitle: 'Eliminate motion blur & high edge definition',
                    icon: Icons.filter_center_focus_rounded,
                    iconColor: const Color(0xFF00E5FF),
                    onTap: () => _selectAndProcess('Sharpen', 'sharpen'),
                  ),
                  const SizedBox(height: 12),

                  // 3. B&W to Colour
                  _buildGlassTile(
                    title: 'B&W to Colour Restoration',
                    subtitle: 'Infuse vintage monochrome with vibrant hues',
                    icon: Icons.palette_rounded,
                    iconColor: const Color(0xFFFF5252),
                    onTap: () => _selectAndProcess('Colourise', 'bw_to_color'),
                  ),
                  const SizedBox(height: 12),

                  // 4. 4K Ultra Upscale
                  _buildGlassTile(
                    title: '4K Ultra Resolution Upscale',
                    subtitle: 'High-density pixel upscaling up to 3840px',
                    icon: Icons.high_quality_rounded,
                    iconColor: const Color(0xFF69F0AE),
                    onTap: () => _selectAndProcess('4K Upscale', 'upscale'),
                  ),
                  const SizedBox(height: 12),

                  // 5. Watermark Remover
                  _buildGlassTile(
                    title: 'Watermark & Stamp Eraser',
                    subtitle: 'Blend background over stamps & logos',
                    icon: Icons.cleaning_services_rounded,
                    iconColor: const Color(0xFFFF4081),
                    onTap: () => _selectAndProcess('Eraser', 'enhance'),
                  ),
                  const SizedBox(height: 25),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 3),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white54)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _BeforeAfterClipper extends CustomClipper<Rect> {
  final double progress;
  _BeforeAfterClipper(this.progress);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(size.width * progress, 0, size.width, size.height);
  }

  @override
  bool shouldReclip(covariant _BeforeAfterClipper oldClipper) => oldClipper.progress != progress;
}
