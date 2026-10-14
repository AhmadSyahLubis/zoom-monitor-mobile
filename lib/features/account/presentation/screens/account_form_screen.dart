import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_surface.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../data/models/zoom_account.dart';
import '../controllers/account_controller.dart';

class AccountFormScreen extends ConsumerStatefulWidget {
  final ZoomAccount? initialAccount;

  const AccountFormScreen({super.key, this.initialAccount});

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _accountIdController;
  late final TextEditingController _clientIdController;
  late final TextEditingController _clientSecretController;
  late final TextEditingController _hostKeyController;
  bool _obscureSecret = true;

  bool get _isEdit => widget.initialAccount != null;

  @override
  void initState() {
    super.initState();
    final acc = widget.initialAccount;
    _nameController = TextEditingController(text: acc?.accountName ?? '');
    _emailController = TextEditingController(text: acc?.email ?? '');
    _accountIdController =
        TextEditingController(text: acc?.zoomAccountId ?? '');
    _clientIdController = TextEditingController(text: acc?.clientId ?? '');
    _clientSecretController = TextEditingController(text: '');
    _hostKeyController = TextEditingController(text: acc?.hostKey ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _accountIdController.dispose();
    _clientIdController.dispose();
    _clientSecretController.dispose();
    _hostKeyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final data = <String, dynamic>{
      'account_name': _nameController.text.trim(),
      'email': _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      'zoom_account_id': _accountIdController.text.trim(),
      'client_id': _clientIdController.text.trim(),
      'host_key': _hostKeyController.text.trim().isEmpty
          ? null
          : _hostKeyController.text.trim(),
    };

    if (_clientSecretController.text.isNotEmpty) {
      data['client_secret'] = _clientSecretController.text.trim();
    }

    bool success;
    if (_isEdit) {
      success =
          await ref.read(accountControllerProvider.notifier).updateAccount(
                widget.initialAccount!.id,
                data,
              );
    } else {
      if (_clientSecretController.text.isEmpty) {
        UiFeedback.showError(
            context, 'Client Secret wajib diisi untuk akun baru');
        return;
      }
      success = await ref
          .read(accountControllerProvider.notifier)
          .createAccount(data);
    }

    if (!mounted) return;

    if (success) {
      UiFeedback.showSuccess(
        context,
        _isEdit
            ? 'Akun Zoom berhasil diperbarui'
            : 'Akun Zoom baru berhasil ditambahkan',
      );
      context.pop();
    } else {
      final err = ref.read(accountControllerProvider).errorMessage ??
          'Gagal menyimpan akun';
      UiFeedback.showError(context, err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountControllerProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        flexibleSpace: const GlassAppBarBackground(),
        title: Text(_isEdit ? 'Edit Akun Zoom' : 'Tambah Akun Zoom S2S'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card Informasi Dasar
              ContentSurface(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Informasi Akun',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Akun / Ruangan *',
                        hintText: 'Contoh: Ruang Rapat Direksi',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Nama akun wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email Akun Zoom (Opsional)',
                        hintText: 'zoom-admin@company.com',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _hostKeyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Host Key (Opsional, 6 digit)',
                        hintText: 'Contoh: 123456',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Card Kredensial OAuth S2S
              ContentSurface(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Kredensial Zoom Server-to-Server OAuth',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 6),
                    const Text(
                      'Diperoleh dari Zoom App Marketplace (Server-to-Server OAuth App)',
                      style:
                          TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _accountIdController,
                      decoration: const InputDecoration(
                        labelText: 'Zoom Account ID *',
                        hintText: 'Masukkan Account ID dari Marketplace',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Zoom Account ID wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _clientIdController,
                      decoration: const InputDecoration(
                        labelText: 'Client ID *',
                        hintText: 'Masukkan Client ID',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Client ID wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _clientSecretController,
                      obscureText: _obscureSecret,
                      decoration: InputDecoration(
                        labelText: _isEdit
                            ? 'Client Secret (Kosongkan jika tidak diubah)'
                            : 'Client Secret *',
                        hintText: 'Masukkan Client Secret',
                        suffixIcon: IconButton(
                          icon: Icon(_obscureSecret
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () =>
                              setState(() => _obscureSecret = !_obscureSecret),
                        ),
                      ),
                      validator: (v) {
                        if (!_isEdit && (v == null || v.trim().isEmpty)) {
                          return 'Client Secret wajib diisi';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: state.isLoading ? null : _submit,
                child: state.isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        _isEdit ? 'Simpan Perubahan' : 'Hubungkan Akun Zoom',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
