import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:drumly/game/presentation/components/note_component.dart';

/// ============================================================================
/// OBJECT POOL - Generic object pooling system
/// ============================================================================
///
/// Reduces garbage collection by reusing objects instead of creating/destroying.
/// Improves performance, especially for frequently spawned components like notes.
///
/// ## Usage
///
/// ```dart
/// final pool = ObjectPool<NoteComponent>(
///   create: () => NoteComponent(...),
///   reset: (note) => note.reset(),
///   initialSize: 50,
/// );
///
/// // Get from pool
/// final note = pool.acquire();
///
/// // Return to pool
/// pool.release(note);
/// ```
/// ============================================================================

class ObjectPool<T> {

  ObjectPool({
    required T Function() create,
    required void Function(T object) reset,
    int initialSize = 0,
  })  : _create = create,
        _reset = reset {
    // Pre-populate pool
    for (int i = 0; i < initialSize; i++) {
      _available.add(_create());
      _totalCreated++;
    }
  }
  /// Factory function to create new objects.
  final T Function() _create;

  /// Function to reset object state before reuse.
  final void Function(T object) _reset;

  /// Available objects in the pool.
  final List<T> _available = [];

  /// Currently active (in-use) objects.
  final Set<T> _active = {};

  /// Total objects created (for stats).
  int _totalCreated = 0;

  /// Acquire an object from the pool.
  ///
  /// If pool is empty, creates a new object.
  T acquire() {
    final object = _available.isEmpty ? _createNew() : _available.removeLast();
    _active.add(object);
    return object;
  }

  /// Release an object back to the pool.
  ///
  /// Resets the object state before returning to pool.
  void release(T object) {
    if (!_active.contains(object)) {
      // Object not from this pool or already released
      return;
    }

    _active.remove(object);
    _reset(object);
    _available.add(object);
  }

  /// Create a new object (called when pool is empty).
  T _createNew() {
    _totalCreated++;
    return _create();
  }

  /// Clear all objects from pool.
  void clear() {
    _available.clear();
    _active.clear();
  }

  /// Pool statistics.
  PoolStats get stats => PoolStats(
        available: _available.length,
        active: _active.length,
        totalCreated: _totalCreated,
      );

  /// Pool size (available + active).
  int get size => _available.length + _active.length;

  /// Available objects count.
  int get availableCount => _available.length;

  /// Active objects count.
  int get activeCount => _active.length;
}

/// ============================================================================
/// POOL STATS - Statistics for monitoring pool performance
/// ============================================================================

class PoolStats {

  const PoolStats({
    required this.available,
    required this.active,
    required this.totalCreated,
  });
  final int available;
  final int active;
  final int totalCreated;

  /// Pool utilization percentage.
  double get utilization {
    final total = available + active;
    return total > 0 ? (active / total) * 100 : 0;
  }

  @override
  String toString() => 'PoolStats(available: $available, active: $active, '
        'total: $totalCreated, utilization: ${utilization.toStringAsFixed(1)}%)';
}

/// ============================================================================
/// NOTE COMPONENT POOL - Specialized pool for NoteComponent
/// ============================================================================

class NoteComponentPool {

  NoteComponentPool({
    required this.parent,
    int initialSize = 50,
  }) {
    _pool = ObjectPool<NoteComponent>(
      create: () => NoteComponentPoolable.pooled(),
      reset: (note) {
        // Remove from parent if still attached
        if (note.isMounted) {
          note.removeFromParent();
        }
        // Reset note state
        note.resetState();
      },
      initialSize: initialSize,
    );
  }
  late final ObjectPool<NoteComponent> _pool;

  /// Parent component to add/remove notes from.
  final Component parent;

  /// Spawn a note with given parameters.
  ///
  /// Gets a note from pool and configures it.
  NoteComponent spawn({
    required int lane,
    required double hitTime,
    required double speed,
    required Vector2 startPosition,
  }) {
    final note = _pool.acquire();
    note.configure(
      lane: lane,
      hitTime: hitTime,
      speed: speed,
      startPosition: startPosition,
    );
    parent.add(note);
    return note;
  }

  /// Despawn a note (return to pool).
  void despawn(NoteComponent note) {
    _pool.release(note);
  }

  /// Get pool statistics.
  PoolStats get stats => _pool.stats;

  /// Clear the pool.
  void clear() {
    _pool.clear();
  }
}

/// ============================================================================
/// POOLABLE INTERFACE - Marker interface for poolable objects
/// ============================================================================

abstract class Poolable {
  /// Reset object to initial state for reuse.
  void resetState();

  /// Configure object with new parameters.
  void configure(Map<String, dynamic> params);
}

/// ============================================================================
/// EXTENSION: Make NoteComponent poolable
/// ============================================================================

extension NoteComponentPoolable on NoteComponent {
  /// Factory for pooled note component.
  static NoteComponent pooled() => NoteComponent(
      laneIndex: 0,
      hitTime: 0,
      speed: 0,
      hitZoneY: 0,
      position: Vector2.zero(),
      radius: 20,
      color: const Color(0xFFFFFFFF),
    );

  /// Reset note state.
  void resetState() {
    position = Vector2.zero();
    scale = Vector2.all(1.0);
    // Reset any other mutable state
  }

  /// Configure note with new parameters.
  void configure({
    required int lane,
    required double hitTime,
    required double speed,
    required Vector2 startPosition,
  }) {
    // Update note properties
    // Note: This is a simplified version
    // Actual implementation may need to update internal fields
    position.setFrom(startPosition);
    // Set other properties as needed based on NoteComponent's actual API
  }
}
