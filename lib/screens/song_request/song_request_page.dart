import 'package:drumly/models/song_request_model.dart';
import 'package:drumly/provider/user_provider.dart';
import 'package:drumly/services/song_request_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SongRequestPage extends StatefulWidget {
  const SongRequestPage({super.key});

  @override
  State<SongRequestPage> createState() => _SongRequestPageState();
}

class _SongRequestPageState extends State<SongRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final SongRequestService _songRequestService = SongRequestService();
  bool _isLoading = false;

  // Form controllers
  final _artistController = TextEditingController();
  final _songTitleController = TextEditingController();
  final _songLinkController = TextEditingController();
  final _albumController = TextEditingController();
  final _genreController = TextEditingController();
  final _releaseYearController = TextEditingController();
  final _languageController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedPriority = 'normal';
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  void _initializeData() {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _searchQuery = args?['searchQuery'];

    // If there's a search query, pre-fill the form
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      // Try to parse artist and song from search query
      final parts = _searchQuery!.split(' - ');
      if (parts.length == 2) {
        _artistController.text = parts[0].trim();
        _songTitleController.text = parts[1].trim();
      } else {
        _songTitleController.text = _searchQuery!;
      }
    }
  }

  @override
  void dispose() {
    _artistController.dispose();
    _songTitleController.dispose();
    _songLinkController.dispose();
    _albumController.dispose();
    _genreController.dispose();
    _releaseYearController.dispose();
    _languageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [
                    const Color(0xFF0F172A),
                    const Color(0xFF1E293B),
                    const Color(0xFF334155),
                  ]
                : [
                    const Color(0xFFF8FAFC),
                    const Color(0xFFE2E8F0),
                    const Color(0xFFCBD5E1),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildAppBar(isDarkMode),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderSection(isDarkMode),
                        const SizedBox(height: 32),
                        _buildRequiredFields(isDarkMode),
                        const SizedBox(height: 24),
                        _buildOptionalFields(isDarkMode),
                        const SizedBox(height: 32),
                        _buildSubmitButton(isDarkMode),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🎨 Modern Header - Songs style
  Widget _buildAppBar(bool isDarkMode) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'request_song'.tr(),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildHeaderSection(bool isDarkMode) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.music_note_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'request_song_title'.tr(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'request_song_desc'.tr(),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode
                              ? Colors.white.withValues(alpha: 0.7)
                              : Colors.black.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildRequiredFields(bool isDarkMode) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'required_fields'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _artistController,
            label: 'artist_name'.tr(),
            hint: 'enter_artist_name'.tr(),
            icon: Icons.person_rounded,
            isDarkMode: isDarkMode,
            isRequired: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _songTitleController,
            label: 'song_title'.tr(),
            hint: 'enter_song_title'.tr(),
            icon: Icons.music_note_rounded,
            isDarkMode: isDarkMode,
            isRequired: true,
          ),
        ],
      );

  Widget _buildOptionalFields(bool isDarkMode) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'optional_fields'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _songLinkController,
            label: 'song_link'.tr(),
            hint: 'enter_youtube_link'.tr(),
            icon: Icons.link_rounded,
            isDarkMode: isDarkMode,
            keyboardType: TextInputType.url,
            validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                final url = value.trim();
                // URL formatını kontrol et
                if (!url.startsWith('http://') && !url.startsWith('https://')) {
                  return 'Geçerli bir URL girin (http:// veya https:// ile başlamalı)';
                }
                // YouTube/müzik platformları için basit kontrol
                if (!url.contains('youtube.com') &&
                    !url.contains('youtu.be') &&
                    !url.contains('spotify.com') &&
                    !url.contains('soundcloud.com')) {
                  return 'YouTube, Spotify veya SoundCloud linki girin';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _albumController,
                  label: 'album_name'.tr(),
                  hint: 'enter_album'.tr(),
                  icon: Icons.album_rounded,
                  isDarkMode: isDarkMode,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _genreController,
                  label: 'genre'.tr(),
                  hint: 'enter_genre'.tr(),
                  icon: Icons.category_rounded,
                  isDarkMode: isDarkMode,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _releaseYearController,
                  label: 'release_year'.tr(),
                  hint: 'enter_year'.tr(),
                  icon: Icons.calendar_today_rounded,
                  isDarkMode: isDarkMode,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _languageController,
                  label: 'language'.tr(),
                  hint: 'enter_language'.tr(),
                  icon: Icons.language_rounded,
                  isDarkMode: isDarkMode,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _descriptionController,
            label: 'description'.tr(),
            hint: 'enter_description'.tr(),
            icon: Icons.description_rounded,
            isDarkMode: isDarkMode,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          _buildPrioritySelector(isDarkMode),
        ],
      );

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDarkMode,
    bool isRequired = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label + (isRequired ? ' *' : ''),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            textInputAction:
                maxLines > 1 ? TextInputAction.done : TextInputAction.next,
            onFieldSubmitted:
                maxLines > 1 ? (_) => FocusScope.of(context).unfocus() : null,
            validator: validator ??
                (isRequired
                    ? (value) => value?.isEmpty == true
                        ? '$label ${'required'.tr()}'
                        : null
                    : null),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon),
              filled: true,
              fillColor: isDarkMode
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              hintStyle: TextStyle(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.black.withValues(alpha: 0.5),
              ),
            ),
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ],
      );

  Widget _buildPrioritySelector(bool isDarkMode) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'priority'.tr(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildPriorityChip('low', 'low_priority'.tr(), isDarkMode),
              const SizedBox(width: 8),
              _buildPriorityChip('normal', 'normal_priority'.tr(), isDarkMode),
              const SizedBox(width: 8),
              _buildPriorityChip('high', 'high_priority'.tr(), isDarkMode),
            ],
          ),
        ],
      );

  Widget _buildPriorityChip(String value, String label, bool isDarkMode) {
    final isSelected = _selectedPriority == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPriority = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF4F46E5)
                : isDarkMode
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? null
                : Border.all(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                  ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : isDarkMode
                      ? Colors.white
                      : Colors.black,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(bool isDarkMode) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submitRequest,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'submit_request'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      );

  Future<void> _submitRequest() async {
    // Form validasyonunu önce kontrol et
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Hemen loading'i başlat
    setState(() => _isLoading = true);

    try {
      // Direkt submit işlemini yap (reklam kaldırıldı)
      await _performSubmit();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('request_submitted_error'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 📝 Gerçek submit işlemi
  Future<void> _performSubmit() async {
    try {
      // Firebase Auth'dan user bilgilerini al
      final firebaseUser = FirebaseAuth.instance.currentUser;
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.userModel;

      final request = SongRequestModel(
        // Firebase Auth bilgilerini kullan
        userId: firebaseUser?.uid ?? user?.userId,
        userEmail: firebaseUser?.email ?? user?.email,
        userName: firebaseUser?.displayName ??
            user?.name ??
            firebaseUser?.email?.split('@').first,
        artistName: _artistController.text.trim(),
        songTitle: _songTitleController.text.trim(),
        songLink: _songLinkController.text.trim().isEmpty
            ? null
            : _songLinkController.text.trim(),
        albumName: _albumController.text.trim().isEmpty
            ? null
            : _albumController.text.trim(),
        genre: _genreController.text.trim().isEmpty
            ? null
            : _genreController.text.trim(),
        releaseYear: _releaseYearController.text.trim().isEmpty
            ? null
            : int.tryParse(_releaseYearController.text.trim()),
        language: _languageController.text.trim().isEmpty
            ? null
            : _languageController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        priority: _selectedPriority,
      );

      final success =
          await _songRequestService.createSongRequest(context, request);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('request_submitted_success'.tr()),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Şarkı talebi gönderilemedi. Lütfen bilgileri kontrol edin.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      String errorMessage = 'Şarkı talebi gönderilemedi';

      // Backend hata mesajını parse et
      final errorStr = e.toString();
      if (errorStr.contains('song_link') && errorStr.contains('URL')) {
        errorMessage =
            'Şarkı linki geçerli bir URL olmalı (YouTube, Spotify vs.)';
      } else if (errorStr.contains('Validation error')) {
        errorMessage = 'Form bilgileri eksik veya hatalı. Lütfen kontrol edin.';
      } else if (errorStr.contains('timeout') || errorStr.contains('network')) {
        errorMessage = 'İnternet bağlantısı sorunu. Lütfen tekrar deneyin.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
