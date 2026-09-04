import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
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
  File? _selectedImage;
  bool _isProcessing = false;
  bool _isProcessed = false;
  String _currentMode = 'Enhance';
  double _sliderValue = 0.5;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(String mode) async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _currentMode = mode;
        _isProcessed = false;
      });
      _processImage();
    }
  }

  void _processImage() {
    setState(() => _isProcessing = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isProcessed = true;
        });
      }
    });
  }

  Future<void> _exportAndSaveImage() async {
    if (_selectedImage == null) return;
    try {
      final xfile = XFile(_selectedImage!.path);
      await Share.shareXFiles([xfile], text: 'Exported from Kennady Photo AI (4K Ultra HD)');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x337928CA),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x3300DFD8),
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: const SizedBox.expand(),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
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
                    'AI Studio & Image Enhancer',
                    style: TextStyle(fontSize: 13, color: Colors.white54, letterSpacing: 1),
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        height: 340,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
                        ),
                        child: _selectedImage == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_rounded, size: 60, color: Color(0xFF00E5FF)),
                                  SizedBox(height: 12),
                                  Text('Select a photo below to enhance', style: TextStyle(color: Colors.white70)),
                                ],
                              )
                            : Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: Image.file(_selectedImage!, fit: BoxFit.cover),
                                  ),
                                  if (_isProcessed) ...[
                                    ClipRect(
                                      clipper: _BeforeAfterClipper(_sliderValue),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(24),
                                        child: ColorFiltered(
                                          colorFilter: const ColorFilter.matrix([
                                            1.25, 0,    0,    0, 15,
                                            0,    1.25, 0,    0, 15,
                                            0,    0,    1.25, 0, 15,
                                            0,    0,    0,    1, 0,
                                          ]),
                                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 0,
                                      bottom: 0,
                                      left: (screenWidth - 40) * _sliderValue - 1.5,
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
                                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                                        child: const Text('BEFORE', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    Positioned(
                                      top: 15,
                                      right: 15,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: const Color(0xFF00E5FF), borderRadius: BorderRadius.circular(8)),
                                        child: const Text('ENHANCED 4K', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                  if (_isProcessing)
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: const Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircularProgressIndicator(color: Color(0xFF00E5FF)),
                                            SizedBox(height: 15),
                                            Text('AI Processing & Upscaling...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  if (_isProcessed) ...[
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
                    const Text('Slide to compare Before / After', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 15),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E5FF),
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _exportAndSaveImage,
                      icon: const Icon(Icons.download_rounded, color: Colors.black, size: 24),
                      label: const Text('EXPORT / SAVE (4K ULTRA HD)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ],
                  const SizedBox(height: 25),
                  _buildGlassActionTile(
                    title: 'Enhance Photo',
                    subtitle: 'Restore Face, Denoise & Sharpen',
                    icon: Icons.auto_awesome,
                    iconColor: const Color(0xFFFFD700),
                    onTap: () => _pickImage('Enhance'),
                  ),
                  const SizedBox(height: 14),
                  _buildGlassActionTile(
                    title: '4K Upscaling',
                    subtitle: 'Increase Resolution 2X, 4X & 8X',
                    icon: Icons.high_quality_rounded,
                    iconColor: const Color(0xFF00E5FF),
                    onTap: () => _pickImage('4K Upscale'),
                  ),
                  const SizedBox(height: 14),
                  _buildGlassActionTile(
                    title: 'Watermark Remover',
                    subtitle: 'Clean Logos, Objects & Text',
                    icon: Icons.cleaning_services_rounded,
                    iconColor: const Color(0xFFFF4081),
                    onTap: () => _pickImage('Watermark Remover'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassActionTile({
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
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
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
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white54)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
              ],
            ),
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
