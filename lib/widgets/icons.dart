import 'package:flutter/material.dart';

final _icons = <String, IconData>{
  'approval': Icons.approval,
  'task': Icons.task,
  'bug_report': Icons.bug_report,
  'assignment': Icons.assignment,
  'paste_outlined': Icons.paste_outlined,
  'edit_note': Icons.edit_note,
  'grading': Icons.grading,
};

Icon getIcon(String nombreIcon, BuildContext context) {
  final colors = Theme.of(context).colorScheme;
  
  return Icon(_icons[nombreIcon], color: colors.secondary);
}
