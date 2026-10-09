import 'package:flutter/material.dart';

import '../../core/services/local_activity_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/community/local_activity_spot.dart';

class LocalActivitySpotsScreen extends StatefulWidget {
  const LocalActivitySpotsScreen({super.key});

  @override
  State<LocalActivitySpotsScreen> createState() =>
      _LocalActivitySpotsScreenState();
}

class _LocalActivitySpotsScreenState extends State<LocalActivitySpotsScreen> {
  final LocalActivityService _service = LocalActivityService.instance;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (!_service.isInitialized) {
      _service.init();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Local Activity Spots'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'About Curated Spots',
            onPressed: () => _showAboutDialog(context),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _service,
        builder: (context, _) {
          final spots = _service.filteredSpots;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Hero Banner
                _buildHeroHeader(),
                const SizedBox(height: 16),

                // 2. Search Field
                _buildSearchBar(),
                const SizedBox(height: 14),

                // 3. Category Filter Chips
                _buildCategoryFilters(),
                const SizedBox(height: 18),

                // 4. Section Count Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_service.selectedCategory.displayName} (${spots.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (_service.favoriteSpotIds.isNotEmpty)
                      Text(
                        '★ ${_service.favoriteSpotIds.length} Saved',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // 5. Spots List or Empty State
                if (spots.isEmpty)
                  _buildEmptyState()
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: spots.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final spot = spots[index];
                      return _buildSpotCard(spot);
                    },
                  ),
                const SizedBox(height: 28),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.place_rounded,
                      size: 13,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'CAMPUS & LOCAL SPOTS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevatedDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.dividerDark),
                ),
                child: const Text(
                  'Offline Directory',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Outdoor Training & Tracks',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimaryDark,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Discover calisthenics rigs, running tracks, and open parks around campus. Distances are curated offline benchmarks for student fitness planning.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondaryDark,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerDark),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 13),
        onChanged: (val) => _service.setSearchQuery(val),
        decoration: InputDecoration(
          hintText: 'Search spots, facilities, or tags...',
          hintStyle: const TextStyle(
            color: AppColors.textSecondaryDark,
            fontSize: 13,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textSecondaryDark,
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  color: AppColors.textSecondaryDark,
                  onPressed: () {
                    _searchController.clear();
                    _service.setSearchQuery('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    const categories = ActivitySpotCategory.values;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = _service.selectedCategory == cat;
          final count = cat == ActivitySpotCategory.all
              ? _service.allSpots.length
              : _service.allSpots.where((s) => s.category == cat).length;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              showCheckmark: false,
              avatar: Icon(
                cat.icon,
                size: 14,
                color: isSelected ? Colors.black : AppColors.textSecondaryDark,
              ),
              label: Text('${cat.displayName} ($count)'),
              labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.black : AppColors.textPrimaryDark,
              ),
              backgroundColor: AppColors.surfaceDark,
              selectedColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.dividerDark,
                ),
              ),
              onSelected: (_) => _service.setCategory(cat),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSpotCard(LocalActivitySpot spot) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: spot.isFavorite
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.dividerDark,
          width: spot.isFavorite ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + Name + Category & Favorite
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.15),
                  border: Border.all(color: AppColors.primary, width: 1.4),
                ),
                child: Center(
                  child: Icon(
                    spot.category.icon,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spot.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryDark,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: AppColors.textSecondaryDark,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            spot.area,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondaryDark,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  spot.isFavorite
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: spot.isFavorite
                      ? AppColors.primary
                      : AppColors.textSecondaryDark,
                  size: 22,
                ),
                tooltip: spot.isFavorite ? 'Remove Favorite' : 'Save Spot',
                onPressed: () => _service.toggleFavorite(spot.id),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Demo Distance & Category Badge Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevatedDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.dividerDark),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.near_me_rounded,
                      size: 11,
                      color: AppColors.brightPurple,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      spot.distanceDemo,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  spot.category.displayName,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Description
          Text(
            spot.shortDescription,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondaryDark,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),

          // Tags Row
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (spot.hasOutdoorGym)
                _buildFeatureTag('Outdoor Gym', Icons.fitness_center_rounded),
              if (spot.hasTrack)
                _buildFeatureTag('Track', Icons.directions_run_rounded),
              if (spot.hasOpenSpace)
                _buildFeatureTag('Open Turf', Icons.park_rounded),
              ...spot.bestForTags.take(2).map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevatedDark,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#$tag',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondaryDark,
                        ),
                      ),
                    ),
                  ),
            ],
          ),
          const SizedBox(height: 14),

          // Footer: Timings & Details Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  spot.timings,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondaryDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _showSpotDetails(context, spot),
                icon: const Icon(Icons.visibility_rounded, size: 14),
                label: const Text(
                  'View Details',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTag(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: AppColors.brightPurple.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: AppColors.brightPurple),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.brightPurple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceDark,
              border: Border.all(color: AppColors.dividerDark),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: AppColors.textSecondaryDark,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No matching activity spots found',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Try adjusting your search terms or selecting a different category filter.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondaryDark,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _searchController.clear();
              _service.setSearchQuery('');
              _service.setCategory(ActivitySpotCategory.all);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surfaceElevatedDark,
              foregroundColor: AppColors.primary,
            ),
            child: const Text('Reset Filters'),
          ),
        ],
      ),
    );
  }

  /// Displays detailed modal bottom sheet with rich equipment, facilities, and safety tips
  void _showSpotDetails(BuildContext context, LocalActivitySpot spot) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.dividerDark,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title & Category Badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              spot.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimaryDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              spot.area,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          spot.category.displayName,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Demo distance banner
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevatedDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.dividerDark),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.near_me_rounded,
                          size: 14,
                          color: AppColors.brightPurple,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Estimated benchmark: ${spot.distanceDemo}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Overview
                  const Text(
                    'About Spot',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    spot.shortDescription,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondaryDark,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Equipment Available (if any)
                  if (spot.equipmentList.isNotEmpty) ...[
                    const Text(
                      'Available Fitness Equipment',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: spot.equipmentList.map((eq) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevatedDark,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.dividerDark),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.fitness_center_rounded,
                                size: 12,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                eq,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimaryDark,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // Key Facilities
                  const Text(
                    'Facilities & Amenities',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: spot.facilities.map((fac) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevatedDark,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.dividerDark),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 13,
                              color: Color(0xFF4CAF50),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              fac,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimaryDark,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // Surface & Timings
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailBox(
                          title: 'Surface Type',
                          value: spot.surfaceType,
                          icon: Icons.layers_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildDetailBox(
                          title: 'Hours',
                          value: spot.timings,
                          icon: Icons.access_time_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Student Safety & Training Tip
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lightbulb_outline_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Student Tip & Advice',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                spot.safetyTip,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textPrimaryDark,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailBox({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryDark,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.place_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'About Activity Spots',
              style: TextStyle(
                color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• Curated offline directory of nearby open gyms, tracks, and student lawns.\n'
              '• Distances are estimated campus benchmarks (no live GPS needed).\n'
              '• Tap the bookmark icon to save your favorite outdoor training spots.\n'
              '• 100% offline, privacy-friendly, and battery saving.',
              style: TextStyle(
                color: AppColors.textSecondaryDark,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
