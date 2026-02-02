import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// ===============================
/// Upgrades / Rewards
/// ===============================
enum UpgradeRarity { common, rare, epic }

enum Difficulty { easy, normal, hard }
enum BoardEdge { left, right, top, bottom }

class UpgradeCard {
  final String id;
  final String name;
  final String description;
  final UpgradeRarity rarity;
  final void Function(GameController c) apply;
  const UpgradeCard({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
    required this.apply,
  });
}

/// ===============================
/// Research Tree
/// ===============================
class ResearchNode {
  final String id;
  final String title;
  final String desc;
  final int cost;
  final List<String> prereq;
  final void Function(GameController c) apply;
  ResearchNode({
    required this.id,
    required this.title,
    required this.desc,
    required this.cost,
    required this.prereq,
    required this.apply,
  });
}

class BoardPreset {
  final String id;
  final String name;
  final String desc;
  final BoardEdge spawnEdge;
  final BoardEdge exitEdge;
  final int targetWave;
  final Color accent;

  const BoardPreset({
    required this.id,
    required this.name,
    required this.desc,
    required this.spawnEdge,
    required this.exitEdge,
    required this.targetWave,
    required this.accent,
  });
}

class WaveBriefing {
  final int wave;
  final bool bossWave;
  final int count;
  final Map<VirusType, double> typeWeights;
  final double splitChance;
  final double rageChance;
  final double zigzagChance;
  final double shieldChanceTank;
  final double shieldChanceOther;
  final double immuneChanceStealth;
  final double immuneChanceOther;

  WaveBriefing({
    required this.wave,
    required this.bossWave,
    required this.count,
    required this.typeWeights,
    required this.splitChance,
    required this.rageChance,
    required this.zigzagChance,
    required this.shieldChanceTank,
    required this.shieldChanceOther,
    required this.immuneChanceStealth,
    required this.immuneChanceOther,
  });
}

class BreachEvent {
  final VirusType type;
  final double damage;
  BreachEvent({required this.type, required this.damage});
}

class WaveSummary {
  final int wave;
  final int kills;
  final int breaches;
  final double infectionGained;
  final Map<CellType, double> damageByCell;
  final List<BreachEvent> breachLog;

  WaveSummary({
    required this.wave,
    required this.kills,
    required this.breaches,
    required this.infectionGained,
    required this.damageByCell,
    required this.breachLog,
  });
}

/// ===============================
/// Cell Types + tiers
/// ===============================
enum CellType { killer, macrophage, support, sentinel, cleaner }

extension CellProps on CellType {
  String get label => switch (this) {
        CellType.killer => "Killer",
        CellType.macrophage => "Macrophage",
        CellType.support => "Support",
        CellType.sentinel => "Sentinel",
        CellType.cleaner => "Cleaner",
      };

  String get lore => switch (this) {
        CellType.killer => "Targets and kills viruses with focused lysis beams.",
        CellType.macrophage => "Engulfs and weakens. Slows targets, helps burst groups.",
        CellType.support => "Buff aura boosts nearby defenders (damage + fire rate).",
        CellType.sentinel => "Long-range piercer that lines up multiple targets.",
        CellType.cleaner => "Disrupts shields and suppresses immunities.",
      };

  int get baseCost => switch (this) {
        CellType.killer => 10,
        CellType.macrophage => 12,
        CellType.support => 9,
        CellType.sentinel => 13,
        CellType.cleaner => 10,
      };

  double get baseDamage => switch (this) {
        CellType.killer => 7.0,
        CellType.macrophage => 4.2,
        CellType.support => 0.0,
        CellType.sentinel => 5.0,
        CellType.cleaner => 2.8,
      };

  double get baseFireRate => switch (this) {
        CellType.killer => 0.38,
        CellType.macrophage => 0.60,
        CellType.support => 9999,
        CellType.sentinel => 0.95,
        CellType.cleaner => 0.60,
      };

  double get baseRange => switch (this) {
        CellType.killer => 0.20,
        CellType.macrophage => 0.15,
        CellType.support => 0.22,
        CellType.sentinel => 0.30,
        CellType.cleaner => 0.17,
      };

  Color get color => switch (this) {
        CellType.killer => Colors.teal,
        CellType.macrophage => Colors.orange,
        CellType.support => Colors.indigo,
        CellType.sentinel => Colors.cyan,
        CellType.cleaner => Colors.green,
      };
}

/// ===============================
/// Virus Types + traits
/// ===============================
enum VirusType { swarm, tank, stealth, boss, leech, spore }

extension VirusProps on VirusType {
  double get baseHp => switch (this) {
        VirusType.swarm => 13,
        VirusType.tank => 34,
        VirusType.stealth => 17,
        VirusType.boss => 140,
        VirusType.leech => 15,
        VirusType.spore => 24,
      };

  double get baseSpeed => switch (this) {
        VirusType.swarm => 0.23,
        VirusType.tank => 0.11,
        VirusType.stealth => 0.19,
        VirusType.boss => 0.12,
        VirusType.leech => 0.21,
        VirusType.spore => 0.14,
      };

  double get breachDamage => switch (this) {
        VirusType.swarm => 1.0,
        VirusType.tank => 2.4,
        VirusType.stealth => 1.3,
        VirusType.boss => 3.5,
        VirusType.leech => 1.2,
        VirusType.spore => 1.5,
      };

  Color get color => switch (this) {
        VirusType.swarm => Colors.pinkAccent,
        VirusType.tank => Colors.deepPurpleAccent,
        VirusType.stealth => Colors.blueGrey,
        VirusType.boss => Colors.redAccent,
        VirusType.leech => Colors.lightGreenAccent,
        VirusType.spore => Colors.deepOrangeAccent,
      };
}

class VirusTraits {
  final bool splitOnDeath;
  final bool shielded;
  final bool rageSprint;
  final bool immuneToSlow;
  final bool zigzag;

  const VirusTraits({
    required this.splitOnDeath,
    required this.shielded,
    required this.rageSprint,
    required this.immuneToSlow,
    required this.zigzag,
  });
}

/// ===============================
/// Core Entities
/// ===============================
class CellUnit {
  final CellType type;
  int tier;

  double x;
  double y;

  double attackCooldown = 0;

  CellUnit({
    required this.type,
    required this.tier,
    required this.x,
    required this.y,
  });

  double get range => type.baseRange * (1.0 + (tier - 1) * 0.15);
  double get damage => type.baseDamage * (1.0 + (tier - 1) * 0.65);

  double get fireRate {
    final base = type.baseFireRate;
    if (base > 9000) return base;
    return base * (1.0 - (tier - 1) * 0.10);
  }
}

class VirusUnit {
  final VirusType type;
  final VirusTraits traits;

  double x;
  double y;

  double hp;
  final double maxHp;

  double shieldHp;

  double slowTimer = 0;
  double weakenTimer = 0;
  double disruptTimer = 0;

  double targetY;
  double retargetTimer;

  double bossSpawnTimer = 9999;

