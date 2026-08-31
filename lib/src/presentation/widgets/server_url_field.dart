import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/data/services/server_probe_service.dart';
import 'package:jplayer/src/domain/providers/discovered_servers_provider.dart';
import 'package:jplayer/src/presentation/widgets/labeled_text_field.dart';

enum ServerUrlFieldMode { discovering, manual, selected }

class ServerUrlField extends StatefulWidget {
  const ServerUrlField({
    required this.mode,
    required this.controller,
    required this.focusNode,
    required this.servers,
    required this.onEdit,
    required this.onSelect,
    this.selected,
    this.suffixIcon,
    this.scanning = false,
    super.key,
  });

  static const label = 'Server URL';
  static const discoveringPlaceholder = 'Auto discovering...';
  static const ValueKey<String> surfaceKey = ValueKey(
    'serverUrlFieldSurface',
  );
  static const fillColor = Color(0xFFEEEEEE);
  static const radius = 10.0;

  final ServerUrlFieldMode mode;
  final TextEditingController controller;
  final FocusNode focusNode;
  final List<DiscoveredServer> servers;
  final DiscoveredServer? selected;
  final VoidCallback onEdit;
  final ValueChanged<DiscoveredServer> onSelect;
  final Widget? suffixIcon;
  final bool scanning;

  @override
  State<ServerUrlField> createState() => _ServerUrlFieldState();
}

class _ServerUrlFieldState extends State<ServerUrlField> {
  bool _menuOpen = false;

  BorderRadius get _surfaceRadius => _menuOpen
      ? const BorderRadius.vertical(top: Radius.circular(ServerUrlField.radius))
      : BorderRadius.circular(ServerUrlField.radius);

  @override
  Widget build(BuildContext context) {
    final server = widget.selected;
    if (widget.mode != ServerUrlFieldMode.selected || server == null) {
      return LabeledTextField(
        label: ServerUrlField.label,
        placeholder: widget.mode == ServerUrlFieldMode.discovering
            ? ServerUrlField.discoveringPlaceholder
            : null,
        keyboardType: TextInputType.url,
        controller: widget.controller,
        focusNode: widget.focusNode,
        textInputAction: TextInputAction.next,
        suffixIcon: widget.mode == ServerUrlFieldMode.discovering
            ? const DiscoveringSpinner()
            : widget.suffixIcon,
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          ServerUrlField.label,
          style: TextStyle(fontFamily: FontFamily.inter, fontSize: 12),
        ),
        const SizedBox(height: 4),
        _selectedServer(server),
      ],
    );
  }

  Widget _selectedServer(DiscoveredServer server) {
    final expandable = widget.servers.length > 1;
    return Builder(
      builder: (fieldContext) => Material(
        key: ServerUrlField.surfaceKey,
        color: ServerUrlField.fillColor,
        borderRadius: _surfaceRadius,
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: expandable ? () => _openDropdown(fieldContext) : null,
                borderRadius: _surfaceRadius,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                  child: Row(
                    children: [
                      Expanded(child: serverSummary(server)),
                      if (widget.scanning) const DiscoveringSpinner(),
                      if (expandable)
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.black54,
                          size: 22,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: widget.onEdit,
              visualDensity: VisualDensity.compact,
              tooltip: 'Enter a server address',
              icon: const Icon(Icons.edit, color: Colors.black54, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDropdown(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) return;

    final topLeft = box.localToGlobal(
      box.size.bottomLeft(Offset.zero),
      ancestor: overlay,
    );
    final bottomRight = box.localToGlobal(
      box.size.bottomRight(Offset.zero),
      ancestor: overlay,
    );

    setState(() => _menuOpen = true);
    final picked = await showMenu<DiscoveredServer>(
      context: context,
      color: ServerUrlField.fillColor,
      position: RelativeRect.fromRect(
        Rect.fromPoints(topLeft, bottomRight),
        Offset.zero & overlay.size,
      ),
      constraints: BoxConstraints(
        minWidth: box.size.width,
        maxWidth: box.size.width,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(ServerUrlField.radius),
        ),
      ),
      items: [
        for (final server in widget.servers)
          PopupMenuItem<DiscoveredServer>(
            value: server,
            padding: EdgeInsets.zero,
            child: _HoverableServer(server: server),
          ),
      ],
    );
    if (mounted) setState(() => _menuOpen = false);
    if (picked != null) widget.onSelect(picked);
  }
}

Widget serverSummary(DiscoveredServer server) => Row(
  children: [
    SvgPicture.asset(_logoAsset(server.serverType), height: 22),
    const SizedBox(width: 10),
    Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            server.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: FontFamily.inter,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          Text(
            server.serverUrl,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: FontFamily.inter,
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    ),
  ],
);

String _logoAsset(ServerType serverType) => switch (serverType) {
  ServerType.jellyfin => SvgPictures.jellyfinLogo,
  ServerType.emby => SvgPictures.embyLogo,
};

class _HoverableServer extends StatefulWidget {
  const _HoverableServer({required this.server});

  final DiscoveredServer server;

  @override
  State<_HoverableServer> createState() => _HoverableServerState();
}

class _HoverableServerState extends State<_HoverableServer> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: Container(
      color: _hovered ? Colors.black12 : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: serverSummary(widget.server),
    ),
  );
}

class DiscoveringSpinner extends StatelessWidget {
  const DiscoveringSpinner({super.key});

  @override
  Widget build(BuildContext context) => const Center(
    widthFactor: 1,
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox.square(
        dimension: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54),
      ),
    ),
  );
}
