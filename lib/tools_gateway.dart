import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Import halaman-halaman yang dibutuhkan
import 'manage_server.dart';
import 'wifi_internal.dart';
import 'wifi_external.dart';
import 'ddos_panel.dart';
import 'nik_check.dart';
import 'tiktok_page.dart';
import 'instagram_page.dart';
import 'qr_gen.dart';
import 'domain_page.dart';
import 'spam_ngl.dart';
import 'anime_home.dart'; 

class ToolsPage extends StatefulWidget {
  final String sessionKey;
  final String userRole;
  final List<Map<String, dynamic>> listDoos;

  const ToolsPage({
    super.key,
    required this.sessionKey,
    required this.userRole,
    required this.listDoos,
  });

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> with TickerProviderStateMixin {
  late AnimationController _bgController;
  late Animation<double> _bgAnimation;
  
  // --- PALET WARNA HITAM-MERAH-UNGU ---
  final Color bgColor = const Color(0xFF0A0A0F);
  final Color cardColor = const Color(0xFF1A0A1A);
  final Color borderColor = const Color(0xFF4A1A3A);
  final Color accentRed = const Color(0xFFFF0033);
  final Color accentPurple = const Color(0xFF9C27B0);
  final Color textWhite = const Color(0xFFFFFFFF);
  final Color textMuted = const Color(0xFF8A6A7A);

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat(reverse: true);

    _bgAnimation = Tween<double>(begin: 0, end: 1).animate(_bgController);
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background dengan partikel
          _buildAnimatedBackground(),
          
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildToolGrid(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _bgAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            Container(color: bgColor),
            // Partikel merah & ungu
            ...List.generate(20, (index) {
              final top = (_bgAnimation.value + index * 0.07) % 1.0;
              final left = (index * 0.12) % 1.0;
              final size = 3.0 + (index % 4) * 2.0;
              final isRed = index % 2 == 0;
              return Positioned(
                top: top * MediaQuery.of(context).size.height,
                left: left * MediaQuery.of(context).size.width,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: (isRed ? accentRed : accentPurple).withOpacity(0.15),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isRed ? accentRed : accentPurple).withOpacity(0.1),
                        blurRadius: 8,
                      )
                    ],
                  ),
                ),
              );
            }),
            // Glow effect
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [accentRed.withOpacity(0.08), Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [accentPurple.withOpacity(0.08), Colors.transparent],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentRed.withOpacity(0.1), accentPurple.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentRed.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: accentRed.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF0033), Color(0xFF9C27B0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: accentRed.withOpacity(0.3),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "TOOLS GATEWAY",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  "${widget.userRole.toUpperCase()} • ${widget.listDoos.length} modules",
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 11,
                    fontFamily: 'ShareTechMono',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF0033), Color(0xFF9C27B0)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "v6.0",
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                fontFamily: 'Orbitron',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolGrid() {
    final List<Map<String, dynamic>> tools = [
      // DDoS
      {'title': 'Attack Panel', 'icon': Icons.bolt, 'color': accentRed, 'page': AttackPanel(sessionKey: widget.sessionKey, listDoos: widget.listDoos)},
      {'title': 'Manage Server', 'icon': Icons.dns, 'color': accentPurple, 'page': ManageServerPage(keyToken: widget.sessionKey)},
      
      // Network
      {'title': 'Spam NGL', 'icon': Icons.newspaper, 'color': const Color(0xFFFF6D00), 'page': const NglPage()},
      {'title': 'WiFi Killer', 'icon': Icons.wifi_off, 'color': const Color(0xFFE53935), 'page': const WifiKillerPage()},
      
      // OSINT
      {'title': 'NIK Check', 'icon': Icons.badge, 'color': const Color(0xFF2196F3), 'page': const NikCheckerPage()},
      {'title': 'Domain OSINT', 'icon': Icons.domain, 'color': const Color(0xFF9C27B0), 'page': const DomainOsintPage()},
      
      // Downloader
      {'title': 'Anime Station', 'icon': Icons.movie_filter, 'color': const Color(0xFFFF4081), 'page': const HomeAnimePage()},
      {'title': 'TikTok DL', 'icon': Icons.tiktok, 'color': const Color(0xFF00BCD4), 'page': const TiktokDownloaderPage()},
      {'title': 'Instagram DL', 'icon': Icons.camera_alt, 'color': const Color(0xFFE91E63), 'page': const InstagramDownloaderPage()},
      
      // Utilities
      {'title': 'QR Generator', 'icon': Icons.qr_code, 'color': const Color(0xFF4CAF50), 'page': const QrGeneratorPage()},
    ];

    // Filter berdasarkan role
    if (widget.userRole != "owner" && widget.userRole != "vip") {
      tools.removeWhere((t) => t['title'] == 'WiFi Killer' || t['title'] == 'Spam NGL');
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.85,
      ),
      itemCount: tools.length,
      itemBuilder: (context, index) {
        final tool = tools[index];
        return _buildToolCard(tool);
      },
    );
  }

  Widget _buildToolCard(Map<String, dynamic> tool) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(context, MaterialPageRoute(builder: (_) => tool['page']));
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              cardColor,
              cardColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (tool['color'] as Color).withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (tool['color'] as Color).withOpacity(0.1),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          (tool['color'] as Color).withOpacity(0.2),
                          (tool['color'] as Color).withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: (tool['color'] as Color).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      tool['icon'] as IconData,
                      color: tool['color'] as Color,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    tool['title'] as String,
                    style: TextStyle(
                      color: textWhite,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Orbitron',
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 30,
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          (tool['color'] as Color),
                          (tool['color'] as Color).withOpacity(0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "OPEN →",
                    style: TextStyle(
                      color: (tool['color'] as Color).withOpacity(0.5),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'ShareTechMono',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}