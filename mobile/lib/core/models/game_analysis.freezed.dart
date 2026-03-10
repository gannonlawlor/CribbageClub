// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_analysis.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

DiscardOption _$DiscardOptionFromJson(Map<String, dynamic> json) {
  return _DiscardOption.fromJson(json);
}

/// @nodoc
mixin _$DiscardOption {
  List<PlayingCard> get keep => throw _privateConstructorUsedError;
  List<PlayingCard> get discard => throw _privateConstructorUsedError;
  double get expectedHandValue => throw _privateConstructorUsedError;
  double get expectedCribValue => throw _privateConstructorUsedError;
  double get expectedCombinedValue => throw _privateConstructorUsedError;

  /// Serializes this DiscardOption to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DiscardOption
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DiscardOptionCopyWith<DiscardOption> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DiscardOptionCopyWith<$Res> {
  factory $DiscardOptionCopyWith(
    DiscardOption value,
    $Res Function(DiscardOption) then,
  ) = _$DiscardOptionCopyWithImpl<$Res, DiscardOption>;
  @useResult
  $Res call({
    List<PlayingCard> keep,
    List<PlayingCard> discard,
    double expectedHandValue,
    double expectedCribValue,
    double expectedCombinedValue,
  });
}

/// @nodoc
class _$DiscardOptionCopyWithImpl<$Res, $Val extends DiscardOption>
    implements $DiscardOptionCopyWith<$Res> {
  _$DiscardOptionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DiscardOption
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? keep = null,
    Object? discard = null,
    Object? expectedHandValue = null,
    Object? expectedCribValue = null,
    Object? expectedCombinedValue = null,
  }) {
    return _then(
      _value.copyWith(
            keep: null == keep
                ? _value.keep
                : keep // ignore: cast_nullable_to_non_nullable
                      as List<PlayingCard>,
            discard: null == discard
                ? _value.discard
                : discard // ignore: cast_nullable_to_non_nullable
                      as List<PlayingCard>,
            expectedHandValue: null == expectedHandValue
                ? _value.expectedHandValue
                : expectedHandValue // ignore: cast_nullable_to_non_nullable
                      as double,
            expectedCribValue: null == expectedCribValue
                ? _value.expectedCribValue
                : expectedCribValue // ignore: cast_nullable_to_non_nullable
                      as double,
            expectedCombinedValue: null == expectedCombinedValue
                ? _value.expectedCombinedValue
                : expectedCombinedValue // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DiscardOptionImplCopyWith<$Res>
    implements $DiscardOptionCopyWith<$Res> {
  factory _$$DiscardOptionImplCopyWith(
    _$DiscardOptionImpl value,
    $Res Function(_$DiscardOptionImpl) then,
  ) = __$$DiscardOptionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<PlayingCard> keep,
    List<PlayingCard> discard,
    double expectedHandValue,
    double expectedCribValue,
    double expectedCombinedValue,
  });
}

/// @nodoc
class __$$DiscardOptionImplCopyWithImpl<$Res>
    extends _$DiscardOptionCopyWithImpl<$Res, _$DiscardOptionImpl>
    implements _$$DiscardOptionImplCopyWith<$Res> {
  __$$DiscardOptionImplCopyWithImpl(
    _$DiscardOptionImpl _value,
    $Res Function(_$DiscardOptionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DiscardOption
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? keep = null,
    Object? discard = null,
    Object? expectedHandValue = null,
    Object? expectedCribValue = null,
    Object? expectedCombinedValue = null,
  }) {
    return _then(
      _$DiscardOptionImpl(
        keep: null == keep
            ? _value._keep
            : keep // ignore: cast_nullable_to_non_nullable
                  as List<PlayingCard>,
        discard: null == discard
            ? _value._discard
            : discard // ignore: cast_nullable_to_non_nullable
                  as List<PlayingCard>,
        expectedHandValue: null == expectedHandValue
            ? _value.expectedHandValue
            : expectedHandValue // ignore: cast_nullable_to_non_nullable
                  as double,
        expectedCribValue: null == expectedCribValue
            ? _value.expectedCribValue
            : expectedCribValue // ignore: cast_nullable_to_non_nullable
                  as double,
        expectedCombinedValue: null == expectedCombinedValue
            ? _value.expectedCombinedValue
            : expectedCombinedValue // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DiscardOptionImpl implements _DiscardOption {
  const _$DiscardOptionImpl({
    required final List<PlayingCard> keep,
    required final List<PlayingCard> discard,
    required this.expectedHandValue,
    required this.expectedCribValue,
    required this.expectedCombinedValue,
  }) : _keep = keep,
       _discard = discard;

  factory _$DiscardOptionImpl.fromJson(Map<String, dynamic> json) =>
      _$$DiscardOptionImplFromJson(json);

  final List<PlayingCard> _keep;
  @override
  List<PlayingCard> get keep {
    if (_keep is EqualUnmodifiableListView) return _keep;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_keep);
  }

  final List<PlayingCard> _discard;
  @override
  List<PlayingCard> get discard {
    if (_discard is EqualUnmodifiableListView) return _discard;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_discard);
  }

  @override
  final double expectedHandValue;
  @override
  final double expectedCribValue;
  @override
  final double expectedCombinedValue;

  @override
  String toString() {
    return 'DiscardOption(keep: $keep, discard: $discard, expectedHandValue: $expectedHandValue, expectedCribValue: $expectedCribValue, expectedCombinedValue: $expectedCombinedValue)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DiscardOptionImpl &&
            const DeepCollectionEquality().equals(other._keep, _keep) &&
            const DeepCollectionEquality().equals(other._discard, _discard) &&
            (identical(other.expectedHandValue, expectedHandValue) ||
                other.expectedHandValue == expectedHandValue) &&
            (identical(other.expectedCribValue, expectedCribValue) ||
                other.expectedCribValue == expectedCribValue) &&
            (identical(other.expectedCombinedValue, expectedCombinedValue) ||
                other.expectedCombinedValue == expectedCombinedValue));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_keep),
    const DeepCollectionEquality().hash(_discard),
    expectedHandValue,
    expectedCribValue,
    expectedCombinedValue,
  );

  /// Create a copy of DiscardOption
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DiscardOptionImplCopyWith<_$DiscardOptionImpl> get copyWith =>
      __$$DiscardOptionImplCopyWithImpl<_$DiscardOptionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DiscardOptionImplToJson(this);
  }
}

