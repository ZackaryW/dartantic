/// Represents metadata for a field in a model
class DttFieldMeta {
  final String type;
  final bool isFinal;
  final bool isLate;
  final String? subModel;

  const DttFieldMeta({
    required this.type,
    required this.isFinal,
    required this.isLate,
    this.subModel,
  });

  /// Creates a FieldMeta from a map
  factory DttFieldMeta.fromMap(Map<String, dynamic> map) {
    return DttFieldMeta(
      type: map['type'] as String,
      isFinal: map['isFinal'] as bool,
      isLate: map['isLate'] as bool,
      subModel: map['subModel'] as String?,
    );
  }

  /// Converts the field metadata to a map
  Map<String, dynamic> toMap() => {
    'type': type,
    'isFinal': isFinal,
    'isLate': isLate,
    'subModel': subModel,
  };
}

/// Base class for model metadata
class DttModelMeta {
  final Map<String, DttFieldMeta> fields;

  const DttModelMeta({required this.fields});

  /// Creates a ModelMeta from a map
  factory DttModelMeta.fromMap(Map<String, dynamic> map) {
    return DttModelMeta(
      fields: Map.fromEntries(
        (map).entries.map(
          (e) => MapEntry(
            e.key,
            DttFieldMeta.fromMap(e.value as Map<String, dynamic>),
          ),
        ),
      ),
    );
  }

  /// Converts the model metadata to a map
  Map<String, dynamic> toMap() => {
    for (final entry in fields.entries) entry.key: entry.value.toMap(),
  };

  // function to yield keys
  Iterable<String> get keys => fields.keys;
  Iterable<DttFieldMeta> get fieldMetas => fields.values;
}
