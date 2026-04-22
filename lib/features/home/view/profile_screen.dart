import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({required this.onSignOut, super.key});

  final Future<void> Function() onSignOut;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  static const Color _bg = Color(0xFF000000);
  static const Color _text = Color(0xFFFFFFFF);
  static const Color _subText = Color(0xFF888888);
  static const Color _accent = Color(0xFFFE2C55);

  final String username = '@creator.name';
  final String displayName = 'Creator Name';
  final String bio = 'Content creator ✨ | Daily videos | Business: email@gmail.com';
  final String following = '512';
  final String followers = '2.3M';
  final String likes = '45.6M';
  final int videoCount = 30;

  late final TabController _tabController;
  bool isFollowing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _copyUsername() async {
    await Clipboard.setData(ClipboardData(text: username));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã copy username')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = width * 0.04;

    return SafeArea(
      child: Scaffold(
        backgroundColor: _bg,
        body: DefaultTabController(
          length: 3,
          child: NestedScrollView(
            physics: const BouncingScrollPhysics(),
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.person_add_outlined, color: _text),
                  ),
                  centerTitle: true,
                  title: GestureDetector(
                    onTap: _copyUsername,
                    child: Text(
                      username,
                      style: const TextStyle(
                        color: _text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  actions: const [
                    Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.more_horiz, color: _text),
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        _buildAvatar(),
                        const SizedBox(height: 12),
                        Text(
                          displayName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _text,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          bio,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _subText,
                            fontSize: 14,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildStats(),
                        const SizedBox(height: 16),
                        _buildActionButtons(width),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: OutlinedButton.icon(
                            onPressed: () => widget.onSignOut(),
                            icon: const Icon(Icons.logout, color: _text, size: 18),
                            label: const Text(
                              'Sign out',
                              style: TextStyle(color: _text),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: _text),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(
                    TabBar(
                      controller: _tabController,
                      indicator: const UnderlineTabIndicator(
                        borderSide: BorderSide(color: _text, width: 2),
                      ),
                      labelColor: _text,
                      unselectedLabelColor: _subText,
                      tabs: const [
                        Tab(icon: Icon(Icons.grid_on)),
                        Tab(icon: Icon(Icons.favorite_border)),
                        Tab(icon: Icon(Icons.repeat)),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildVideoGrid(),
                const Center(
                  child: Text('No liked videos', style: TextStyle(color: _subText)),
                ),
                const Center(
                  child: Text('No reposted videos', style: TextStyle(color: _subText)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        InkWell(
          customBorder: const CircleBorder(),
          onTap: () {},
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _text, width: 2),
              gradient: const LinearGradient(
                colors: [Color(0xFF1F1F1F), Color(0xFF3A3A3A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.person, color: _text, size: 44),
          ),
        ),
        Positioned(
          bottom: -6,
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(color: _accent, shape: BoxShape.circle),
            child: const Icon(Icons.add, size: 16, color: _text),
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(child: _StatItem(value: following, label: 'Following')),
        _divider(),
        Expanded(child: _StatItem(value: followers, label: 'Followers')),
        _divider(),
        Expanded(child: _StatItem(value: likes, label: 'Likes')),
      ],
    );
  }

  Widget _divider() => Container(width: 1, height: 30, color: Colors.white24);

  Widget _buildActionButtons(double screenWidth) {
    if (!isFollowing) {
      return SizedBox(
        width: screenWidth - 32,
        height: 44,
        child: AnimatedScale(
          scale: isFollowing ? 0.97 : 1,
          duration: const Duration(milliseconds: 180),
          child: ElevatedButton(
            onPressed: () => setState(() => isFollowing = true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: _text,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'FOLLOW',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: _outlineButton(
            label: 'Following',
            onTap: () => setState(() => isFollowing = false),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 4,
          child: _outlineButton(label: 'Message', onTap: () {}),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 44,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _text),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Icon(Icons.keyboard_arrow_down, color: _text),
            ),
          ),
        ),
      ],
    );
  }

  Widget _outlineButton({required String label, required VoidCallback onTap}) {
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _text),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(label, style: const TextStyle(color: _text)),
      ),
    );
  }

  Widget _buildVideoGrid() {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(0),
      itemCount: videoCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
        childAspectRatio: 9 / 16,
      ),
      itemBuilder: (context, index) {
        final isLive = index % 5 == 0;
        return InkWell(
          onTap: () {},
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.lerp(const Color(0xFF2B2B2B), const Color(0xFF707070), (index % 9) / 9)!,
                      Color.lerp(const Color(0xFF101010), const Color(0xFF303030), (index % 7) / 7)!,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Positioned(
                left: 6,
                bottom: 6,
                child: Row(
                  children: const [
                    Icon(Icons.play_arrow, color: _text, size: 14),
                    SizedBox(width: 2),
                    Text(
                      '1.2M',
                      style: TextStyle(
                        color: _text,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (isLive)
                Positioned(
                  left: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    color: _accent,
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: _text,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
      ],
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context,
      double shrinkOffset,
      bool overlapsContent,
      ) {
    return Container(color: const Color(0xFF000000), child: tabBar);
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) {
    return oldDelegate.tabBar != tabBar;
  }
}