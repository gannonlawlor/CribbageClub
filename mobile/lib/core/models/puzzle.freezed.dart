// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'puzzle.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PuzzleResponse _$PuzzleResponseFromJson(Map<String, dynamic> json) {
  return _PuzzleResponse.fromJson(json);
}

/// @nodoc
mixin _$PuzzleResponse {
  String get id => throw _privateConstructorUsedError;
  List<PlayingCard> get hand => throw _privateConstructorUsedError;
  bool get isDealer => throw _privateConstructorUsedError;
  String get puzzleDate => throw _privateConstructorUsedError;
  bool get alreadySolved => throw _privateConstructorUsedError;

  /// Serializes this PuzzleResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PuzzleResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PuzzleResponseCopyWith<PuzzleResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PuzzleResponseCopyWith<$Res> {
  factory $PuzzleResponseCopyWith(
    PuzzleResponse value,
    $Res Function(PuzzleResponse) then,
  ) = _$PuzzleResponseCopyWithImpl<$Res, PuzzleResponse>;
  @useResult
  $Res call({
    String id,
    List<PlayingCard> hand,
    bool isDealer,
    String puzzleDate,
    bool alreadySolved,
  });
}

/// @nodoc
class _$PuzzleResponseCopyWithImpl<$Res, $Val extends PuzzleResponse>
    implements $PuzzleResponseCopyWith<$Res> {
  _$PuzzleResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PuzzleResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? hand = null,
    Object? isDealer = null,
    Object? puzzleDate = null,
    Object? alreadySolved = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            hand: null == hand
                ? _value.hand
                : hand // ignore: cast_nullable_to_non_nullable
                      as List<PlayingCard>,
            isDealer: null == isDealer
                ? _value.isDealer
                : isDealer // ignore: cast_nullable_to_non_nullable
                      as bool,
            puzzleDate: null == puzzleDate
                ? _value.puzzleDate
                : puzzleDate // ignore: cast_nullable_to_non_nullable
                      as String,
            alreadySolved: null == alreadySolved
                ? _value.alreadySolved
                : alreadySolved // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PuzzleResponseImplCopyWith<$Res>
    implements $PuzzleResponseCopyWith<$Res> {
  factory _$$PuzzleResponseImplCopyWith(
    _$PuzzleResponseImpl value,
    $Res Function(_$PuzzleResponseImpl) then,
  ) = __$$PuzzleResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    List<PlayingCard> hand,
    bool isDealer,
    String puzzleDate,
    bool alreadySolved,
  });
}

