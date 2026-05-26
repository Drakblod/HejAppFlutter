// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'files_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sharedFiles)
const sharedFilesProvider = SharedFilesFamily._();

final class SharedFilesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SharedFile>>,
          List<SharedFile>,
          Stream<List<SharedFile>>
        >
    with $FutureModifier<List<SharedFile>>, $StreamProvider<List<SharedFile>> {
  const SharedFilesProvider._({
    required SharedFilesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'sharedFilesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sharedFilesHash();

  @override
  String toString() {
    return r'sharedFilesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<SharedFile>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SharedFile>> create(Ref ref) {
    final argument = this.argument as String;
    return sharedFiles(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SharedFilesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sharedFilesHash() => r'266d01b5f5cd20bfc3f6744c97fd81443c9fb4d6';

final class SharedFilesFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<SharedFile>>, String> {
  const SharedFilesFamily._()
    : super(
        retry: null,
        name: r'sharedFilesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SharedFilesProvider call(String groupId) =>
      SharedFilesProvider._(argument: groupId, from: this);

  @override
  String toString() => r'sharedFilesProvider';
}

@ProviderFor(FilesController)
const filesControllerProvider = FilesControllerProvider._();

final class FilesControllerProvider
    extends $AsyncNotifierProvider<FilesController, void> {
  const FilesControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filesControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filesControllerHash();

  @$internal
  @override
  FilesController create() => FilesController();
}

String _$filesControllerHash() => r'206c2362d1ec558a86a659953d0f0235f81e0bc7';

abstract class _$FilesController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}
