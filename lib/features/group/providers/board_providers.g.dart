// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'board_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(groupMeta)
const groupMetaProvider = GroupMetaFamily._();

final class GroupMetaProvider
    extends $FunctionalProvider<AsyncValue<Group?>, Group?, FutureOr<Group?>>
    with $FutureModifier<Group?>, $FutureProvider<Group?> {
  const GroupMetaProvider._({
    required GroupMetaFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'groupMetaProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$groupMetaHash();

  @override
  String toString() {
    return r'groupMetaProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Group?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Group?> create(Ref ref) {
    final argument = this.argument as String;
    return groupMeta(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupMetaProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$groupMetaHash() => r'60835dd488ec6cb69dd2987cbd07219a185f0aa8';

final class GroupMetaFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Group?>, String> {
  const GroupMetaFamily._()
    : super(
        retry: null,
        name: r'groupMetaProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GroupMetaProvider call(String groupId) =>
      GroupMetaProvider._(argument: groupId, from: this);

  @override
  String toString() => r'groupMetaProvider';
}

@ProviderFor(boardItems)
const boardItemsProvider = BoardItemsFamily._();

final class BoardItemsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BoardItem>>,
          List<BoardItem>,
          Stream<List<BoardItem>>
        >
    with $FutureModifier<List<BoardItem>>, $StreamProvider<List<BoardItem>> {
  const BoardItemsProvider._({
    required BoardItemsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'boardItemsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$boardItemsHash();

  @override
  String toString() {
    return r'boardItemsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<BoardItem>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<BoardItem>> create(Ref ref) {
    final argument = this.argument as String;
    return boardItems(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BoardItemsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$boardItemsHash() => r'5e45300f54d9a3a701b8aca3ac40f6ad7d4a706c';

final class BoardItemsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<BoardItem>>, String> {
  const BoardItemsFamily._()
    : super(
        retry: null,
        name: r'boardItemsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BoardItemsProvider call(String groupId) =>
      BoardItemsProvider._(argument: groupId, from: this);

  @override
  String toString() => r'boardItemsProvider';
}

@ProviderFor(groupMembers)
const groupMembersProvider = GroupMembersFamily._();

final class GroupMembersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<({GroupMember member, UserProfile? profile})>>,
          List<({GroupMember member, UserProfile? profile})>,
          Stream<List<({GroupMember member, UserProfile? profile})>>
        >
    with
        $FutureModifier<List<({GroupMember member, UserProfile? profile})>>,
        $StreamProvider<List<({GroupMember member, UserProfile? profile})>> {
  const GroupMembersProvider._({
    required GroupMembersFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'groupMembersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$groupMembersHash();

  @override
  String toString() {
    return r'groupMembersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<({GroupMember member, UserProfile? profile})>>
  $createElement($ProviderPointer pointer) => $StreamProviderElement(pointer);

  @override
  Stream<List<({GroupMember member, UserProfile? profile})>> create(Ref ref) {
    final argument = this.argument as String;
    return groupMembers(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupMembersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$groupMembersHash() => r'61c24606b2629dd23a0b74dd35bc09b09f02bdc8';

final class GroupMembersFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<({GroupMember member, UserProfile? profile})>>,
          String
        > {
  const GroupMembersFamily._()
    : super(
        retry: null,
        name: r'groupMembersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GroupMembersProvider call(String groupId) =>
      GroupMembersProvider._(argument: groupId, from: this);

  @override
  String toString() => r'groupMembersProvider';
}