/// @nodoc
class __$$PuzzleResponseImplCopyWithImpl<$Res>
    extends _$PuzzleResponseCopyWithImpl<$Res, _$PuzzleResponseImpl>
    implements _$$PuzzleResponseImplCopyWith<$Res> {
  __$$PuzzleResponseImplCopyWithImpl(
    _$PuzzleResponseImpl _value,
    $Res Function(_$PuzzleResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PuzzleResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? hand = null,
    Object? isDealer = null,
    Object? puzzleDate = null,
    Object? alreadySolved = null,
  }) {
    return _then(
      _$PuzzleResponseImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        hand: null == hand
            ? _value._hand
            : hand // ignore: cast_nullable_to_non_nullable
                  as List<PlayingCard>,
        isDealer: null == isDealer
            ? _value.isDealer
            : isDealer // ignore: cast_nullable_to_non_nullable
                  as bool,
        puzzleDate: null == puzzleDate
            ? _value.puzzleDate
            : puzzleDate // ignore: cast_nullable_to_non_nullable
                  as String,
        alreadySolved: null == alreadySolved
            ? _value.alreadySolved
            : alreadySolved // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PuzzleResponseImpl implements _PuzzleResponse {
  const _$PuzzleResponseImpl({
    required this.id,
    required final List<PlayingCard> hand,
    required this.isDealer,
    required this.puzzleDate,
    this.alreadySolved = false,
  }) : _hand = hand;

  factory _$PuzzleResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$PuzzleResponseImplFromJson(json);

  @override
  final String id;
  final List<PlayingCard> _hand;
  @override
  List<PlayingCard> get hand {
    if (_hand is EqualUnmodifiableListView) return _hand;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_hand);
  }

  @override
  final bool isDealer;
  @override
  final String puzzleDate;
  @override
  @JsonKey()
  final bool alreadySolved;

  @override
  String toString() {
    return 'PuzzleResponse(id: $id, hand: $hand, isDealer: $isDealer, puzzleDate: $puzzleDate, alreadySolved: $alreadySolved)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PuzzleResponseImpl &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality().equals(other._hand, _hand) &&
            (identical(other.isDealer, isDealer) ||
                other.isDealer == isDealer) &&
            (identical(other.puzzleDate, puzzleDate) ||
                other.puzzleDate == puzzleDate) &&
            (identical(other.alreadySolved, alreadySolved) ||
                other.alreadySolved == alreadySolved));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    const DeepCollectionEquality().hash(_hand),
    isDealer,
    puzzleDate,
    alreadySolved,
  );

  /// Create a copy of PuzzleResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PuzzleResponseImplCopyWith<_$PuzzleResponseImpl> get copyWith =>
      __$$PuzzleResponseImplCopyWithImpl<_$PuzzleResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PuzzleResponseImplToJson(this);
  }
}

abstract class _PuzzleResponse implements PuzzleResponse {
  const factory _PuzzleResponse({
    required final String id,
    required final List<PlayingCard> hand,
    required final bool isDealer,
    required final String puzzleDate,
    final bool alreadySolved,
  }) = _$PuzzleResponseImpl;

  factory _PuzzleResponse.fromJson(Map<String, dynamic> json) =
      _$PuzzleResponseImpl.fromJson;

  @override
  String get id;
  @override
  List<PlayingCard> get hand;
  @override
  bool get isDealer;
  @override
  String get puzzleDate;
  @override
  bool get alreadySolved;

  /// Create a copy of PuzzleResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PuzzleResponseImplCopyWith<_$PuzzleResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PuzzleSolveResponse _$PuzzleSolveResponseFromJson(Map<String, dynamic> json) {
  return _PuzzleSolveResponse.fromJson(json);
}

/// @nodoc
mixin _$PuzzleSolveResponse {
  bool get isOptimal => throw _privateConstructorUsedError;
  double get evDifference => throw _privateConstructorUsedError;
  DiscardOption get yourOption => throw _privateConstructorUsedError;
  DiscardOption get optimalOption => throw _privateConstructorUsedError;
  List<DiscardOption> get allOptions => throw _privateConstructorUsedError;
  List<AchievementStatus> get unlockedAchievements =>
      throw _privateConstructorUsedError;

  /// Serializes this PuzzleSolveResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PuzzleSolveResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PuzzleSolveResponseCopyWith<PuzzleSolveResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PuzzleSolveResponseCopyWith<$Res> {
  factory $PuzzleSolveResponseCopyWith(
    PuzzleSolveResponse value,
    $Res Function(PuzzleSolveResponse) then,
  ) = _$PuzzleSolveResponseCopyWithImpl<$Res, PuzzleSolveResponse>;
  @useResult
  $Res call({
    bool isOptimal,
    double evDifference,
    DiscardOption yourOption,
    DiscardOption optimalOption,
    List<DiscardOption> allOptions,
    List<AchievementStatus> unlockedAchievements,
  });

  $DiscardOptionCopyWith<$Res> get yourOption;
  $DiscardOptionCopyWith<$Res> get optimalOption;
}

