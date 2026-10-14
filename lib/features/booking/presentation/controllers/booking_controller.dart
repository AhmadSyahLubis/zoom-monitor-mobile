import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/booking_repository.dart';
import '../../data/models/availability_result.dart';
import '../../data/models/booking_request.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(ref.watch(dioClientProvider));
});

class SearchParams {
  final String date;
  final String startTime;
  final int duration;

  SearchParams({
    required this.date,
    required this.startTime,
    required this.duration,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchParams &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          startTime == other.startTime &&
          duration == other.duration;

  @override
  int get hashCode => date.hashCode ^ startTime.hashCode ^ duration.hashCode;
}

final searchAvailabilityProvider =
    FutureProvider.autoDispose.family<List<AvailabilityResult>, SearchParams>((ref, params) async {
  final repo = ref.watch(bookingRepositoryProvider);
  return repo.searchAvailability(
    date: params.date,
    startTime: params.startTime,
    duration: params.duration,
  );
});

class BookingState {
  final bool isLoading;
  final String? errorMessage;
  final BookMeetingResponse? lastSuccess;

  BookingState({
    this.isLoading = false,
    this.errorMessage,
    this.lastSuccess,
  });

  BookingState copyWith({
    bool? isLoading,
    String? errorMessage,
    BookMeetingResponse? lastSuccess,
    bool clearError = false,
  }) {
    return BookingState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastSuccess: lastSuccess ?? this.lastSuccess,
    );
  }
}

class BookingController extends StateNotifier<BookingState> {
  final BookingRepository _repository;

  BookingController(this._repository) : super(BookingState());

  Future<BookMeetingResponse?> bookMeeting(BookMeetingRequest request) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _repository.bookMeeting(request);
      state = state.copyWith(isLoading: false, lastSuccess: res);
      return res;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }
}

final bookingControllerProvider = StateNotifierProvider<BookingController, BookingState>((ref) {
  return BookingController(ref.watch(bookingRepositoryProvider));
});
