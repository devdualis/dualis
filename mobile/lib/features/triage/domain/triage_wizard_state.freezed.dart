// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'triage_wizard_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TriageWizardState {

 TriageVertical get activeVertical; int get currentStep; Map<int, String> get answers; bool get isCompleting;
/// Create a copy of TriageWizardState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TriageWizardStateCopyWith<TriageWizardState> get copyWith => _$TriageWizardStateCopyWithImpl<TriageWizardState>(this as TriageWizardState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TriageWizardState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TriageWizardState&&(identical(other.activeVertical, _this.activeVertical) || other.activeVertical == _this.activeVertical)&&(identical(other.currentStep, _this.currentStep) || other.currentStep == _this.currentStep)&&const DeepCollectionEquality().equals(other.answers, _this.answers)&&(identical(other.isCompleting, _this.isCompleting) || other.isCompleting == _this.isCompleting));
}


@override
int get hashCode {
  final _this = this as TriageWizardState;
  return Object.hash(runtimeType,_this.activeVertical,_this.currentStep,const DeepCollectionEquality().hash(_this.answers),_this.isCompleting);
}

@override
String toString() {
  final _this = this as TriageWizardState;
  return 'TriageWizardState(activeVertical: ${_this.activeVertical}, currentStep: ${_this.currentStep}, answers: ${_this.answers}, isCompleting: ${_this.isCompleting})';
}


}

/// @nodoc
abstract mixin class $TriageWizardStateCopyWith<$Res>  {
  factory $TriageWizardStateCopyWith(TriageWizardState value, $Res Function(TriageWizardState) _then) = _$TriageWizardStateCopyWithImpl;
@useResult
$Res call({
 TriageVertical activeVertical, int currentStep, Map<int, String> answers, bool isCompleting
});




}
/// @nodoc
class _$TriageWizardStateCopyWithImpl<$Res>
    implements $TriageWizardStateCopyWith<$Res> {
  _$TriageWizardStateCopyWithImpl(this._self, this._then);

  final TriageWizardState _self;
  final $Res Function(TriageWizardState) _then;

/// Create a copy of TriageWizardState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? activeVertical = null,Object? currentStep = null,Object? answers = null,Object? isCompleting = null,}) {
  return _then(TriageWizardState(
activeVertical: null == activeVertical ? _self.activeVertical : activeVertical // ignore: cast_nullable_to_non_nullable
as TriageVertical,currentStep: null == currentStep ? _self.currentStep : currentStep // ignore: cast_nullable_to_non_nullable
as int,answers: null == answers ? _self.answers : answers // ignore: cast_nullable_to_non_nullable
as Map<int, String>,isCompleting: null == isCompleting ? _self.isCompleting : isCompleting // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [TriageWizardState].
extension TriageWizardStatePatterns on TriageWizardState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TriageWizardState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TriageWizardState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TriageWizardState value)  $default,){
final _that = this;
switch (_that) {
case _TriageWizardState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TriageWizardState value)?  $default,){
final _that = this;
switch (_that) {
case _TriageWizardState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TriageVertical activeVertical,  int currentStep,  Map<int, String> answers,  bool isCompleting)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TriageWizardState() when $default != null:
return $default(_that.activeVertical,_that.currentStep,_that.answers,_that.isCompleting);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TriageVertical activeVertical,  int currentStep,  Map<int, String> answers,  bool isCompleting)  $default,) {final _that = this;
switch (_that) {
case _TriageWizardState():
return $default(_that.activeVertical,_that.currentStep,_that.answers,_that.isCompleting);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TriageVertical activeVertical,  int currentStep,  Map<int, String> answers,  bool isCompleting)?  $default,) {final _that = this;
switch (_that) {
case _TriageWizardState() when $default != null:
return $default(_that.activeVertical,_that.currentStep,_that.answers,_that.isCompleting);case _:
  return null;

}
}

}

/// @nodoc


class _TriageWizardState extends TriageWizardState {
  const _TriageWizardState({this.activeVertical = TriageVertical.psicoEmocional, this.currentStep = 0,  Map<int, String> answers = const <int, String>{}, this.isCompleting = false}): _answers = answers,super._();
  

@override@JsonKey() final  TriageVertical activeVertical;
@override@JsonKey() final  int currentStep;
 final  Map<int, String> _answers;
@override@JsonKey() Map<int, String> get answers {
  if (_answers is EqualUnmodifiableMapView) return _answers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_answers);
}

@override@JsonKey() final  bool isCompleting;

/// Create a copy of TriageWizardState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TriageWizardStateCopyWith<_TriageWizardState> get copyWith => __$TriageWizardStateCopyWithImpl<_TriageWizardState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TriageWizardState&&(identical(other.activeVertical, activeVertical) || other.activeVertical == activeVertical)&&(identical(other.currentStep, currentStep) || other.currentStep == currentStep)&&const DeepCollectionEquality().equals(other.answers, _answers)&&(identical(other.isCompleting, isCompleting) || other.isCompleting == isCompleting));
}


@override
int get hashCode {
    return Object.hash(runtimeType,activeVertical,currentStep,const DeepCollectionEquality().hash(_answers),isCompleting);
}

@override
String toString() {
    return 'TriageWizardState(activeVertical: $activeVertical, currentStep: $currentStep, answers: $answers, isCompleting: $isCompleting)';
}


}

/// @nodoc
abstract mixin class _$TriageWizardStateCopyWith<$Res> implements $TriageWizardStateCopyWith<$Res> {
  factory _$TriageWizardStateCopyWith(_TriageWizardState value, $Res Function(_TriageWizardState) _then) = __$TriageWizardStateCopyWithImpl;
@override @useResult
$Res call({
 TriageVertical activeVertical, int currentStep, Map<int, String> answers, bool isCompleting
});




}
/// @nodoc
class __$TriageWizardStateCopyWithImpl<$Res>
    implements _$TriageWizardStateCopyWith<$Res> {
  __$TriageWizardStateCopyWithImpl(this._self, this._then);

  final _TriageWizardState _self;
  final $Res Function(_TriageWizardState) _then;

/// Create a copy of TriageWizardState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? activeVertical = null,Object? currentStep = null,Object? answers = null,Object? isCompleting = null,}) {
  return _then(_TriageWizardState(
activeVertical: null == activeVertical ? _self.activeVertical : activeVertical // ignore: cast_nullable_to_non_nullable
as TriageVertical,currentStep: null == currentStep ? _self.currentStep : currentStep // ignore: cast_nullable_to_non_nullable
as int,answers: null == answers ? _self._answers : answers // ignore: cast_nullable_to_non_nullable
as Map<int, String>,isCompleting: null == isCompleting ? _self.isCompleting : isCompleting // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
