import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../game/game_controller.dart';

class SidePanel extends StatelessWidget {
  final GameController controller;
  const SidePanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(left: BorderSide(color: onSurface.withOpacity(0.08))),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            StatusCard(controller: controller),
            const SizedBox(height: 12),
            if (!controller.waveActive && !controller.rewardPending && !controller.gameOver)
              WaveBriefingCard(controller: controller),
            if (!controller.waveActive && !controller.rewardPending && !controller.gameOver) const SizedBox(height: 12),
            CellPalette(controller: controller),
            const SizedBox(height: 12),
            Controls(controller: controller),
            const SizedBox(height: 12),
            LegendCard(controller: controller),
          ],
        ),
      ),
    );
  }
}

class StatusCard extends StatelessWidget {
  final GameController controller;
  const StatusCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final pct = (controller.infection / controller.infectionMax).clamp(0.0, 1.0);
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Lab Status", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _pill("DNA", "${controller.dna}", onSurface),
                _pill("Wave", "${controller.wave}", onSurface),
                _pill("Viruses", "${controller.viruses.length}", onSurface),
                _pill("Kill DNA", "${controller.killDnaThisWave}/${controller.killDnaCap}", onSurface),
                _pill("RP", "${controller.researchPoints}", onSurface),
              ],
            ),
            const SizedBox(height: 12),
            Text("Infection: ${controller.infection.toStringAsFixed(1)} / ${controller.infectionMax.toStringAsFixed(0)}"),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: pct),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, String value, Color onSurface) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: onSurface.withOpacity(0.08),
      ),
      child: Text("$label: $value", style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class CellPalette extends StatelessWidget {
  final GameController controller;
  const CellPalette({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Cell Loadout", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: CellType.values.map((t) {
              final unlocked = controller.isCellUnlocked(t);
              final selected = controller.selectedCell == t;
              return ChoiceChip(
                selected: selected,
                label: Text(unlocked ? "${t.label} (${t.baseCost})" : "${t.label} (locked)"),
                onSelected: unlocked ? (_) => controller.selectCell(t) : null,
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Text(
            "Elite Fusion: Place ${controller.mergeCountRequired} same-type nearby → Tier 2. Do it again → Tier 3.",
            style: TextStyle(color: onSurface.withOpacity(0.60), fontWeight: FontWeight.w600),
          ),
        ]),
      ),
    );
  }
}

class Controls extends StatelessWidget {
  final GameController controller;
  const Controls({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final canStart = !controller.waveActive && !controller.gameOver && !controller.rewardPending;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: canStart ? controller.startWave : null,
            icon: const Icon(Icons.play_arrow),
            label: const Text("Start Wave"),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: controller.reset,
            icon: const Icon(Icons.refresh),
            label: const Text("Reset"),
          ),
        ),
      ],
    );
  }
}

class LegendCard extends StatelessWidget {
  final GameController controller;
  const LegendCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Legend / Clarity", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          _legendRow(onSurface, CellType.killer, "Laser damage. Best vs single targets."),
          const SizedBox(height: 6),
          _legendRow(onSurface, CellType.macrophage, "Engulf: slows + weakens. Great control."),
          const SizedBox(height: 6),
          _legendRow(onSurface, CellType.support, "Aura: boosts damage + fire rate nearby."),
          const SizedBox(height: 6),
          _legendRow(onSurface, CellType.sentinel, "Piercing line shot. Great vs clustered paths."),
          const SizedBox(height: 6),
          _legendRow(onSurface, CellType.cleaner, "Disrupts shields and immunities."),
          const Divider(height: 18),
          Text(
            "Virus Status Markers:",
            style: TextStyle(fontWeight: FontWeight.w900, color: onSurface.withOpacity(0.70)),
          ),
          const SizedBox(height: 6),
          Text("• Cyan bubble = shield", style: TextStyle(color: onSurface.withOpacity(0.62))),
          Text("• Blue ring = slowed", style: TextStyle(color: onSurface.withOpacity(0.62))),
          Text("• Yellow dot = weakened", style: TextStyle(color: onSurface.withOpacity(0.62))),
        ]),
      ),
    );
  }

  Widget _legendRow(Color onSurface, CellType type, String desc) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: type.color.withOpacity(0.9), shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            "${type.label}: $desc",
            style: TextStyle(color: onSurface.withOpacity(0.70), fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class WaveBriefingCard extends StatelessWidget {
  final GameController controller;
  const WaveBriefingCard({super.key, required this.controller});

  String _pct(double v) => "${(v * 100).round()}%";
  String _typeLabel(VirusType t) {
    switch (t) {
      case VirusType.swarm:
        return "Swarm";
      case VirusType.tank:
        return "Tank";
      case VirusType.stealth:
        return "Stealth";
      case VirusType.boss:
        return "Boss";
      case VirusType.leech:
        return "Leech";
      case VirusType.spore:
        return "Spore";
    }
  }

  @override
  Widget build(BuildContext context) {
    final briefing = controller.getWaveBriefing();
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final bossText = briefing.bossWave ? "Boss wave incoming (spawns swarms)." : "Standard wave.";
    final typeList = briefing.typeWeights.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final typeText = typeList.map((e) => "${_typeLabel(e.key)} ${_pct(e.value)}").join(" · ");

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Wave ${briefing.wave} — Threat Briefing", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(bossText, style: TextStyle(color: onSurface.withOpacity(0.70), fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text("Estimated count: ${briefing.count}", style: TextStyle(color: onSurface.withOpacity(0.70))),
          const SizedBox(height: 8),
          Text(
            "Types: $typeText",
            style: TextStyle(color: onSurface.withOpacity(0.60), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            "Traits: Split ${_pct(briefing.splitChance)}, Rage ${_pct(briefing.rageChance)}, Zigzag ${_pct(briefing.zigzagChance)}",
            style: TextStyle(color: onSurface.withOpacity(0.60), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            "Shield: Tank ${_pct(briefing.shieldChanceTank)}, Other ${_pct(briefing.shieldChanceOther)}",
            style: TextStyle(color: onSurface.withOpacity(0.60), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            "Immune to slow: Stealth ${_pct(briefing.immuneChanceStealth)}, Other ${_pct(briefing.immuneChanceOther)}",
            style: TextStyle(color: onSurface.withOpacity(0.60), fontWeight: FontWeight.w600),
          ),
        ]),
      ),
    );
  }
}

