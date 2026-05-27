import 'package:app_quadras/esporte.dart';
import 'package:app_quadras/quadra.dart';
import 'package:app_quadras/usuario.dart';
import 'package:flutter/material.dart';

class Jogo {
  final int id;
  final Quadra quadra;
  final Esporte esporte;
  final DateTime data;
  final TimeOfDay horarioInicio;
  final TimeOfDay horarioFim;
  final Usuario host;

  Jogo({
    required this.id,
    required this.quadra,
    required this.esporte,
    required this.data,
    required this.horarioInicio,
    required this.horarioFim,
    required this.host,
  });
}