/// @nodoc
class _$PuzzleSolveResponseCopyWithImpl<$Res, $Val extends PuzzleSolveResponse>
    implements $PuzzleSolveResponseCopyWith<$Res> {
  _$PuzzleSolveResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PuzzleSolveResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isOptimal = null,
    Object? evDifference = null,
    Object? yourOption = null,
    Object? optimalOption = null,
    Object? allOptions = null,
    Object? unlockedAchievements = null,
  }) {
    return _then(
      _value.copyWith(
            isOptimal: null == isOptimal
                ? _value.isOptimal
                : isOptimal // ignore: cast_nullable_to_non_nullable
                      as bool,
            evDifference: null == evDifference
                ? _value.evDifference
                : evDifference // ignore: cast_nullable_to_non_nullable
                      as double,
            yourOption: null == yourOption
                ? _value.yourOption
                : yourOption // ignore: cast_nullable_to_non_nullable
                      as DiscardOption,
            optimalOption: null == optimalOption
                ? _value.optimalOption
                : optimalOption // ignore: cast_nullable_to_non_nullable
                      as DiscardOption,
            allOptions: null == allOptions
                ? _value.allOptions
                : allOptions // ignore: cast_nullable_to_non_nullable
                      as List<DiscardOption>,
            unlockedAchievements: null == unlockedAchievements
                ? _value.unlockedAchievements
                : unlockedAchievements // ignore: cast_nullable_to_non_nullable
                      as List<AchievementStatus>,
          )
          as $Val,
    );
  }

  /// Create a copy of PuzzleSolveResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DiscardOptionCopyWith<$Res> get yourOption {
    return $DiscardOptionCopyWith<$Res>(_value.yourOption, (value) {
      return _then(_value.copyWith(yourOption: value) as $Val);
    });
  }

  /// Create a copy of PuzzleSolveResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DiscardOptionCopyWith<$Res> get optimalOption {
    return $DiscardOptionCopyWith<$Res>(_value.optimalOption, (value) {
      return _then(_value.copyWith(optimalOption: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PuzzleSolveResponseImplCopyWith<$Res>
    implements $PuzzleSolveResponseCopyWith<$Res> {
  factory _$$PuzzleSolveResponseImplCopyWith(
    _$PuzzleSolveResponseImpl value,
    $Res Function(_$PuzzleSolveResponseImpl) then,
  ) = __$$PuzzleSolveResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool isOptimal,
    double evDifference,
    DiscardOption yourOption,
    DiscardOption optimalOption,
    List<DiscardOption> allOptions,
    List<AchievementStatus> unlockedAchievements,
  });

  @override
  $DiscardOptionCopyWith<$Res> get yourOption;
  @override
  $DiscardOptionCopyWith<$Res> get optimalOption;
}

/// @nodoc
class __$$PuzzleSolveResponseImplCopyWithImpl<$Res>
    extends _$PuzzleSolveResponseCopyWithImpl<$Res, _$PuzzleSolveResponseImpl>
    implements _$$PuzzleSolveResponseImplCopyWith<$Res> {
  __$$PuzzleSolveResponseImplCopyWithImpl(
    _$PuzzleSolveResponseImpl _value,
    $Res Function(_$PuzzleSolveResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PuzzleSolveResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isOptimal = null,
    Object? evDifference = null,
    Object? yourOption = null,
    Object? optimalOption = null,
    Object? allOptions = null,
    Object? unlockedAchievements = null,
  }) {
    return _then(
      _$PuzzleSolveResponseImpl(
        isOptimal: null == isOptimal
            ? _value.isOptimal
            : isOptimal // ignore: cast_nullable_to_non_nullable
                  as bool,
        evDifference: null == evDifference
            ? _value.evDifference
            : evDifference // ignore: cast_nullable_to_non_nullable
                  as double,
        yourOption: null == yourOption
            ? _value.yourOption
            : yourOption // ignore: cast_nullable_to_non_nullable
                  as DiscardOption,
        optimalOption: null == optimalOption
            ? _value.optimalOption
            : optimalOption // ignore: cast_nullable_to_non_nullable
                  as DiscardOption,
        allOptions: null == allOptions
            ? _value._allOptions
            : allOptions // ignore: cast_nullable_to_non_nullable
                  as List<DiscardOption>,
        unlockedAchievements: null == unlockedAchievements
            ? _value._unlockedAchievements
            : unlockedAchievements // ignore: cast_nullable_to_non_nullable
                  as List<AchievementStatus>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PuzzleSolveResponseImpl implements _PuzzleSolveResponse {
  const _$PuzzleSolveResponseImpl({
    required this.isOptimal,
    required this.evDifference,
    required this.yourOption,
    required this.optimalOption,
    required final List<DiscardOption> allOptions,
    final List<AchievementStatus> unlockedAchievements = const [],
  }) : _allOptions = allOptions,
       _unlockedAchievements = unlockedAchievements;

  factory _$PuzzleSolveResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$PuzzleSolveResponseImplFromJson(json);

  @override
  final bool isOptimal;
  @override
  final double evDifference;
  @override
  final DiscardOption yourOption;
  @override
  final DiscardOption optimalOption;
  final List<DiscardOption> _allOptions;
  @override
  List<DiscardOption> get allOptions {
    if (_allOptions is EqualUnmodifiableListView) return _allOptions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_allOptions);
  }

  final List<AchievementStatus> _unlockedAchievements;
  @override
  @JsonKey()
  List<AchievementStatus> get unlockedAchievements {
    if (_unlockedAchievements is EqualUnmodifiableListView)
      return _unlockedAchievements;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_unlockedAchievements);
  }

  @override
  String toString() {
    return 'PuzzleSolveResponse(isOptimal: $isOptimal, evDifference: $evDifference, yourOption: $yourOption, optimalOption: $optimalOption, allOptions: $allOptions, unlockedAchievements: $unlockedAchievements)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PuzzleSolveResponseImpl &&
            (identical(other.isOptimal, isOptimal) ||
                other.isOptimal == isOptimal) &&
            (identical(other.evDifference, evDifference) ||
                other.evDifference == evDifference) &&
            (identical(other.yourOption, yourOption) ||
                other.yourOption == yourOption) &&
            (identical(other.optimalOption, optimalOption) ||
                other.optimalOption == optimalOption) &&
            const DeepCollectionEquality().equals(
              other._allOptions,
              _allOptions,
            ) &&
            const DeepCollectionEquality().equals(
              other._unlockedAchievements,
              _unlockedAchievements,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    isOptimal,
    evDifference,
    yourOption,
    optimalOption,
    const DeepCollectionEquality().hash(_allOptions),
    const DeepCollectionEquality().hash(_unlockedAchievements),
  );

  /// Create a copy of PuzzleSolveResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PuzzleSolveResponseImplCopyWith<_$PuzzleSolveResponseImpl> get copyWith =>
      __$$PuzzleSolveResponseImplCopyWithImpl<_$PuzzleSolveResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PuzzleSolveResponseImplToJson(this);
  }
}

abstract class _PuzzleSolveResponse implements PuzzleSolveResponse {
  const factory _PuzzleSolveResponse({
    required final bool isOptimal,
    required final double evDifference,
    required final DiscardOption yourOption,
    required final DiscardOption optimalOption,
    required final List<DiscardOption> allOptions,
    final List<AchievementStatus> unlockedAchievements,
  }) = _$PuzzleSolveResponseImpl;

  factory _PuzzleSolveResponse.fromJson(Map<String, dynamic> json) =
      _$PuzzleSolveResponseImpl.fromJson;

  @override
  bool get isOptimal;
  @override
  double get evDifference;
  @override
  DiscardOption get yourOption;
  @override
  DiscardOption get optimalOption;
  @override
  List<DiscardOption> get allOptions;
  @override
  List<AchievementStatus> get unlockedAchievements;

  /// Create a copy of PuzzleSolveResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PuzzleSolveResponseImplCopyWith<_$PuzzleSolveResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
