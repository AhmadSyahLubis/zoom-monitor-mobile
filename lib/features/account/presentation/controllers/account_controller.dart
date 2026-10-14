import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../data/account_repository.dart';
import '../../data/models/zoom_account.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(ref.watch(dioClientProvider));
});

final accountsListProvider = FutureProvider<List<ZoomAccount>>((ref) async {
  final repo = ref.watch(accountRepositoryProvider);
  return repo.listAccounts();
});

class AccountFormState {
  final bool isLoading;
  final String? errorMessage;
  final CheckConnectionResponse? connectionResult;

  AccountFormState({
    this.isLoading = false,
    this.errorMessage,
    this.connectionResult,
  });

  AccountFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    CheckConnectionResponse? connectionResult,
    bool clearError = false,
  }) {
    return AccountFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      connectionResult: connectionResult ?? this.connectionResult,
    );
  }
}

class AccountController extends StateNotifier<AccountFormState> {
  final AccountRepository _repository;
  final Ref _ref;

  AccountController(this._repository, this._ref) : super(AccountFormState());

  Future<bool> createAccount(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final success = await _repository.createAccount(data);
      state = state.copyWith(isLoading: false);
      _ref.invalidate(accountsListProvider);
      _ref.read(dashboardAccountsProvider.notifier).loadDashboard(forceRefresh: true);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateAccount(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final success = await _repository.updateAccount(id, data);
      state = state.copyWith(isLoading: false);
      _ref.invalidate(accountsListProvider);
      _ref.read(dashboardAccountsProvider.notifier).loadDashboard(forceRefresh: true);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteAccount(int id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final success = await _repository.deleteAccount(id);
      state = state.copyWith(isLoading: false);
      _ref.invalidate(accountsListProvider);
      _ref.read(dashboardAccountsProvider.notifier).loadDashboard(forceRefresh: true);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<CheckConnectionResponse> checkConnection(int id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.checkConnection(id);
      state = state.copyWith(isLoading: false, connectionResult: result);
      return result;
    } catch (e) {
      final fallback = CheckConnectionResponse(
        isConnected: false,
        accountName: '',
        message: e.toString(),
      );
      state = state.copyWith(isLoading: false, connectionResult: fallback);
      return fallback;
    }
  }
}

final accountControllerProvider = StateNotifierProvider<AccountController, AccountFormState>((ref) {
  return AccountController(ref.watch(accountRepositoryProvider), ref);
});
