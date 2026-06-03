import 'package:flutter/material.dart';
import 'package:rukun_app_proyek4/utils/avatar_utils.dart';
import 'package:rukun_app_proyek4/utils/colors_utils.dart';
import 'package:rukun_app_proyek4/services/local/offline_sync_status_service.dart';

class AppBarUtils {
  static PreferredSizeWidget buildAppBar({
    required BuildContext context,
    required String name,
    required String title,
    String? subtitle,
    bool showName = true,
    bool showAvatar = true,
    bool showGreeting = true,
    Widget? leading,
    Widget? trailing,
    Widget? settingsWidget,
    bool showSyncBadge = true,
  }) {
    final canPop = Navigator.canPop(context);

    final Widget? finalLeading =
        leading ??
        (canPop
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: ColorsUtils.white,
                  size: 22,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null);

    return AppBar(
      backgroundColor: ColorsUtils.b500,
      elevation: 0,
      toolbarHeight: 90,

      // automaticallyImplyLeading: false,
      leading: finalLeading,

      leadingWidth: finalLeading != null ? 60 : 0,

      titleSpacing: finalLeading != null ? 0 : 16,

      title: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (showAvatar) ...[
                CircleAvatar(radius: 23, child: buildAvatar(name)),

                const SizedBox(width: 12),
              ],

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showGreeting)
                      Text(
                        _getGreeting(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: ColorsUtils.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                    if (showName)
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 15,
                          color: ColorsUtils.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              if (settingsWidget != null) ...[
                const SizedBox(width: 8),
                settingsWidget,
              ] else if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing,
              ] else if (showSyncBadge) ...[
                const SizedBox(width: 8),
                const _OfflineSyncBadge(),
              ],
            ],
          ),

          if (title.isNotEmpty) ...[
            const SizedBox(height: 6),

            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: ColorsUtils.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          if (subtitle != null) ...[
            const SizedBox(height: 2),

            Text(
              subtitle,
              style: const TextStyle(fontSize: 14, color: ColorsUtils.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  static String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) return "Selamat Pagi";
    if (hour < 16) return "Selamat Siang";
    if (hour < 18) return "Selamat Sore";

    return "Selamat Malam";
  }
}

class _OfflineSyncBadge extends StatelessWidget {
  const _OfflineSyncBadge();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: OfflineSyncStatusService.instance.pendingCount,
      builder: (context, count, _) {
        final hasPending = count > 0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: hasPending
                ? ColorsUtils.white.withValues(alpha: 0.16)
                : ColorsUtils.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: ColorsUtils.white.withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasPending ? Icons.sync : Icons.cloud_done_outlined,
                size: 16,
                color: ColorsUtils.white,
              ),
              if (hasPending) ...[
                const SizedBox(width: 6),
                Text(
                  '$count',
                  style: const TextStyle(
                    color: ColorsUtils.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
