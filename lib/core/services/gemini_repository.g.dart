// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gemini_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(geminiRepository)
const geminiRepositoryProvider = GeminiRepositoryProvider._();

final class GeminiRepositoryProvider
    extends
        $FunctionalProvider<
          GeminiRepository,
          GeminiRepository,
          GeminiRepository
        >
    with $Provider<GeminiRepository> {
  const GeminiRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'geminiRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$geminiRepositoryHash();

  @$internal
  @override
  $ProviderElement<GeminiRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GeminiRepository create(Ref ref) {
    return geminiRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GeminiRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GeminiRepository>(value),
    );
  }
}

String _$geminiRepositoryHash() => r'6b2c7512a48e2b5d9b712fa653ca3f8d5ebaab0a';
