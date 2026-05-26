// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(galleryItems)
const galleryItemsProvider = GalleryItemsFamily._();

final class GalleryItemsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GalleryItem>>,
          List<GalleryItem>,
          Stream<List<GalleryItem>>
        >
    with
        $FutureModifier<List<GalleryItem>>,
        $StreamProvider<List<GalleryItem>> {
  const GalleryItemsProvider._({
    required GalleryItemsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'galleryItemsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$galleryItemsHash();

  @override
  String toString() {
    return r'galleryItemsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<GalleryItem>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<GalleryItem>> create(Ref ref) {
    final argument = this.argument as String;
    return galleryItems(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GalleryItemsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$galleryItemsHash() => r'd9d005bd2517e6cd3038dad5f79455710b971f74';

final class GalleryItemsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<GalleryItem>>, String> {
  const GalleryItemsFamily._()
    : super(
        retry: null,
        name: r'galleryItemsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GalleryItemsProvider call(String groupId) =>
      GalleryItemsProvider._(argument: groupId, from: this);

  @override
  String toString() => r'galleryItemsProvider';
}

@ProviderFor(GalleryController)
const galleryControllerProvider = GalleryControllerProvider._();

final class GalleryControllerProvider
    extends $AsyncNotifierProvider<GalleryController, void> {
  const GalleryControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'galleryControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$galleryControllerHash();

  @$internal
  @override
  GalleryController create() => GalleryController();
}

String _$galleryControllerHash() => r'8d910c79431cb41cf0631cd7850b76a0c5751134';

abstract class _$GalleryController extends $AsyncNotifier<void> {
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
