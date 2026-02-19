class StickerAsset {
  const StickerAsset({
    required this.id,
    required this.labelKey,
    required this.assetPath,
    required this.category,
  });

  final String id;
  final String labelKey;
  final String assetPath;
  final StickerCategory category;
}

enum StickerCategory {
  waxSeals,
  tapes,
  stamps,
  florals,
}

const List<StickerAsset> stickerCatalog = [
  StickerAsset(
    id: 'wax_seal_red',
    labelKey: 'sticker_wax_red',
    assetPath: 'assets/stickers/wax_seal_red.svg',
    category: StickerCategory.waxSeals,
  ),
  StickerAsset(
    id: 'wax_seal_blue',
    labelKey: 'sticker_wax_blue',
    assetPath: 'assets/stickers/wax_seal_blue.svg',
    category: StickerCategory.waxSeals,
  ),
  StickerAsset(
    id: 'wax_seal_gold',
    labelKey: 'sticker_wax_gold',
    assetPath: 'assets/stickers/wax_seal_gold.svg',
    category: StickerCategory.waxSeals,
  ),
  StickerAsset(
    id: 'wax_seal_green',
    labelKey: 'sticker_wax_green',
    assetPath: 'assets/stickers/wax_seal_green.svg',
    category: StickerCategory.waxSeals,
  ),
  StickerAsset(
    id: 'wax_seal_black',
    labelKey: 'sticker_wax_black',
    assetPath: 'assets/stickers/wax_seal_black.svg',
    category: StickerCategory.waxSeals,
  ),
  StickerAsset(
    id: 'tape_kraft',
    labelKey: 'sticker_tape_kraft',
    assetPath: 'assets/stickers/tape_kraft.svg',
    category: StickerCategory.tapes,
  ),
  StickerAsset(
    id: 'tape_transparent',
    labelKey: 'sticker_tape_transparent',
    assetPath: 'assets/stickers/tape_transparent.svg',
    category: StickerCategory.tapes,
  ),
  StickerAsset(
    id: 'tape_grid',
    labelKey: 'sticker_tape_grid',
    assetPath: 'assets/stickers/tape_grid.svg',
    category: StickerCategory.tapes,
  ),
  StickerAsset(
    id: 'tape_note',
    labelKey: 'sticker_tape_note',
    assetPath: 'assets/stickers/tape_note.svg',
    category: StickerCategory.tapes,
  ),
  StickerAsset(
    id: 'tape_corner_left',
    labelKey: 'sticker_tape_corner_left',
    assetPath: 'assets/stickers/tape_corner_left.svg',
    category: StickerCategory.tapes,
  ),
  StickerAsset(
    id: 'tape_corner_right',
    labelKey: 'sticker_tape_corner_right',
    assetPath: 'assets/stickers/tape_corner_right.svg',
    category: StickerCategory.tapes,
  ),
  StickerAsset(
    id: 'stamp_rose',
    labelKey: 'sticker_stamp_rose',
    assetPath: 'assets/stickers/post_stamp_rose.svg',
    category: StickerCategory.stamps,
  ),
  StickerAsset(
    id: 'stamp_bird',
    labelKey: 'sticker_stamp_bird',
    assetPath: 'assets/stickers/post_stamp_bird.svg',
    category: StickerCategory.stamps,
  ),
  StickerAsset(
    id: 'stamp_mountain',
    labelKey: 'sticker_stamp_mountain',
    assetPath: 'assets/stickers/post_stamp_mountain.svg',
    category: StickerCategory.stamps,
  ),
  StickerAsset(
    id: 'stamp_train',
    labelKey: 'sticker_stamp_train',
    assetPath: 'assets/stickers/post_stamp_train.svg',
    category: StickerCategory.stamps,
  ),
  StickerAsset(
    id: 'stamp_wave',
    labelKey: 'sticker_stamp_wave',
    assetPath: 'assets/stickers/post_stamp_wave.svg',
    category: StickerCategory.stamps,
  ),
  StickerAsset(
    id: 'floral_lavender',
    labelKey: 'sticker_floral_lavender',
    assetPath: 'assets/stickers/pressed_flower_lavender.svg',
    category: StickerCategory.florals,
  ),
  StickerAsset(
    id: 'floral_fern',
    labelKey: 'sticker_floral_fern',
    assetPath: 'assets/stickers/pressed_flower_fern.svg',
    category: StickerCategory.florals,
  ),
  StickerAsset(
    id: 'floral_rose',
    labelKey: 'sticker_floral_rose',
    assetPath: 'assets/stickers/pressed_flower_rose.svg',
    category: StickerCategory.florals,
  ),
  StickerAsset(
    id: 'floral_daisy',
    labelKey: 'sticker_floral_daisy',
    assetPath: 'assets/stickers/pressed_flower_daisy.svg',
    category: StickerCategory.florals,
  ),
];
