import '../errors/exceptions.dart';
import '../constants/app_constants.dart';

/// Represents a validation result with potential errors.
class ValidationResult {
  const ValidationResult({this.isValid = true, this.errors = const {}});

  final bool isValid;
  final Map<String, String> errors;

  /// Creates an invalid result with the given errors.
  factory ValidationResult.invalid(Map<String, String> errors) {
    return ValidationResult(isValid: false, errors: errors);
  }

  /// Creates a valid result.
  factory ValidationResult.valid() {
    return const ValidationResult(isValid: true);
  }

  /// Returns true if there are no errors.
  bool get hasErrors => errors.isNotEmpty;

  /// Gets the first error message, or null if valid.
  String? get firstError => errors.isNotEmpty ? errors.values.first : null;

  /// Throws a [ValidationException] if the result is invalid.
  void throwIfInvalid() {
    if (!isValid) {
      throw ValidationException(
        message: firstError ?? 'Validation failed',
        field: errors.keys.firstOrNull,
      );
    }
  }
}

/// Validates journal entry data.
class JournalEntryValidator {
  const JournalEntryValidator._();

  /// Validates a journal entry title.
  ///
  /// Returns null if valid, error message if invalid.
  static String? validateTitle(String? title) {
    if (title == null || title.trim().isEmpty) {
      return null; // Title is optional
    }

    if (title.length > AppLimits.maxTitleLength) {
      return 'Title cannot exceed ${AppLimits.maxTitleLength} characters';
    }

    return null;
  }

  /// Validates journal entry content.
  static String? validateContent(String? content) {
    if (content == null || content.trim().isEmpty) {
      return 'Content cannot be empty';
    }

    if (content.length > AppLimits.maxContentLength) {
      return 'Content cannot exceed ${AppLimits.maxContentLength} characters';
    }

    return null;
  }

  /// Validates a list of tags.
  static String? validateTags(List<String>? tags) {
    if (tags == null || tags.isEmpty) {
      return null; // Tags are optional
    }

    if (tags.length > AppLimits.maxTagsCount) {
      return 'Cannot have more than ${AppLimits.maxTagsCount} tags';
    }

    for (final tag in tags) {
      if (tag.length > AppLimits.maxTagLength) {
        return 'Tag "$tag" exceeds ${AppLimits.maxTagLength} characters';
      }
      if (tag.trim().isEmpty) {
        return 'Tags cannot be empty';
      }
    }

    return null;
  }

  /// Validates a single tag.
  static String? validateTag(String tag) {
    if (tag.trim().isEmpty) {
      return 'Tag cannot be empty';
    }

    if (tag.length > AppLimits.maxTagLength) {
      return 'Tag cannot exceed ${AppLimits.maxTagLength} characters';
    }

    return null;
  }

  /// Validates attachment paths.
  static String? validateAttachments(List<String>? attachments) {
    if (attachments == null || attachments.isEmpty) {
      return null; // Attachments are optional
    }

    if (attachments.length > AppLimits.maxAttachmentsCount) {
      return 'Cannot have more than ${AppLimits.maxAttachmentsCount} attachments';
    }

    return null;
  }

  /// Validates all journal entry fields and returns a [ValidationResult].
  static ValidationResult validate({
    String? title,
    required String content,
    List<String>? tags,
    List<String>? attachments,
  }) {
    final errors = <String, String>{};

    final titleError = validateTitle(title);
    if (titleError != null) {
      errors['title'] = titleError;
    }

    final contentError = validateContent(content);
    if (contentError != null) {
      errors['content'] = contentError;
    }

    final tagsError = validateTags(tags);
    if (tagsError != null) {
      errors['tags'] = tagsError;
    }

    final attachmentsError = validateAttachments(attachments);
    if (attachmentsError != null) {
      errors['attachments'] = attachmentsError;
    }

    if (errors.isNotEmpty) {
      return ValidationResult.invalid(errors);
    }

    return ValidationResult.valid();
  }
}

/// Validates category data.
class CategoryValidator {
  const CategoryValidator._();

  /// Validates a category name.
  static String? validateName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Category name cannot be empty';
    }

    if (name.length > AppLimits.maxCategoryNameLength) {
      return 'Category name cannot exceed ${AppLimits.maxCategoryNameLength} characters';
    }

    return null;
  }

  /// Validates a category color value.
  static String? validateColor(int? color) {
    if (color == null) {
      return 'Category color is required';
    }

    // Color value should be a valid 32-bit integer
    if (color < 0 || color > 0xFFFFFFFF) {
      return 'Invalid color value';
    }

    return null;
  }

  /// Validates all category fields and returns a [ValidationResult].
  static ValidationResult validate({
    required String name,
    required int color,
    String? iconPath,
  }) {
    final errors = <String, String>{};

    final nameError = validateName(name);
    if (nameError != null) {
      errors['name'] = nameError;
    }

    final colorError = validateColor(color);
    if (colorError != null) {
      errors['color'] = colorError;
    }

    if (errors.isNotEmpty) {
      return ValidationResult.invalid(errors);
    }

    return ValidationResult.valid();
  }
}

/// Validates search queries.
class SearchValidator {
  const SearchValidator._();

  /// Validates a search query.
  static String? validateQuery(String? query) {
    if (query == null || query.trim().isEmpty) {
      return 'Search query cannot be empty';
    }

    if (query.trim().length < 2) {
      return 'Search query must be at least 2 characters';
    }

    return null;
  }

  /// Sanitizes a search query by removing extra whitespace.
  static String sanitizeQuery(String query) {
    return query.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}
