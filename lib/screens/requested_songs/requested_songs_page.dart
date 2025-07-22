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
    _tabController.addListener(_onTabChanged);
    _loadSongRequests();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      final statuses = ['all', 'pending', 'approved', 'rejected', 'completed'];
      _selectedStatus = statuses[_tabController.index];
      _currentPage = 0;
      _hasMore = true;
      _songRequests.clear();
      _loadSongRequests();
    }
  }

  Future<void> _loadSongRequests({bool loadMore = false}) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final requests = await _songRequestService.getUserSongRequests(
        context,
        status: _selectedStatus == 'all' ? null : _selectedStatus,
        limit: _limit,
        offset: loadMore ? _currentPage * _limit : 0,
      );

      if (requests != null) {
        setState(() {
          if (loadMore) {
            _songRequests.addAll(requests);
          } else {
            _songRequests = requests;
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
            content: Text('Failed to load song requests: $e'),
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
      backgroundColor: isDarkMode ? const Color(0xFF0F172A) : Colors.grey[50],
      appBar: _buildAppBar(isDarkMode),
      body: Column(
        children: [
          _buildTabBar(isDarkMode),
          Expanded(
            child: _buildTabBarView(isDarkMode),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(isDarkMode),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDarkMode) => AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        title: Text(
          'my_song_requests'.tr(),
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            onPressed: _refreshRequests,
          ),
        ],
      );

  Widget _buildTabBar(bool isDarkMode) => DecoratedBox(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
            ),
          ),
        ),
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicator: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDarkMode
                    ? const Color(0xFF6366F1)
                    : const Color(0xFF4F46E5),
                width: 3,
              ),
            ),
          ),
          labelColor:
              isDarkMode ? const Color(0xFF6366F1) : const Color(0xFF4F46E5),
          unselectedLabelColor:
              isDarkMode ? Colors.grey[400] : Colors.grey[600],
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
        children: List.generate(5, (index) => _buildRequestsList(isDarkMode)),
      );

  Widget _buildRequestsList(bool isDarkMode) {
    if (_isLoading && _songRequests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_songRequests.isEmpty) {
      return _buildEmptyState(isDarkMode);
    }

    return RefreshIndicator(
      onRefresh: _refreshRequests,
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
          padding: const EdgeInsets.all(16),
          itemCount: _songRequests.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _songRequests.length) {
              return _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
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
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
          ),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black26
                  : Colors.grey.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        Text(
                          'by ${request.artistName}',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildStatusChip(request.status, isDarkMode),
                ],
              ),
              if (request.albumName != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.album_rounded,
                      size: 16,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      request.albumName!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
              if (request.genre != null || request.releaseYear != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (request.genre != null) ...[
                      Icon(
                        Icons.music_note_rounded,
                        size: 16,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        request.genre!,
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                    if (request.genre != null && request.releaseYear != null)
                      Text(
                        ' • ',
                        style: TextStyle(
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    if (request.releaseYear != null)
                      Text(
                        '${request.releaseYear}',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ],
              if (request.description != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        isDarkMode ? const Color(0xFF0F172A) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    request.description!,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildPriorityChip(request.priority, isDarkMode),
                      if (request.songLink != null) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.link_rounded,
                          size: 16,
                          color:
                              isDarkMode ? Colors.blue[400] : Colors.blue[600],
                        ),
                      ],
                    ],
                  ),
                  if (request.createdAt != null)
                    Text(
                      DateFormat('dd MMM yyyy').format(request.createdAt!),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                      ),
                    ),
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
            status.toUpperCase(),
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
        priority.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.queue_music_rounded,
              size: 64,
              color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'no_requests_found'.tr(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedStatus == 'all'
                  ? 'no_requests_desc'.tr()
                  : 'no_filtered_requests_desc'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      );

  Widget _buildFAB(bool isDarkMode) => FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/song-request'),
        backgroundColor:
            isDarkMode ? const Color(0xFF6366F1) : const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'new_request'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      );
}
