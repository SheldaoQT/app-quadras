import 'package:flutter/material.dart';

class ComponenteAgendamento extends StatelessWidget {
  const ComponenteAgendamento({
    super.key,
    required this.clickContainer,
    required this.textoHorario,
    this.containerColor,
  });

  final VoidCallback clickContainer;

  final Color? containerColor;

  final String textoHorario;

  @override
  Widget build(
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: clickContainer,

      child: Padding(
        padding: const EdgeInsets.all(
          6,
        ),

        child: Container(
          alignment: Alignment.center,

          decoration: BoxDecoration(
            color: containerColor,

            border: Border.all(
              color: Colors.black12,
            ),

            borderRadius: BorderRadius.circular(
              12,
            ),
          ),

          child: Text(
            textoHorario,

            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
