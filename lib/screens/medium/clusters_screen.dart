import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/data/awing_tones.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';
import 'package:awing_ai_learning/services/auth_service.dart';

class ClustersScreen extends StatefulWidget {
  const ClustersScreen({Key? key}) : super(key: key);

  @override
  State<ClustersScreen> createState() => _ClustersScreenState();
}

class _ClustersScreenState extends State<ClustersScreen> {
  final PronunciationService _pronunciation = PronunciationService();
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _pronunciation.init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthService>().completeLesson('medium_clusters');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consonant Clusters'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Tab buttons
          Container(
            color: Colors.orange.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _TabButton(
                  label: 'Prenasalized',
                  isSelected: _selectedTabIndex == 0,
                  onTap: () => setState(() => _selectedTabIndex = 0),
                ),
                _TabButton(
                  label: 'Palatalized',
                  isSelected: _selectedTabIndex == 1,
                  onTap: () => setState(() => _selectedTabIndex = 1),
                ),
                _TabButton(
                  label: 'Labialized',
                  isSelected: _selectedTabIndex == 2,
                  onTap: () => setState(() => _selectedTabIndex = 2),
                ),
              ],
            ),
          ),
          // Tab content
          Expanded(
            child: _buildTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    final clusters = _selectedTabIndex == 0
        ? prenasalizedClusters
        : _selectedTabIndex == 1
            ? palatalizedClusters
            : labializedClusters;

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: clusters.length,
      itemBuilder: (context, index) => _ClusterCard(
        cluster: clusters[index],
        pronunciation: _pronunciation,
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.orange : Colors.transparent,
                width: 4,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.orange : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClusterCard extends StatelessWidget {
  final ConsonantCluster cluster;
  final PronunciationService pronunciation;

  const _ClusterCard({
    required this.cluster,
    required this.pronunciation,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grapheme in circle + phonetic notation
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.orange.shade300,
                  child: Text(
                    cluster.grapheme.split(' ')[0], // Just the lowercase version
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Grapheme: ${cluster.grapheme}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Phonetic: ${cluster.cluster}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Description
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                cluster.description,
                style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 12),
            // Example word with speaker button
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Example: ${cluster.exampleWord}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '(${cluster.exampleEnglish})',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                FloatingActionButton.small(
                  backgroundColor: Colors.orange,
                  onPressed: () => pronunciation.speakAwing(cluster.exampleWord),
                  child: const Icon(Icons.volume_up, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
