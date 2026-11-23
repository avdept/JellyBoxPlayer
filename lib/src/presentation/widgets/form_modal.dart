import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jplayer/src/presentation/themes/app_colors.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/hover_icon_button.dart';

Widget dismissOnEscape(BuildContext context, Widget child) =>
    _DismissOnEscape(child: child);

class _DismissOnEscape extends StatefulWidget {
  const _DismissOnEscape({required this.child});

  final Widget child;

  @override
  State<_DismissOnEscape> createState() => _DismissOnEscapeState();
}

class _DismissOnEscapeState extends State<_DismissOnEscape> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.escape ||
        !mounted ||
        ModalRoute.of(context)?.isCurrent != true) {
      return false;
    }
    Navigator.of(context).pop();
    return true;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

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
  double width = 360,
}) {
  final device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
  if (device.isDesktop) {
    return showAppDialog<T>(
      context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: width,
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
            child: SingleChildScrollView(child: builder(context)),
          ),
        ),
      ),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxWidth: 640,
      maxHeight: MediaQuery.sizeOf(context).height * 0.9,
    ),
    backgroundColor: Colors.grey[900],
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        top: 12,
        bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: dismissOnEscape(context, builder(context)),
      ),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ),
        HoverIconButton(
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Close',
          color: theme.colorScheme.onPrimary.withValues(alpha: 0.6),
          hoverColor: theme.colorScheme.onPrimary,
          iconSize: 24,
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
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
    foregroundColor: primary ? AppColors.from(context).onPrimaryFill : null,
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
        child: const Text('Cancel'),
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
