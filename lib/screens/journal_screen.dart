import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/streak_service.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  // Journal entry management
  final TextEditingController _journalController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final List<Map<String, dynamic>> _journalEntries = [];

  // Mood selection
  final List<Map<String, dynamic>> _moods = [
    {'emoji': '😊', 'label': 'Happy', 'color': Colors.amber},
    {'emoji': '😌', 'label': 'Calm', 'color': Colors.blue},
    {'emoji': '😔', 'label': 'Sad', 'color': Colors.indigo},
    {'emoji': '😡', 'label': 'Angry', 'color': Colors.red},
    {'emoji': '😰', 'label': 'Anxious', 'color': Colors.orange},
    {'emoji': '😴', 'label': 'Tired', 'color': Colors.purple},
  ];

  String _selectedMood = '😊';
  Color _selectedMoodColor = Colors.amber;

  // Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('journal')
          .orderBy('date', descending: true)
          .get();

      setState(() {
        _journalEntries.clear();
        for (var doc in snapshot.docs) {
          final data = doc.data();
          _journalEntries.add({
            'id': doc.id,
            'date': (data['date'] as Timestamp).toDate(),
            'text': data['text'],
            'mood': data['mood'],
            'moodColor': Color(data['moodColor'] as int),
          });
        }
      });
    } catch (e) {
      _showSnackbar('Error loading journal: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Removed _loadSampleEntries

  Future<void> _saveEntry() async {
    if (_journalController.text.trim().isEmpty) {
      _showSnackbar('Please write something before saving');
      return;
    }

    User? user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final entryData = {
        'date': Timestamp.fromDate(now),
        'text': _journalController.text.trim(),
        'mood': _selectedMood,
        'moodColor': _selectedMoodColor.value,
      };

      final docRef = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('journal')
          .add(entryData);

      setState(() {
        _journalEntries.insert(0, {
          'id': docRef.id,
          'date': now,
          'text': _journalController.text.trim(),
          'mood': _selectedMood,
          'moodColor': _selectedMoodColor,
        });

        _journalController.clear();
        _selectedMood = '😊';
        _selectedMoodColor = Colors.amber;
      });

      // Update streak
      StreakService().updateStreak('journal');
      _showSnackbar('Journal entry saved!');
    } catch (e) {
      _showSnackbar('Error saving journal: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteEntry(String id) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('journal')
          .doc(id)
          .delete();

      setState(() {
        _journalEntries.removeWhere((entry) => entry['id'] == id);
      });
      _showSnackbar('Entry deleted');
    } catch (e) {
      _showSnackbar('Error deleting entry: $e');
    }
  }

  void _editEntry(Map<String, dynamic> entry) {
    _journalController.text = entry['text'];
    _selectedMood = entry['mood'];
    _selectedMoodColor = entry['moodColor'];

    // Remove the old entry
    setState(() {
      _journalEntries.removeWhere((e) => e['id'] == entry['id']);
    });

    _showSnackbar('Editing entry...');
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredEntries() {
    if (_searchQuery.isEmpty) {
      return _journalEntries;
    }

    return _journalEntries.where((entry) {
      final text = entry['text'].toLowerCase();
      final mood = entry['mood'];
      final date = DateFormat('MMM dd, yyyy').format(entry['date']).toLowerCase();

      return text.contains(_searchQuery.toLowerCase()) ||
          mood.contains(_searchQuery) ||
          date.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _clearAllEntries() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All Entries?'),
        content: Text('This will delete all your journal entries. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _journalEntries.clear();
              });
              Navigator.pop(context);
              _showSnackbar('All entries cleared');
            },
            child: Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _exportEntries() {
    // In a real app, this would export to a file
    _showSnackbar('Export feature coming soon!');
  }

  @override
  Widget build(BuildContext context) {
    final filteredEntries = _getFilteredEntries();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.grey.shade700),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'My Journal',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.help_outline, color: Colors.grey.shade600),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Journaling Tips'),
                          content: Text(
                            '• Write freely without judgment\n'
                                '• Note how you feel before/after writing\n'
                                '• Be honest with yourself\n'
                                '• Write regularly for best results\n'
                                '• Review past entries to see progress',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Got it'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // New Entry Card
                      Container(
                        padding: EdgeInsets.all(20),
                        margin: EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'New Entry',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            SizedBox(height: 16),

                            // Mood selector
                            Text(
                              'How are you feeling?',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 10),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _moods.map((mood) {
                                  bool isSelected = _selectedMood == mood['emoji'];
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedMood = mood['emoji'];
                                        _selectedMoodColor = mood['color'];
                                      });
                                    },
                                    child: Container(
                                      margin: EdgeInsets.only(right: 12),
                                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isSelected ? mood['color'].withOpacity(0.1) : Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(50),
                                        border: Border.all(
                                          color: isSelected ? mood['color'] : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            mood['emoji'],
                                            style: TextStyle(fontSize: 20),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            mood['label'],
                                            style: TextStyle(
                                              color: isSelected ? mood['color'] : Colors.grey.shade700,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                            SizedBox(height: 20),

                            // Journal text field
                            TextField(
                              controller: _journalController,
                              maxLines: 6,
                              decoration: InputDecoration(
                                hintText: 'Write your thoughts here...',
                                hintStyle: TextStyle(color: Colors.grey.shade500),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                            ),

                            SizedBox(height: 20),

                            // Save button
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _saveEntry,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _selectedMoodColor,
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      'SAVE ENTRY',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Search and filter bar
                      Container(
                        padding: EdgeInsets.all(16),
                        margin: EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: (value) {
                                      setState(() {
                                        _searchQuery = value;
                                      });
                                    },
                                    decoration: InputDecoration(
                                      hintText: 'Search entries...',
                                      prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                PopupMenuButton<String>(
                                  icon: Icon(Icons.more_vert, color: Colors.grey.shade700),
                                  onSelected: (value) {
                                    if (value == 'clear') {
                                      _clearAllEntries();
                                    } else if (value == 'export') {
                                      _exportEntries();
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'export',
                                      child: Row(
                                        children: [
                                          Icon(Icons.download, size: 20),
                                          SizedBox(width: 8),
                                          Text('Export Entries'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'clear',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, size: 20, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Clear All', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Past Entries (${filteredEntries.length})',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                if (_searchQuery.isNotEmpty)
                                  TextButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                    child: Text('Clear Search', style: TextStyle(color: Colors.blue)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Journal entries list
                      if (filteredEntries.isEmpty)
                        Container(
                          padding: EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(Icons.edit_note, size: 80, color: Colors.grey.shade300),
                              SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'No journal entries yet'
                                    : 'No entries found for "$_searchQuery"',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              if (_searchQuery.isEmpty)
                                Text(
                                  'Write your first entry above!',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                            ],
                          ),
                        )
                      else
                        Column(
                          children: filteredEntries.map((entry) {
                            return _buildJournalEntryCard(entry);
                          }).toList(),
                        ),

                      SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJournalEntryCard(Map<String, dynamic> entry) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          // Entry header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: entry['moodColor'].withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      entry['mood'],
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('MMM dd, yyyy').format(entry['date']),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      Text(
                        DateFormat('hh:mm a').format(entry['date']),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey.shade600, size: 20),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editEntry(entry);
                    } else if (value == 'delete') {
                      _deleteEntry(entry['id']);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Entry content
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              entry['text'],
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade800,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}