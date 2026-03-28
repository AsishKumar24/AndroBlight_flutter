import 'package:flutter/foundation.dart';
import '../models/threat_rule.dart';
import '../services/api_service.dart';

/// Rules Provider — state management for custom threat rules (Feature 6 / Chunk 5).
class RulesProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<ThreatRule> _rules = [];
  bool _isLoading = false;
  String? _error;

  RulesProvider(this._apiService);

  // ── Getters ──
  List<ThreatRule> get rules => _rules;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── Load ──

  Future<void> loadRules() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.getRules();
      _rules = data.map(ThreatRule.fromJson).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Create ──

  /// Returns null on success, error message on failure.
  Future<String?> createRule({
    required String name,
    required List<String> permissions,
    required String threat,
    required String description,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.createRule(
        name: name,
        permissions: permissions,
        threat: threat,
        description: description,
      );
      final newRule = ThreatRule.fromJson(
        response['rule'] as Map<String, dynamic>,
      );
      _rules.insert(0, newRule);
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  // ── Update ──

  /// Returns null on success, error message on failure.
  Future<String?> updateRule(
    int ruleId, {
    String? name,
    List<String>? permissions,
    String? threat,
    String? description,
    bool? isActive,
  }) async {
    final updates = <String, dynamic>{
      if (name != null) 'name': name,
      if (permissions != null) 'permissions': permissions,
      if (threat != null) 'threat': threat,
      if (description != null) 'description': description,
      if (isActive != null) 'is_active': isActive,
    };

    try {
      final response = await _apiService.updateRule(ruleId, updates);
      final updated = ThreatRule.fromJson(
        response['rule'] as Map<String, dynamic>,
      );
      final idx = _rules.indexWhere((r) => r.id == ruleId);
      if (idx != -1) {
        _rules[idx] = updated;
        notifyListeners();
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ── Toggle active state ──

  Future<void> toggleRule(int ruleId, bool active) async {
    await updateRule(ruleId, isActive: active);
  }

  // ── Delete ──

  /// Returns null on success, error message on failure.
  Future<String?> deleteRule(int ruleId) async {
    try {
      await _apiService.deleteRule(ruleId);
      _rules.removeWhere((r) => r.id == ruleId);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