/// Reward picker
class RewardPicker extends StatelessWidget {
  final GameController controller;
  final void Function(UpgradeCard) onPick;
  final VoidCallback onOpenResearch;

  const RewardPicker({
    super.key,
    required this.controller,
    required this.onPick,
    required this.onOpenResearch,
  });

  Color _rarityColor(Color onSurface, UpgradeRarity r) {
    switch (r) {
      case UpgradeRarity.common:
        return onSurface.withOpacity(0.10);
      case UpgradeRarity.rare:
        return Colors.teal.withOpacity(0.15);
      case UpgradeRarity.epic:
        return Colors.purple.withOpacity(0.18);
    }
  }

  @override
  Widget build(BuildContext context) {
    final choices = controller.rewardChoices;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final summary = controller.lastWaveSummary;
    String virusLabel(VirusType t) {
      switch (t) {
        case VirusType.swarm:
          return "Swarm";
        case VirusType.tank:
          return "Tank";
        case VirusType.stealth:
          return "Stealth";
        case VirusType.boss:
          return "Boss";
        case VirusType.leech:
          return "Leech";
        case VirusType.spore:
          return "Spore";
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight =
            constraints.maxHeight.isFinite ? constraints.maxHeight : MediaQuery.of(context).size.height * 0.85;

        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Choose 1 Upgrade",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(
                  "Or open Research (uses RP).",
                  style: TextStyle(color: onSurface.withOpacity(0.60), fontWeight: FontWeight.w600),
                ),
                if (summary != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: onSurface.withOpacity(0.05),
                      border: Border.all(color: onSurface.withOpacity(0.12)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Wave ${summary.wave} Summary", style: const TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        Text("Kills: ${summary.kills} · Breaches: ${summary.breaches}"),
                        Text("Infection gained: ${summary.infectionGained.toStringAsFixed(1)}"),
                        if (summary.breachLog.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            "Breach log:",
                            style: TextStyle(fontWeight: FontWeight.w800, color: onSurface.withOpacity(0.70)),
                          ),
                          for (final b in summary.breachLog.take(3))
                            Text(
                              "• ${virusLabel(b.type)} +${b.damage.toStringAsFixed(1)} infection",
                              style: TextStyle(color: onSurface.withOpacity(0.70)),
                            ),
                        ],
                        const SizedBox(height: 6),
                  Text(
                    "Damage: Killer ${(summary.damageByCell[CellType.killer] ?? 0).toStringAsFixed(1)} · "
                    "Macrophage ${(summary.damageByCell[CellType.macrophage] ?? 0).toStringAsFixed(1)}",
                    style: TextStyle(color: onSurface.withOpacity(0.70), fontWeight: FontWeight.w600),
                  ),
                  Text(
                    "Sentinel ${(summary.damageByCell[CellType.sentinel] ?? 0).toStringAsFixed(1)} · "
                    "Cleaner ${(summary.damageByCell[CellType.cleaner] ?? 0).toStringAsFixed(1)}",
                    style: TextStyle(color: onSurface.withOpacity(0.70), fontWeight: FontWeight.w600),
                  ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                for (final card in choices)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: _rarityColor(onSurface, card.rarity),
                      border: Border.all(color: onSurface.withOpacity(0.12)),
                    ),
                    child: ListTile(
                      title: Text(card.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(card.description),
                      ),
                      onTap: () => onPick(card),
                    ),
                  ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.hub_outlined),
                    label: Text("Open Research (${controller.researchPoints} RP)"),
                    onPressed: onOpenResearch,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Research panel
class ResearchPanel extends StatefulWidget {
  final GameController controller;
  const ResearchPanel({super.key, required this.controller});

  @override
  State<ResearchPanel> createState() => _ResearchPanelState();
}

class _ResearchPanelState extends State<ResearchPanel> {
  late final ScrollController _laneScrollController;

  @override
  void initState() {
    super.initState();
    _laneScrollController = ScrollController();
  }

  @override
  void dispose() {
    _laneScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        final nodes = controller.researchTree;
        final titleById = {for (final n in nodes) n.id: n.title};
        final nodeById = {for (final n in nodes) n.id: n};
        final onSurface = Theme.of(context).colorScheme.onSurface;

        return Padding(
          padding: const EdgeInsets.all(14),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxHeight =
                  constraints.maxHeight.isFinite ? constraints.maxHeight : MediaQuery.of(context).size.height * 0.7;
              final reserved = nodeById.containsKey("r_start") ? 240.0 : 180.0;
              final maxListHeight = (maxHeight - reserved).clamp(0.0, maxHeight).toDouble();
              final listHeight = maxListHeight > 0 ? maxListHeight : 0.0;

              final lanes = [
                ("Core", ["r_lane_core", "r_breach_resist2", "r_immunity", "r_harvest"]),
                ("Fusion", ["r_lane_fusion", "r_merge2", "r_merge3", "r_merge4"]),
                ("Support", ["r_lane_support", "r_support_lux", "r_support_range2", "r_support_fire2", "r_support_amp2"]),
                ("Macrophage", ["r_lane_macro", "r_macro_core", "r_macro_splash2", "r_macro_linger", "r_macro_amplify", "r_cleaner_unlock"]),
                ("Killer", ["r_lane_killer", "r_killer_precision", "r_killer_focus", "r_killer_overclock", "r_killer_execute", "r_sentinel_unlock"]),
              ];

              Widget buildBaselineCard(ResearchNode n) {
                final unlocked = controller.isResearchUnlocked(n.id);
                final can = controller.canUnlockResearch(n);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: onSurface.withOpacity(0.05),
                    border: Border.all(color: onSurface.withOpacity(0.12)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                              const SizedBox(height: 2),
                              Text(n.desc, style: TextStyle(color: onSurface.withOpacity(0.70))),
                            ],
                          ),
                        ),
                        if (unlocked)
                          const Icon(Icons.check_circle, color: Colors.green, size: 18)
                        else
                          ElevatedButton(
                            onPressed: can ? () => controller.unlockResearch(n) : null,
                            child: const Text("Unlock"),
                          ),
                      ],
                    ),
                  ),
                );
              }

              Widget buildNodeCard(ResearchNode n) {
                final unlocked = controller.isResearchUnlocked(n.id);
                final can = controller.canUnlockResearch(n);
                final prereqTitles = n.prereq.map((id) => titleById[id] ?? id).toList();
                final prereqLine = prereqTitles.isEmpty ? "" : "\nRequires: ${prereqTitles.join(", ")}";

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: unlocked ? onSurface.withOpacity(0.06) : onSurface.withOpacity(0.04),
                    border: Border.all(color: onSurface.withOpacity(0.12)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                "${n.title}  ${n.cost > 0 ? "(${n.cost} RP)" : ""}",
                                style: const TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                            if (unlocked) const Icon(Icons.check_circle, color: Colors.green, size: 18),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text("${n.desc}$prereqLine"),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: unlocked
                              ? const SizedBox(height: 32)
                              : ElevatedButton(
                                  onPressed: can ? () => controller.unlockResearch(n) : null,
                                  child: const Text("Unlock"),
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text(
                    "Research Tree",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Spend RP to unlock progression. You gain 1 RP each wave.",
                    style: TextStyle(color: onSurface.withOpacity(0.60), fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Tip: Shift + scroll to pan sideways.",
                    style: TextStyle(color: onSurface.withOpacity(0.50), fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  if (nodeById.containsKey("r_start")) ...[
                    SizedBox(
                      width: double.infinity,
                      child: buildBaselineCard(nodeById["r_start"]!),
                    ),
                    const SizedBox(height: 6),
                  ],
                  SizedBox(
                    height: listHeight,
                    child: Scrollbar(
                      controller: _laneScrollController,
                      thumbVisibility: true,
                      trackVisibility: true,
                      interactive: true,
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(
                          dragDevices: {
                            PointerDeviceKind.mouse,
                            PointerDeviceKind.touch,
                            PointerDeviceKind.trackpad,
                            PointerDeviceKind.stylus,
                          },
                        ),
                        child: SingleChildScrollView(
                          controller: _laneScrollController,
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final lane in lanes)
                                Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: SizedBox(
                                    width: 220,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          lane.$1,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(fontWeight: FontWeight.w900, color: onSurface.withOpacity(0.70)),
                                        ),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          height: (listHeight - 28).clamp(0.0, listHeight),
                                          child: SingleChildScrollView(
                                            child: Column(
                                              children: [
                                                for (final id in lane.$2)
                                                  if (nodeById.containsKey(id)) buildNodeCard(nodeById[id]!),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child:
                        Text("RP Available: ${controller.researchPoints}", style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
