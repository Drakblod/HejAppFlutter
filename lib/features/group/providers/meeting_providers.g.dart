// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meeting_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(groupProposals)
const groupProposalsProvider = GroupProposalsFamily._();

final class GroupProposalsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MeetingProposal>>,
          List<MeetingProposal>,
          Stream<List<MeetingProposal>>
        >
    with
        $FutureModifier<List<MeetingProposal>>,
        $StreamProvider<List<MeetingProposal>> {
  const GroupProposalsProvider._({
    required GroupProposalsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'groupProposalsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$groupProposalsHash();

  @override
  String toString() {
    return r'groupProposalsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<MeetingProposal>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<MeetingProposal>> create(Ref ref) {
    final argument = this.argument as String;
    return groupProposals(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupProposalsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$groupProposalsHash() => r'2db615131a3a2cc1ef7dabd58b9636f362e20aed';

final class GroupProposalsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<MeetingProposal>>, String> {
  const GroupProposalsFamily._()
    : super(
        retry: null,
        name: r'groupProposalsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GroupProposalsProvider call(String groupId) =>
      GroupProposalsProvider._(argument: groupId, from: this);

  @override
  String toString() => r'groupProposalsProvider';
}

@ProviderFor(activeProposals)
const activeProposalsProvider = ActiveProposalsFamily._();

final class ActiveProposalsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MeetingProposal>>,
          List<MeetingProposal>,
          Stream<List<MeetingProposal>>
        >
    with
        $FutureModifier<List<MeetingProposal>>,
        $StreamProvider<List<MeetingProposal>> {
  const ActiveProposalsProvider._({
    required ActiveProposalsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'activeProposalsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$activeProposalsHash();

  @override
  String toString() {
    return r'activeProposalsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<MeetingProposal>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<MeetingProposal>> create(Ref ref) {
    final argument = this.argument as String;
    return activeProposals(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ActiveProposalsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$activeProposalsHash() => r'2e9209066329e403948f8cb0625edd22bf0a665e';

final class ActiveProposalsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<MeetingProposal>>, String> {
  const ActiveProposalsFamily._()
    : super(
        retry: null,
        name: r'activeProposalsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ActiveProposalsProvider call(String groupId) =>
      ActiveProposalsProvider._(argument: groupId, from: this);

  @override
  String toString() => r'activeProposalsProvider';
}

@ProviderFor(confirmedMeetings)
const confirmedMeetingsProvider = ConfirmedMeetingsFamily._();

final class ConfirmedMeetingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MeetingProposal>>,
          List<MeetingProposal>,
          Stream<List<MeetingProposal>>
        >
    with
        $FutureModifier<List<MeetingProposal>>,
        $StreamProvider<List<MeetingProposal>> {
  const ConfirmedMeetingsProvider._({
    required ConfirmedMeetingsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'confirmedMeetingsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$confirmedMeetingsHash();

  @override
  String toString() {
    return r'confirmedMeetingsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<MeetingProposal>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<MeetingProposal>> create(Ref ref) {
    final argument = this.argument as String;
    return confirmedMeetings(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ConfirmedMeetingsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$confirmedMeetingsHash() => r'936e0cecd395356e76eade6f31140d4d2fc31e6f';

final class ConfirmedMeetingsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<MeetingProposal>>, String> {
  const ConfirmedMeetingsFamily._()
    : super(
        retry: null,
        name: r'confirmedMeetingsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ConfirmedMeetingsProvider call(String groupId) =>
      ConfirmedMeetingsProvider._(argument: groupId, from: this);

  @override
  String toString() => r'confirmedMeetingsProvider';
}
