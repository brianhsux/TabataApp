import 'package:flutter/material.dart';

class CycleSetBlockWidget extends StatelessWidget {
  final String label;
  final int value;
  final Color iconColor;
  final IconData icon;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const CycleSetBlockWidget({
    super.key,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.icon,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor),
          SizedBox(height: 10),
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: iconColor)),
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: iconColor, fontWeight: FontWeight.bold),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.remove, color: iconColor),
                onPressed: onRemove,
              ),
              IconButton(
                icon: Icon(Icons.add, color: iconColor),
                onPressed: onAdd,
              ),
            ],
          ),
        ],
      ),
    );
  }
} 