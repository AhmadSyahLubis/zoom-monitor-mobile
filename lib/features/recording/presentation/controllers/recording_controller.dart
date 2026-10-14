import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/models/recording_item.dart';
import '../../data/recording_repository.dart';

final recordingRepositoryProvider = Provider<RecordingRepository>((ref) {
  return RecordingRepository(ref.watch(dioClientProvider));
});

class RecordingFilter {
  final String? from;
  final String? to;
  final String? search;

  RecordingFilter({this.from, this.to, this.search});

  RecordingFilter copyWith({String? from, String? to, String? search}) {
    return RecordingFilter(
      from: from ?? this.from,
      to: to ?? this.to,
      search: search ?? this.search,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordingFilter &&
          runtimeType == other.runtimeType &&
          from == other.from &&
          to == other.to &&
          search == other.search;

  @override
  int get hashCode => from.hashCode ^ to.hashCode ^ search.hashCode;
}

final recordingFilterProvider = StateProvider<RecordingFilter>((ref) {
  return RecordingFilter();
});

final recordingsListProvider =
    FutureProvider<List<RecordingItem>>((ref) async {
  final repo = ref.watch(recordingRepositoryProvider);
  final filter = ref.watch(recordingFilterProvider);
  return repo.listRecordings(
    from: filter.from,
    to: filter.to,
    search: filter.search,
  );
});
