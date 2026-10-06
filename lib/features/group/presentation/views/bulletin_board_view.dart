import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../providers/board_providers.dart';
import '../../providers/postit_providers.dart';
import '../../../auth/data/auth_repository.dart';
import '../widgets/post_it_widget.dart';
import '../../models/board_item.dart';
import '../../../rating/data/rating_repository.dart';
import '../../../rating/presentation/rating_view.dart';

class BulletinBoardView extends ConsumerWidget {
  final String groupId;

  const BulletinBoardView({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(boardItemsProvider(groupId));
    final groupAsync = ref.watch(groupMetaProvider(groupId));
    final currentUser = ref.watch(authRepositoryProvider).currentUser;

    // Listen for deletion results
    ref.listen(postItControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (err, stack) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not delete: $err'),
              backgroundColor: Colors.red,
            ),
          );
        },
        data: (_) {
          if (previous?.isLoading == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Post-it removed from board')),
            );
          }
        },
      );
    });

    return Container(
      color: Colors.transparent,
      child: groupAsync.when(
        data: (group) => itemsAsync.when(
          data: (items) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(boardItemsProvider(groupId));
                ref.invalidate(groupMetaProvider(groupId));
                if (group?.enabledModules['rating'] == true) {
                  ref.invalidate(ratingArchiveProvider(groupId));
                }
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                    sliver: SliverMainAxisGroup(
                      slivers: [
                        if (group?.enabledModules['rating'] == true)
                          SliverToBoxAdapter(
                            child: RatingSummary(groupId: groupId),
                          ),
                        if (items.isEmpty)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(
                                child: Text('No items on the board. Add one!'),
                              ),
                            ),
                          ),
                        SliverMasonryGrid.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final isAuthor = item.senderId == currentUser?.uid;

                            // ONLY allow deleting yellow post-its, not chat messages from the board
                            final canDelete =
                                item.type == BoardItemType.postit && isAuthor;

                            return PostItWidget(
                              item: item,
                              fontFamily: group?.fontFamily,
                              onDelete: canDelete
                                  ? () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Deleting post-it...'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                      ref
                                          .read(
                                            postItControllerProvider.notifier,
                                          )
                                          .deletePostIt(groupId, item.id);
                                    }
                                  : null,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Error loading group context')),
      ),
    );
  }
}
