import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/category_model.dart';
import '../models/video_model.dart';
import '../repository/video_repository.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key, VideoRepository? videoRepository})
      : _videoRepository = videoRepository;

  final VideoRepository? _videoRepository;

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late final VideoRepository _videoRepository;
  late Future<List<CategoryModel>> _categoriesFuture;
  CategoryModel? _selectedCategory;
  Future<List<VideoModel>>? _videosFuture;

  @override
  void initState() {
    super.initState();
    _videoRepository = widget._videoRepository ?? VideoRepository();
    _categoriesFuture = _videoRepository.fetchCategories();
  }

  Future<void> _reloadCategories() async {
    final categoriesFuture = _videoRepository.fetchCategories();
    setState(() {
      _selectedCategory = null;
      _videosFuture = null;
      _categoriesFuture = categoriesFuture;
    });
    await categoriesFuture;
  }

  void _selectCategory(CategoryModel category) {
    setState(() {
      _selectedCategory = category;
      _videosFuture = _videoRepository.fetchVideosByCategory(
        categoryId: category.id,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _reloadCategories,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            FutureBuilder<List<CategoryModel>>(
              future: _categoriesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: _MessageState(
                      message: 'Không thể tải danh mục video.',
                      actionLabel: 'Thử lại',
                      onAction: () => _reloadCategories(),
                    ),
                  );
                }

                final categories = snapshot.data ?? const <CategoryModel>[];
                if (categories.isEmpty) {
                  return SliverFillRemaining(
                    child: _MessageState(
                      message: 'Chưa có danh mục để hiển thị.',
                      actionLabel: 'Tải lại',
                      onAction: () => _reloadCategories(),
                    ),
                  );
                }

                return SliverList.list(
                  children: [
                    _buildCategoryList(categories),
                    _buildSelectedCategoryVideos(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 18, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Chọn danh mục để xem video tương ứng.',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(List<CategoryModel> categories) {
    return SizedBox(
      height: 136,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = category.id == _selectedCategory?.id;
          return _CategoryCard(
            category: category,
            isSelected: selected,
            onTap: () => _selectCategory(category),
          );
        },
      ),
    );
  }

  Widget _buildSelectedCategoryVideos() {
    final selectedCategory = _selectedCategory;
    final videosFuture = _videosFuture;

    if (selectedCategory == null || videosFuture == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Hãy chọn một category ở phía trên.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return FutureBuilder<List<VideoModel>>(
      future: videosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return _MessageState(
            message: 'Không thể tải video của ${selectedCategory.name}.',
            actionLabel: 'Thử lại',
            onAction: () => _selectCategory(selectedCategory),
          );
        }

        final videos = snapshot.data ?? const <VideoModel>[];
        if (videos.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Category ${selectedCategory.name} chưa có video.',
              style: const TextStyle(color: Colors.white70),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selectedCategory.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: videos.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.74,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) =>
                    _VideoTile(video: videos[index]),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final CategoryModel category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 118,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.redAccent : Colors.white12,
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _NetworkThumb(
              imageUrl: category.iconImageUrl,
              width: 42,
              height: 42,
              borderRadius: 12,
              fallbackIcon: Icons.category_outlined,
            ),
            const SizedBox(height: 10),
            Text(
              category.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoTile extends StatelessWidget {
  const _VideoTile({required this.video});

  final VideoModel video;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _NetworkThumb(
              imageUrl: video.thumbnailUrl,
              width: double.infinity,
              height: double.infinity,
              borderRadius: 0,
              fallbackIcon: Icons.play_circle_outline,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              video.description.isEmpty ? 'Video' : video.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkThumb extends StatelessWidget {
  const _NetworkThumb({
    required this.imageUrl,
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.fallbackIcon,
  });

  final String imageUrl;
  final double width;
  final double height;
  final double borderRadius;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      color: Colors.white10,
      child: Icon(fallbackIcon, color: Colors.white54),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: imageUrl.isEmpty
          ? placeholder
          : CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: (_, __) => placeholder,
        errorWidget: (_, __, ___) => placeholder,
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}