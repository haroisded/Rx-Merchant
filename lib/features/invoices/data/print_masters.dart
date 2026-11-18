import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/singles.dart';
import '../../../core/numbers/format.dart';
import '../../setup/data/setup_queries.dart';

// Letter Head, Print Heading and Terms and Conditions (05-invoices-and-
// receipts INV-R14 to R16).

extension PrintMasters on AppDatabase {
  Value<String> get _now => Value(toStorage(DateTime.now()));

  /// INV-R14: one Letter Head is the Default; saving another as Default
  /// clears the first.
  Future<int> saveLetterHead(LetterHeadCompanion row) => transaction(() async {
    final id = await upsert(letterHead, row.copyWith(modifiedAt: _now), row.id);
    if (row.isDefault.value == 1) {
      await (update(letterHead)..where((h) => h.id.equals(id).not())).write(
        LetterHeadCompanion(isDefault: const Value(0), modifiedAt: _now),
      );
    }
    return id;
  });

  /// INV-R15. A rename follows into POS Settings, which keeps it by name.
  Future<int> savePrintHeading(PrintHeadingCompanion row) =>
      transaction(() async {
        await _followRename(
          'select_print_heading',
          row.id,
          row.name.value,
          () => (select(printHeading)..where((h) => h.id.equals(row.id.value)))
              .map((h) => h.name)
              .getSingleOrNull(),
        );
        return upsert(printHeading, row.copyWith(modifiedAt: _now), row.id);
      });

  /// INV-R16. A rename follows into POS Settings, which keeps it by title.
  Future<int> saveTerms(TermsAndConditionsCompanion row) => transaction(
    () async {
      await _followRename(
        'tc_name',
        row.id,
        row.title.value,
        () =>
            (select(termsAndConditions)
                  ..where((t) => t.id.equals(row.id.value)))
                .map((t) => t.title)
                .getSingleOrNull(),
      );
      return upsert(termsAndConditions, row.copyWith(modifiedAt: _now), row.id);
    },
  );

  Future<void> _followRename(
    String key,
    Value<int> id,
    String name,
    Future<String?> Function() oldName,
  ) async {
    if (!id.present) return;
    final old = await oldName();
    final pos = await readSingle(PosSettings.doctype);
    if (old != null && old != name && pos[key] == old) {
      await writeSingle(PosSettings.doctype, {key: name});
    }
  }
}
