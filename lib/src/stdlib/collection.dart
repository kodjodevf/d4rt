import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/stdlib/collection/double_linked_queue.dart';
import 'package:d4rt/src/stdlib/collection/has_next_iterator.dart';
import 'package:d4rt/src/stdlib/collection/hash_map.dart';
import 'package:d4rt/src/stdlib/collection/hash_set.dart';
import 'package:d4rt/src/stdlib/collection/linked_hash_map.dart';
import 'package:d4rt/src/stdlib/collection/linked_hash_set.dart';
import 'package:d4rt/src/stdlib/collection/linked_list.dart';
import 'package:d4rt/src/stdlib/collection/list_queue.dart';
import 'package:d4rt/src/stdlib/collection/map_view.dart';
import 'package:d4rt/src/stdlib/collection/queue.dart';
import 'package:d4rt/src/stdlib/collection/splay_tree_map.dart';
import 'package:d4rt/src/stdlib/collection/splay_tree_set.dart';
import 'package:d4rt/src/stdlib/collection/unmodifiable_list_view.dart';
import 'package:d4rt/src/stdlib/collection/unmodifiable_map_view.dart';
import 'package:d4rt/src/stdlib/collection/unmodifiable_set_view.dart';

export 'package:d4rt/src/environment.dart';
export 'package:d4rt/src/stdlib/collection/double_linked_queue.dart';
export 'package:d4rt/src/stdlib/collection/has_next_iterator.dart';
export 'package:d4rt/src/stdlib/collection/hash_map.dart';
export 'package:d4rt/src/stdlib/collection/hash_set.dart';
export 'package:d4rt/src/stdlib/collection/linked_hash_map.dart';
export 'package:d4rt/src/stdlib/collection/linked_hash_set.dart';
export 'package:d4rt/src/stdlib/collection/linked_list.dart';
export 'package:d4rt/src/stdlib/collection/list_queue.dart';
export 'package:d4rt/src/stdlib/collection/map_view.dart';
export 'package:d4rt/src/stdlib/collection/queue.dart';
export 'package:d4rt/src/stdlib/collection/splay_tree_map.dart';
export 'package:d4rt/src/stdlib/collection/splay_tree_set.dart';
export 'package:d4rt/src/stdlib/collection/unmodifiable_list_view.dart';
export 'package:d4rt/src/stdlib/collection/unmodifiable_map_view.dart';
export 'package:d4rt/src/stdlib/collection/unmodifiable_set_view.dart';

class CollectionStdlib {
  static void register(Environment environment) {
    // Register specific map implementations
    environment.defineBridge(HashMapCollection.definition);
    environment.defineBridge(LinkedHashMapCollection.definition);
    environment.defineBridge(SplayTreeMapCollection.definition);
    environment.defineBridge(UnmodifiableMapViewCollection.definition);
    environment.defineBridge(MapViewCollection.definition);

    // Register specific set implementations
    environment.defineBridge(HashSetCollection.definition);
    environment.defineBridge(LinkedHashSetCollection.definition);
    environment.defineBridge(SplayTreeSetCollection.definition);
    environment.defineBridge(UnmodifiableSetViewCollection.definition);

    // Register list views and linked structures
    environment.defineBridge(UnmodifiableListViewCollection.definition);
    environment.defineBridge(LinkedListCollection.definition);
    environment.defineBridge(LinkedListEntryCollection.definition);

    // Register queue implementations (concrete first, base Queue last)
    environment.defineBridge(ListQueueCollection.definition);
    environment.defineBridge(DoubleLinkedQueueCollection.definition);
    environment.defineBridge(DoubleLinkedQueueEntryCollection.definition);
    environment.defineBridge(QueueCollection.definition);

    // Iterators
    environment.defineBridge(HasNextIteratorCollection.definition);
  }
}
