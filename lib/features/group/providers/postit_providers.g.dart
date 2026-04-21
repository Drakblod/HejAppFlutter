// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'postit_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PostItController)
const postItControllerProvider = PostItControllerProvider._();

final class PostItControllerProvider
    extends $AsyncNotifierProvider<PostItController, void> {
  const PostItControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'postItControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$postItControllerHash();

  @$internal
  @override
  PostItController create() => PostItController();
}

String _$postItControllerHash() => r'351d8fbe0ea2cfdf2c65925d2011342d1ba8dc1a';

abstract class _$PostItController extends $AsyncNotifier<void> {
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
