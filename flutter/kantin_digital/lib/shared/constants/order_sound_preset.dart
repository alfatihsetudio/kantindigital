import 'package:flutter/material.dart';

class SoundPreset {
  final String id;
  final String name;
  final String description;
  final IconData icon;

  const SoundPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
}

const List<SoundPreset> kOrderSoundPresets = [
  SoundPreset(
    id: 'dingdong',
    name: 'Ding Dong Kasir',
    description: 'Dua dentang lonceng khas minimarket & kasir (Rekomendasi)',
    icon: Icons.notifications_active_rounded,
  ),
  SoundPreset(
    id: 'chime',
    name: 'Chime Melodi',
    description: 'Harmoni 3 nada naik yang ramah dan elegan',
    icon: Icons.music_note_rounded,
  ),
  SoundPreset(
    id: 'marimba',
    name: 'Marimba Ceria',
    description: 'Irama perkusi bilah kayu melodis yang ceria',
    icon: Icons.grain_rounded,
  ),
  SoundPreset(
    id: 'bell',
    name: 'Lonceng Resto',
    description: 'Dentang lonceng meja counter jernih dan berdering',
    icon: Icons.notifications_rounded,
  ),
  SoundPreset(
    id: 'beep',
    name: 'Beep Digital (Klasik)',
    description: 'Bunyi pulsa digital nyaring standar lama',
    icon: Icons.alarm_rounded,
  ),
  SoundPreset(
    id: 'gentle',
    name: 'Nada Lembut',
    description: 'Dua nada halus dan tenang, cocok untuk kafe santai',
    icon: Icons.spa_rounded,
  ),
  SoundPreset(
    id: 'urgent',
    name: 'Alarm Siaga',
    description: 'Peringatan cepat tegas, terdengar jelas di tempat ramai',
    icon: Icons.campaign_rounded,
  ),
];

SoundPreset getSoundPresetById(String? id) {
  final searchId = (id ?? 'dingdong').trim().toLowerCase();
  return kOrderSoundPresets.firstWhere(
    (preset) => preset.id == searchId,
    orElse: () => kOrderSoundPresets.first,
  );
}
