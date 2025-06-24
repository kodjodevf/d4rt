import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/stdlib/collection/hash_map.dart';
import 'package:d4rt/src/stdlib/collection/hash_set.dart';
import 'package:d4rt/src/stdlib/collection/linked_hash_map.dart';
import 'package:d4rt/src/stdlib/collection/linked_list.dart';
import 'package:d4rt/src/stdlib/collection/list_queue.dart';
import 'package:d4rt/src/stdlib/collection/queue.dart';
import 'package:d4rt/src/stdlib/collection/splay_tree_map.dart';
import 'package:d4rt/src/stdlib/collection/unmodifiable_list_view.dart';

class CollectionStdlib {
  static void register(Environment environment) {
    environment.defineBridge(HashMapCollection.definition);
    environment.defineBridge(HashSetCollection.definition);
    environment.defineBridge(LinkedHashMapCollection.definition);
    environment.defineBridge(LinkedListCollection.definition);
    environment.defineBridge(LinkedListEntryCollection.definition);
    environment.defineBridge(ListQueueCollection.definition);
    environment.defineBridge(QueueCollection.definition);
    environment.defineBridge(SplayTreeMapCollection.definition);
    environment.defineBridge(UnmodifiableListViewCollection.definition);
  }
}
