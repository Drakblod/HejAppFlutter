import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../group/providers/board_providers.dart';
import '../data/rating_repository.dart';
import '../models/rating_models.dart';
import 'rating_config_dialog.dart';
import 'rating_item_dialog.dart';

const _ink = Color(0xFF183E2B);
const _muted = Color(0xFF64776B);
const _gold = Color(0xFFDFC281);

class RatingView extends ConsumerWidget {
  final String groupId;
  const RatingView({super.key, required this.groupId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ratingArchiveProvider(groupId));
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: _LoadError(
          error: e,
          retry: () => ref.invalidate(ratingArchiveProvider(groupId)),
        ),
      ),
      data: (archive) {
        final config = archive.config;
        if (config == null) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: _Panel(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.workspace_premium_outlined,
                        color: _ink,
                        size: 60,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Ert intresse. Er egen topplista.',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        archive.canConfigure
                            ? 'Bygg ett arkiv för vad ni älskar. Välj egna kriterier och fält – eller prova demomallen Sardinarkivet.'
                            : 'Gruppadministratören kan nu välja namn, betygsskala och egna fält för ert arkiv.',
                        textAlign: TextAlign.center,
                      ),
                      if (archive.canConfigure) ...[
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () =>
                              showRatingConfig(context, groupId, archive),
                          icon: const Icon(Icons.tune),
                          label: const Text('Konfigurera modulen'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        final ranked = archive.ranked;
        final podium = archive.topThree;
        return RefreshIndicator(
          onRefresh: () => ref.refresh(ratingArchiveProvider(groupId).future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 125),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: const LinearGradient(
                            colors: [_ink, Color(0xFF2C6245)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'UPPTÄCK • BETYGSÄTT • JÄMFÖR',
                              style: TextStyle(
                                color: _gold,
                                fontSize: 11,
                                letterSpacing: 1.8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              config.title,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${archive.items.length} objekt · ${config.primaryLabel} ${config.min}–${config.max}\nEtt gemensamt arkiv, format av era omdömen.',
                              style: const TextStyle(
                                color: Color(0xFFD4E5D8),
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 22),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFDAEECF),
                                    foregroundColor: _ink,
                                  ),
                                  onPressed: () => showRatingItemEditor(
                                    context,
                                    groupId,
                                    archive,
                                  ),
                                  icon: const Icon(Icons.add),
                                  label: Text(
                                    'Lägg till ${config.itemTypeName.toLowerCase()}',
                                  ),
                                ),
                                if (archive.canConfigure)
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(
                                        color: Colors.white54,
                                      ),
                                    ),
                                    onPressed: () => showRatingConfig(
                                      context,
                                      groupId,
                                      archive,
                                    ),
                                    icon: const Icon(Icons.tune, size: 18),
                                    label: const Text('Anpassa'),
                                  ),
                                IconButton(
                                  onPressed: () => ref.invalidate(
                                    ratingArchiveProvider(groupId),
                                  ),
                                  tooltip: 'Uppdatera',
                                  icon: const Icon(
                                    Icons.refresh,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (podium.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        _SectionTitle(
                          'Gruppens favoriter',
                          trailing: 'TOPP ${podium.length}',
                        ),
                        const SizedBox(height: 14),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth >= 760 ? 3 : 1;
                            final width =
                                (constraints.maxWidth - (columns - 1) * 14) /
                                columns;
                            return Wrap(
                              spacing: 14,
                              runSpacing: 14,
                              children: [
                                for (var i = 0; i < podium.length; i++)
                                  SizedBox(
                                    width: width,
                                    child: _PodiumCard(
                                      item: podium[i],
                                      rank: i + 1,
                                      config: config,
                                      onTap: () => _openDetail(
                                        context,
                                        groupId,
                                        podium[i].id,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 28),
                      const _SectionTitle(
                        'Hela arkivet',
                        trailing: 'HÖGST BETYG FÖRST',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Snitt av angivna betyg. Saknade betyg påverkar inte snittet. Lika betyg sorteras efter namn.',
                        style: TextStyle(color: _muted, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      if (ranked.isEmpty)
                        const _Panel(
                          child: Text(
                            'Arkivet är redo. Lägg till ert första objekt och börja upptäcka tillsammans.',
                          ),
                        ),
                      for (var i = 0; i < ranked.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _RankingRow(
                            item: ranked[i],
                            rank: i + 1,
                            config: config,
                            onTap: () =>
                                _openDetail(context, groupId, ranked[i].id),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title, trailing;
  const _SectionTitle(this.title, {required this.trailing});
  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 14,
    runSpacing: 8,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 21,
          color: _ink,
          fontWeight: FontWeight.w800,
        ),
      ),
      Text(
        trailing,
        style: const TextStyle(
          fontSize: 10,
          color: _muted,
          letterSpacing: 1.3,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _Panel extends StatelessWidget {
  final Widget child;
  const _Panel({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFE0E7DF)),
    ),
    child: child,
  );
}

class RatingImage extends StatelessWidget {
  final RatingItem item;
  final double height;
  const RatingImage({super.key, required this.item, this.height = 180});
  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE4EBDD), Color(0xFFF6F0DE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.auto_awesome_outlined,
          size: height > 100 ? 48 : 22,
          color: _ink.withValues(alpha: .5),
        ),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: item.imageUrl == null
          ? placeholder
          : Image.network(
              item.imageUrl!,
              height: height,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => placeholder,
            ),
    );
  }
}

class _PodiumCard extends StatelessWidget {
  final RatingItem item;
  final int rank;
  final RatingConfig config;
  final VoidCallback onTap;
  const _PodiumCard({
    required this.item,
    required this.rank,
    required this.config,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                RatingImage(item: item),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Chip(
                    avatar: const Icon(Icons.emoji_events_outlined, size: 18),
                    label: Text('#$rank'),
                    backgroundColor: rank == 1 ? _gold : Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                color: _ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${ratingScore(item.score)} / ${config.max}',
              style: const TextStyle(
                fontSize: 28,
                color: _ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '${config.primaryLabel} · ${item.ratingCount} betyg',
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
}

class _RankingRow extends StatelessWidget {
  final RatingItem item;
  final int rank;
  final RatingConfig config;
  final VoidCallback onTap;
  const _RankingRow({
    required this.item,
    required this.rank,
    required this.config,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Text(
                item.score == null ? '—' : '$rank',
                style: const TextStyle(
                  color: _muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(width: 54, child: RatingImage(item: item, height: 54)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${config.primaryLabel}: ${ratingScore(item.score)}',
                    style: const TextStyle(color: _muted),
                  ),
                  if (config.criteria.any((c) => c['showInRanking'] == true))
                    Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          for (final c in config.criteria.where(
                            (c) => c['showInRanking'] == true,
                          ))
                            Text(
                              '${c['label']}: ${ratingScore(item.criterionScore(c['id'] as String))}',
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: _muted, size: 18),
          ],
        ),
      ),
    ),
  );
}

void _openDetail(BuildContext context, String groupId, String itemId) {
  context.push('/group/$groupId/rating/$itemId');
}

class RatingDetailPage extends ConsumerWidget {
  final String groupId, itemId;
  const RatingDetailPage({
    super.key,
    required this.groupId,
    required this.itemId,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ratingArchiveProvider(groupId));
    final members = ref.watch(groupMembersProvider(groupId)).value ?? [];
    String name(String? uid) {
      final profile = members
          .where((m) => m.member.uid == uid)
          .firstOrNull
          ?.profile;
      return profile?.fullName.isNotEmpty == true
          ? profile!.fullName
          : profile?.username ?? 'Gruppmedlem';
    }

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/group/$groupId'),
        ),
        title: Text(state.value?.config?.title ?? 'Arkiv'),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: _LoadError(
            error: e,
            retry: () => ref.invalidate(ratingArchiveProvider(groupId)),
          ),
        ),
        data: (archive) {
          final item = archive.items.where((i) => i.id == itemId).firstOrNull;
          if (item == null || archive.config == null) {
            return const Center(child: Text('Objektet finns inte kvar.'));
          }
          final config = archive.config!;
          return ListView(
            padding: const EdgeInsets.all(22),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 850),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      RatingImage(item: item, height: 300),
                      const SizedBox(height: 22),
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 30,
                          color: _ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${config.primaryLabel}: ${ratingScore(item.score)}${item.score == null ? '' : ' / ${config.max}'}',
                        style: const TextStyle(
                          fontSize: 24,
                          color: _ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${item.ratingCount} betyg · Skapad av ${name(item.creatorId)}\nTillagd ${_date(item.createdAt)} · Uppdaterad ${_date(item.updatedAt)}',
                        style: const TextStyle(color: _muted, height: 1.7),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.icon(
                            onPressed: () => showRatingItemEditor(
                              context,
                              groupId,
                              archive,
                              item: item,
                              reviewOnly: true,
                            ),
                            icon: const Icon(Icons.star_outline),
                            label: Text(
                              item.reviews.containsKey(archive.userId)
                                  ? 'Redigera din recension'
                                  : 'Betygsätt',
                            ),
                          ),
                          if (archive.canConfigure ||
                              item.creatorId == archive.userId) ...[
                            OutlinedButton.icon(
                              onPressed: () => showRatingItemEditor(
                                context,
                                groupId,
                                archive,
                                item: item,
                              ),
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Redigera objekt'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  _delete(context, ref, archive, item),
                              child: const Text('Ta bort objekt'),
                            ),
                          ],
                        ],
                      ),
                      if (config.criteria.isNotEmpty) ...[
                        const SizedBox(height: 22),
                        _Panel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const _SectionTitle(
                                'Gruppens omdömen',
                                trailing: 'SNITTBETYG',
                              ),
                              for (final c in config.criteria)
                                Padding(
                                  padding: const EdgeInsets.only(top: 18),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${c['label']} · ${ratingScore(item.criterionScore(c['id'] as String))}',
                                        style: const TextStyle(
                                          color: _ink,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (item.criterionScore(
                                            c['id'] as String,
                                          ) !=
                                          null) ...[
                                        const SizedBox(height: 8),
                                        LinearProgressIndicator(
                                          value:
                                              ((item.criterionScore(
                                                            c['id'] as String,
                                                          )! -
                                                          (c['min'] as num)) /
                                                      ((c['max'] as num) -
                                                          (c['min'] as num)))
                                                  .clamp(0, 1)
                                                  .toDouble(),
                                          minHeight: 6,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          color: _ink,
                                          backgroundColor: const Color(
                                            0xFFE9EEE7,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                      if (config.fields.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _Panel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _SectionTitle(
                                'Om objektet',
                                trailing: 'DETALJER',
                              ),
                              for (final f in config.fields)
                                Padding(
                                  padding: const EdgeInsets.only(top: 14),
                                  child: Text(
                                    '${f['label']}: ${metadataDisplay(f, item.metadata[f['id']])}',
                                    style: const TextStyle(color: _ink),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        'Recensioner',
                        trailing: 'GRUPPENS RÖSTER',
                      ),
                      const SizedBox(height: 14),
                      for (final review in item.reviews.values)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _Panel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  review.json['sourceLabel'] as String? ??
                                      name(review.userId),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: _ink,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${config.primaryLabel}: ${ratingScore(review.primaryRating)} · ${_date(review.updatedAt)}',
                                  style: const TextStyle(color: _muted),
                                ),
                                for (final c in config.criteria)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      '${c['label']}: ${ratingScore(review.criteria[c['id']] as num?)}',
                                      style: const TextStyle(
                                        color: _muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                if (review.comment.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(review.comment),
                                ],
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 25),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    RatingArchive archive,
    RatingItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Ta bort objekt?'),
        content: Text(
          '“${item.title}” och alla dess recensioner tas bort. Detta kan inte ångras.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Avbryt'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Ta bort'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(ratingRepositoryProvider).call(groupId, 'deleteItem', {
        'id': item.id,
        'version': item.version,
        'configRevision': archive.config!.revision,
      });
      ref.invalidate(ratingArchiveProvider(groupId));
      if (context.mounted) {
        context.canPop() ? context.pop() : context.go('/group/$groupId');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ratingError(e))));
      }
    }
  }
}

class RatingSummary extends ConsumerWidget {
  final String groupId;
  const RatingSummary({super.key, required this.groupId});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(ratingArchiveProvider(groupId))
      .when(
        loading: () => const Padding(
          padding: EdgeInsets.all(12),
          child: LinearProgressIndicator(),
        ),
        error: (e, _) => _LoadError(
          error: e,
          retry: () => ref.invalidate(ratingArchiveProvider(groupId)),
        ),
        data: (archive) {
          final config = archive.config;
          if (config == null || !config.showSummary || archive.items.isEmpty) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionTitle(config.title, trailing: 'GRUPPENS TOPP 3'),
                  const SizedBox(height: 12),
                  for (var i = 0; i < archive.topThree.length; i++)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFF0E7CD),
                        foregroundColor: _ink,
                        child: Text('${i + 1}'),
                      ),
                      title: Text(archive.topThree[i].title),
                      trailing: Text(
                        ratingScore(archive.topThree[i].score),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          color: _ink,
                        ),
                      ),
                      onTap: () =>
                          _openDetail(context, groupId, archive.topThree[i].id),
                    ),
                  for (final c in config.criteria.where(
                    (c) => (c['highlightLabel'] as String? ?? '').isNotEmpty,
                  ))
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        '${c['highlightLabel']}: ${archive.highlight(c['id'] as String)?.title ?? 'Ej betygsatt'}',
                        style: const TextStyle(color: _muted),
                      ),
                    ),
                  if (archive.latest != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Text(
                        'Senast tillagt / betygsatt: ${archive.latest!.title}',
                        style: const TextStyle(
                          color: _ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
}

class _LoadError extends StatelessWidget {
  final Object error;
  final VoidCallback retry;
  const _LoadError({required this.error, required this.retry});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(ratingError(error), textAlign: TextAlign.center),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: retry, child: const Text('Försök igen')),
      ],
    ),
  );
}

String _date(int value) =>
    DateFormat('yyyy-MM-dd').format(DateTime.fromMillisecondsSinceEpoch(value));
