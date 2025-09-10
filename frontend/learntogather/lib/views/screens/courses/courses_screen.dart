// views/screens/courses/courses_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/course_controller.dart';
import '../../../models/course_model.dart';
import '../../widgets/course_card.dart';
import '../../widgets/category_chip.dart';
import 'course_detail_screen.dart';
import '../../../../app_theme.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({Key? key}) : super(key: key);

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final _searchController = TextEditingController();
  int? _selectedCategoryId;
  String _sortBy = 'newest'; // newest, popular, rating
  bool _showGrid = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final courseController = Provider.of<CourseController>(context, listen: false);
    courseController.loadCourses(
      search: _searchController.text.isEmpty ? null : _searchController.text,
      categoryId: _selectedCategoryId,
    );
  }

  void _filterByCategory(int? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });
    _performSearch();
  }

  List<CourseModel> _getSortedCourses(List<CourseModel> courses) {
    switch (_sortBy) {
      case 'popular':
        return courses..sort((a, b) => b.totalEnrollments.compareTo(a.totalEnrollments));
      case 'rating':
        return courses..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
      case 'newest':
      default:
        return courses;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CourseController>(
      builder: (context, courseController, child) {
        final sortedCourses = _getSortedCourses([...courseController.courses]);

        return CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              title: const Text('All Courses'),
              floating: true,
              backgroundColor: AppColors.primaryGreen,
              actions: [
                IconButton(
                  onPressed: _showFilterOptions,
                  icon: const Icon(Icons.filter_list),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showGrid = !_showGrid;
                    });
                  },
                  icon: Icon(_showGrid ? Icons.view_list : Icons.grid_view),
                ),
              ],
            ),

            // Search Bar
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search courses, instructors...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              _performSearch();
                              setState(() {});
                            },
                            icon: Icon(Icons.clear, color: Colors.grey[600]),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  onChanged: (value) {
                    setState(() {});
                    _performSearch();
                  },
                ),
              ),
            ),

            // Active Filters
            if (_selectedCategoryId != null || _searchController.text.isNotEmpty)
              SliverToBoxAdapter(
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      if (_selectedCategoryId != null) ...[
                        _buildFilterChip(
                          label: courseController.categories
                              .firstWhere((cat) => cat.id == _selectedCategoryId)
                              .name,
                          onRemove: () => _filterByCategory(null),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (_searchController.text.isNotEmpty) ...[
                        _buildFilterChip(
                          label: 'Search: "${_searchController.text}"',
                          onRemove: () {
                            _searchController.clear();
                            _performSearch();
                            setState(() {});
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            // Categories
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          'Categories',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Sort: ${_sortBy}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: courseController.categories.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          // "All" category
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: GestureDetector(
                              onTap: () => _filterByCategory(null),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: _selectedCategoryId == null
                                      ? AppColors.primaryGreen
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: _selectedCategoryId == null
                                        ? AppColors.primaryGreen
                                        : Colors.grey[300]!,
                                  ),
                                ),
                                child: Text(
                                  'All',
                                  style: TextStyle(
                                    color: _selectedCategoryId == null 
                                        ? Colors.white 
                                        : Colors.grey[700],
                                    fontWeight: _selectedCategoryId == null 
                                        ? FontWeight.w600 
                                        : FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                        
                        final category = courseController.categories[index - 1];
                        final isSelected = _selectedCategoryId == category.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () => _filterByCategory(
                              isSelected ? null : category.id,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryGreen
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryGreen
                                      : Colors.grey[300]!,
                                ),
                              ),
                              child: Text(
                                category.name,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey[700],
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Loading state
            if (courseController.isLoading)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(color: AppColors.primaryGreen),
                  ),
                ),
              )
            // Empty state
            else if (sortedCourses.isEmpty)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No courses found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your search or filter criteria',
                          style: TextStyle(color: Colors.grey[500]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            // Courses Grid/List
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: _showGrid
                    ? SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final course = sortedCourses[index];
                            return CourseCard(
                              course: course,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CourseDetailScreen(course: course),
                                  ),
                                );
                              },
                            );
                          },
                          childCount: sortedCourses.length,
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final course = sortedCourses[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: CourseCard(
                                course: course,
                                isHorizontal: true,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CourseDetailScreen(course: course),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                          childCount: sortedCourses.length,
                        ),
                      ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip({required String label, required VoidCallback onRemove}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              color: Colors.white,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Text(
                      'Sort & Filter',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sort by',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      _buildSortOption('Newest First', 'newest'),
                      _buildSortOption('Most Popular', 'popular'),
                      _buildSortOption('Highest Rated', 'rating'),
                      
                      const SizedBox(height: 20),
                      
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedCategoryId = null;
                                  _sortBy = 'newest';
                                });
                                _searchController.clear();
                                _performSearch();
                                Navigator.pop(context);
                              },
                              child: const Text('Clear All'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _performSearch();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
                              ),
                              child: const Text('Apply'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortOption(String title, String value) {
    return RadioListTile<String>(
      title: Text(title),
      value: value,
      groupValue: _sortBy,
      activeColor: AppColors.primaryGreen,
      onChanged: (String? value) {
        setState(() {
          _sortBy = value!;
        });
      },
    );
  }
}