abstract class _DiscardOption implements DiscardOption {
  const factory _DiscardOption({
    required final List<PlayingCard> keep,
    required final List<PlayingCard> discard,
    required final double expectedHandValue,
    required final double expectedCribValue,
    required final double expectedCombinedValue,
  }) = _$DiscardOptionImpl;

  factory _DiscardOption.fromJson(Map<String, dynamic> json) =
      _$DiscardOptionImpl.fromJson;

  @override
  List<PlayingCard> get keep;
  @override
  List<PlayingCard> get discard;
  @override
  double get expectedHandValue;
  @override
  double get expectedCribValue;
  @override
  double get expectedCombinedValue;

  /// Create a copy of DiscardOption
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DiscardOptionImplCopyWith<_$DiscardOptionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PlayerRoundAnalysis _$PlayerRoundAnalysisFromJson(Map<String, dynamic> json) {
  return _PlayerRoundAnalysis.fromJson(json);
}

/// @nodoc
mixin _$PlayerRoundAnalysis {
  String get playerId => throw _privateConstructorUsedError;
  bool get isDealer => throw _privateConstructorUsedError;
  List<PlayingCard> get dealtHand => throw _privateConstructorUsedError;
  List<PlayingCard> get keptHand => throw _privateConstructorUsedError;
  List<PlayingCard> get discarded => throw _privateConstructorUsedError;
  int get actualHandScore => throw _privateConstructorUsedError;
  int? get actualCribScore => throw _privateConstructorUsedError;
  DiscardOption get optimalDiscard => throw _privateConstructorUsedError;
  DiscardOption get playerDiscard => throw _privateConstructorUsedError;
  double get evDifference => throw _privateConstructorUsedError;
  List<DiscardOption>? get allOptions => throw _privateConstructorUsedError;

  /// Serializes this PlayerRoundAnalysis to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlayerRoundAnalysis
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlayerRoundAnalysisCopyWith<PlayerRoundAnalysis> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlayerRoundAnalysisCopyWith<$Res> {
  factory $PlayerRoundAnalysisCopyWith(
    PlayerRoundAnalysis value,
    $Res Function(PlayerRoundAnalysis) then,
  ) = _$PlayerRoundAnalysisCopyWithImpl<$Res, PlayerRoundAnalysis>;
  @useResult
  $Res call({
    String playerId,
    bool isDealer,
    List<PlayingCard> dealtHand,
    List<PlayingCard> keptHand,
    List<PlayingCard> discarded,
    int actualHandScore,
    int? actualCribScore,
    DiscardOption optimalDiscard,
    DiscardOption playerDiscard,
    double evDifference,
    List<DiscardOption>? allOptions,
  });

  $DiscardOptionCopyWith<$Res> get optimalDiscard;
  $DiscardOptionCopyWith<$Res> get playerDiscard;
}

/// @nodoc
class _$PlayerRoundAnalysisCopyWithImpl<$Res, $Val extends PlayerRoundAnalysis>
    implements $PlayerRoundAnalysisCopyWith<$Res> {
  _$PlayerRoundAnalysisCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlayerRoundAnalysis
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playerId = null,
    Object? isDealer = null,
    Object? dealtHand = null,
    Object? keptHand = null,
    Object? discarded = null,
    Object? actualHandScore = null,
    Object? actualCribScore = freezed,
    Object? optimalDiscard = null,
    Object? playerDiscard = null,
    Object? evDifference = null,
    Object? allOptions = freezed,
  }) {
    return _then(
      _value.copyWith(
            playerId: null == playerId
                ? _value.playerId
                : playerId // ignore: cast_nullable_to_non_nullable
                      as String,
            isDealer: null == isDealer
                ? _value.isDealer
                : isDealer // ignore: cast_nullable_to_non_nullable
                      as bool,
            dealtHand: null == dealtHand
                ? _value.dealtHand
                : dealtHand // ignore: cast_nullable_to_non_nullable
                      as List<PlayingCard>,
            keptHand: null == keptHand
                ? _value.keptHand
                : keptHand // ignore: cast_nullable_to_non_nullable
                      as List<PlayingCard>,
            discarded: null == discarded
                ? _value.discarded
                : discarded // ignore: cast_nullable_to_non_nullable
                      as List<PlayingCard>,
            actualHandScore: null == actualHandScore
                ? _value.actualHandScore
                : actualHandScore // ignore: cast_nullable_to_non_nullable
                      as int,
            actualCribScore: freezed == actualCribScore
                ? _value.actualCribScore
                : actualCribScore // ignore: cast_nullable_to_non_nullable
                      as int?,
            optimalDiscard: null == optimalDiscard
                ? _value.optimalDiscard
                : optimalDiscard // ignore: cast_nullable_to_non_nullable
                      as DiscardOption,
            playerDiscard: null == playerDiscard
                ? _value.playerDiscard
                : playerDiscard // ignore: cast_nullable_to_non_nullable
                      as DiscardOption,
            evDifference: null == evDifference
                ? _value.evDifference
                : evDifference // ignore: cast_nullable_to_non_nullable
                      as double,
            allOptions: freezed == allOptions
                ? _value.allOptions
                : allOptions // ignore: cast_nullable_to_non_nullable
                      as List<DiscardOption>?,
          )
          as $Val,
    );
  }

