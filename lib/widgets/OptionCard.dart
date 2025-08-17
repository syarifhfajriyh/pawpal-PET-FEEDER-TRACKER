import 'package:flutter/material.dart';

class OptionCard extends StatelessWidget {
  final String title;
  final String title2;
  final String icon;
  final bool active;
  final int id;
  final ValueChanged<int>? onClick;

  const OptionCard({
    super.key,
    required this.title,
    required this.title2,
    required this.icon,
    required this.id,
    required this.onClick,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => onClick?.call(id),
      child: Card(
        elevation: 3.0,
        color: active ? theme.colorScheme.primary : Colors.white,
        shadowColor: active ? theme.colorScheme.secondary : const Color(0xFFf7f7f7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: SizedBox(
          width: ((MediaQuery.of(context).size.width - 80) / 3).floorToDouble(),
          height: 100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(5, 5, 5, 10),
                child: Image.asset(icon),
              ),
              Text(title, style: theme.textTheme.bodyLarge),
              Text(title2, style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }
}
