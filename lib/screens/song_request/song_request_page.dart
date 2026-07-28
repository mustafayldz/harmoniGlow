import 'package:easy_localization/easy_localization.dart';
import 'package:drumly/models/song_request_model.dart';
import 'package:drumly/services/song_request_service.dart';
import 'package:flutter/material.dart';

class SongRequestPage extends StatefulWidget {
  const SongRequestPage({super.key});

  @override
  State<SongRequestPage> createState() => _SongRequestPageState();
}

class _SongRequestPageState extends State<SongRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _songController = TextEditingController();
  final _artistController = TextEditingController();
  final _urlController = TextEditingController();
  final _albumController = TextEditingController();
  final _genreController = TextEditingController();
  final _yearController = TextEditingController();
  final _languageController = TextEditingController();
  final _descriptionController = TextEditingController();
  final SongRequestService _service = SongRequestService();
  bool _didPrefill = false;
  bool _isSubmitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrefill) return;
    _didPrefill = true;
    final argument = ModalRoute.of(context)?.settings.arguments;
    if (argument is String && argument.trim().isNotEmpty) {
      _songController.text = argument.trim();
    }
  }

  @override
  void dispose() {
    _songController.dispose();
    _artistController.dispose();
    _urlController.dispose();
    _albumController.dispose();
    _genreController.dispose();
    _yearController.dispose();
    _languageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF111827);
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? const [Color(0xFF0F172A), Color(0xFF1E293B)]
                : const [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                  child: Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'request_song'.tr(),
                        style: TextStyle(
                          color: textColor,
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                sliver: SliverToBoxAdapter(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            ),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.queue_music_rounded,
                                color: Colors.white,
                                size: 34,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  'request_song_desc'.tr(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    height: 1.4,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        _RequestField(
                          controller: _songController,
                          label: 'song_title'.tr(),
                          icon: Icons.music_note_rounded,
                          isDarkMode: isDarkMode,
                          validator: _requiredValidator,
                        ),
                        const SizedBox(height: 14),
                        _RequestField(
                          controller: _artistController,
                          label: 'artist_name'.tr(),
                          icon: Icons.person_rounded,
                          isDarkMode: isDarkMode,
                          validator: _requiredValidator,
                        ),
                        const SizedBox(height: 14),
                        _RequestField(
                          controller: _urlController,
                          label: 'song_url_optional'.tr(),
                          icon: Icons.link_rounded,
                          isDarkMode: isDarkMode,
                          keyboardType: TextInputType.url,
                        ),
                        const SizedBox(height: 14),
                        _RequestField(
                          controller: _albumController,
                          label: 'album_name'.tr(),
                          icon: Icons.album_rounded,
                          isDarkMode: isDarkMode,
                        ),
                        const SizedBox(height: 14),
                        _RequestField(
                          controller: _genreController,
                          label: 'genre'.tr(),
                          icon: Icons.category_rounded,
                          isDarkMode: isDarkMode,
                        ),
                        const SizedBox(height: 14),
                        _RequestField(
                          controller: _yearController,
                          label: 'release_year'.tr(),
                          icon: Icons.calendar_month_rounded,
                          isDarkMode: isDarkMode,
                          keyboardType: TextInputType.number,
                          validator: _yearValidator,
                        ),
                        const SizedBox(height: 14),
                        _RequestField(
                          controller: _languageController,
                          label: 'language'.tr(),
                          icon: Icons.language_rounded,
                          isDarkMode: isDarkMode,
                        ),
                        const SizedBox(height: 14),
                        _RequestField(
                          controller: _descriptionController,
                          label: 'description'.tr(),
                          icon: Icons.notes_rounded,
                          isDarkMode: isDarkMode,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton.icon(
                            onPressed: _isSubmitting ? null : _submitRequest,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: _isSubmitting
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded),
                            label: Text(
                              'request_song'.tr(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
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

  String? _requiredValidator(String? value) =>
      value == null || value.trim().isEmpty ? 'required_fields'.tr() : null;

  String? _yearValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final year = int.tryParse(value.trim());
    if (year == null || year < 1800 || year > 2100) {
      return 'enter_year'.tr();
    }
    return null;
  }

  Future<void> _submitRequest() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);

    final request = SongRequestModel(
      songTitle: _songController.text,
      artistName: _artistController.text,
      songLink: _optionalText(_urlController),
      albumName: _optionalText(_albumController),
      genre: _optionalText(_genreController),
      releaseYear: int.tryParse(_yearController.text.trim()),
      language: _optionalText(_languageController),
      description: _optionalText(_descriptionController),
    );
    final created = await _service.createSongRequest(context, request);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          created == null
              ? 'request_api_unavailable'.tr()
              : 'request_created_success'.tr(),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (created != null) {
      Navigator.pop(context);
    }
  }

  String? _optionalText(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }
}

class _RequestField extends StatelessWidget {
  const _RequestField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.isDarkMode,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isDarkMode;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF6366F1)),
          filled: true,
          fillColor: isDarkMode
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.white.withValues(alpha: 0.78),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: const Color(0xFF6366F1).withValues(alpha: 0.18),
            ),
          ),
        ),
      );
}
