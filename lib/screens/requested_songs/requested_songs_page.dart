import 'package:drumly/models/song_request_model.dart';
import 'package:drumly/services/song_request_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class RequestedSongsPage extends StatefulWidget {
  const RequestedSongsPage({super.key});

  @override
  State<RequestedSongsPage> createState() => _RequestedSongsPageState();
}

class _RequestedSongsPageState extends State<RequestedSongsPage>
    with TickerProviderStateMixin {
  final SongRequestService _songRequestService = SongRequestService();
  List<SongRequestModel> _songRequests = [];
  bool _isLoading = false;
  String _selectedStatus = 'all';
  late TabController _tabController;

  // Pagination
  int _currentPage = 0;
  final int _limit = 20;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    // Tab değişikliklerini dinle
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _onTabChanged();
      }
    });

    // İlk veriyi yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSongRequests();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(() {
      if (!_tabController.indexIsChanging) {
        _onTabChanged();
      }
    });
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    final statuses = ['all', 'pending', 'approved', 'rejected', 'completed'];
    final newStatus = statuses[_tabController.index];

    // Sadece status gerçekten değiştiyse yeni veri yükle
    if (newStatus != _selectedStatus) {
      debugPrint('🔄 Tab changed from $_selectedStatus to $newStatus');

      setState(() {
        _selectedStatus = newStatus;
        _currentPage = 0;
        _hasMore = true;
        _songRequests.clear();
      });

      // Yeni veriyi yükle
      _loadSongRequests();
    }
  }

  Future<void> _loadSongRequests({bool loadMore = false}) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      debugPrint('🎵 Loading song requests with status: $_selectedStatus');

      final requests = await _songRequestService.getUserSongRequests(
        context,
        status: _selectedStatus == 'all' ? null : _selectedStatus,
        limit: _limit,
        offset: loadMore ? _currentPage * _limit : 0,
      );

      debugPrint('🎵 Received ${requests?.length ?? 0} requests from API');

      if (requests != null) {
        // Debug: İlk request'i detaylı log'la
        if (requests.isNotEmpty) {
          final firstRequest = requests.first;
          debugPrint('🔍 First request details:');
          debugPrint('  - songTitle: "${firstRequest.songTitle}"');
          debugPrint('  - artistName: "${firstRequest.artistName}"');
          debugPrint('  - description: "${firstRequest.description}"');
          debugPrint('  - status: "${firstRequest.status}"');
          debugPrint('  - priority: "${firstRequest.priority}"');
          debugPrint('  - requestId: "${firstRequest.requestId}"');
        }

        // Client-side filtering as backup
        List<SongRequestModel> filteredRequests;
        if (_selectedStatus == 'all') {
          filteredRequests = requests;
        } else {
          filteredRequests = requests
              .where(
                (request) =>
                    request.status.toLowerCase() ==
                    _selectedStatus.toLowerCase(),
              )
              .toList();
        }

        setState(() {
          if (loadMore) {
            _songRequests.addAll(filteredRequests);
          } else {
            _songRequests = filteredRequests;
          }
          _hasMore = requests.length >= _limit;
          if (loadMore) _currentPage++;
        });
      }
    } catch (e) {
      debugPrint('Error loading song requests: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'error_loading_requests'.tr()}\n$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshRequests() async {
    _currentPage = 0;
    _hasMore = true;
    await _loadSongRequests();
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
                    const Color(0xFF0F172A), // Dark slate
                    const Color(0xFF1E293B), // Lighter slate
                    const Color(0xFF334155), // Even lighter
                  ]
                : [
                    const Color(0xFFF8FAFC), // Light gray
                    const Color(0xFFE2E8F0), // Slightly darker
                    const Color(0xFFCBD5E1), // Even darker
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Modern Header
              _buildModernHeader(isDarkMode),
              // Tab Bar
              _buildTabBar(isDarkMode),
              // Content
              Expanded(
                child: _buildTabBarView(isDarkMode),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(isDarkMode),
    );
  }

  /// 🎨 Modern Header - Songs style
  Widget _buildModernHeader(bool isDarkMode) => Container(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
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
                'my_song_requests'.tr(),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
            // Refresh Button
            DecoratedBox(
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.refresh_rounded,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                onPressed: _refreshRequests,
                tooltip: 'refresh'.tr(),
              ),
            ),
          ],
        ),
      );

  Widget _buildTabBar(bool isDarkMode) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
          ),
        ),
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start, // Sol tarafa hizala
          padding: EdgeInsets.zero, // Padding'i sıfırla
          labelPadding: const EdgeInsets.symmetric(
            horizontal: 12,
          ), // Tab'lar arası mesafe
          dividerColor: Colors.transparent, // Alt çizgiyi kaldır
          onTap: (index) {
            debugPrint('🎯 Tab tapped: $index');
            // Manuel tab değişimi için
            final statuses = [
              'all',
              'pending',
              'approved',
              'rejected',
              'completed',
            ];
            final newStatus = statuses[index];
            if (newStatus != _selectedStatus) {
              _onTabChanged();
            }
          },
          indicator: BoxDecoration(
            color: isDarkMode
                ? const Color(0xFF6366F1).withValues(alpha: 0.2)
                : const Color(0xFF4F46E5).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.all(4),
          labelColor:
              isDarkMode ? const Color(0xFF6366F1) : const Color(0xFF4F46E5),
          unselectedLabelColor: isDarkMode
              ? Colors.white.withValues(alpha: 0.6)
              : Colors.black.withValues(alpha: 0.6),
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
          tabs: [
            Tab(text: 'all_requests'.tr()),
            Tab(text: 'pending_requests'.tr()),
            Tab(text: 'approved_requests'.tr()),
            Tab(text: 'rejected_requests'.tr()),
            Tab(text: 'completed_requests'.tr()),
          ],
        ),
      );

  Widget _buildTabBarView(bool isDarkMode) => TabBarView(
        controller: _tabController,
        physics:
            const NeverScrollableScrollPhysics(), // Tab değişimini sadece tab tıklamasıyla sınırla
        children: List.generate(5, (index) => _buildRequestsList(isDarkMode)),
      );

  Widget _buildRequestsList(bool isDarkMode) {
    if (_isLoading && _songRequests.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          color: isDarkMode ? const Color(0xFF6366F1) : const Color(0xFF4F46E5),
        ),
      );
    }

    if (_songRequests.isEmpty) {
      return _buildEmptyState(isDarkMode);
    }

    return RefreshIndicator(
      onRefresh: _refreshRequests,
      color: isDarkMode ? const Color(0xFF6366F1) : const Color(0xFF4F46E5),
      child: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (scrollInfo is ScrollEndNotification &&
              scrollInfo.metrics.pixels >=
                  scrollInfo.metrics.maxScrollExtent - 200 &&
              _hasMore &&
              !_isLoading) {
            _loadSongRequests(loadMore: true);
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: _songRequests.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _songRequests.length) {
              return _isLoading
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                          color: isDarkMode
                              ? const Color(0xFF6366F1)
                              : const Color(0xFF4F46E5),
                        ),
                      ),
                    )
                  : const SizedBox.shrink();
            }

            return _buildRequestCard(_songRequests[index], isDarkMode);
          },
        ),
      ),
    );
  }

  Widget _buildRequestCard(SongRequestModel request, bool isDarkMode) =>
      Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [
                    const Color(0xFF1E293B).withValues(alpha: 0.9),
                    const Color(0xFF334155).withValues(alpha: 0.7),
                  ]
                : [
                    Colors.white,
                    const Color(0xFFF8FAFC),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Song info + Status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Music Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDarkMode
                            ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                            : [
                                const Color(0xFF4F46E5),
                                const Color(0xFF7C3AED),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.music_note_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Song details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.songTitle,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.person_rounded,
                              size: 14,
                              color: isDarkMode
                                  ? Colors.white.withValues(alpha: 0.6)
                                  : Colors.black.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                request.artistName,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode
                                      ? Colors.white.withValues(alpha: 0.7)
                                      : Colors.black.withValues(alpha: 0.7),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Status chip
                  _buildStatusChip(request.status, isDarkMode),
                ],
              ),

              const SizedBox(height: 16),

              // Description (if available)
              if (request.description != null &&
                  request.description!.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.description_rounded,
                            size: 14,
                            color: isDarkMode
                                ? Colors.white.withValues(alpha: 0.6)
                                : Colors.black.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'description'.tr(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? Colors.white.withValues(alpha: 0.6)
                                  : Colors.black.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        request.description!,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDarkMode
                              ? Colors.white.withValues(alpha: 0.8)
                              : Colors.black.withValues(alpha: 0.8),
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Additional info row
              Row(
                children: [
                  // Created date
                  if (request.createdAt != null) ...[
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.5)
                          : Colors.black.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd MMM yyyy').format(request.createdAt!),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Priority chip
                  _buildPriorityChip(request.priority, isDarkMode),

                  // Link indicator
                  if (request.songLink != null &&
                      request.songLink!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.blue.withValues(alpha: 0.2)
                            : Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.link_rounded,
                        size: 14,
                        color: isDarkMode ? Colors.blue[300] : Colors.blue[600],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildStatusChip(String status, bool isDarkMode) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'pending':
        bgColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        icon = Icons.pending_rounded;
        break;
      case 'approved':
        bgColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        icon = Icons.check_circle_rounded;
        break;
      case 'rejected':
        bgColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        icon = Icons.cancel_rounded;
        break;
      case 'completed':
        bgColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        icon = Icons.done_all_rounded;
        break;
      default:
        bgColor = Colors.grey[100]!;
        textColor = Colors.grey[800]!;
        icon = Icons.help_rounded;
    }

    if (isDarkMode) {
      bgColor = bgColor.withValues(alpha: 0.2);
      textColor = textColor.withValues(alpha: 0.9);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            'status_${status.toLowerCase()}'.tr().toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityChip(String priority, bool isDarkMode) {
    Color bgColor;
    Color textColor;

    switch (priority.toLowerCase()) {
      case 'high':
        bgColor = isDarkMode ? Colors.red[900]! : Colors.red[100]!;
        textColor = isDarkMode ? Colors.red[300]! : Colors.red[800]!;
        break;
      case 'normal':
        bgColor = isDarkMode ? Colors.blue[900]! : Colors.blue[100]!;
        textColor = isDarkMode ? Colors.blue[300]! : Colors.blue[800]!;
        break;
      case 'low':
        bgColor = isDarkMode ? Colors.grey[800]! : Colors.grey[200]!;
        textColor = isDarkMode ? Colors.grey[400]! : Colors.grey[700]!;
        break;
      default:
        bgColor = isDarkMode ? Colors.grey[800]! : Colors.grey[200]!;
        textColor = isDarkMode ? Colors.grey[400]! : Colors.grey[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'priority_${priority.toLowerCase()}'.tr().toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) => Center(
        child: Container(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      (isDarkMode
                              ? const Color(0xFF6366F1)
                              : const Color(0xFF4F46E5))
                          .withValues(alpha: 0.1),
                      (isDarkMode
                              ? const Color(0xFF8B5CF6)
                              : const Color(0xFF7C3AED))
                          .withValues(alpha: 0.1),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.queue_music_rounded,
                  size: 60,
                  color: isDarkMode
                      ? const Color(0xFF6366F1)
                      : const Color(0xFF4F46E5),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'no_requests_found'.tr(),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _selectedStatus == 'all'
                    ? 'no_requests_description'.tr()
                    : 'no_filtered_requests_description'.tr(),
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  Widget _buildFAB(bool isDarkMode) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isDarkMode ? const Color(0xFF6366F1) : const Color(0xFF4F46E5),
              isDarkMode ? const Color(0xFF8B5CF6) : const Color(0xFF7C3AED),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: (isDarkMode
                      ? const Color(0xFF6366F1)
                      : const Color(0xFF4F46E5))
                  .withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.pushNamed(context, '/song-request'),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          highlightElevation: 0,
          icon: const Icon(Icons.add_rounded, size: 24),
          label: Text(
            'new_request'.tr(),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      );
}
