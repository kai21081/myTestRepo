// Template for class that holds a mapping from keys to callback functions that
// accept a single argument. Contains methods to add/remove callbacks from the
// group, as well as calling all of the callbacks with a provided value.
class CallbackCollection<K, T> {
  Map<K, void Function(T)> _callbacks = Map<K, void Function(T)>();

  // Adds the provided callback with the specified key.
  //
  // Throws:
  //   ArgumentError if callback with provided key already exists.
  void addCallback(K key, void Function(T) callback) {
    print('Adding callback: $key');

    if (_callbacks.containsKey(key)) {
      throw ArgumentError('addCallback failed because a callback with name '
          '$key already exists.');
    }
    _callbacks[key] = callback;
  }

  void removeCallback(K key) {
    if (_callbacks.containsKey(key)) {
      print('removing callback with key $key');
      _callbacks.remove(key);
    }
  }

  void clearCallbacks() {
    _callbacks.clear();
  }

  void handleValue(T value) {
    _callbacks.values.forEach((void Function(T) callback) => callback(value));
  }
}
