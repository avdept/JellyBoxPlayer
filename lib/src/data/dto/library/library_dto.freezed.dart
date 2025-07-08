// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'library_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LibraryDTO {

@JsonKey(name: 'Id') String get id;@JsonKey(name: 'Name') String? get name;@JsonKey(name: 'Path') String? get path;@JsonKey(name: 'Type') String? get type;@JsonKey(name: 'CollectionType') String? get collectionType;@JsonKey(name: 'ImageTags') Map<String, String> get imageTags;
/// Create a copy of LibraryDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LibraryDTOCopyWith<LibraryDTO> get copyWith => _$LibraryDTOCopyWithImpl<LibraryDTO>(this as LibraryDTO, _$identity);

  /// Serializes this LibraryDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LibraryDTO&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.path, path) || other.path == path)&&(identical(other.type, type) || other.type == type)&&(identical(other.collectionType, collectionType) || other.collectionType == collectionType)&&const DeepCollectionEquality().equals(other.imageTags, imageTags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,path,type,collectionType,const DeepCollectionEquality().hash(imageTags));

@override
String toString() {
  return 'LibraryDTO(id: $id, name: $name, path: $path, type: $type, collectionType: $collectionType, imageTags: $imageTags)';
}


}

/// @nodoc
abstract mixin class $LibraryDTOCopyWith<$Res>  {
  factory $LibraryDTOCopyWith(LibraryDTO value, $Res Function(LibraryDTO) _then) = _$LibraryDTOCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'Id') String id,@JsonKey(name: 'Name') String? name,@JsonKey(name: 'Path') String? path,@JsonKey(name: 'Type') String? type,@JsonKey(name: 'CollectionType') String? collectionType,@JsonKey(name: 'ImageTags') Map<String, String> imageTags
});




}
/// @nodoc
class _$LibraryDTOCopyWithImpl<$Res>
    implements $LibraryDTOCopyWith<$Res> {
  _$LibraryDTOCopyWithImpl(this._self, this._then);

  final LibraryDTO _self;
  final $Res Function(LibraryDTO) _then;

/// Create a copy of LibraryDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = freezed,Object? path = freezed,Object? type = freezed,Object? collectionType = freezed,Object? imageTags = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,path: freezed == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String?,collectionType: freezed == collectionType ? _self.collectionType : collectionType // ignore: cast_nullable_to_non_nullable
as String?,imageTags: null == imageTags ? _self.imageTags : imageTags // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

}