  VirusUnit({
    required this.type,
    required this.traits,
    required this.x,
    required this.y,
    required this.hp,
    required this.maxHp,
    required this.shieldHp,
    required this.targetY,
    required this.retargetTimer,
  });

  bool get isDead => hp <= 0;

  void applyDamage(double dmg) {
    if (shieldHp > 0) {
      final used = min(shieldHp, dmg);
      shieldHp -= used;
      dmg -= used;
    }
    if (dmg > 0) hp -= dmg;
  }

  double get speedMult {
    double m = 1.0;
    if (traits.rageSprint && hp < maxHp * 0.45) m *= 1.45;
    if (slowTimer > 0 && (!traits.immuneToSlow || disruptTimer > 0)) m *= 0.55;
    return m;
  }
}

/// ===============================
/// FX Entities
/// ===============================
enum BeamStyle { laser, immuneStream, engulf }

class BeamEvent {
  final Offset from;
  final Offset to;
  final Color color;
  final BeamStyle style;
  double ttl;
  BeamEvent({required this.from, required this.to, required this.color, required this.style, required this.ttl});
}

class ImpactEvent {
  final Offset pos;
  final Color color;
  double ttl;
  ImpactEvent({required this.pos, required this.color, required this.ttl});
}

class PulseEvent {
  final Offset pos;
  final Color color;
  final double maxTtl;
  double ttl;
  PulseEvent({required this.pos, required this.color, required this.ttl}) : maxTtl = ttl;
}

class Particle {
  Offset pos;
  Offset vel;
  double r;
  double ttl;
  Color color;
  Particle({required this.pos, required this.vel, required this.r, required this.ttl, required this.color});

  void update(double dt) {
    pos = pos + vel * dt;
    vel = vel * pow(0.85, dt * 60).toDouble();
    ttl -= dt;
  }
}

/// ===============================
/// Controller
/// ===============================
class GameController extends ChangeNotifier {
  final Random rng = Random();

  Difficulty difficulty = Difficulty.normal;
  BoardPreset boardPreset = const BoardPreset(
    id: "default",
    name: "Capillary Run",
    desc: "Standard left-to-right flow.",
    spawnEdge: BoardEdge.left,
    exitEdge: BoardEdge.right,
    targetWave: 10,
    accent: Colors.redAccent,
  );
  int targetWave = 10;
  Offset _travelDir = const Offset(1, 0);
  bool _driftOnX = false;

  int dna = 50;

  int wave = 0;
  bool waveActive = false;
  bool gameOver = false;
  bool victory = false;

  double infection = 0;
  double infectionMax = 10;

  CellType selectedCell = CellType.killer;
  Offset? hoverPos;

  final List<CellUnit> cells = [];
  final List<VirusUnit> viruses = [];

  final List<BeamEvent> beams = [];
  final List<ImpactEvent> impacts = [];
  final List<PulseEvent> pulses = [];
  final List<Particle> particles = [];

  Timer? _timer;
  double renderTime = 0;

  int _virusesToSpawn = 0;
  int _spawned = 0;
  double _spawnCooldown = 0;

  bool rewardPending = false;
  bool rewardModalOpen = false;
  List<UpgradeCard> rewardChoices = const [];

  final Set<CellType> unlockedCells = {
    CellType.killer,
    CellType.macrophage,
    CellType.support,
  };
  final Set<VirusType> unlockedVirusTypes = {
    VirusType.swarm,
    VirusType.tank,
    VirusType.stealth,
  };

  int dnaPerKill = 0;
  int killDnaThisWave = 0;
  int killDnaCap = 30;

  int killsThisWave = 0;
  int breachesThisWave = 0;
  double infectionGainedThisWave = 0;
  final List<BreachEvent> breachLogThisWave = [];
  final Map<CellType, double> damageThisWave = {
    CellType.killer: 0.0,
    CellType.macrophage: 0.0,
    CellType.support: 0.0,
    CellType.sentinel: 0.0,
    CellType.cleaner: 0.0,
  };
  WaveSummary? lastWaveSummary;

  double killerDamageMult = 1.0;
  double killerFireMult = 1.0;
  double killerRangeBonus = 0.0;

  double macrophageWeakenBonus = 0.10;
  double macrophageWeakenDuration = 0.75;
  double macrophageSlowDuration = 0.80;
  bool macrophageSplash = false;

  double supportAuraDamageMult = 1.25;
  double supportAuraFireBonus = 0.08;
  double supportAuraRangeBonus = 0.0;

  double breachDamageMult = 1.0;

  int mergeCountRequired = 3;
  double mergeRadius = 0.045;

  int researchPoints = 0;
  final Set<String> unlockedResearch = {};

  late final List<UpgradeCard> upgradePool;
  late final List<ResearchNode> researchTree;

  GameController() {
    upgradePool = _buildUpgradePool();
    researchTree = _buildResearchTree();
    _configureTravel(boardPreset.exitEdge);
  }

  double get _cellDamageDifficultyMult => switch (difficulty) {
        Difficulty.easy => 1.15,
        Difficulty.normal => 1.0,
        Difficulty.hard => 0.90,
      };

  double get _virusHpDifficultyMult => switch (difficulty) {
        Difficulty.easy => 0.90,
        Difficulty.normal => 1.0,
        Difficulty.hard => 1.12,
      };

  double get _breachDifficultyMult => switch (difficulty) {
        Difficulty.easy => 0.90,
        Difficulty.normal => 1.0,
        Difficulty.hard => 1.10,
      };

  double get _spawnCountDifficultyMult => switch (difficulty) {
        Difficulty.easy => 0.85,
        Difficulty.normal => 1.0,
        Difficulty.hard => 1.10,
      };

  int get _startDnaByDifficulty => switch (difficulty) {
        Difficulty.easy => 60,
        Difficulty.normal => 50,
        Difficulty.hard => 45,
      };

  double get _infectionMaxByDifficulty => switch (difficulty) {
        Difficulty.easy => 12,
        Difficulty.normal => 10,
        Difficulty.hard => 9,
      };

