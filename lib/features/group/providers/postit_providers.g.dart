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

String _$postItControllerHash() => r'65acecb4208890fc1a11fec938370d91afeffeee';

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

@ProviderFor(GeminiController)
const geminiControllerProvider = GeminiControllerProvider._();

final class GeminiControllerProvider
    extends $AsyncNotifierProvider<GeminiController, List<PostIt>> {
  const GeminiControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'geminiControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$geminiControllerHash();

  @$internal
  @override
  GeminiController create() => GeminiController();
}

String _$geminiControllerHash() => r'68898fcabe1cc9b9177e5c3f393aa2feef175f7f';

abstract class _$GeminiController extends $AsyncNotifier<List<PostIt>> {
  FutureOr<List<PostIt>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<List<PostIt>>, List<PostIt>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<PostIt>>, List<PostIt>>,
              AsyncValue<List<PostIt>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
