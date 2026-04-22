class ChannelModel {
  const ChannelModel({
    required this.id,
    required this.username,
    required this.avatarUrl,
    required this.isFollowed,
  });

  final String id;
  final String username;
  final String avatarUrl;
  final bool isFollowed;

  ChannelModel copyWith({
    String? id,
    String? username,
    String? avatarUrl,
    bool? isFollowed,
  }) {
    return ChannelModel(
      id: id ?? this.id,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isFollowed: isFollowed ?? this.isFollowed,
    );
  }
}