  /// Create a copy of PlayerRoundAnalysis
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DiscardOptionCopyWith<$Res> get optimalDiscard {
    return $DiscardOptionCopyWith<$Res>(_value.optimalDiscard, (value) {
      return _then(_value.copyWith(optimalDiscard: value) as $Val);
    });
  }

  /// Create a copy of PlayerRoundAnalysis
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DiscardOptionCopyWith<$Res> get playerDiscard {
    return $DiscardOptionCopyWith<$Res>(_value.playerDiscard, (value) {
      return _then(_value.copyWith(playerDiscard: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PlayerRoundAnalysisImplCopyWith<$Res>
    implements $PlayerRoundAnalysisCopyWith<$Res> {
  factory _$$PlayerRoundAnalysisImplCopyWith(
    _$PlayerRoundAnalysisImpl value,
    $Res Function(_$PlayerRoundAnalysisImpl) then,
  ) = __$$PlayerRoundAnalysisImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String playerId,
    bool isDealer,
    List<PlayingCard> dealtHand,
    List<PlayingCard> keptHand,
    List<PlayingCard> discarded,
    int actualHandScore,
    int? actualCribScore,
    DiscardOption optimalDiscard,
    DiscardOption playerDiscard,
    double evDifference,
    List<DiscardOption>? allOptions,
  });

  @override
  $DiscardOptionCopyWith<$Res> get optimalDiscard;
  @override
  $DiscardOptionCopyWith<$Res> get playerDiscard;
}

/// @nodoc
class __$$PlayerRoundAnalysisImplCopyWithImpl<$Res>
    extends _$PlayerRoundAnalysisCopyWithImpl<$Res, _$PlayerRoundAnalysisImpl>
    implements _$$PlayerRoundAnalysisImplCopyWith<$Res> {
  __$$PlayerRoundAnalysisImplCopyWithImpl(
    _$PlayerRoundAnalysisImpl _value,
    $Res Function(_$PlayerRoundAnalysisImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PlayerRoundAnalysis
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playerId = null,
    Object? isDealer = null,
    Object? dealtHand = null,
    Object? keptHand = null,
    Object? discarded = null,
    Object? actualHandScore = null,
    Object? actualCribScore = freezed,
    Object? optimalDiscard = null,
    Object? playerDiscard = null,
    Object? evDifference = null,
    Object? allOptions = freezed,
  }) {
    return _then(
      _$PlayerRoundAnalysisImpl(
        playerId: null == playerId
            ? _value.playerId
            : playerId // ignore: cast_nullable_to_non_nullable
                  as String,
        isDealer: null == isDealer
            ? _value.isDealer
            : isDealer // ignore: cast_nullable_to_non_nullable
                  as bool,
        dealtHand: null == dealtHand
            ? _value._dealtHand
            : dealtHand // ignore: cast_nullable_to_non_nullable
                  as List<PlayingCard>,
        keptHand: null == keptHand
            ? _value._keptHand
            : keptHand // ignore: cast_nullable_to_non_nullable
                  as List<PlayingCard>,
        discarded: null == discarded
            ? _value._discarded
            : discarded // ignore: cast_nullable_to_non_nullable
                  as List<PlayingCard>,
        actualHandScore: null == actualHandScore
            ? _value.actualHandScore
            : actualHandScore // ignore: cast_nullable_to_non_nullable
                  as int,
        actualCribScore: freezed == actualCribScore
            ? _value.actualCribScore
            : actualCribScore // ignore: cast_nullable_to_non_nullable
                  as int?,
        optimalDiscard: null == optimalDiscard
            ? _value.optimalDiscard
            : optimalDiscard // ignore: cast_nullable_to_non_nullable
                  as DiscardOption,
        playerDiscard: null == playerDiscard
            ? _value.playerDiscard
            : playerDiscard // ignore: cast_nullable_to_non_nullable
                  as DiscardOption,
        evDifference: null == evDifference
            ? _value.evDifference
            : evDifference // ignore: cast_nullable_to_non_nullable
                  as double,
        allOptions: freezed == allOptions
            ? _value._allOptions
            : allOptions // ignore: cast_nullable_to_non_nullable
                  as List<DiscardOption>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PlayerRoundAnalysisImpl implements _PlayerRoundAnalysis {
  const _$PlayerRoundAnalysisImpl({
    required this.playerId,
    required this.isDealer,
    required final List<PlayingCard> dealtHand,
    required final List<PlayingCard> keptHand,
    required final List<PlayingCard> discarded,
    required this.actualHandScore,
    this.actualCribScore,
    required this.optimalDiscard,
    required this.playerDiscard,
    required this.evDifference,
    final List<DiscardOption>? allOptions,
  }) : _dealtHand = dealtHand,
       _keptHand = keptHand,
       _discarded = discarded,
       _allOptions = allOptions;

  factory _$PlayerRoundAnalysisImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlayerRoundAnalysisImplFromJson(json);

  @override
  final String playerId;
  @override
  final bool isDealer;
  final List<PlayingCard> _dealtHand;
  @override
  List<PlayingCard> get dealtHand {
    if (_dealtHand is EqualUnmodifiableListView) return _dealtHand;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_dealtHand);
  }

  final List<PlayingCard> _keptHand;
  @override
  List<PlayingCard> get keptHand {
    if (_keptHand is EqualUnmodifiableListView) return _keptHand;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_keptHand);
  }

  final List<PlayingCard> _discarded;
  @override
  List<PlayingCard> get discarded {
    if (_discarded is EqualUnmodifiableListView) return _discarded;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_discarded);
  }

  @override
  final int actualHandScore;
  @override
  final int? actualCribScore;
  @override
  final DiscardOption optimalDiscard;
  @override
  final DiscardOption playerDiscard;
  @override
  final double evDifference;
  final List<DiscardOption>? _allOptions;
  @override
  List<DiscardOption>? get allOptions {
    final value = _allOptions;
    if (value == null) return null;
    if (_allOptions is EqualUnmodifiableListView) return _allOptions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'PlayerRoundAnalysis(playerId: $playerId, isDealer: $isDealer, dealtHand: $dealtHand, keptHand: $keptHand, discarded: $discarded, actualHandScore: $actualHandScore, actualCribScore: $actualCribScore, optimalDiscard: $optimalDiscard, playerDiscard: $playerDiscard, evDifference: $evDifference, allOptions: $allOptions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayerRoundAnalysisImpl &&
            (identical(other.playerId, playerId) ||
                other.playerId == playerId) &&
            (identical(other.isDealer, isDealer) ||
                other.isDealer == isDealer) &&
            const DeepCollectionEquality().equals(
              other._dealtHand,
              _dealtHand,
            ) &&
            const DeepCollectionEquality().equals(other._keptHand, _keptHand) &&
            const DeepCollectionEquality().equals(
              other._discarded,
              _discarded,
            ) &&
            (identical(other.actualHandScore, actualHandScore) ||
                other.actualHandScore == actualHandScore) &&
            (identical(other.actualCribScore, actualCribScore) ||
                other.actualCribScore == actualCribScore) &&
            (identical(other.optimalDiscard, optimalDiscard) ||
                other.optimalDiscard == optimalDiscard) &&
            (identical(other.playerDiscard, playerDiscard) ||
                other.playerDiscard == playerDiscard) &&
            (identical(other.evDifference, evDifference) ||
                other.evDifference == evDifference) &&
            const DeepCollectionEquality().equals(
              other._allOptions,
              _allOptions,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    playerId,
    isDealer,
    const DeepCollectionEquality().hash(_dealtHand),
    const DeepCollectionEquality().hash(_keptHand),
    const DeepCollectionEquality().hash(_discarded),
    actualHandScore,
    actualCribScore,
    optimalDiscard,
    playerDiscard,
    evDifference,
    const DeepCollectionEquality().hash(_allOptions),
  );

  /// Create a copy of PlayerRoundAnalysis
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayerRoundAnalysisImplCopyWith<_$PlayerRoundAnalysisImpl> get copyWith =>
      __$$PlayerRoundAnalysisImplCopyWithImpl<_$PlayerRoundAnalysisImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PlayerRoundAnalysisImplToJson(this);
  }
}

abstract class _PlayerRoundAnalysis implements PlayerRoundAnalysis {
  const factory _PlayerRoundAnalysis({
    required final String playerId,
    required final bool isDealer,
    required final List<PlayingCard> dealtHand,
    required final List<PlayingCard> keptHand,
    required final List<PlayingCard> discarded,
    required final int actualHandScore,
    final int? actualCribScore,
    required final DiscardOption optimalDiscard,
    required final DiscardOption playerDiscard,
    required final double evDifference,
    final List<DiscardOption>? allOptions,
  }) = _$PlayerRoundAnalysisImpl;

  factory _PlayerRoundAnalysis.fromJson(Map<String, dynamic> json) =
      _$PlayerRoundAnalysisImpl.fromJson;

  @override
  String get playerId;
  @override
  bool get isDealer;
  @override
  List<PlayingCard> get dealtHand;
  @override
  List<PlayingCard> get keptHand;
  @override
  List<PlayingCard> get discarded;
  @override
  int get actualHandScore;
  @override
  int? get actualCribScore;
  @override
  DiscardOption get optimalDiscard;
  @override
  DiscardOption get playerDiscard;
  @override
  double get evDifference;
  @override
  List<DiscardOption>? get allOptions;

  /// Create a copy of PlayerRoundAnalysis
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlayerRoundAnalysisImplCopyWith<_$PlayerRoundAnalysisImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RoundAnalysis _$RoundAnalysisFromJson(Map<String, dynamic> json) {
  return _RoundAnalysis.fromJson(json);
}

/// @nodoc
mixin _$RoundAnalysis {
  int get roundNumber => throw _privateConstructorUsedError;
  PlayingCard? get cutCard => throw _privateConstructorUsedError;
  String get dealerPlayerId => throw _privateConstructorUsedError;
  List<PlayerRoundAnalysis> get playerAnalyses =>
      throw _privateConstructorUsedError;

  /// Serializes this RoundAnalysis to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RoundAnalysis
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RoundAnalysisCopyWith<RoundAnalysis> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RoundAnalysisCopyWith<$Res> {
  factory $RoundAnalysisCopyWith(
    RoundAnalysis value,
    $Res Function(RoundAnalysis) then,
  ) = _$RoundAnalysisCopyWithImpl<$Res, RoundAnalysis>;
  @useResult
  $Res call({
    int roundNumber,
    PlayingCard? cutCard,
    String dealerPlayerId,
    List<PlayerRoundAnalysis> playerAnalyses,
  });

  $PlayingCardCopyWith<$Res>? get cutCard;
}

/// @nodoc
class _$RoundAnalysisCopyWithImpl<$Res, $Val extends RoundAnalysis>
    implements $RoundAnalysisCopyWith<$Res> {
  _$RoundAnalysisCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RoundAnalysis
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? roundNumber = null,
    Object? cutCard = freezed,
    Object? dealerPlayerId = null,
    Object? playerAnalyses = null,
  }) {
    return _then(
      _value.copyWith(
            roundNumber: null == roundNumber
                ? _value.roundNumber
                : roundNumber // ignore: cast_nullable_to_non_nullable
                      as int,
            cutCard: freezed == cutCard
                ? _value.cutCard
                : cutCard // ignore: cast_nullable_to_non_nullable
                      as PlayingCard?,
            dealerPlayerId: null == dealerPlayerId
                ? _value.dealerPlayerId
                : dealerPlayerId // ignore: cast_nullable_to_non_nullable
                      as String,
            playerAnalyses: null == playerAnalyses
                ? _value.playerAnalyses
                : playerAnalyses // ignore: cast_nullable_to_non_nullable
                      as List<PlayerRoundAnalysis>,
          )
          as $Val,
    );
  }

  /// Create a copy of RoundAnalysis
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PlayingCardCopyWith<$Res>? get cutCard {
    if (_value.cutCard == null) {
      return null;
    }

    return $PlayingCardCopyWith<$Res>(_value.cutCard!, (value) {
      return _then(_value.copyWith(cutCard: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$RoundAnalysisImplCopyWith<$Res>
    implements $RoundAnalysisCopyWith<$Res> {
  factory _$$RoundAnalysisImplCopyWith(
    _$RoundAnalysisImpl value,
    $Res Function(_$RoundAnalysisImpl) then,
  ) = __$$RoundAnalysisImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int roundNumber,
    PlayingCard? cutCard,
    String dealerPlayerId,
    List<PlayerRoundAnalysis> playerAnalyses,
  });

  @override
  $PlayingCardCopyWith<$Res>? get cutCard;
}

/// @nodoc
class __$$RoundAnalysisImplCopyWithImpl<$Res>
    extends _$RoundAnalysisCopyWithImpl<$Res, _$RoundAnalysisImpl>
    implements _$$RoundAnalysisImplCopyWith<$Res> {
  __$$RoundAnalysisImplCopyWithImpl(
    _$RoundAnalysisImpl _value,
    $Res Function(_$RoundAnalysisImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RoundAnalysis
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? roundNumber = null,
    Object? cutCard = freezed,
    Object? dealerPlayerId = null,
    Object? playerAnalyses = null,
  }) {
    return _then(
      _$RoundAnalysisImpl(
        roundNumber: null == roundNumber
            ? _value.roundNumber
            : roundNumber // ignore: cast_nullable_to_non_nullable
                  as int,
        cutCard: freezed == cutCard
            ? _value.cutCard
            : cutCard // ignore: cast_nullable_to_non_nullable
                  as PlayingCard?,
        dealerPlayerId: null == dealerPlayerId
            ? _value.dealerPlayerId
            : dealerPlayerId // ignore: cast_nullable_to_non_nullable
                  as String,
        playerAnalyses: null == playerAnalyses
            ? _value._playerAnalyses
            : playerAnalyses // ignore: cast_nullable_to_non_nullable
                  as List<PlayerRoundAnalysis>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RoundAnalysisImpl implements _RoundAnalysis {
  const _$RoundAnalysisImpl({
    required this.roundNumber,
    this.cutCard,
    required this.dealerPlayerId,
    required final List<PlayerRoundAnalysis> playerAnalyses,
  }) : _playerAnalyses = playerAnalyses;

  factory _$RoundAnalysisImpl.fromJson(Map<String, dynamic> json) =>
      _$$RoundAnalysisImplFromJson(json);

  @override
  final int roundNumber;
  @override
  final PlayingCard? cutCard;
  @override
  final String dealerPlayerId;
  final List<PlayerRoundAnalysis> _playerAnalyses;
  @override
  List<PlayerRoundAnalysis> get playerAnalyses {
    if (_playerAnalyses is EqualUnmodifiableListView) return _playerAnalyses;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_playerAnalyses);
  }

  @override
  String toString() {
    return 'RoundAnalysis(roundNumber: $roundNumber, cutCard: $cutCard, dealerPlayerId: $dealerPlayerId, playerAnalyses: $playerAnalyses)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RoundAnalysisImpl &&
            (identical(other.roundNumber, roundNumber) ||
                other.roundNumber == roundNumber) &&
            (identical(other.cutCard, cutCard) || other.cutCard == cutCard) &&
            (identical(other.dealerPlayerId, dealerPlayerId) ||
                other.dealerPlayerId == dealerPlayerId) &&
            const DeepCollectionEquality().equals(
              other._playerAnalyses,
              _playerAnalyses,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    roundNumber,
    cutCard,
    dealerPlayerId,
    const DeepCollectionEquality().hash(_playerAnalyses),
  );

  /// Create a copy of RoundAnalysis
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RoundAnalysisImplCopyWith<_$RoundAnalysisImpl> get copyWith =>
      __$$RoundAnalysisImplCopyWithImpl<_$RoundAnalysisImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RoundAnalysisImplToJson(this);
  }
}

abstract class _RoundAnalysis implements RoundAnalysis {
  const factory _RoundAnalysis({
    required final int roundNumber,
    final PlayingCard? cutCard,
    required final String dealerPlayerId,
    required final List<PlayerRoundAnalysis> playerAnalyses,
  }) = _$RoundAnalysisImpl;

  factory _RoundAnalysis.fromJson(Map<String, dynamic> json) =
      _$RoundAnalysisImpl.fromJson;

  @override
  int get roundNumber;
  @override
  PlayingCard? get cutCard;
  @override
  String get dealerPlayerId;
  @override
  List<PlayerRoundAnalysis> get playerAnalyses;

  /// Create a copy of RoundAnalysis
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RoundAnalysisImplCopyWith<_$RoundAnalysisImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GameAnalysis _$GameAnalysisFromJson(Map<String, dynamic> json) {
  return _GameAnalysis.fromJson(json);
}

/// @nodoc
mixin _$GameAnalysis {
  String get gameId => throw _privateConstructorUsedError;
  List<RoundAnalysis> get rounds => throw _privateConstructorUsedError;

  /// Serializes this GameAnalysis to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GameAnalysis
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GameAnalysisCopyWith<GameAnalysis> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GameAnalysisCopyWith<$Res> {
  factory $GameAnalysisCopyWith(
    GameAnalysis value,
    $Res Function(GameAnalysis) then,
  ) = _$GameAnalysisCopyWithImpl<$Res, GameAnalysis>;
  @useResult
  $Res call({String gameId, List<RoundAnalysis> rounds});
}

/// @nodoc
class _$GameAnalysisCopyWithImpl<$Res, $Val extends GameAnalysis>
    implements $GameAnalysisCopyWith<$Res> {
  _$GameAnalysisCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GameAnalysis
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? gameId = null, Object? rounds = null}) {
    return _then(
      _value.copyWith(
            gameId: null == gameId
                ? _value.gameId
                : gameId // ignore: cast_nullable_to_non_nullable
                      as String,
            rounds: null == rounds
                ? _value.rounds
                : rounds // ignore: cast_nullable_to_non_nullable
                      as List<RoundAnalysis>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GameAnalysisImplCopyWith<$Res>
    implements $GameAnalysisCopyWith<$Res> {
  factory _$$GameAnalysisImplCopyWith(
    _$GameAnalysisImpl value,
    $Res Function(_$GameAnalysisImpl) then,
  ) = __$$GameAnalysisImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String gameId, List<RoundAnalysis> rounds});
}

/// @nodoc
class __$$GameAnalysisImplCopyWithImpl<$Res>
    extends _$GameAnalysisCopyWithImpl<$Res, _$GameAnalysisImpl>
    implements _$$GameAnalysisImplCopyWith<$Res> {
  __$$GameAnalysisImplCopyWithImpl(
    _$GameAnalysisImpl _value,
    $Res Function(_$GameAnalysisImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GameAnalysis
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? gameId = null, Object? rounds = null}) {
    return _then(
      _$GameAnalysisImpl(
        gameId: null == gameId
            ? _value.gameId
            : gameId // ignore: cast_nullable_to_non_nullable
                  as String,
        rounds: null == rounds
            ? _value._rounds
            : rounds // ignore: cast_nullable_to_non_nullable
                  as List<RoundAnalysis>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GameAnalysisImpl implements _GameAnalysis {
  const _$GameAnalysisImpl({
    required this.gameId,
    required final List<RoundAnalysis> rounds,
  }) : _rounds = rounds;

  factory _$GameAnalysisImpl.fromJson(Map<String, dynamic> json) =>
      _$$GameAnalysisImplFromJson(json);

  @override
  final String gameId;
  final List<RoundAnalysis> _rounds;
  @override
  List<RoundAnalysis> get rounds {
    if (_rounds is EqualUnmodifiableListView) return _rounds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_rounds);
  }

  @override
  String toString() {
    return 'GameAnalysis(gameId: $gameId, rounds: $rounds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GameAnalysisImpl &&
            (identical(other.gameId, gameId) || other.gameId == gameId) &&
            const DeepCollectionEquality().equals(other._rounds, _rounds));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    gameId,
    const DeepCollectionEquality().hash(_rounds),
  );

  /// Create a copy of GameAnalysis
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GameAnalysisImplCopyWith<_$GameAnalysisImpl> get copyWith =>
      __$$GameAnalysisImplCopyWithImpl<_$GameAnalysisImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GameAnalysisImplToJson(this);
  }
}

abstract class _GameAnalysis implements GameAnalysis {
  const factory _GameAnalysis({
    required final String gameId,
    required final List<RoundAnalysis> rounds,
  }) = _$GameAnalysisImpl;

  factory _GameAnalysis.fromJson(Map<String, dynamic> json) =
      _$GameAnalysisImpl.fromJson;

  @override
  String get gameId;
  @override
  List<RoundAnalysis> get rounds;

  /// Create a copy of GameAnalysis
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GameAnalysisImplCopyWith<_$GameAnalysisImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
