// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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

String _$geminiControllerHash() => r'dfb53a2179f81ae5f70471f4f61cbbb395ebcf37';

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
