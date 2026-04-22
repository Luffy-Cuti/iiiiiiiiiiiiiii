import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/bloc/login_bloc.dart';
import '../../auth/services/auth_local_storage.dart';
import '../../auth/view/login_page.dart';

import '../../upload/bloc/upload_bloc.dart';
import '../bloc/video_bloc.dart';
import '../bloc/video_event.dart';
import '../bloc/video_state.dart';
import '../widgets/video_player_widget.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  int _bottomIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<VideoBloc>().add(const FetchVideos());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    setState(() => _bottomIndex = index);
    if (index == 2) {
      context.read<UploadBloc>().add(const StartUpload());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đang upload video...')),
      );
    }
  }
  Future<void> _handleSignOut() async {
    await AuthLocalStorage.clearLoginStatus();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => LoginPage(bloc: LoginBloc())),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildBodyByTab(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }
  Widget _buildBodyByTab() {
    if (_bottomIndex == 4) {
      return ProfileScreen(onSignOut: _handleSignOut);
    }

    if (_bottomIndex == 1) {
      return const _SimpleTabPage(title: 'Search video, channel');
    }

    if (_bottomIndex == 2) {
      return const _SimpleTabPage(title: 'Upload đang chạy nền...');
    }

    if (_bottomIndex == 3) {
      return const _SimpleTabPage(title: 'Danh sách theo category');
    }

    return Stack(
      children: [
        BlocBuilder<VideoBloc, VideoState>(
          builder: (context, state) {
            if (state is VideoLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is VideoError) {
              return Center(child: Text(state.message));
            }
            if (state is! VideoLoaded) return const SizedBox.shrink();

            return PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: state.videos.length,
              itemBuilder: (context, index) {
                final video = state.videos[index];
                return VideoPlayerWidget(
                  key: ValueKey(video.id),
                  video: video,
                  onLike: () => context.read<VideoBloc>().add(LikeVideo(video.id)),
                  onFollow: () =>
                      context.read<VideoBloc>().add(FollowChannel(video.channel.id)),
                );
              },
            );
          },
        ),
        _buildTopBar(),
      ],
    );
  }


  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Spacer(),
            Row(
              children: const [
                Text('Following', style: TextStyle(color: Colors.white70)),
                SizedBox(width: 16),
                Text(
                  'For You',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.search, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return BottomNavigationBar(
      currentIndex: _bottomIndex,
      onTap: _onNavTap,
      backgroundColor: Colors.black,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      type: BottomNavigationBarType.fixed,
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        const BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(
          icon: Container(
            width: 34,
            height: 26,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.redAccent, width: 1.4),
              gradient: const LinearGradient(
                colors: [Colors.cyan, Colors.redAccent],
              ),
            ),
            child: const Icon(Icons.add, color: Colors.white),
          ),
          label: 'Upload',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.category_outlined),
          label: 'Category',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
class _SimpleTabPage extends StatelessWidget {
  const _SimpleTabPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }
}