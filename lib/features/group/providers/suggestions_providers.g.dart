// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'suggestions_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(suggestions)
const suggestionsProvider = SuggestionsProvider._();

final class SuggestionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Suggestion>>,
          List<Suggestion>,
          Stream<List<Suggestion>>
        >
    with $FutureModifier<List<Suggestion>>, $StreamProvider<List<Suggestion>> {
  const SuggestionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'suggestionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$suggestionsHash();

  @$internal
  @override
  $StreamProviderElement<List<Suggestion>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Suggestion>> create(Ref ref) {
    return suggestions(ref);
  }
}

String _$suggestionsHash() => r'5e6de5096707ad3135086fe6d48a74e9e8634322';

@ProviderFor(SuggestionsController)
const suggestionsControllerProvider = SuggestionsControllerProvider._();

final class SuggestionsControllerProvider
    extends $AsyncNotifierProvider<SuggestionsController, void> {
  const SuggestionsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'suggestionsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$suggestionsControllerHash();

  @$internal
  @override
  SuggestionsController create() => SuggestionsController();
}

String _$suggestionsControllerHash() =>
    r'46a58f900178df4bb65291181db4ddec35851967';

abstract class _$SuggestionsController extends $AsyncNotifier<void> {
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
