import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/data/models/user_profile.dart';

class OpdParticipantPicker extends StatelessWidget {
  const OpdParticipantPicker({
    super.key,
    required this.opds,
    required this.selectedIds,
    required this.onChanged,
    this.enabled = true,
  });

  final List<OpdProfile> opds;
  final Set<int> selectedIds;
  final ValueChanged<Set<int>> onChanged;
  final bool enabled;

  Future<void> _open(BuildContext context) async {
    final result = await showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.neoBase,
      builder: (_) => _OpdSelectionSheet(opds: opds, initialIds: selectedIds),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final names = selectedIds.map((id) {
      for (final opd in opds) {
        if (opd.id == id) return opd.name;
      }
      return 'OPD $id';
    }).toList();
    final preview = names.take(2).join(', ');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('OPD peserta', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 4),
      Text('Pilih satu atau beberapa OPD yang diundang.',
          style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: enabled ? () => _open(context) : null,
          icon: const Icon(Icons.groups_outlined),
          label: Text(selectedIds.isEmpty
              ? 'Pilih OPD peserta'
              : 'Ubah pilihan OPD (${selectedIds.length})'),
        ),
      ),
      if (names.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            names.length > 2
                ? '$preview, +${names.length - 2} lainnya'
                : preview,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
    ]);
  }
}

class _OpdSelectionSheet extends StatefulWidget {
  const _OpdSelectionSheet({required this.opds, required this.initialIds});
  final List<OpdProfile> opds;
  final Set<int> initialIds;

  @override
  State<_OpdSelectionSheet> createState() => _OpdSelectionSheetState();
}

class _OpdSelectionSheetState extends State<_OpdSelectionSheet> {
  late final Set<int> draft = {...widget.initialIds};
  String query = '';

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final availableHeight = MediaQuery.sizeOf(context).height - keyboard;
    final opds = widget.opds
        .where((opd) => opd.isActive || draft.contains(opd.id))
        .toList()
      ..sort((a, b) {
        final selectedOrder =
            (draft.contains(b.id) ? 1 : 0) - (draft.contains(a.id) ? 1 : 0);
        return selectedOrder != 0 ? selectedOrder : a.name.compareTo(b.name);
      });
    final matches = opds
        .where((opd) =>
            opd.name.toLowerCase().contains(query.toLowerCase()) ||
            opd.code.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SizedBox(
        height: availableHeight * 0.82,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Pilih OPD peserta',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                  '${draft.length} dipilih · ${widget.opds.length} OPD tersedia',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 14),
              TextField(
                autofocus: false,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                    labelText: 'Cari nama atau kode OPD',
                    prefixIcon: Icon(Icons.search)),
                onChanged: (value) => setState(() => query = value.trim()),
              ),
            ]),
          ),
          Expanded(
            child: matches.isEmpty
                ? const Center(
                    child: Text('OPD tidak ditemukan. Coba kata kunci lain.'))
                : ListView.builder(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      final opd = matches[index];
                      return CheckboxListTile(
                        value: draft.contains(opd.id),
                        title: Text(opd.name,
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle:
                            opd.isActive ? null : const Text('Tidak aktif'),
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (value) => setState(() {
                          value == true
                              ? draft.add(opd.id)
                              : draft.remove(opd.id);
                        }),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(children: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal')),
                const Spacer(),
                FilledButton(
                    onPressed: () => Navigator.pop(context, draft),
                    child: Text('Simpan (${draft.length})')),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