  void setDifficulty(Difficulty value) {
    if (difficulty == value) return;
    difficulty = value;
    reset();
  }

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      try {
        _tick(0.033);
      } catch (e, st) {
        debugPrint("TICK ERROR: $e\n$st");
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void reset({bool preserveResearch = false}) {
    dna = _startDnaByDifficulty;
    wave = 0;
    waveActive = false;
    gameOver = false;
    victory = false;

    infection = 0;
    infectionMax = _infectionMaxByDifficulty;
    selectedCell = CellType.killer;
    hoverPos = null;

    cells.clear();
    viruses.clear();
    beams.clear();
    impacts.clear();
    pulses.clear();
    particles.clear();

    _virusesToSpawn = 0;
    _spawned = 0;
    _spawnCooldown = 0;

    rewardPending = false;
    rewardModalOpen = false;
    rewardChoices = const [];

    if (!preserveResearch) {
      unlockedCells
        ..clear()
        ..addAll([CellType.killer, CellType.macrophage, CellType.support]);
    }
    unlockedVirusTypes
      ..clear()
      ..addAll([VirusType.swarm, VirusType.tank, VirusType.stealth]);

    dnaPerKill = 0;
    killDnaThisWave = 0;
    killsThisWave = 0;
    breachesThisWave = 0;
    infectionGainedThisWave = 0;
    breachLogThisWave.clear();
    damageThisWave.updateAll((_, __) => 0.0);
    lastWaveSummary = null;

    killerDamageMult = 1.0;
    killerFireMult = 1.0;
    killerRangeBonus = 0.0;

    macrophageWeakenBonus = 0.10;
    macrophageWeakenDuration = 0.75;
    macrophageSlowDuration = 0.80;
    macrophageSplash = false;

    supportAuraDamageMult = 1.30;
    supportAuraFireBonus = 0.10;
    supportAuraRangeBonus = 0.0;

    breachDamageMult = _breachDifficultyMult;

    mergeCountRequired = 3;
    mergeRadius = 0.045;

    if (!preserveResearch) {
      researchPoints = 0;
      unlockedResearch.clear();
    }

    notifyListeners();
  }

  void selectCell(CellType t) {
    if (!unlockedCells.contains(t)) return;
    selectedCell = t;
    notifyListeners();
  }

  bool isCellUnlocked(CellType t) => unlockedCells.contains(t);

  void unlockCell(CellType t) {
    if (unlockedCells.add(t)) {
      notifyListeners();
    }
  }

  void setHover(Offset? normalized) {
    hoverPos = normalized;
    notifyListeners();
  }

  bool canPlaceAt(Offset pos) {
    if (gameOver || waveActive || rewardPending) return false;
    if (dna < selectedCell.baseCost) return false;

    double minX = 0.02;
    double maxX = 0.98;
    double minY = 0.02;
    double maxY = 0.98;

    if (boardPreset.spawnEdge == BoardEdge.left || boardPreset.exitEdge == BoardEdge.left) minX = 0.07;
    if (boardPreset.spawnEdge == BoardEdge.right || boardPreset.exitEdge == BoardEdge.right) maxX = 0.93;
    if (boardPreset.spawnEdge == BoardEdge.top || boardPreset.exitEdge == BoardEdge.top) minY = 0.07;
    if (boardPreset.spawnEdge == BoardEdge.bottom || boardPreset.exitEdge == BoardEdge.bottom) maxY = 0.93;

    if (pos.dx < minX || pos.dx > maxX || pos.dy < minY || pos.dy > maxY) return false;
    return true;
  }

  void placeCellAt(Offset pos) {
    if (!canPlaceAt(pos)) return;

    dna -= selectedCell.baseCost;

    cells.add(CellUnit(type: selectedCell, tier: 1, x: pos.dx, y: pos.dy));

    pulses.add(PulseEvent(pos: pos, color: selectedCell.color, ttl: 0.55));
    _spawnPuff(pos, selectedCell.color);

    _tryMergeAt(pos, selectedCell);

    notifyListeners();
  }

  void _spawnPuff(Offset pos, Color c) {
    for (int i = 0; i < 12; i++) {
      final a = rng.nextDouble() * 2 * pi;
      final mag = 0.35 + rng.nextDouble() * 0.55;
      particles.add(
        Particle(
          pos: pos + Offset((rng.nextDouble() - 0.5) * 0.01, (rng.nextDouble() - 0.5) * 0.01),
          vel: Offset(cos(a) * mag, sin(a) * mag),
          r: 0.003 + rng.nextDouble() * 0.003,
          ttl: 0.35 + rng.nextDouble() * 0.25,
          color: c.withOpacity(0.55),
        ),
      );
    }
  }

  void _tryMergeAt(Offset pos, CellType type) {
    final nearby = cells.where((c) {
      if (c.type != type) return false;
      if (c.tier != 1) return false;
      final dx = c.x - pos.dx;
      final dy = c.y - pos.dy;
      return sqrt(dx * dx + dy * dy) <= mergeRadius;
    }).toList();

    if (nearby.length < mergeCountRequired) return;

    nearby.sort((a, b) {
      final da = (a.x - pos.dx) * (a.x - pos.dx) + (a.y - pos.dy) * (a.y - pos.dy);
      final db = (b.x - pos.dx) * (b.x - pos.dx) + (b.y - pos.dy) * (b.y - pos.dy);
      return da.compareTo(db);
    });

    final mergeSet = nearby.take(mergeCountRequired).toList();
    final mx = mergeSet.map((e) => e.x).reduce((a, b) => a + b) / mergeSet.length;
    final my = mergeSet.map((e) => e.y).reduce((a, b) => a + b) / mergeSet.length;
    final mPos = Offset(mx, my);

    for (final c in mergeSet) {
      cells.remove(c);
    }

    cells.add(CellUnit(type: type, tier: 2, x: mPos.dx, y: mPos.dy));

    pulses.add(PulseEvent(pos: mPos, color: type.color, ttl: 0.85));
    _spawnFusionBurst(mPos, type.color);

    _tryMergeTier2(mPos, type);
  }

  void _tryMergeTier2(Offset pos, CellType type) {
    final nearby = cells.where((c) {
      if (c.type != type) return false;
      if (c.tier != 2) return false;
      final dx = c.x - pos.dx;
      final dy = c.y - pos.dy;
      return sqrt(dx * dx + dy * dy) <= mergeRadius * 1.15;
    }).toList();

    if (nearby.length < mergeCountRequired) return;

    nearby.sort((a, b) {
      final da = (a.x - pos.dx) * (a.x - pos.dx) + (a.y - pos.dy) * (a.y - pos.dy);
      final db = (b.x - pos.dx) * (b.x - pos.dx) + (b.y - pos.dy) * (b.y - pos.dy);
      return da.compareTo(db);
    });

    final mergeSet = nearby.take(mergeCountRequired).toList();
    final mx = mergeSet.map((e) => e.x).reduce((a, b) => a + b) / mergeSet.length;
    final my = mergeSet.map((e) => e.y).reduce((a, b) => a + b) / mergeSet.length;
    final mPos = Offset(mx, my);

    for (final c in mergeSet) {
      cells.remove(c);
    }

    cells.add(CellUnit(type: type, tier: 3, x: mPos.dx, y: mPos.dy));

    pulses.add(PulseEvent(pos: mPos, color: type.color.withOpacity(0.95), ttl: 1.05));
    _spawnFusionBurst(mPos, type.color.withOpacity(0.9));
  }

  void _spawnFusionBurst(Offset pos, Color c) {
    for (int i = 0; i < 24; i++) {
      final a = rng.nextDouble() * 2 * pi;
      final mag = 0.75 + rng.nextDouble() * 0.75;
      particles.add(
        Particle(
          pos: pos,
          vel: Offset(cos(a) * mag, sin(a) * mag),
          r: 0.004 + rng.nextDouble() * 0.004,
          ttl: 0.55 + rng.nextDouble() * 0.30,
          color: c.withOpacity(0.65),
        ),
      );
    }
  }

  void startWave() {
    if (gameOver || waveActive || rewardPending) return;

    wave++;
    waveActive = true;

    _updateVirusUnlocksForWave(wave);

    _virusesToSpawn = ((8 + wave * 3) * _spawnCountDifficultyMult).round();
    if (_virusesToSpawn < 1) _virusesToSpawn = 1;
    _spawned = 0;
    _spawnCooldown = 0;

    killDnaThisWave = 0;
    killsThisWave = 0;
    breachesThisWave = 0;
    infectionGainedThisWave = 0;
    breachLogThisWave.clear();
    damageThisWave.updateAll((_, __) => 0.0);
    lastWaveSummary = null;

    if (wave == 5) {
      _virusesToSpawn = 1;
    }

    notifyListeners();
  }

  void _updateVirusUnlocksForWave(int w) {
    unlockedVirusTypes
      ..clear()
      ..addAll([VirusType.swarm, VirusType.tank, VirusType.stealth]);
    if (w >= 3) unlockedVirusTypes.add(VirusType.leech);
    if (w >= 7) unlockedVirusTypes.add(VirusType.spore);
  }

  Map<VirusType, double> _virusWeightsForWave(int w) {
    final weights = <VirusType, double>{
      VirusType.swarm: 0.50,
      VirusType.stealth: 0.22,
      VirusType.tank: 0.18,
    };

    if (w >= 3) {
      weights[VirusType.leech] = 0.06;
    }
    if (w >= 7) {
      weights[VirusType.spore] = 0.06;
    }

    final gated = <VirusType, double>{
      for (final e in weights.entries)
        if (unlockedVirusTypes.contains(e.key)) e.key: e.value,
    };

    final total = gated.values.fold(0.0, (a, b) => a + b);
    return {for (final e in gated.entries) e.key: e.value / total};
  }

  WaveBriefing getWaveBriefing() {
    final nextWave = wave + 1;
    final bossWave = nextWave == 5;
    final count = bossWave ? 1 : (8 + nextWave * 3);
    final typeWeights = _virusWeightsForWave(nextWave);

    final splitChance = min(0.28, 0.10 + nextWave * 0.015);
    final rageChance = min(0.40, 0.12 + nextWave * 0.018);
    final zigzagChance = min(0.60, 0.22 + nextWave * 0.02);

    final shieldChanceTank = min(0.70, 0.25 + nextWave * 0.03);
    final shieldChanceOther = min(0.30, 0.08 + nextWave * 0.015);

    final immuneChanceStealth = min(0.80, 0.25 + nextWave * 0.03);
    final immuneChanceOther = min(0.30, 0.05 + nextWave * 0.015);

    return WaveBriefing(
      wave: nextWave,
      bossWave: bossWave,
      count: count,
      typeWeights: typeWeights,
      splitChance: splitChance,
      rageChance: rageChance,
      zigzagChance: zigzagChance,
      shieldChanceTank: shieldChanceTank,
      shieldChanceOther: shieldChanceOther,
      immuneChanceStealth: immuneChanceStealth,
      immuneChanceOther: immuneChanceOther,
    );
  }

  void _recordDamage(CellType type, double amount) {
    damageThisWave[type] = (damageThisWave[type] ?? 0.0) + amount;
  }

  void _spawnVirus({VirusType? forceType, Offset? forcePos}) {
    final type = forceType ?? _rollVirusType();

    final hpScale = (1.0 + wave * 0.10) * _virusHpDifficultyMult;
    final traits = _rollTraits(type);

    Offset spawn = forcePos ?? _randomSpawnPos();
    final spawnX = spawn.dx;
    final spawnY = spawn.dy;

    double shieldHp = 0;
    if (traits.shielded) shieldHp = (type.baseHp * hpScale) * 0.40;

    final v = VirusUnit(
      type: type,
      traits: traits,
      x: spawnX,
      y: spawnY,
      hp: type.baseHp * hpScale,
      maxHp: type.baseHp * hpScale,
      shieldHp: shieldHp,
      targetY: _driftOnX ? spawnX : spawnY,
      retargetTimer: 0.35 + rng.nextDouble() * 1.0,
    );

    if (type == VirusType.boss) {
      v.bossSpawnTimer = 1.2;
    }

    viruses.add(v);
    pulses.add(PulseEvent(pos: Offset(v.x, v.y), color: type.color, ttl: type == VirusType.boss ? 1.1 : 0.55));
  }

  VirusType _rollVirusType() {
    final weights = _virusWeightsForWave(wave);
    final r = rng.nextDouble();
    double acc = 0;
    for (final entry in weights.entries) {
      acc += entry.value;
      if (r <= acc) return entry.key;
    }
    return VirusType.swarm;
  }

  VirusTraits _rollTraits(VirusType type) {
    final splitChance = min(0.28, 0.10 + wave * 0.015);
    final rageChance = min(0.40, 0.12 + wave * 0.018);
    final zigzagChance = min(0.60, 0.22 + wave * 0.02);

    final shieldChance = type == VirusType.tank
        ? min(0.70, 0.25 + wave * 0.03)
        : min(0.30, 0.08 + wave * 0.015);

    final immuneChance = type == VirusType.stealth
        ? min(0.80, 0.25 + wave * 0.03)
        : min(0.30, 0.05 + wave * 0.015);

    if (type == VirusType.spore) {
      return VirusTraits(
        splitOnDeath: false,
        shielded: rng.nextDouble() < (shieldChance * 0.4),
        rageSprint: false,
        immuneToSlow: false,
        zigzag: true,
      );
    }

    if (type == VirusType.leech) {
      return VirusTraits(
        splitOnDeath: false,
        shielded: rng.nextDouble() < (shieldChance * 0.3),
        rageSprint: rng.nextDouble() < (rageChance * 0.4),
        immuneToSlow: rng.nextDouble() < (immuneChance * 0.5),
        zigzag: rng.nextDouble() < (zigzagChance * 0.6),
      );
    }

    if (type == VirusType.boss) {
      return const VirusTraits(
        splitOnDeath: false,
        shielded: true,
        rageSprint: true,
        immuneToSlow: true,
        zigzag: true,
      );
    }

    return VirusTraits(
      splitOnDeath: rng.nextDouble() < splitChance,
      shielded: rng.nextDouble() < shieldChance,
      rageSprint: rng.nextDouble() < rageChance,
      immuneToSlow: rng.nextDouble() < immuneChance,
      zigzag: rng.nextDouble() < zigzagChance,
    );
  }

  void _tick(double dt) {
    if (gameOver) return;

    renderTime += dt;

    if (waveActive) {
      _spawnCooldown -= dt;

      if (wave == 5 && _spawned == 0 && _spawnCooldown <= 0) {
        _spawnCooldown = 999;
        _spawnVirus(forceType: VirusType.boss, forcePos: _spawnEdgeCenter());
        _spawned++;
      } else if (wave != 5) {
        if (_spawned < _virusesToSpawn && _spawnCooldown <= 0) {
          _spawnCooldown = max(0.10, 0.28 - wave * 0.02);
          _spawnVirus();
          _spawned++;
        }
      }
    }

    // boss spawns minions (copy list to avoid concurrent modification)
    final bosses = viruses.where((x) => x.type == VirusType.boss).toList();
    for (final v in bosses) {
      v.bossSpawnTimer -= dt;
      if (v.bossSpawnTimer <= 0) {
        v.bossSpawnTimer = 1.0 + rng.nextDouble() * 0.5;
        final base = Offset(v.x, v.y) - (_travelDir * 0.01);
        final drift = (rng.nextDouble() - 0.5) * 0.18;
        final pos = _driftOnX
            ? Offset((base.dx + drift).clamp(0.05, 0.95), base.dy.clamp(0.05, 0.95))
            : Offset(base.dx.clamp(0.05, 0.95), (base.dy + drift).clamp(0.05, 0.95));
        _spawnVirus(forceType: VirusType.swarm, forcePos: pos);
      }
    }

    for (final v in viruses) {
      final base = v.type.baseSpeed * (1.0 + wave * 0.05);

      v.retargetTimer -= dt;
      if (v.retargetTimer <= 0) {
        v.retargetTimer = 0.25 + rng.nextDouble() * 1.2;
        final drift = (rng.nextDouble() - 0.5) * (v.traits.zigzag ? 0.35 : 0.18);
        v.targetY = (v.targetY + drift).clamp(0.05, 0.95);
      }

      if (_driftOnX) {
        final dx = v.targetY - v.x;
        v.x += dx * dt * (v.traits.zigzag ? 2.6 : 1.7);
      } else {
        final dy = v.targetY - v.y;
        v.y += dy * dt * (v.traits.zigzag ? 2.6 : 1.7);
      }

      v.x += base * v.speedMult * dt * _travelDir.dx;
      v.y += base * v.speedMult * dt * _travelDir.dy;

      if (v.slowTimer > 0) v.slowTimer -= dt;
      if (v.weakenTimer > 0) v.weakenTimer -= dt;
      if (v.disruptTimer > 0) v.disruptTimer -= dt;
    }

    _cellsAttack(dt);

    for (final b in beams) b.ttl -= dt;
    beams.removeWhere((b) => b.ttl <= 0);

    for (final i in impacts) i.ttl -= dt;
    impacts.removeWhere((i) => i.ttl <= 0);

    for (final p in pulses) p.ttl -= dt;
    pulses.removeWhere((p) => p.ttl <= 0);

    for (final p in particles) p.update(dt);
    particles.removeWhere((p) => p.ttl <= 0);

    _handleDeaths();

    final breached = viruses.where(_isBreached).toList();
    if (breached.isNotEmpty) {
      for (final v in breached) {
        final dmg = v.type.breachDamage * breachDamageMult;
        infection += dmg;
        breachesThisWave += 1;
        infectionGainedThisWave += dmg;
        breachLogThisWave.add(BreachEvent(type: v.type, damage: dmg));
        if (v.type == VirusType.leech) {
          dna = max(0, dna - 3);
        }
      }
      viruses.removeWhere((v) => breached.contains(v));
    }

    if (waveActive) {
      final allSpawned = _spawned >= _virusesToSpawn;
      final noneAlive = viruses.isEmpty;

      if (allSpawned && noneAlive) {
        waveActive = false;
        dna += 15 + wave * 3;
        researchPoints += 1;

        lastWaveSummary = WaveSummary(
          wave: wave,
          kills: killsThisWave,
          breaches: breachesThisWave,
          infectionGained: infectionGainedThisWave,
          damageByCell: {
            CellType.killer: damageThisWave[CellType.killer] ?? 0.0,
            CellType.macrophage: damageThisWave[CellType.macrophage] ?? 0.0,
            CellType.support: damageThisWave[CellType.support] ?? 0.0,
            CellType.sentinel: damageThisWave[CellType.sentinel] ?? 0.0,
            CellType.cleaner: damageThisWave[CellType.cleaner] ?? 0.0,
          },
          breachLog: List<BreachEvent>.from(breachLogThisWave),
        );

        rewardPending = true;
        rewardChoices = _rollRewards();

        notifyListeners();
      }
    }

    if (infection >= infectionMax) {
      gameOver = true;
      victory = false;
    }

    if (!gameOver && wave >= targetWave && !waveActive && viruses.isEmpty && !rewardPending) {
      gameOver = true;
      victory = true;
    }

    notifyListeners();
  }

  bool _isBuffed(CellUnit c) {
    if (c.type == CellType.support) return false;
    final aura = CellType.support.baseRange + supportAuraRangeBonus;

    for (final s in cells.where((x) => x.type == CellType.support)) {
      final dx = c.x - s.x;
      final dy = c.y - s.y;
      final d = sqrt(dx * dx + dy * dy);
      if (d <= aura) return true;
    }
    return false;
  }

  double _supportDamageMult(CellUnit c) => _isBuffed(c) ? supportAuraDamageMult : 1.0;
  double _supportFireMult(CellUnit c) => _isBuffed(c) ? (1.0 - supportAuraFireBonus) : 1.0;

  void _cellsAttack(double dt) {
    for (final c in cells) {
      if (c.type == CellType.support) continue;

      c.attackCooldown -= dt;
      if (c.attackCooldown > 0) continue;

      final range = c.range + (c.type == CellType.killer ? killerRangeBonus : 0.0);

      VirusUnit? best;
      double bestD = 999;

      for (final v in viruses) {
        final dx = v.x - c.x;
        final dy = v.y - c.y;
        final d = sqrt(dx * dx + dy * dy);
        if (d <= range && d < bestD) {
          bestD = d;
          best = v;
        }
      }

      if (best == null) continue;

      if (c.type == CellType.killer) {
        _attackKiller(c, best);
      } else if (c.type == CellType.macrophage) {
        _attackMacrophage(c, best);
      } else if (c.type == CellType.sentinel) {
        _attackSentinel(c, best);
      } else if (c.type == CellType.cleaner) {
        _attackCleaner(c, best);
      }

      c.attackCooldown = c.fireRate * (c.type == CellType.killer ? killerFireMult : 1.0) * _supportFireMult(c);
    }
  }

  void _attackKiller(CellUnit c, VirusUnit v) {
    var dmg = c.damage * killerDamageMult * _supportDamageMult(c) * _cellDamageDifficultyMult;

    if (v.weakenTimer > 0) dmg *= (1.0 + macrophageWeakenBonus);

    v.applyDamage(dmg);
    _recordDamage(CellType.killer, dmg);

    beams.add(
      BeamEvent(
        from: Offset(c.x, c.y),
        to: Offset(v.x, v.y),
        color: CellType.killer.color,
        style: BeamStyle.laser,
        ttl: 0.10,
      ),
    );

    impacts.add(ImpactEvent(pos: Offset(v.x, v.y), color: CellType.killer.color, ttl: 0.14));
  }

  void _attackMacrophage(CellUnit c, VirusUnit v) {
    var dmg = c.damage * _supportDamageMult(c) * _cellDamageDifficultyMult;
    v.applyDamage(dmg);
    _recordDamage(CellType.macrophage, dmg);

    if (!v.traits.immuneToSlow || v.disruptTimer > 0) {
      v.slowTimer = max(v.slowTimer, macrophageSlowDuration + (c.tier - 1) * 0.20);
    }
    v.weakenTimer = max(v.weakenTimer, macrophageWeakenDuration + (c.tier - 1) * 0.25);

    beams.add(
      BeamEvent(
        from: Offset(c.x, c.y),
        to: Offset(v.x, v.y),
        color: CellType.macrophage.color,
        style: BeamStyle.engulf,
        ttl: 0.14,
      ),
    );

    impacts.add(ImpactEvent(pos: Offset(v.x, v.y), color: CellType.macrophage.color, ttl: 0.18));

    if (macrophageSplash) {
      for (final n in viruses) {
        if (identical(n, v)) continue;
        final dx = n.x - v.x;
        final dy = n.y - v.y;
        final d = sqrt(dx * dx + dy * dy);
        if (d < 0.06) {
          n.applyDamage(dmg * 0.35);
          _recordDamage(CellType.macrophage, dmg * 0.35);
          impacts.add(ImpactEvent(pos: Offset(n.x, n.y), color: CellType.macrophage.color, ttl: 0.12));
        }
      }
    }
  }

  void _attackSentinel(CellUnit c, VirusUnit v) {
    final dmg = c.damage * _supportDamageMult(c) * _cellDamageDifficultyMult;
    final origin = Offset(c.x, c.y);
    final target = Offset(v.x, v.y);
    final dir = target - origin;
    final len = dir.distance;
    if (len == 0) return;
    final unit = Offset(dir.dx / len, dir.dy / len);
    int hits = 0;

    for (final n in viruses) {
      final toN = Offset(n.x - origin.dx, n.y - origin.dy);
      final proj = toN.dx * unit.dx + toN.dy * unit.dy;
      if (proj < 0 || proj > c.range) continue;
      final closest = Offset(origin.dx + unit.dx * proj, origin.dy + unit.dy * proj);
      final dx = n.x - closest.dx;
      final dy = n.y - closest.dy;
      final d = sqrt(dx * dx + dy * dy);
      if (d <= 0.02) {
        n.applyDamage(dmg);
        _recordDamage(CellType.sentinel, dmg);
        hits += 1;
        if (hits >= 3) break;
      }
    }

    beams.add(
      BeamEvent(
        from: origin,
        to: origin + unit * c.range,
        color: CellType.sentinel.color,
        style: BeamStyle.immuneStream,
        ttl: 0.12,
      ),
    );
  }

  void _attackCleaner(CellUnit c, VirusUnit v) {
    final dmg = c.damage * _supportDamageMult(c) * _cellDamageDifficultyMult;
    v.applyDamage(dmg);
    _recordDamage(CellType.cleaner, dmg);
    v.shieldHp = 0;
    v.disruptTimer = max(v.disruptTimer, 0.8);

    beams.add(
      BeamEvent(
        from: Offset(c.x, c.y),
        to: Offset(v.x, v.y),
        color: CellType.cleaner.color,
        style: BeamStyle.engulf,
        ttl: 0.12,
      ),
    );

    impacts.add(ImpactEvent(pos: Offset(v.x, v.y), color: CellType.cleaner.color, ttl: 0.12));
  }

  Offset _randomSpawnPos() {
    switch (boardPreset.spawnEdge) {
      case BoardEdge.left:
        return Offset(0.02, rng.nextDouble() * 0.92 + 0.04);
      case BoardEdge.right:
        return Offset(0.98, rng.nextDouble() * 0.92 + 0.04);
      case BoardEdge.top:
        return Offset(rng.nextDouble() * 0.92 + 0.04, 0.02);
      case BoardEdge.bottom:
        return Offset(rng.nextDouble() * 0.92 + 0.04, 0.98);
    }
  }

  Offset _spawnEdgeCenter() {
    switch (boardPreset.spawnEdge) {
      case BoardEdge.left:
        return const Offset(0.03, 0.50);
      case BoardEdge.right:
        return const Offset(0.97, 0.50);
      case BoardEdge.top:
        return const Offset(0.50, 0.03);
      case BoardEdge.bottom:
        return const Offset(0.50, 0.97);
    }
  }

  bool _isBreached(VirusUnit v) {
    switch (boardPreset.exitEdge) {
      case BoardEdge.right:
        return v.x >= 0.98;
      case BoardEdge.left:
        return v.x <= 0.02;
      case BoardEdge.top:
        return v.y <= 0.02;
      case BoardEdge.bottom:
        return v.y >= 0.98;
    }
  }

  /// ===============================
  /// Death handling (UPDATED)
  /// ===============================
  void _handleDeaths() {
    final dead = viruses.where((v) => v.isDead).toList();
    if (dead.isEmpty) return;

    for (final v in dead) {
      final pos = Offset(v.x, v.y);
      killsThisWave += 1;

      // normal death burst
      _deathBurst(pos, v.type.color);

      if (dnaPerKill > 0 && killDnaThisWave < killDnaCap) {
        final grant = min(dnaPerKill, killDnaCap - killDnaThisWave);
        dna += grant;
        killDnaThisWave += grant;
      }

      if (v.type == VirusType.spore) {
        _splitBurstFx(pos, v.type.color);
        for (int i = 0; i < 2; i++) {
          final childPos = Offset(
            (v.x - 0.012).clamp(0.03, 0.40),
            (v.y + (rng.nextDouble() - 0.5) * 0.12).clamp(0.05, 0.95),
          );
          _spawnVirus(forceType: VirusType.swarm, forcePos: childPos);
        }
        continue;
      }

      // ✅ Split Burst animation before spawning children
      if (v.traits.splitOnDeath && v.type != VirusType.boss) {
        _splitBurstFx(pos, v.type.color);

        for (int i = 0; i < 2; i++) {
          final back = _travelDir * -0.015;
          final lateral = _driftOnX
              ? Offset(0, (rng.nextDouble() - 0.5) * 0.08)
              : Offset((rng.nextDouble() - 0.5) * 0.08, 0);
          final childPos = Offset(
            (v.x + back.dx + lateral.dx).clamp(0.03, 0.97),
            (v.y + back.dy + lateral.dy).clamp(0.05, 0.95),
          );
          _spawnVirus(forceType: VirusType.swarm, forcePos: childPos);
        }
      }
    }

    viruses.removeWhere((v) => v.isDead);
  }

  void _deathBurst(Offset pos, Color c) {
    pulses.add(PulseEvent(pos: pos, color: c.withOpacity(0.9), ttl: 0.55));
    for (int i = 0; i < 22; i++) {
      final a = rng.nextDouble() * 2 * pi;
      final mag = 0.55 + rng.nextDouble() * 0.75;
      particles.add(
        Particle(
          pos: pos,
          vel: Offset(cos(a) * mag, sin(a) * mag),
          r: 0.003 + rng.nextDouble() * 0.004,
          ttl: 0.55 + rng.nextDouble() * 0.25,
          color: c.withOpacity(0.65),
        ),
      );
    }
  }

  /// ✅ NEW: Split rupture FX (shockwave + glitter)
  void _splitBurstFx(Offset pos, Color base) {
    // Strong shockwave ring
    pulses.add(PulseEvent(pos: pos, color: Colors.white.withOpacity(0.95), ttl: 0.42));
    pulses.add(PulseEvent(pos: pos, color: base.withOpacity(0.85), ttl: 0.70));

    // "Membrane rupture" particles (bright + fast)
    for (int i = 0; i < 30; i++) {
      final a = rng.nextDouble() * 2 * pi;
      final mag = 1.15 + rng.nextDouble() * 1.00;
      particles.add(
        Particle(
          pos: pos + Offset((rng.nextDouble() - 0.5) * 0.008, (rng.nextDouble() - 0.5) * 0.008),
          vel: Offset(cos(a) * mag, sin(a) * mag),
          r: 0.003 + rng.nextDouble() * 0.005,
          ttl: 0.30 + rng.nextDouble() * 0.22,
          color: Color.lerp(base, Colors.cyanAccent, rng.nextDouble())!.withOpacity(0.85),
        ),
      );
    }
  }

  /// ===============================
  /// Rewards / Upgrades
  /// ===============================
  List<UpgradeCard> _buildUpgradePool() {
    return [
      UpgradeCard(
        id: "killer_dmg_15",
        name: "Sharpened Receptors",
        description: "Killer damage +15%.",
        rarity: UpgradeRarity.common,
        apply: (c) => c.killerDamageMult *= 1.15,
      ),
      UpgradeCard(
        id: "killer_fire_10",
        name: "Rapid Cytotoxicity",
        description: "Killer fire rate +10%.",
        rarity: UpgradeRarity.common,
        apply: (c) => c.killerFireMult *= 0.90,
      ),
      UpgradeCard(
        id: "killer_range",
        name: "Long Range Targeting",
        description: "Killer range +10%.",
        rarity: UpgradeRarity.common,
        apply: (c) => c.killerRangeBonus += 0.02,
      ),
      UpgradeCard(
        id: "macro_slow",
        name: "Sticky Engulfment",
        description: "Macrophage slow duration +0.4s.",
        rarity: UpgradeRarity.common,
        apply: (c) => c.macrophageSlowDuration += 0.40,
      ),
      UpgradeCard(
        id: "macro_weaken",
        name: "Immune Tagging",
        description: "Weaken lasts longer and increases damage taken.",
        rarity: UpgradeRarity.rare,
        apply: (c) {
          c.macrophageWeakenDuration += 0.50;
          c.macrophageWeakenBonus += 0.08;
        },
      ),
      UpgradeCard(
        id: "macro_splash",
        name: "Cytokine Burst",
        description: "Macrophage gains splash damage.",
        rarity: UpgradeRarity.rare,
        apply: (c) => c.macrophageSplash = true,
      ),
      UpgradeCard(
        id: "support_amp",
        name: "Amplification Aura",
        description: "Support aura damage bonus increases.",
        rarity: UpgradeRarity.common,
        apply: (c) => c.supportAuraDamageMult = max(c.supportAuraDamageMult, 1.40),
      ),
      UpgradeCard(
        id: "support_fire",
        name: "Rapid Signaling",
        description: "Buffed cells fire faster in aura.",
        rarity: UpgradeRarity.common,
        apply: (c) => c.supportAuraFireBonus = max(c.supportAuraFireBonus, 0.16),
      ),
      UpgradeCard(
        id: "support_range",
        name: "Wide Spectrum Signals",
        description: "Support aura range increases.",
        rarity: UpgradeRarity.rare,
        apply: (c) => c.supportAuraRangeBonus += 0.03,
      ),
      UpgradeCard(
        id: "kill_dna",
        name: "Harvest Antigens",
        description: "+1 DNA per kill (cap 30/wave).",
        rarity: UpgradeRarity.rare,
        apply: (c) => c.dnaPerKill = max(c.dnaPerKill, 1),
      ),
      UpgradeCard(
        id: "breach_resist",
        name: "Membrane Hardening",
        description: "Breach damage reduced by 12%.",
        rarity: UpgradeRarity.common,
        apply: (c) => c.breachDamageMult *= 0.88,
      ),
      UpgradeCard(
        id: "merge_radius",
        name: "Fusion Gel",
        description: "Merge radius increases (easier Elite merges).",
        rarity: UpgradeRarity.rare,
        apply: (c) => c.mergeRadius += 0.010,
      ),
    ];
  }

  List<UpgradeCard> _rollRewards() {
    final commons = upgradePool.where((u) => u.rarity == UpgradeRarity.common).toList();
    final rares = upgradePool.where((u) => u.rarity == UpgradeRarity.rare).toList();

    UpgradeCard pick() {
      final r = rng.nextDouble();
      if (r < 0.70) return commons[rng.nextInt(commons.length)];
      return rares[rng.nextInt(rares.length)];
    }

    final out = <UpgradeCard>[];
    int guard = 0;
    while (out.length < 3 && guard++ < 100) {
      final c = pick();
      if (out.any((x) => x.id == c.id)) continue;
      out.add(c);
    }
    return out;
  }

  void pickReward(UpgradeCard card) {
    if (!rewardPending) return;
    card.apply(this);
    rewardPending = false;
    rewardChoices = const [];
    notifyListeners();
  }

  /// ===============================
  /// Research Tree
  /// ===============================
  List<ResearchNode> _buildResearchTree() {
    return [
      ResearchNode(
        id: "r_start",
        title: "Baseline Protocol",
        desc: "Unlocks research tree.",
        cost: 0,
        prereq: const [],
        apply: (_) {},
      ),
      ResearchNode(
        id: "r_lane_core",
        title: "Core Systems",
        desc: "Unlocks defense + economy research.",
        cost: 1,
        prereq: const ["r_start"],
        apply: (_) {},
      ),
      ResearchNode(
        id: "r_lane_fusion",
        title: "Fusion Lab",
        desc: "Unlocks fusion research.",
        cost: 1,
        prereq: const ["r_start"],
        apply: (_) {},
      ),
      ResearchNode(
        id: "r_lane_support",
        title: "Signal Lab",
        desc: "Unlocks support research.",
        cost: 1,
        prereq: const ["r_start"],
        apply: (_) {},
      ),
      ResearchNode(
        id: "r_lane_macro",
        title: "Engulfment Lab",
        desc: "Unlocks macrophage research.",
        cost: 1,
        prereq: const ["r_start"],
        apply: (_) {},
      ),
      ResearchNode(
        id: "r_lane_killer",
        title: "Lysis Lab",
        desc: "Unlocks killer research.",
        cost: 1,
        prereq: const ["r_start"],
        apply: (_) {},
      ),
      // Fusion branch
      ResearchNode(
        id: "r_merge2",
        title: "Stabilized Fusion",
        desc: "Fusion gel stability improves (merge radius +).",
        cost: 1,
        prereq: const ["r_lane_fusion"],
        apply: (c) => c.mergeRadius += 0.008,
      ),
      ResearchNode(
        id: "r_merge3",
        title: "Fusion Surge",
        desc: "Fusion radius increases further.",
        cost: 2,
        prereq: const ["r_merge2"],
        apply: (c) => c.mergeRadius += 0.010,
      ),
      ResearchNode(
        id: "r_merge4",
        title: "Rapid Fusion",
        desc: "Requires fewer same-type cells to merge.",
        cost: 4,
        prereq: const ["r_merge3"],
        apply: (c) => c.mergeCountRequired = max(2, c.mergeCountRequired - 1),
      ),
      // Support branch
      ResearchNode(
        id: "r_support_lux",
        title: "Signal Optimization",
        desc: "Support aura damage buff improved.",
        cost: 2,
        prereq: const ["r_lane_support"],
        apply: (c) => c.supportAuraDamageMult = max(c.supportAuraDamageMult, 1.50),
      ),
      ResearchNode(
        id: "r_support_range2",
        title: "Signal Reach",
        desc: "Support aura range increases.",
        cost: 2,
        prereq: const ["r_support_lux"],
        apply: (c) => c.supportAuraRangeBonus += 0.03,
      ),
      ResearchNode(
        id: "r_support_fire2",
        title: "Signal Acceleration",
        desc: "Buffed cells fire faster in aura.",
        cost: 2,
        prereq: const ["r_support_lux"],
        apply: (c) => c.supportAuraFireBonus = max(c.supportAuraFireBonus, 0.18),
      ),
      ResearchNode(
        id: "r_support_amp2",
        title: "Amplification Cascade",
        desc: "Support aura damage bonus increases further.",
        cost: 3,
        prereq: const ["r_support_range2", "r_support_fire2"],
        apply: (c) => c.supportAuraDamageMult = max(c.supportAuraDamageMult, 1.60),
      ),
      // Macrophage branch
      ResearchNode(
        id: "r_macro_core",
        title: "Engulfment Catalysts",
        desc: "Macrophage slow + weaken improved.",
        cost: 2,
        prereq: const ["r_lane_macro"],
        apply: (c) {
          c.macrophageSlowDuration += 0.35;
          c.macrophageWeakenBonus += 0.08;
        },
      ),
      ResearchNode(
        id: "r_macro_splash2",
        title: "Cytokine Burst",
        desc: "Macrophage gains splash damage.",
        cost: 3,
        prereq: const ["r_macro_core"],
        apply: (c) => c.macrophageSplash = true,
      ),
      ResearchNode(
        id: "r_macro_linger",
        title: "Lingering Debilitation",
        desc: "Slow + weaken lasts longer.",
        cost: 2,
        prereq: const ["r_macro_core"],
        apply: (c) {
          c.macrophageSlowDuration += 0.30;
          c.macrophageWeakenDuration += 0.50;
        },
      ),
      ResearchNode(
        id: "r_macro_amplify",
        title: "Immune Tagging",
        desc: "Weaken increases damage taken further.",
        cost: 4,
        prereq: const ["r_macro_splash2", "r_macro_linger"],
        apply: (c) => c.macrophageWeakenBonus += 0.12,
      ),
      ResearchNode(
        id: "r_cleaner_unlock",
        title: "Cleaner Protocol",
        desc: "Unlocks Cleaner cell.",
        cost: 3,
        prereq: const ["r_macro_core"],
        apply: (c) => c.unlockCell(CellType.cleaner),
      ),
      // Killer branch
      ResearchNode(
        id: "r_killer_precision",
        title: "Precision Lysis",
        desc: "Killer damage + range improved.",
        cost: 3,
        prereq: const ["r_lane_killer"],
        apply: (c) {
          c.killerDamageMult *= 1.12;
          c.killerRangeBonus += 0.02;
        },
      ),
      ResearchNode(
        id: "r_killer_focus",
        title: "Focused Lenses",
        desc: "Killer range increases further.",
        cost: 2,
        prereq: const ["r_killer_precision"],
        apply: (c) => c.killerRangeBonus += 0.03,
      ),
      ResearchNode(
        id: "r_killer_overclock",
        title: "Overclocked Cytotoxicity",
        desc: "Killer fire rate improves.",
        cost: 3,
        prereq: const ["r_killer_precision"],
        apply: (c) => c.killerFireMult *= 0.90,
      ),
      ResearchNode(
        id: "r_killer_execute",
        title: "Execution Protocol",
        desc: "Killer damage spikes significantly.",
        cost: 4,
        prereq: const ["r_killer_focus", "r_killer_overclock"],
        apply: (c) => c.killerDamageMult *= 1.20,
      ),
      ResearchNode(
        id: "r_sentinel_unlock",
        title: "Sentinel Array",
        desc: "Unlocks Sentinel cell.",
        cost: 3,
        prereq: const ["r_killer_focus"],
        apply: (c) => c.unlockCell(CellType.sentinel),
      ),
      // Defense + economy branch
      ResearchNode(
        id: "r_breach_resist2",
        title: "Membrane Hardening",
        desc: "Breach damage reduced further.",
        cost: 2,
        prereq: const ["r_lane_core"],
        apply: (c) => c.breachDamageMult *= 0.90,
      ),
      ResearchNode(
        id: "r_immunity",
        title: "Tissue Resilience",
        desc: "Infection capacity increases.",
        cost: 3,
        prereq: const ["r_breach_resist2"],
        apply: (c) => c.infectionMax += 3,
      ),
      ResearchNode(
        id: "r_harvest",
        title: "Antigen Harvesting",
        desc: "+1 DNA per kill (cap increased).",
        cost: 2,
        prereq: const ["r_lane_core"],
        apply: (c) {
          c.dnaPerKill = max(c.dnaPerKill, 1);
          c.killDnaCap += 10;
        },
      ),
    ];
  }

  bool isResearchUnlocked(String id) => unlockedResearch.contains(id);

  bool canUnlockResearch(ResearchNode node) {
    if (isResearchUnlocked(node.id)) return false;
    if (node.id != "r_start" && !isResearchUnlocked("r_start")) return false;
    for (final p in node.prereq) {
      if (!isResearchUnlocked(p)) return false;
    }
    return researchPoints >= node.cost;
  }

  void unlockResearch(ResearchNode node) {
    if (!canUnlockResearch(node)) return;
    researchPoints -= node.cost;
    unlockedResearch.add(node.id);
    node.apply(this);
    notifyListeners();
  }

  void setBoardPreset(BoardPreset preset) {
    boardPreset = preset;
    targetWave = preset.targetWave;
    _configureTravel(preset.exitEdge);
    reset(preserveResearch: true);
  }

  void _configureTravel(BoardEdge exitEdge) {
    switch (exitEdge) {
      case BoardEdge.right:
        _travelDir = const Offset(1, 0);
        _driftOnX = false;
        break;
      case BoardEdge.left:
        _travelDir = const Offset(-1, 0);
        _driftOnX = false;
        break;
      case BoardEdge.bottom:
        _travelDir = const Offset(0, 1);
        _driftOnX = true;
        break;
      case BoardEdge.top:
        _travelDir = const Offset(0, -1);
        _driftOnX = true;
        break;
    }
  }
}
