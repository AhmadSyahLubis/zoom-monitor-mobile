import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/glass_surface.dart';
import '../../auth/data/models/user_profile.dart';
import '../data/meeting_request.dart';
import '../data/meeting_request_repository.dart';

class OpdAccountsScreen extends ConsumerStatefulWidget {
  const OpdAccountsScreen({super.key});
  @override
  ConsumerState<OpdAccountsScreen> createState() => _OpdAccountsScreenState();
}

class _OpdAccountsScreenState extends ConsumerState<OpdAccountsScreen> {
  late Future<List<OpdAccount>> accounts;
  late Future<List<OpdProfile>> opds;
  String search = '';
  String? error;
  @override
  void initState() {
    super.initState();
    final repo = ref.read(meetingRequestRepositoryProvider);
    accounts = repo.opdAccounts();
    opds = repo.opds();
  }

  void reload() => setState(() {
        accounts = ref
            .read(meetingRequestRepositoryProvider)
            .opdAccounts(search: search);
        error = null;
      });

  Future<void> create(
      List<OpdProfile> directory, List<OpdAccount> existing) async {
    var username = '', password = '';
    int? opdId;
    String? formError;
    final choices = directory
        .where((o) => o.isActive && !existing.any((a) => a.opd?.id == o.id))
        .toList();
    final ok = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, update) => AlertDialog(
                    title: const Text('Buat akun OPD'),
                    content: SingleChildScrollView(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                      DropdownButtonFormField<int>(
                          initialValue: opdId,
                          decoration: const InputDecoration(labelText: 'OPD'),
                          items: choices
                              .map((o) => DropdownMenuItem(
                                  value: o.id,
                                  child: Text(o.name,
                                      overflow: TextOverflow.ellipsis)))
                              .toList(),
                          onChanged: (v) => update(() => opdId = v)),
                      TextField(
                          onChanged: (value) => username = value,
                          decoration:
                              const InputDecoration(labelText: 'Username')),
                      TextField(
                          onChanged: (value) => password = value,
                          obscureText: true,
                          decoration: const InputDecoration(
                              labelText: 'Password awal')),
                      if (formError != null)
                        Text(formError!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
                    ])),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Batal')),
                      FilledButton(
                          onPressed: () {
                            final validUser = RegExp(r'^[A-Za-z0-9._-]{3,64}$')
                                .hasMatch(username.trim());
                            final validPassword = password.trim().isNotEmpty &&
                                password.runes.length >= 10 &&
                                utf8.encode(password).length <= 72;
                            if (opdId == null || !validUser || !validPassword) {
                              update(() => formError =
                                  'Pilih OPD, isi username 3–64 karakter, dan password minimal 10 karakter (maks. 72 byte).');
                              return;
                            }
                            Navigator.pop(context, true);
                          },
                          child: const Text('Buat akun'))
                    ])));
    if (ok == true &&
        opdId != null &&
        username.trim().length >= 3 &&
        password.isNotEmpty) {
      try {
        await ref.read(meetingRequestRepositoryProvider).createOpdAccount({
          'opd_id': opdId,
          'username': username.trim(),
          'password': password
        });
        reload();
      } catch (e) {
        if (mounted) setState(() => error = requestError(e));
      }
    }
  }

  Future<void> edit(OpdAccount account) async {
    var username = account.username, password = '';
    String? formError;
    bool active = account.isActive;
    final ok = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, update) => AlertDialog(
                    title: Text('Edit ${account.opd?.name ?? account.name}'),
                    content: SingleChildScrollView(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                      TextFormField(
                          initialValue: account.username,
                          onChanged: (value) => username = value,
                          decoration:
                              const InputDecoration(labelText: 'Username')),
                      TextField(
                          onChanged: (value) => password = value,
                          obscureText: true,
                          decoration: const InputDecoration(
                              labelText: 'Password baru (opsional)')),
                      SwitchListTile(
                          title: const Text('Aktif'),
                          value: active,
                          onChanged: (v) => update(() => active = v)),
                      const Text(
                          'Perubahan login atau status mencabut sesi dan pendaftaran biometrik lama.'),
                      if (formError != null)
                        Text(formError!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
                    ])),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Batal')),
                      FilledButton(
                          onPressed: () {
                            final validUser = RegExp(r'^[A-Za-z0-9._-]{3,64}$')
                                .hasMatch(username.trim());
                            final validPassword = password.isEmpty ||
                                (password.trim().isNotEmpty &&
                                    password.runes.length >= 10 &&
                                    utf8.encode(password).length <= 72);
                            if (!validUser || !validPassword) {
                              update(() => formError =
                                  'Username 3–64 karakter; password baru minimal 10 karakter dan maksimal 72 byte.');
                              return;
                            }
                            Navigator.pop(context, true);
                          },
                          child: const Text('Simpan'))
                    ])));
    if (ok == true) {
      try {
        await ref
            .read(meetingRequestRepositoryProvider)
            .updateOpdAccount(account.id, {
          'username': username.trim(),
          'is_active': active,
          if (password.isNotEmpty) 'password': password
        });
        reload();
      } catch (e) {
        if (mounted) setState(() => error = requestError(e));
      }
    }
  }

  Future<void> remove(OpdAccount account) async {
    final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Hapus akun OPD?'),
                content: Text(
                    '${account.username} tidak dapat login lagi. Riwayat rapat tetap tersimpan.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Hapus akun'))
                ]));
    if (ok == true) {
      try {
        await ref
            .read(meetingRequestRepositoryProvider)
            .deleteOpdAccount(account.id);
        reload();
      } catch (e) {
        if (mounted) setState(() => error = requestError(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
            flexibleSpace: const GlassAppBarBackground(),
            title: const Text('Akun OPD')),
        body: FutureBuilder<List<OpdAccount>>(
            future: accounts,
            builder: (context, snapshot) =>
                ListView(padding: const EdgeInsets.all(16), children: [
                  TextField(
                      decoration: const InputDecoration(
                          labelText: 'Cari OPD atau username',
                          prefixIcon: Icon(Icons.search)),
                      onSubmitted: (v) {
                        search = v.trim();
                        reload();
                      }),
                  const SizedBox(height: 12),
                  FutureBuilder<List<OpdProfile>>(
                      future: opds,
                      builder: (context, directory) => FilledButton.icon(
                          onPressed: snapshot.hasData && directory.hasData
                              ? () => create(directory.data!, snapshot.data!)
                              : null,
                          icon: const Icon(Icons.person_add_alt_1),
                          label: const Text('Buat akun OPD'))),
                  if (error != null)
                    Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(error!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error))),
                  const SizedBox(height: 16),
                  if (!snapshot.hasData)
                    snapshot.hasError
                        ? TextButton(
                            onPressed: reload,
                            child: Text(
                                '${requestError(snapshot.error!)} · Coba lagi'))
                        : const Center(child: CircularProgressIndicator())
                  else if (snapshot.data!.isEmpty)
                    const ContentSurface(child: Text('Belum ada akun OPD.'))
                  else
                    for (final account in snapshot.data!) ...[
                      ContentSurface(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(account.opd?.name ?? 'OPD belum terhubung',
                                style: Theme.of(context).textTheme.titleMedium),
                            Text(
                                '${account.username} · ${account.isActive ? 'Aktif' : 'Nonaktif'}'),
                            if (account.canManage)
                              Wrap(spacing: 8, children: [
                                TextButton(
                                    onPressed: () => edit(account),
                                    child: const Text('Edit')),
                                TextButton(
                                    onPressed: () => remove(account),
                                    child: const Text('Hapus'))
                              ])
                            else
                              const Text('Akun admin dilindungi.'),
                          ])),
                      const SizedBox(height: 10),
                    ],
                ])),
      );
}
