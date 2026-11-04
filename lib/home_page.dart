import 'api_server.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

class HomePage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final String role;
  final String expiredDate;
  final bool isGroup;

  const HomePage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.listBug,
    required this.role,
    required this.expiredDate,
    this.isGroup = false,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late AnimationController _pulseController;
  late AnimationController _resultCtrl;
  late Animation<double> _resultFade;
  late Animation<Offset> _resultSlide;

  final targetController = TextEditingController();
  final linkController = TextEditingController();
  final customBugController = TextEditingController();
  final PageController _bugPageController = PageController(viewportFraction: 0.85);
  late PageController _menuPageController;

  String? _selectedBugId;
  bool _isSending = false;
  String? _responseMessage;
  int _currentBugPage = 0;
  int _selectedMenuIndex = -1;
  int _currentMenuPage = 0;

  // Sender
  List<String> _globalSenders = [];
  List<String> _privateSenders = [];
  bool _isLoadingSenders = false;
  int _privateSenderCount = 0;
  int _globalSenderCount = 0;
  bool _loadingSender = false;
  Timer? _senderTimer;
  String? _senderError;

  String _selectedSender = 'private';

  // ==================== CYBERPUNK COLOR THEME ====================
  final Color _bugNumberColor = const Color(0xFF00FFFF);   // Cyan neon
  final Color _bugGroupColor = const Color(0xFFFF00FF);    // Magenta neon
  final Color _customBugColor = const Color(0xFFAA00FF);   // Ungu neon
  final Color _greenAccent = const Color(0xFF00FF88);      // Hijau neon
  final Color _textWhite = const Color(0xFFE0F0FF);        // Putih kebiruan
  final Color _textGrey = const Color(0xFF7A8B9E);         // Abu-abu biru
  final Color _neonPink = const Color(0xFFFF007F);
  final Color _neonPurple = const Color(0xFF9D00FF);
  final Color _neonBlue = const Color(0xFF0066FF);
  final Color _darkBg = const Color(0xFF0A0A1A);

  final String baseUrl = '$ApiServer.baseUrl';

  bool get canAccessGlobalSender {
    final r = widget.role.toLowerCase();
    return r == 'owner' || r == 'admin' || r == 'moderator' || r == 'partner' || r == 'vip' ||
        r == 'founder' || r == 'high admin' || r == 'high owner' || r == 'dev';
  }

  Color getCurrentModeColor() {
    if (_selectedMenuIndex == 1) return _bugGroupColor;
    if (_selectedMenuIndex == 2) return _customBugColor;
    return _bugNumberColor;
  }

  @override
  void initState() {
    super.initState();

    _videoController = VideoPlayerController.asset('assets/videos/background.mp4')
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _videoController.setLooping(true);
        _videoController.setVolume(0.0);
        _videoController.play();
      }).catchError((e) {
        print('Error loading video: $e');
      });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _resultCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _resultFade = CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOut);
    _resultSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOutCubic));

    _menuPageController = PageController(initialPage: 0);

    _fetchSenderStats();
    _loadSenders();
    _senderTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchSenderStats();
      _loadSenders();
    });

    if (widget.listBug.isNotEmpty) {
      _selectedBugId = widget.listBug[0]['bug_id'] as String? ?? '0';
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    _pulseController.dispose();
    _resultCtrl.dispose();
    targetController.dispose();
    linkController.dispose();
    customBugController.dispose();
    _bugPageController.dispose();
    _menuPageController.dispose();
    _senderTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchSenderStats() async {
    if (_loadingSender) return;
    setState(() => _loadingSender = true);
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/whatsapp/mySender?key=${widget.sessionKey}"),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true && data['connections'] != null) {
          final globalList = data['connections']['global'] as List?;
          final privateList = data['connections']['private'] as List?;
          setState(() {
            _globalSenderCount = globalList?.length ?? 0;
            _privateSenderCount = privateList?.length ?? 0;
            _loadingSender = false;
            _senderError = null;
          });
        } else {
          setState(() {
            _loadingSender = false;
            _senderError = data['message'] ?? 'Invalid session';
          });
        }
      } else {
        setState(() {
          _loadingSender = false;
          _senderError = 'HTTP ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _loadingSender = false;
        _senderError = 'Connection error';
      });
    }
  }

  Future<void> _loadSenders() async {
    try {
      final res = await http.get(Uri.parse(
        '$baseUrl/api/whatsapp/mySender?key=${widget.sessionKey}',
      )).timeout(const Duration(seconds: 10));
      
      final data = jsonDecode(res.body);
      if (data['valid'] == true && data['connections'] != null) {
        final globalList = data['connections']['global'] as List?;
        final privateList = data['connections']['private'] as List?;
        if (mounted) {
          setState(() {
            _globalSenders = globalList?.map((e) => e.toString()).toList() ?? [];
            _privateSenders = privateList?.map((e) => e.toString()).toList() ?? [];
            _globalSenderCount = _globalSenders.length;
            _privateSenderCount = _privateSenders.length;
          });
        }
      }
    } catch (e) {
      print('Error loading senders: $e');
    }
  }

  String? formatPhoneNumber(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^\d+]'), '');
    if (!cleaned.startsWith('+') || cleaned.length < 8) return null;
    return cleaned;
  }

  void _setResponse(String type, String msg) {
    if (!mounted) return;
    setState(() => _responseMessage = '$type|$msg');
    _resultCtrl.forward(from: 0);
  }

  Future<void> _sendBugNumber() async {
    final rawInput = targetController.text.trim();

    if (formatPhoneNumber(rawInput) == null) {
      _showAlert("Nomor Tidak Valid", "Gunakan format internasional.\nContoh: +62812xxxxxxxx");
      return;
    }

    if (_selectedBugId == null || _selectedBugId!.isEmpty) {
      _showAlert("No Bug Selected", "Pilih bug untuk dikirim.");
      return;
    }

    await _loadSenders();
    
    if (_selectedSender == 'private' && _privateSenders.isEmpty) {
      _showAlert("No Private Sender", "Tidak ada private sender tersedia.");
      return;
    }
    
    if (_selectedSender == 'global' && _globalSenders.isEmpty) {
      _showAlert("No Global Sender", "Tidak ada global sender tersedia.");
      return;
    }

    setState(() {
      _isSending = true;
      _responseMessage = null;
    });
    _resultCtrl.reset();

    try {
      final encodedTarget = Uri.encodeComponent(rawInput);
      String url = '$baseUrl/sendBug?key=${widget.sessionKey}&target=$encodedTarget&bug=${_selectedBugId}&senderType=$_selectedSender';
      
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      final data = jsonDecode(res.body);

      if (data['valid'] == false) {
        _setResponse('error', 'Session key tidak valid.');
      } else if (data['cooldown'] == true) {
        _setResponse('warning', 'Cooldown aktif! Tunggu ${data['wait'] ?? 0} detik.');
      } else if (data['sended'] == true) {
        _setResponse('success', '✅ Bug berhasil dikirim ke $rawInput!');
        targetController.clear();
        _fetchSenderStats();
        _loadSenders();
      } else {
        _setResponse('error', '❌ Gagal mengirim: ${data['message'] ?? 'Server error'}');
      }
    } catch (e) {
      _setResponse('error', '⚠️ Koneksi error');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _sendBugGroup() async {
    final link = linkController.text.trim();

    if (link.isEmpty) {
      _showAlert("Link Tidak Valid", "Link group tidak boleh kosong!");
      return;
    }

    if (!link.contains("chat.whatsapp.com")) {
      _showAlert("Link Invalid", "Link Group tidak valid!");
      return;
    }

    if (_selectedBugId == null || _selectedBugId!.isEmpty) {
      _showAlert("No Bug Selected", "Pilih bug untuk dikirim.");
      return;
    }

    await _loadSenders();
    
    if (_selectedSender == 'private' && _privateSenders.isEmpty) {
      _showAlert("No Private Sender", "Tidak ada private sender tersedia.");
      return;
    }
    
    if (_selectedSender == 'global' && _globalSenders.isEmpty) {
      _showAlert("No Global Sender", "Tidak ada global sender tersedia.");
      return;
    }

    setState(() {
      _isSending = true;
      _responseMessage = null;
    });
    _resultCtrl.reset();

    try {
      final encodedLink = Uri.encodeComponent(link);
      String url = '$baseUrl/raidGroup?key=${widget.sessionKey}&link=$encodedLink&bug=${_selectedBugId}&senderType=$_selectedSender';
      
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      final data = jsonDecode(res.body);

      if (data['valid'] == false) {
        _setResponse('error', 'Session key tidak valid.');
      } else if (data['cooldown'] == true) {
        _setResponse('warning', 'Cooldown aktif! Tunggu ${data['wait'] ?? 0} detik.');
      } else if (data['sended'] == true) {
        _setResponse('success', '✅ Bug berhasil dikirim ke Group!');
        linkController.clear();
        _fetchSenderStats();
        _loadSenders();
      } else {
        _setResponse('error', '❌ Gagal mengirim: ${data['message'] ?? 'Server error'}');
      }
    } catch (e) {
      _setResponse('error', '⚠️ Koneksi error');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _sendCustomBug() async {
    final customPayload = customBugController.text.trim();

    if (customPayload.isEmpty) {
      _showAlert("Error", "Custom payload tidak boleh kosong!");
      return;
    }

    setState(() {
      _isSending = true;
      _responseMessage = null;
    });
    _resultCtrl.reset();

    try {
      final url = '$baseUrl/customBug?key=${widget.sessionKey}&payload=$customPayload';
      final res = await http.post(Uri.parse(url)).timeout(const Duration(seconds: 15));
      final data = jsonDecode(res.body);

      if (data['success'] == true) {
        _setResponse('success', '✅ Custom bug payload terkirim!');
        customBugController.clear();
      } else {
        _setResponse('error', '❌ Gagal mengirim custom bug.');
      }
    } catch (e) {
      _setResponse('error', '⚠️ Koneksi error');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showAlert(String title, String msg) {
    final modeColor = getCurrentModeColor();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _darkBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: modeColor, width: 2),
        ),
        title: Text(title, style: TextStyle(color: modeColor, fontWeight: FontWeight.bold)),
        content: Text(msg, style: TextStyle(color: _textWhite.withOpacity(0.8))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: TextStyle(color: modeColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _selectMenu(int index) {
    setState(() {
      _selectedMenuIndex = index;
      _responseMessage = null;
    });
  }

  void _backToMenu() {
    setState(() {
      _selectedMenuIndex = -1;
      _responseMessage = null;
      targetController.clear();
      linkController.clear();
      customBugController.clear();
    });
  }

  Widget _glassCard({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
    BorderRadius? borderRadius,
    Color? borderColor,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: borderRadius ?? BorderRadius.circular(20),
            border: Border.all(color: borderColor ?? Colors.white.withOpacity(0.1), width: 1.2),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildTopAppBar() {
    final modeColor = getCurrentModeColor();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: _selectedMenuIndex != -1 ? _backToMenu : null,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: modeColor.withOpacity(0.15),
                border: Border.all(color: modeColor, width: 1.8),
                boxShadow: [BoxShadow(color: modeColor.withOpacity(0.3), blurRadius: 8)],
              ),
              child: Icon(_selectedMenuIndex != -1 ? Icons.arrow_back : Icons.shield_rounded, 
                  color: modeColor, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _selectedMenuIndex == -1 ? 'XForcez Death' : 
            (_selectedMenuIndex == 0 ? 'BUG NUMBER' : 
             (_selectedMenuIndex == 1 ? 'BUG GROUP' : 'CUSTOM BUG')),
            style: TextStyle(
              color: _textWhite,
              fontFamily: 'Orbitron',
              fontWeight: FontWeight.w900,
              fontSize: 19,
              letterSpacing: 2,
              shadows: [Shadow(color: modeColor.withOpacity(0.3), blurRadius: 10)],
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: modeColor, width: 1.5),
              boxShadow: [BoxShadow(color: modeColor.withOpacity(0.2), blurRadius: 8)],
            ),
            child: Text('v6.0', style: TextStyle(color: modeColor, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final modeColor = getCurrentModeColor();
    return _glassCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: modeColor, width: 2.5),
                  boxShadow: [BoxShadow(color: modeColor.withOpacity(0.3), blurRadius: 12)],
                ),
                child: ClipOval(
                  child: Image.asset('assets/images/logo.png', fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(Icons.person, color: modeColor, size: 32)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.username.toUpperCase(),
                        style: TextStyle(color: _textWhite, fontFamily: 'Orbitron', fontWeight: FontWeight.w900, fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(widget.role.toUpperCase(),
                        style: TextStyle(color: modeColor, fontFamily: 'ShareTechMono', fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: _darkBg.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: modeColor.withOpacity(0.2)),
                ),
                child: Text(widget.expiredDate, style: TextStyle(color: _textWhite, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_darkBg.withOpacity(0.5), modeColor.withOpacity(0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: modeColor.withOpacity(0.15), width: 1),
            ),
            child: Row(
              children: [
                _buildStatItem(Icons.bug_report_rounded, modeColor, '${widget.listBug.length}', 'Total Bugs'),
                _buildStatDivider(),
                _buildStatItem(Icons.bolt_rounded, _greenAccent, 'GACOR', 'Success Rate'),
                _buildStatDivider(),
                _buildStatItem(Icons.check_circle_rounded, _greenAccent, 'ACTIVE', 'Status'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, Color color, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: color.withOpacity(0.3), width: 1.2),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 7),
          Text(value, style: TextStyle(color: _textWhite, fontWeight: FontWeight.w900, fontSize: 14)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: _textGrey, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, height: 52, color: Colors.white.withOpacity(0.06));
  }

  Widget _buildMainMenu() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00FFFF), Color(0xFFFF00FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00FFFF).withOpacity(0.4),
                blurRadius: 25,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(Icons.flash_on_rounded, color: Colors.black, size: 34),
        ),
        const SizedBox(height: 12),
        Text(
          "XForcez Death MENU",
          style: TextStyle(
            color: _textWhite,
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 3,
            shadows: [
              Shadow(color: const Color(0xFF00FFFF).withOpacity(0.4), blurRadius: 15),
              Shadow(color: const Color(0xFFFF00FF).withOpacity(0.3), blurRadius: 25),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Pilih menu yang tersedia bosque!",
          style: TextStyle(color: _textGrey, fontSize: 13, fontFamily: 'ShareTechMono'),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 540,
          child: PageView.builder(
            controller: _menuPageController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() => _currentMenuPage = index);
            },
            itemCount: 3,
            itemBuilder: (context, index) {
              final menus = [
                {
                  "title": "XForcez Death BUG",
                  "subtitle": "Bug tanpa custom",
                  "desc": "Gunakan langsung tanpa custom delay dan loops",
                  "features": ["Mudah digunakan", "Function terbaru", "All work gacor"],
                  "color": _bugNumberColor,
                  "icon": Icons.bug_report,
                  "menuIndex": 0
                },
                {
                  "title": "GROUP BUG",
                  "subtitle": "Raid group WhatsApp",
                  "desc": "Kirim bug ke group dengan cepat",
                  "features": ["Support all group", "Fast response", "Anti cooldown"],
                  "color": _bugGroupColor,
                  "icon": Icons.group,
                  "menuIndex": 1
                },
                {
                  "title": "CUSTOM BUG",
                  "subtitle": "Payload custom sendiri",
                  "desc": "Buat payload sesuai keinginan",
                  "features": ["Fully customizable", "Support semua format", "Premium feature"],
                  "color": _customBugColor,
                  "icon": Icons.code,
                  "menuIndex": 2
                },
              ];
              
              final menu = menus[index];
              final Color cardColor = menu["color"] as Color;
              
              return GestureDetector(
                onTap: () => _selectMenu(menu["menuIndex"] as int),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: cardColor.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              cardColor.withOpacity(0.5),
                              _darkBg.withOpacity(0.8),
                              Colors.black.withOpacity(0.5),
                            ],
                          ),
                          border: Border.all(color: cardColor.withOpacity(0.4), width: 1.8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: cardColor.withOpacity(0.2)),
                                    ),
                                    child: Icon(menu["icon"] as IconData, color: Colors.white, size: 28),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [cardColor, cardColor.withOpacity(0.5)],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Text(
                                      "NEW",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Orbitron',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Text(
                                menu["title"] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Orbitron',
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                menu["subtitle"] as String,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                  fontFamily: 'ShareTechMono',
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(height: 1, color: Colors.white.withOpacity(0.1)),
                              const SizedBox(height: 14),
                              Text(
                                menu["desc"] as String,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 13,
                                  fontFamily: 'ShareTechMono',
                                ),
                              ),
                              const SizedBox(height: 20),
                              ...(menu["features"] as List<String>).map((feature) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: cardColor,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        feature,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 12,
                                          fontFamily: 'ShareTechMono',
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              const Spacer(),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [cardColor.withOpacity(0.2), cardColor.withOpacity(0.05)],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: cardColor.withOpacity(0.2)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "START MODULE",
                                      style: TextStyle(
                                        color: cardColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Orbitron',
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(Icons.arrow_forward, color: cardColor, size: 16),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final isActive = i == _currentMenuPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 30 : 8,
              height: 6,
              decoration: BoxDecoration(
                gradient: isActive
                    ? const LinearGradient(colors: [Color(0xFF00FFFF), Color(0xFFFF00FF)])
                    : null,
                color: isActive ? null : Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(3),
                boxShadow: isActive
                    ? [BoxShadow(color: const Color(0xFF00FFFF).withOpacity(0.5), blurRadius: 6)]
                    : null,
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          "Geser kiri/kanan • ${_currentMenuPage + 1}/3",
          style: TextStyle(
            color: _textGrey.withOpacity(0.5),
            fontSize: 11,
            fontFamily: 'ShareTechMono',
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBugNumberForm() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 14),
          _buildNomorAndBugPanel(),
          const SizedBox(height: 14),
          _buildSenderPanel(),
          const SizedBox(height: 20),
          _buildSendButton(onPressed: _sendBugNumber, label: 'SEND BUG'),
          _buildResponseMessage(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBugGroupForm() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 14),
          _buildGroupLinkPanel(),
          const SizedBox(height: 14),
          _buildBugSelectorPanel(),
          const SizedBox(height: 14),
          _buildSenderPanel(),
          const SizedBox(height: 20),
          _buildSendButton(onPressed: _sendBugGroup, label: 'SEND BUG GROUP'),
          _buildResponseMessage(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCustomBugForm() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 14),
          _buildCustomPayloadPanel(),
          const SizedBox(height: 20),
          _buildSendButton(onPressed: _sendCustomBug, label: 'SEND CUSTOM BUG'),
          _buildResponseMessage(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildNomorAndBugPanel() {
    final modeColor = getCurrentModeColor();
    return _glassCard(
      padding: const EdgeInsets.all(18),
      borderColor: modeColor.withOpacity(0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.phone_android_rounded, color: modeColor, size: 18),
              const SizedBox(width: 8),
              Text('NOMOR TARGET', style: TextStyle(color: _textWhite, fontFamily: 'Orbitron', fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: _darkBg.withOpacity(0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: modeColor.withOpacity(0.25), width: 1.2),
              boxShadow: [BoxShadow(color: modeColor.withOpacity(0.08), blurRadius: 8)],
            ),
            child: TextField(
              controller: targetController,
              style: TextStyle(color: _textWhite, fontSize: 15),
              cursorColor: modeColor,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: '+62812xxxxxxxx',
                hintStyle: TextStyle(color: _textGrey.withOpacity(0.5)),
                prefixIcon: Icon(Icons.language_rounded, color: _textGrey, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.bug_report, color: modeColor, size: 20),
              const SizedBox(width: 8),
              Text('PILIH BUG', style: TextStyle(color: _textWhite, fontFamily: 'Orbitron', fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 170,
            child: PageView.builder(
              controller: _bugPageController,
              itemCount: widget.listBug.length,
              onPageChanged: (i) {
                setState(() {
                  _currentBugPage = i;
                  _selectedBugId = widget.listBug[i]['bug_id'] as String? ?? '$i';
                });
              },
              itemBuilder: (context, index) {
                final bug = widget.listBug[index];
                final bugId = bug['bug_id'] as String? ?? '$index';
                final isSelected = _selectedBugId == bugId;
                return GestureDetector(
                  onTap: () => setState(() => _selectedBugId = bugId),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [modeColor.withOpacity(0.2), _darkBg.withOpacity(0.6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected ? null : Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected ? modeColor : Colors.white.withOpacity(0.08),
                        width: isSelected ? 2.5 : 1.2,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: modeColor.withOpacity(0.2), blurRadius: 12)]
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(Icons.shield_rounded, color: isSelected ? modeColor : _textGrey, size: 36),
                            if (isSelected) Icon(Icons.check_circle, color: _greenAccent, size: 24),
                          ],
                        ),
                        const Spacer(),
                        Text((bug['bug_name'] as String? ?? 'BUG').toUpperCase(),
                            style: TextStyle(color: isSelected ? modeColor : _textWhite, fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _darkBg.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: modeColor.withOpacity(0.1)),
                          ),
                          child: Text(bugId, style: TextStyle(color: _textGrey, fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.listBug.length, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _currentBugPage ? 24 : 8,
                height: 6,
                decoration: BoxDecoration(
                  gradient: i == _currentBugPage
                      ? const LinearGradient(colors: [Color(0xFF00FFFF), Color(0xFFFF00FF)])
                      : null,
                  color: i == _currentBugPage ? null : Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupLinkPanel() {
    final modeColor = getCurrentModeColor();
    return _glassCard(
      padding: const EdgeInsets.all(18),
      borderColor: modeColor.withOpacity(0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.link, color: modeColor, size: 18),
              const SizedBox(width: 8),
              Text('LINK GROUP', style: TextStyle(color: _textWhite, fontFamily: 'Orbitron', fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: _darkBg.withOpacity(0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: modeColor.withOpacity(0.25), width: 1.2),
              boxShadow: [BoxShadow(color: modeColor.withOpacity(0.08), blurRadius: 8)],
            ),
            child: TextField(
              controller: linkController,
              style: TextStyle(color: _textWhite, fontSize: 15),
              cursorColor: modeColor,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                hintText: 'https://chat.whatsapp.com/...',
                hintStyle: TextStyle(color: _textGrey.withOpacity(0.5)),
                prefixIcon: Icon(Icons.group, color: _textGrey, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomPayloadPanel() {
    final modeColor = getCurrentModeColor();
    return _glassCard(
      padding: const EdgeInsets.all(18),
      borderColor: modeColor.withOpacity(0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.code, color: modeColor, size: 18),
              const SizedBox(width: 8),
              Text('CUSTOM PAYLOAD', style: TextStyle(color: _textWhite, fontFamily: 'Orbitron', fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: _darkBg.withOpacity(0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: modeColor.withOpacity(0.25), width: 1.2),
              boxShadow: [BoxShadow(color: modeColor.withOpacity(0.08), blurRadius: 8)],
            ),
            child: TextField(
              controller: customBugController,
              style: TextStyle(color: _textWhite, fontSize: 15),
              cursorColor: modeColor,
              maxLines: 5,
              minLines: 3,
              decoration: InputDecoration(
                hintText: 'Masukkan payload custom disini...',
                hintStyle: TextStyle(color: _textGrey.withOpacity(0.5)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBugSelectorPanel() {
    final modeColor = getCurrentModeColor();
    return _glassCard(
      padding: const EdgeInsets.all(18),
      borderColor: modeColor.withOpacity(0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bug_report, color: modeColor, size: 20),
              const SizedBox(width: 8),
              Text('PILIH BUG', style: TextStyle(color: _textWhite, fontFamily: 'Orbitron', fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 170,
            child: PageView.builder(
              controller: _bugPageController,
              itemCount: widget.listBug.length,
              onPageChanged: (i) {
                setState(() {
                  _currentBugPage = i;
                  _selectedBugId = widget.listBug[i]['bug_id'] as String? ?? '$i';
                });
              },
              itemBuilder: (context, index) {
                final bug = widget.listBug[index];
                final bugId = bug['bug_id'] as String? ?? '$index';
                final isSelected = _selectedBugId == bugId;
                return GestureDetector(
                  onTap: () => setState(() => _selectedBugId = bugId),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [modeColor.withOpacity(0.2), _darkBg.withOpacity(0.6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected ? null : Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected ? modeColor : Colors.white.withOpacity(0.08),
                        width: isSelected ? 2.5 : 1.2,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: modeColor.withOpacity(0.2), blurRadius: 12)]
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(Icons.shield_rounded, color: isSelected ? modeColor : _textGrey, size: 36),
                            if (isSelected) Icon(Icons.check_circle, color: _greenAccent, size: 24),
                          ],
                        ),
                        const Spacer(),
                        Text((bug['bug_name'] as String? ?? 'BUG').toUpperCase(),
                            style: TextStyle(color: isSelected ? modeColor : _textWhite, fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _darkBg.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: modeColor.withOpacity(0.1)),
                          ),
                          child: Text(bugId, style: TextStyle(color: _textGrey, fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.listBug.length, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _currentBugPage ? 24 : 8,
                height: 6,
                decoration: BoxDecoration(
                  gradient: i == _currentBugPage
                      ? const LinearGradient(colors: [Color(0xFF00FFFF), Color(0xFFFF00FF)])
                      : null,
                  color: i == _currentBugPage ? null : Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSenderPanel() {
    final modeColor = getCurrentModeColor();
    return _glassCard(
      padding: const EdgeInsets.all(16),
      borderColor: modeColor.withOpacity(0.15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.swap_horiz_rounded, color: _textWhite, size: 20),
              const SizedBox(width: 8),
              Text('PILIH SENDER', style: TextStyle(color: _textWhite, fontFamily: 'Orbitron', fontWeight: FontWeight.bold, fontSize: 14)),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  _fetchSenderStats();
                  _loadSenders();
                },
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _darkBg.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: modeColor.withOpacity(0.2)),
                  ),
                  child: (_isLoadingSenders || _loadingSender)
                      ? Padding(padding: const EdgeInsets.all(7), child: CircularProgressIndicator(strokeWidth: 2, color: modeColor))
                      : Icon(Icons.refresh_rounded, color: _textGrey, size: 16),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: modeColor),
                  boxShadow: [BoxShadow(color: modeColor.withOpacity(0.15), blurRadius: 6)],
                ),
                child: Text(_loadingSender ? 'loading...' : '${_privateSenderCount + _globalSenderCount} ready',
                    style: TextStyle(color: _greenAccent, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await _loadSenders();
                    setState(() => _selectedSender = 'private');
                  },
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: _selectedSender == 'private'
                          ? const LinearGradient(
                              colors: [Color(0xFF00FF88), Color(0xFF00FFFF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: _selectedSender == 'private' ? null : _darkBg.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _selectedSender == 'private' ? const Color(0xFF00FF88) : Colors.white.withOpacity(0.06),
                        width: 1.8,
                      ),
                      boxShadow: _selectedSender == 'private'
                          ? [BoxShadow(color: const Color(0xFF00FF88).withOpacity(0.3), blurRadius: 15)]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_rounded, color: _selectedSender == 'private' ? Colors.black : _textGrey, size: 38),
                        const SizedBox(height: 10),
                        Text('Pribadi', style: TextStyle(color: _selectedSender == 'private' ? Colors.black : _textGrey, fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 6),
                        _privateSenderCount == 0
                            ? Text('Tidak Ada', style: TextStyle(color: Colors.redAccent, fontSize: 12))
                            : Text('$_privateSenderCount sender', style: TextStyle(color: _selectedSender == 'private' ? Colors.black87 : _greenAccent, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    if (!canAccessGlobalSender) {
                      _showAlert('Akses Ditolak', 'Global sender hanya untuk Owner, Admin, Moderator, Partner & VIP!');
                      return;
                    }
                    await _loadSenders();
                    setState(() => _selectedSender = 'global');
                  },
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: _selectedSender == 'global'
                          ? const LinearGradient(
                              colors: [Color(0xFFFF00FF), Color(0xFF9D00FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: _selectedSender == 'global' ? null : _darkBg.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _selectedSender == 'global' ? const Color(0xFFFF00FF) : Colors.white.withOpacity(0.06),
                        width: 1.8,
                      ),
                      boxShadow: _selectedSender == 'global'
                          ? [BoxShadow(color: const Color(0xFFFF00FF).withOpacity(0.3), blurRadius: 15)]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.public_rounded, color: _selectedSender == 'global' ? Colors.black : _textGrey, size: 38),
                        const SizedBox(height: 10),
                        Text('Global', style: TextStyle(color: _selectedSender == 'global' ? Colors.black : _textGrey, fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 6),
                        _globalSenderCount == 0
                            ? Text('Tidak Ada', style: TextStyle(color: Colors.redAccent, fontSize: 12))
                            : Text('$_globalSenderCount sender', style: TextStyle(color: _selectedSender == 'global' ? Colors.black87 : modeColor, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_privateSenders.isNotEmpty && _selectedSender == 'private')
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _darkBg.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _greenAccent.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_privateSenders.length} sender aktif', style: TextStyle(color: _textGrey, fontSize: 11)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _privateSenders.take(3).map((sender) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _greenAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _greenAccent.withOpacity(0.1)),
                        ),
                        child: Text(sender, style: TextStyle(color: _greenAccent, fontSize: 10)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSendButton({required VoidCallback onPressed, required String label}) {
    final modeColor = getCurrentModeColor();
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          height: 55,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [modeColor, modeColor.withOpacity(0.5), _neonPurple.withOpacity(0.3)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: modeColor.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: _neonPurple.withOpacity(0.2),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isSending ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isSending
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildResponseMessage() {
    if (_responseMessage == null) return const SizedBox.shrink();
    final parts = _responseMessage!.split('|');
    final type = parts[0];
    final msg = parts.length > 1 ? parts[1] : '';
    Color color = type == 'success' ? _greenAccent : (type == 'warning' ? Colors.amber : Colors.redAccent);
    return FadeTransition(
      opacity: _resultFade,
      child: SlideTransition(
        position: _resultSlide,
        child: Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), _darkBg.withOpacity(0.5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.4), width: 1.5),
            boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 12)],
          ),
          child: Row(
            children: [
              Icon(type == 'success' ? Icons.check_circle_outline : (type == 'warning' ? Icons.warning_rounded : Icons.error_outline), color: color, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(msg, style: TextStyle(color: _textGrey, fontSize: 12))),
              GestureDetector(
                onTap: () => setState(() => _responseMessage = null),
                child: Icon(Icons.close, color: _textGrey, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: _videoController.value.isInitialized ? VideoPlayer(_videoController) : Container(color: _darkBg),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.5),
                  _darkBg.withOpacity(0.85),
                  _darkBg.withOpacity(0.95),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopAppBar(),
                Container(height: 1, color: Colors.white.withOpacity(0.05)),
                Expanded(
                  child: _selectedMenuIndex == -1
                      ? _buildMainMenu()
                      : (_selectedMenuIndex == 0
                          ? _buildBugNumberForm()
                          : (_selectedMenuIndex == 1 ? _buildBugGroupForm() : _buildCustomBugForm())),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}