import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/node_device.dart';

/// Repository untuk manajemen perangkat node ESP32 di Firestore
class NodeRepository {
  final FirebaseFirestore? firestore;

  // In-memory fallback untuk testing lokal
  final List<NodeDevice> _mockNodes = [
    NodeDevice(
      deviceId: 'NODE_POLINES_01',
      name: 'Node Survei Utama 01',
      locationName: 'Gerbang Utama Polines Tembalang',
      calibGain: 1.0,
      calibOffset: -1.2,
      notes: 'ESP32 DevKitC V4 32U + MAX4466 + Antena 2.4GHz',
      locationPointId: 'loc_polines_gate',
      isOnline: true,
      rssi: -62,
      uptimeSec: 3640,
    ),
    NodeDevice(
      deviceId: 'NODE_POLINES_02',
      name: 'Node Laboratorium Elektro 02',
      locationName: 'Gedung Tata Niaga / Elektro',
      calibGain: 1.05,
      calibOffset: 0.5,
      notes: 'Uji kebisingan ruang kuliah',
      locationPointId: 'loc_polines_lab',
      isOnline: false,
      rssi: -78,
      uptimeSec: 120,
    ),
  ];

  NodeRepository({this.firestore});

  Stream<List<NodeDevice>> streamNodes() {
    if (Firebase.apps.isNotEmpty && firestore != null) {
      try {
        return firestore!
            .collection('nodes')
            .snapshots()
            .map((snapshot) => snapshot.docs.map((doc) => NodeDevice.fromFirestore(doc.data(), doc.id)).toList());
      } catch (_) {}
    }
    return Stream.value(_mockNodes);
  }

  Future<void> saveNode(NodeDevice node) async {
    if (Firebase.apps.isNotEmpty && firestore != null) {
      try {
        await firestore!.collection('nodes').doc(node.deviceId).set(node.toFirestore());
        return;
      } catch (_) {}
    }

    final index = _mockNodes.indexWhere((n) => n.deviceId == node.deviceId);
    if (index >= 0) {
      _mockNodes[index] = node;
    } else {
      _mockNodes.add(node);
    }
  }

  Future<void> deleteNode(String deviceId) async {
    if (Firebase.apps.isNotEmpty && firestore != null) {
      try {
        await firestore!.collection('nodes').doc(deviceId).delete();
        return;
      } catch (_) {}
    }
    _mockNodes.removeWhere((n) => n.deviceId == deviceId);
  }
}
