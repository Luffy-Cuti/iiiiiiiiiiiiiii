abstract class SearchEvent {
  const SearchEvent();
}

class SearchQueryChanged extends SearchEvent {
  const SearchQueryChanged(this.query);

  final String query;
}

class SearchCleared extends SearchEvent {
  const SearchCleared();
}

class SearchChannelFollowToggled extends SearchEvent {
  const SearchChannelFollowToggled(this.channelId);

  final String channelId;
}