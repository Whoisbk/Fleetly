import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../utils/document_picker.dart';

class DropUploadTarget extends StatefulWidget {
  const DropUploadTarget({
    super.key,
    required this.builder,
    required this.onDropped,
    this.onError,
    this.enabled = true,
  });

  final Widget Function(bool hovering) builder;
  final ValueChanged<PlatformFile> onDropped;
  final ValueChanged<String>? onError;
  final bool enabled;

  @override
  State<DropUploadTarget> createState() => _DropUploadTargetState();
}

class _DropUploadTargetState extends State<DropUploadTarget> {
  bool _hovering = false;

  Future<void> _handleDrop(DropDoneDetails detail) async {
    if (!widget.enabled || detail.files.isEmpty) return;

    try {
      final dropped = detail.files.first;
      final name = dropped.name.isNotEmpty
          ? dropped.name
          : dropped.path.split(RegExp(r'[/\\]')).last;
      final bytes = await dropped.readAsBytes();
      if (!mounted) return;

      final file = await DocumentPicker.fromDropped(name: name, bytes: bytes);
      if (!mounted) return;
      widget.onDropped(file);
    } on DocumentPickerException catch (e) {
      widget.onError?.call(e.message);
    } catch (_) {
      widget.onError?.call('Could not drop that file — try another PDF or image');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      enable: widget.enabled,
      onDragEntered: (_) {
        if (!widget.enabled) return;
        setState(() => _hovering = true);
      },
      onDragExited: (_) => setState(() => _hovering = false),
      onDragDone: (detail) async {
        setState(() => _hovering = false);
        if (!widget.enabled) return;
        await _handleDrop(detail);
      },
      child: widget.builder(_hovering),
    );
  }
}
