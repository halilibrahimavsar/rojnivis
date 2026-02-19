import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'sticker_catalog.dart';

Future<StickerAsset?> showStickerPickerSheet(BuildContext context) {
  return showModalBottomSheet<StickerAsset>(
    context: context,
    isScrollControlled: true,
    builder: (context) => const _StickerPickerSheet(),
  );
}

class _StickerPickerSheet extends StatefulWidget {
  const _StickerPickerSheet();

  @override
  State<_StickerPickerSheet> createState() => _StickerPickerSheetState();
}

class _StickerPickerSheetState extends State<_StickerPickerSheet> {
  StickerCategory _selectedCategory = StickerCategory.waxSeals;

  @override
  Widget build(BuildContext context) {
    final stickers = stickerCatalog
        .where((item) => item.category == _selectedCategory)
        .toList(growable: false);
    final maxHeight = MediaQuery.of(context).size.height * 0.68;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: SizedBox(
          height: maxHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'sticker_picker'.tr(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _categoryChip(context, StickerCategory.waxSeals, 'sticker_category_wax'.tr()),
                  _categoryChip(context, StickerCategory.tapes, 'sticker_category_tape'.tr()),
                  _categoryChip(context, StickerCategory.stamps, 'sticker_category_stamp'.tr()),
                  _categoryChip(context, StickerCategory.florals, 'sticker_category_floral'.tr()),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  itemCount: stickers.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final sticker = stickers[index];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.pop(context, sticker),
                        child: Ink(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outlineVariant,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: SvgPicture.asset(sticker.assetPath),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryChip(
    BuildContext context,
    StickerCategory category,
    String label,
  ) {
    return ChoiceChip(
      selected: _selectedCategory == category,
      label: Text(label),
      onSelected: (_) {
        setState(() => _selectedCategory = category);
      },
    );
  }
}
