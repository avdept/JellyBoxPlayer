import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jplayer/generated/l10n.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';

Widget dismissOnEscape(BuildContext context, Widget child) => Focus(
  onKeyEvent: (node, event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  },
  child: child,
);

Future<T?> showAppDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) => showAdaptiveDialog<T>(
  context: context,
  builder: (context) => dismissOnEscape(context, builder(context)),
);

Future<T?> showFormModal<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  final device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
  if (device.isDesktop) {
    return showAppDialog<T>(
      context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: SizedBox(
          width: 360,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
            child: builder(context),
          ),
        ),
      ),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.grey[900],
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        top: 12,
        bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: dismissOnEscape(context, builder(context)),
    ),
  );
}

class ModalFormHeader extends StatelessWidget {
  const ModalFormHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          tooltip: S.of(context).close,
          visualDensity: VisualDensity.compact,
          style: ButtonStyle(
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            splashFactory: NoSplash.splashFactory,
            iconColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.hovered)
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onPrimary.withValues(alpha: 0.6),
            ),
          ),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
}

class ModalFormActions extends StatelessWidget {
  const ModalFormActions({
    required this.submitLabel,
    required this.onSubmit,
    this.busy = false,
    super.key,
  });

  final String submitLabel;
  final VoidCallback? onSubmit;
  final bool busy;

  static ButtonStyle buttonStyle(
    BuildContext context, {
    bool primary = false,
  }) => TextButton.styleFrom(
    backgroundColor: primary ? Theme.of(context).colorScheme.primary : null,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  );

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        style: buttonStyle(context),
        child: Text(S.of(context).cancel),
      ),
      TextButton(
        onPressed: busy ? null : onSubmit,
        style: buttonStyle(context, primary: true),
        child: busy
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(submitLabel),
      ),
    ],
  );
}
