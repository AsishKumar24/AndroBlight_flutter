import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_styling_tokens.dart';
import '../core/theme.dart';
import '../core/responsive.dart';
import '../providers/history_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/scan_card.dart';

/// History Screen - Past scans list with search, filter chips, sort, and cloud sync.
/// Implements task 3.5.

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _syncAnimController;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _syncAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().loadHistory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _syncAnimController.dispose();
    super.dispose();
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceLight,
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear all scan history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.malwareRed,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<HistoryProvider>().clearHistory();
    }
  }

  Future<void> _syncWithCloud() async {
    _syncAnimController.repeat();
    await context.read<HistoryProvider>().syncWithCloud();
    _syncAnimController.stop();
    _syncAnimController.reset();

    if (!mounted) return;
    final provider = context.read<HistoryProvider>();
    if (provider.syncMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                provider.syncSuccess == true
                    ? Icons.cloud_done_rounded
                    : Icons.cloud_off_rounded,
                color: provider.syncSuccess == true
                    ? AppTheme.benignGreen
                    : AppTheme.malwareRed,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(provider.syncMessage!)),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.surfaceLight,
          duration: const Duration(seconds: 3),
        ),
      );
      provider.clearSyncMessage();
    }
  }

  void _showSortSheet() {
    final provider = context.read<HistoryProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.textMuted.withAlpha(100),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Sort By',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSortOption(
                  context: ctx,
                  title: 'Newest First',
                  icon: Icons.arrow_downward_rounded,
                  order: HistorySortOrder.newest,
                  currentOrder: provider.sortOrder,
                ),
                _buildSortOption(
                  context: ctx,
                  title: 'Oldest First',
                  icon: Icons.arrow_upward_rounded,
                  order: HistorySortOrder.oldest,
                  currentOrder: provider.sortOrder,
                ),
                _buildSortOption(
                  context: ctx,
                  title: 'Highest Risk',
                  icon: Icons.warning_amber_rounded,
                  order: HistorySortOrder.highestRisk,
                  currentOrder: provider.sortOrder,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortOption({
    required BuildContext context,
    required String title,
    required IconData icon,
    required HistorySortOrder order,
    required HistorySortOrder currentOrder,
  }) {
    final isSelected = order == currentOrder;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppTheme.brand : AppTheme.textMuted,
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppTheme.brand : AppTheme.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_rounded, color: AppTheme.brand, size: 20)
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        this.context.read<HistoryProvider>().setSortOrder(order);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final isAuthenticated =
        context.watch<AuthProvider>().state == AuthState.authenticated;

    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.pageBackground,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: _showSearch
            ? _buildSearchField(r)
            : Text(
                'Scan history',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: r.sp(18),
                  letterSpacing: -0.3,
                ),
              ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (_showSearch) {
              setState(() {
                _showSearch = false;
                _searchController.clear();
                context.read<HistoryProvider>().setSearchQuery('');
              });
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          // Search toggle
          IconButton(
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  context.read<HistoryProvider>().setSearchQuery('');
                }
              });
            },
            icon: Icon(_showSearch ? Icons.close : Icons.search_rounded),
            tooltip: _showSearch ? 'Close Search' : 'Search',
          ),
          // Sort button
          IconButton(
            onPressed: _showSortSheet,
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort',
          ),
          // Cloud sync (only if authenticated)
          if (isAuthenticated)
            Consumer<HistoryProvider>(
              builder: (context, provider, _) {
                return IconButton(
                  onPressed: provider.isSyncing ? null : _syncWithCloud,
                  icon: RotationTransition(
                    turns: _syncAnimController,
                    child: Icon(
                      Icons.cloud_sync_rounded,
                      color: provider.isSyncing
                          ? AppTheme.textMuted
                          : AppTheme.brandDark,
                    ),
                  ),
                  tooltip: 'Sync with Cloud',
                );
              },
            ),
          // Clear history
          Consumer<HistoryProvider>(
            builder: (context, provider, _) {
              if (provider.history.isEmpty) return const SizedBox();
              return IconButton(
                onPressed: _clearHistory,
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Clear History',
              );
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _historyBackground(context),
          Column(
            children: [
              _buildFilterChips(r),
              _buildActiveFiltersBar(r),
              Expanded(
                child: Consumer<HistoryProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.brand,
                        ),
                      );
                    }

                    final items = provider.filteredHistory;

                    if (provider.history.isEmpty) {
                      return _buildEmptyState(r);
                    }

                    if (items.isEmpty) {
                      return _buildNoResultsState(r);
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        provider.refresh();
                        if (isAuthenticated) {
                          await provider.syncWithCloud();
                        }
                      },
                      color: AppTheme.brand,
                      backgroundColor: AppTheme.surfaceLight,
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: r.screenPadding,
                        itemCount: items.length,
                        separatorBuilder: (_, _) =>
                            SizedBox(height: r.spacingSM),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return ScanCard(
                            item: item,
                            responsive: r,
                            onDelete: () async {
                              await provider.deleteItem(item);
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _historyBackground(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF8F7FF),
                AppTheme.primaryLight,
                AppTheme.pageBackground,
              ],
              stops: [0.0, 0.35, 1.0],
            ),
          ),
        ),
        Positioned(
          top: -AppScale.verticalScale(context, 30),
          right: -AppScale.scale(context, 40),
          child: IgnorePointer(
            child: Container(
              width: AppScale.scale(context, 180),
              height: AppScale.scale(context, 180),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.brand.withAlpha(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField(Responsive r) {
    return TextField(
      controller: _searchController,
      autofocus: true,
      style: TextStyle(
        color: AppTheme.textPrimary,
        fontSize: r.sp(15),
      ),
      decoration: InputDecoration(
        hintText: 'Search scans...',
        hintStyle: TextStyle(
          color: AppTheme.textMuted,
          fontSize: r.sp(15),
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        filled: false,
      ),
      onChanged: (value) {
        context.read<HistoryProvider>().setSearchQuery(value);
      },
    );
  }

  Widget _buildFilterChips(Responsive r) {
    return Consumer<HistoryProvider>(
      builder: (context, provider, _) {
        if (provider.history.isEmpty) return const SizedBox();

        return Container(
          padding: EdgeInsets.symmetric(vertical: r.spacingXS),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: r.spacingMD),
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'All',
                  icon: Icons.list_alt_rounded,
                  filter: HistoryFilter.all,
                  currentFilter: provider.selectedFilter,
                  r: r,
                ),
                SizedBox(width: r.spacingXS),
                _buildFilterChip(
                  label: 'Malware',
                  icon: Icons.warning_rounded,
                  filter: HistoryFilter.malware,
                  currentFilter: provider.selectedFilter,
                  r: r,
                  activeColor: AppTheme.malwareRed,
                ),
                SizedBox(width: r.spacingXS),
                _buildFilterChip(
                  label: 'Benign',
                  icon: Icons.check_circle_rounded,
                  filter: HistoryFilter.benign,
                  currentFilter: provider.selectedFilter,
                  r: r,
                  activeColor: AppTheme.benignGreen,
                ),
                SizedBox(width: r.spacingXS),
                _buildFilterChip(
                  label: 'APK',
                  icon: Icons.android_rounded,
                  filter: HistoryFilter.apk,
                  currentFilter: provider.selectedFilter,
                  r: r,
                ),
                SizedBox(width: r.spacingXS),
                _buildFilterChip(
                  label: 'Play Store',
                  icon: Icons.store_rounded,
                  filter: HistoryFilter.playstore,
                  currentFilter: provider.selectedFilter,
                  r: r,
                  activeColor: AppTheme.brandDark,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required HistoryFilter filter,
    required HistoryFilter currentFilter,
    required Responsive r,
    Color? activeColor,
  }) {
    final isSelected = filter == currentFilter;
    final color = isSelected ? (activeColor ?? AppTheme.brand) : AppTheme.textMuted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: r.sp(13), color: color),
            SizedBox(width: r.spacingXS - 1),
            Text(
              label,
              style: TextStyle(
                fontSize: r.sp(12),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.surfaceLight,
        selectedColor: (activeColor ?? AppTheme.brand).withAlpha(30),
        side: BorderSide(
          color: isSelected
              ? (activeColor ?? AppTheme.brand).withAlpha(120)
              : AppTheme.surfaceLight,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        showCheckmark: false,
        padding: EdgeInsets.symmetric(
          horizontal: r.spacingXS,
          vertical: r.spacingXS - 2,
        ),
        onSelected: (_) {
          context.read<HistoryProvider>().setFilter(filter);
        },
      ),
    );
  }

  Widget _buildActiveFiltersBar(Responsive r) {
    return Consumer<HistoryProvider>(
      builder: (context, provider, _) {
        final hasSearch = provider.searchQuery.isNotEmpty;
        final hasFilter = provider.selectedFilter != HistoryFilter.all;
        final hasSort = provider.sortOrder != HistorySortOrder.newest;
        final filteredCount = provider.filteredHistory.length;
        final totalCount = provider.history.length;

        if (!hasSearch && !hasFilter && !hasSort) return const SizedBox();
        if (provider.history.isEmpty) return const SizedBox();

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: r.spacingMD,
            vertical: r.spacingXS,
          ),
          child: Row(
            children: [
              Text(
                '$filteredCount of $totalCount scans',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: r.sp(12),
                ),
              ),
              const Spacer(),
              if (hasSearch || hasFilter || hasSort)
                TextButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    provider.clearFilters();
                    setState(() => _showSearch = false);
                  },
                  icon: Icon(Icons.clear_all_rounded, size: r.sp(16)),
                  label: Text(
                    'Clear Filters',
                    style: TextStyle(fontSize: r.sp(12)),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.brand,
                    padding: EdgeInsets.symmetric(horizontal: r.spacingXS),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(Responsive r) {
    return Center(
      child: Padding(
        padding: r.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: r.adaptive(small: 70.0, medium: 80.0),
              height: r.adaptive(small: 70.0, medium: 80.0),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history,
                size: r.adaptive(small: 35.0, medium: 40.0),
                color: AppTheme.textMuted,
              ),
            ),
            SizedBox(height: r.spacingMD),
            Text(
              'No scan history',
              style: TextStyle(
                fontSize: r.sp(16),
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            SizedBox(height: r.spacingXS),
            Text(
              'Your scanned files will appear here',
              style: TextStyle(
                fontSize: r.sp(13),
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(Responsive r) {
    return Center(
      child: Padding(
        padding: r.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: r.adaptive(small: 70.0, medium: 80.0),
              height: r.adaptive(small: 70.0, medium: 80.0),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: r.adaptive(small: 35.0, medium: 40.0),
                color: AppTheme.textMuted,
              ),
            ),
            SizedBox(height: r.spacingMD),
            Text(
              'No matching scans',
              style: TextStyle(
                fontSize: r.sp(16),
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            SizedBox(height: r.spacingXS),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(
                fontSize: r.sp(13),
                color: AppTheme.textMuted,
              ),
            ),
            SizedBox(height: r.spacingMD),
            TextButton.icon(
              onPressed: () {
                _searchController.clear();
                context.read<HistoryProvider>().clearFilters();
                setState(() => _showSearch = false);
              },
              icon: const Icon(Icons.clear_all_rounded),
              label: const Text('Clear All Filters'),
            ),
          ],
        ),
      ),
    );
  }
}
