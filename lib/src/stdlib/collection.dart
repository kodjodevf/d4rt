import 'package:d4rt/src/environment.dart';
import 'collection/queue.dart';
import 'collection/hash_map.dart';
import 'collection/hash_set.dart';
import 'collection/list_queue.dart';
import 'collection/linked_hash_map.dart';
import 'collection/splay_tree_map.dart';
import 'collection/unmodifiable_list_view.dart';
import 'collection/linked_list.dart';

void registerCollectionLibs(Environment environment) {
  registerQueue(environment);
  registerHashMap(environment);
  registerHashSet(environment);
  registerListQueue(environment);
  registerLinkedHashMap(environment);
  registerSplayTreeMap(environment);
  registerUnmodifiableListView(environment);
  registerLinkedList(environment);
  registerLinkedListEntry(environment);
}