/// Adds pattern-matching-related methods to [LibraryDTO].
extension LibraryDTOPatterns on LibraryDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LibraryDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LibraryDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LibraryDTO value)  $default,){
final _that = this;
switch (_that) {
case _LibraryDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LibraryDTO value)?  $default,){
final _that = this;
switch (_that) {
case _LibraryDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'Id')  String id, @JsonKey(name: 'Name')  String? name, @JsonKey(name: 'Path')  String? path, @JsonKey(name: 'Type')  String? type, @JsonKey(name: 'CollectionType')  String? collectionType, @JsonKey(name: 'ImageTags')  Map<String, String> imageTags)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LibraryDTO() when $default != null:
return $default(_that.id,_that.name,_that.path,_that.type,_that.collectionType,_that.imageTags);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'Id')  String id, @JsonKey(name: 'Name')  String? name, @JsonKey(name: 'Path')  String? path, @JsonKey(name: 'Type')  String? type, @JsonKey(name: 'CollectionType')  String? collectionType, @JsonKey(name: 'ImageTags')  Map<String, String> imageTags)  $default,) {final _that = this;
switch (_that) {
case _LibraryDTO():
return $default(_that.id,_that.name,_that.path,_that.type,_that.collectionType,_that.imageTags);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'Id')  String id, @JsonKey(name: 'Name')  String? name, @JsonKey(name: 'Path')  String? path, @JsonKey(name: 'Type')  String? type, @JsonKey(name: 'CollectionType')  String? collectionType, @JsonKey(name: 'ImageTags')  Map<String, String> imageTags)?  $default,) {final _that = this;
switch (_that) {
case _LibraryDTO() when $default != null:
return $default(_that.id,_that.name,_that.path,_that.type,_that.collectionType,_that.imageTags);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LibraryDTO implements LibraryDTO {
  const _LibraryDTO({@JsonKey(name: 'Id') required this.id, @JsonKey(name: 'Name') this.name, @JsonKey(name: 'Path') this.path, @JsonKey(name: 'Type') this.type, @JsonKey(name: 'CollectionType') this.collectionType, @JsonKey(name: 'ImageTags') final  Map<String, String> imageTags = const {}}): _imageTags = imageTags;
  factory _LibraryDTO.fromJson(Map<String, dynamic> json) => _$LibraryDTOFromJson(json);

@override@JsonKey(name: 'Id') final  String id;
@override@JsonKey(name: 'Name') final  String? name;
@override@JsonKey(name: 'Path') final  String? path;
@override@JsonKey(name: 'Type') final  String? type;
@override@JsonKey(name: 'CollectionType') final  String? collectionType;
 final  Map<String, String> _imageTags;
@override@JsonKey(name: 'ImageTags') Map<String, String> get imageTags {
  if (_imageTags is EqualUnmodifiableMapView) return _imageTags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_imageTags);
}


/// Create a copy of LibraryDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LibraryDTOCopyWith<_LibraryDTO> get copyWith => __$LibraryDTOCopyWithImpl<_LibraryDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LibraryDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LibraryDTO&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.path, path) || other.path == path)&&(identical(other.type, type) || other.type == type)&&(identical(other.collectionType, collectionType) || other.collectionType == collectionType)&&const DeepCollectionEquality().equals(other._imageTags, _imageTags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,path,type,collectionType,const DeepCollectionEquality().hash(_imageTags));

@override
String toString() {
  return 'LibraryDTO(id: $id, name: $name, path: $path, type: $type, collectionType: $collectionType, imageTags: $imageTags)';
}


}

/// @nodoc
abstract mixin class _$LibraryDTOCopyWith<$Res> implements $LibraryDTOCopyWith<$Res> {
  factory _$LibraryDTOCopyWith(_LibraryDTO value, $Res Function(_LibraryDTO) _then) = __$LibraryDTOCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'Id') String id,@JsonKey(name: 'Name') String? name,@JsonKey(name: 'Path') String? path,@JsonKey(name: 'Type') String? type,@JsonKey(name: 'CollectionType') String? collectionType,@JsonKey(name: 'ImageTags') Map<String, String> imageTags
});




}
/// @nodoc
class __$LibraryDTOCopyWithImpl<$Res>
    implements _$LibraryDTOCopyWith<$Res> {
  __$LibraryDTOCopyWithImpl(this._self, this._then);

  final _LibraryDTO _self;
  final $Res Function(_LibraryDTO) _then;

/// Create a copy of LibraryDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = freezed,Object? path = freezed,Object? type = freezed,Object? collectionType = freezed,Object? imageTags = null,}) {
  return _then(_LibraryDTO(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,path: freezed == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String?,collectionType: freezed == collectionType ? _self.collectionType : collectionType // ignore: cast_nullable_to_non_nullable
as String?,imageTags: null == imageTags ? _self._imageTags : imageTags // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}


}


/// @nodoc
mixin _$Libraries {

@JsonKey(name: 'Items') List<LibraryDTO> get libraries;
/// Create a copy of Libraries
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LibrariesCopyWith<Libraries> get copyWith => _$LibrariesCopyWithImpl<Libraries>(this as Libraries, _$identity);

  /// Serializes this Libraries to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Libraries&&const DeepCollectionEquality().equals(other.libraries, libraries));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(libraries));

@override
String toString() {
  return 'Libraries(libraries: $libraries)';
}


}

/// @nodoc
abstract mixin class $LibrariesCopyWith<$Res>  {
  factory $LibrariesCopyWith(Libraries value, $Res Function(Libraries) _then) = _$LibrariesCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'Items') List<LibraryDTO> libraries
});




}
/// @nodoc
class _$LibrariesCopyWithImpl<$Res>
    implements $LibrariesCopyWith<$Res> {
  _$LibrariesCopyWithImpl(this._self, this._then);

  final Libraries _self;
  final $Res Function(Libraries) _then;

/// Create a copy of Libraries
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? libraries = null,}) {
  return _then(_self.copyWith(
libraries: null == libraries ? _self.libraries : libraries // ignore: cast_nullable_to_non_nullable
as List<LibraryDTO>,
  ));
}

}


/// Adds pattern-matching-related methods to [Libraries].
extension LibrariesPatterns on Libraries {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Libraries value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Libraries() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Libraries value)  $default,){
final _that = this;
switch (_that) {
case _Libraries():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Libraries value)?  $default,){
final _that = this;
switch (_that) {
case _Libraries() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'Items')  List<LibraryDTO> libraries)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Libraries() when $default != null:
return $default(_that.libraries);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'Items')  List<LibraryDTO> libraries)  $default,) {final _that = this;
switch (_that) {
case _Libraries():
return $default(_that.libraries);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'Items')  List<LibraryDTO> libraries)?  $default,) {final _that = this;
switch (_that) {
case _Libraries() when $default != null:
return $default(_that.libraries);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Libraries implements Libraries {
  const _Libraries({@JsonKey(name: 'Items') required final  List<LibraryDTO> libraries}): _libraries = libraries;
  factory _Libraries.fromJson(Map<String, dynamic> json) => _$LibrariesFromJson(json);

 final  List<LibraryDTO> _libraries;
@override@JsonKey(name: 'Items') List<LibraryDTO> get libraries {
  if (_libraries is EqualUnmodifiableListView) return _libraries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_libraries);
}


/// Create a copy of Libraries
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LibrariesCopyWith<_Libraries> get copyWith => __$LibrariesCopyWithImpl<_Libraries>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LibrariesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Libraries&&const DeepCollectionEquality().equals(other._libraries, _libraries));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_libraries));

@override
String toString() {
  return 'Libraries(libraries: $libraries)';
}


}

/// @nodoc
abstract mixin class _$LibrariesCopyWith<$Res> implements $LibrariesCopyWith<$Res> {
  factory _$LibrariesCopyWith(_Libraries value, $Res Function(_Libraries) _then) = __$LibrariesCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'Items') List<LibraryDTO> libraries
});




}
/// @nodoc
class __$LibrariesCopyWithImpl<$Res>
    implements _$LibrariesCopyWith<$Res> {
  __$LibrariesCopyWithImpl(this._self, this._then);

  final _Libraries _self;
  final $Res Function(_Libraries) _then;

/// Create a copy of Libraries
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? libraries = null,}) {
  return _then(_Libraries(
libraries: null == libraries ? _self._libraries : libraries // ignore: cast_nullable_to_non_nullable
as List<LibraryDTO>,
  ));
}


}

// dart format on
