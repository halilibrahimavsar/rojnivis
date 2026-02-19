enum PageVisualFamily {
  classic,
  vintage,
}

enum VintagePaperVariant {
  parchment,
  sepiaDiary,
  pressedFloral,
}

enum AnimationIntensity {
  off,
  subtle,
  cinematic,
}

extension PageVisualFamilyX on PageVisualFamily {
  String get id {
    switch (this) {
      case PageVisualFamily.classic:
        return PageVisualFamilyIds.classic;
      case PageVisualFamily.vintage:
        return PageVisualFamilyIds.vintage;
    }
  }

  static PageVisualFamily fromId(String? id) {
    switch (id) {
      case PageVisualFamilyIds.vintage:
        return PageVisualFamily.vintage;
      case PageVisualFamilyIds.classic:
      default:
        return PageVisualFamily.classic;
    }
  }
}

extension VintagePaperVariantX on VintagePaperVariant {
  String get id {
    switch (this) {
      case VintagePaperVariant.parchment:
        return VintagePaperVariantIds.parchment;
      case VintagePaperVariant.sepiaDiary:
        return VintagePaperVariantIds.sepiaDiary;
      case VintagePaperVariant.pressedFloral:
        return VintagePaperVariantIds.pressedFloral;
    }
  }

  static VintagePaperVariant fromId(String? id) {
    switch (id) {
      case VintagePaperVariantIds.sepiaDiary:
        return VintagePaperVariant.sepiaDiary;
      case VintagePaperVariantIds.pressedFloral:
        return VintagePaperVariant.pressedFloral;
      case VintagePaperVariantIds.parchment:
      default:
        return VintagePaperVariant.parchment;
    }
  }
}

extension AnimationIntensityX on AnimationIntensity {
  String get id {
    switch (this) {
      case AnimationIntensity.off:
        return AnimationIntensityIds.off;
      case AnimationIntensity.subtle:
        return AnimationIntensityIds.subtle;
      case AnimationIntensity.cinematic:
        return AnimationIntensityIds.cinematic;
    }
  }

  bool get isAnimated => this != AnimationIntensity.off;

  static AnimationIntensity fromId(String? id) {
    switch (id) {
      case AnimationIntensityIds.off:
        return AnimationIntensity.off;
      case AnimationIntensityIds.cinematic:
        return AnimationIntensity.cinematic;
      case AnimationIntensityIds.subtle:
      default:
        return AnimationIntensity.subtle;
    }
  }
}

class PageVisualFamilyIds {
  const PageVisualFamilyIds._();

  static const String classic = 'classic';
  static const String vintage = 'vintage';
}

class VintagePaperVariantIds {
  const VintagePaperVariantIds._();

  static const String parchment = 'parchment';
  static const String sepiaDiary = 'sepia_diary';
  static const String pressedFloral = 'pressed_floral';
}

class AnimationIntensityIds {
  const AnimationIntensityIds._();

  static const String off = 'off';
  static const String subtle = 'subtle';
  static const String cinematic = 'cinematic';
}
