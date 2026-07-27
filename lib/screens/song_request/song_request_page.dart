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
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B)
                                .withValues(alpha: isDarkMode ? 0.14 : 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFF59E0B)
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                color: Color(0xFFF59E0B),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'request_api_unavailable'.tr(),
                                  style: TextStyle(
                                    color: textColor.withValues(alpha: 0.72),
                                    fontSize: 12,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
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

  Future<void> _submitRequest() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);

    final request = SongRequestModel(
      songTitle: _songController.text,
      artist: _artistController.text,
      notes: _urlController.text.trim().isEmpty
          ? null
          : 'Source link: ${_urlController.text.trim()}',
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
}

class _RequestField extends StatelessWidget {
  const _RequestField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.isDarkMode,
    this.validator,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isDarkMode;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
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
