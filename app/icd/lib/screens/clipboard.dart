import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:icd/models/clipboard_model.dart';
import 'package:icd/widgets/clipboard/expandable_description.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class ClipboardScreen extends StatefulWidget {
  const ClipboardScreen({super.key});

  @override
  State<ClipboardScreen> createState() => _ClipboardScreenState();
}

class _ClipboardScreenState extends State<ClipboardScreen>
    with SingleTickerProviderStateMixin {
  List<ClipboardItem> _items = [];
  List<ClipboardItem> _filteredItems = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = '';
  bool _isSelectionMode = false;
  Set<String> _selectedCodes = {}; // Track selected codes
  late final AnimationController _animationController;
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadItems();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final items = await ClipboardService.getItems();
      // Sort by timestamp, newest first
      items.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      setState(() {
        _items = items;
        _filteredItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Failed to load clipboard items');
    }
  }

  void _filterItems() {
    if (_searchQuery.isEmpty) {
      setState(() {
        _filteredItems = _items;
      });
      return;
    }

    final query = _searchQuery.toLowerCase();
    setState(() {
      _filteredItems = _items.where((item) {
        return item.code.toLowerCase().contains(query) ||
            item.description.toLowerCase().contains(query) ||
            (item.category?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  Future<void> _deleteItem(String code) async {
    try {
      await ClipboardService.removeItem(code);
      _loadItems();
      _showSnackBar('Code removed from clipboard');
    } catch (e) {
      _showError('Failed to remove item');
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Clipboard?'),
        content: const Text(
            'This will remove all saved codes from your clipboard history. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ClipboardService.clearAll();
        _loadItems();
        _showSnackBar('Clipboard cleared');
      } catch (e) {
        _showError('Failed to clear clipboard');
      }
    }
  }

  Future<void> _copyAllCodes() async {
    if (_filteredItems.isEmpty) {
      _showSnackBar('No codes to copy');
      return;
    }

    final formattedText = _filteredItems.map((item) {
      return '${item.code} - ${item.description}';
    }).join('\n');

    await Clipboard.setData(ClipboardData(text: formattedText));
    _showSnackBar('All codes copied to clipboard');
  }

  Future<void> _shareAllCodes() async {
    if (_filteredItems.isEmpty) {
      _showSnackBar('No codes to share');
      return;
    }

    final formattedText = _filteredItems.map((item) {
      return '${item.code} - ${item.description}';
    }).join('\n');

    await Share.share(
      'ICD-11 Codes:\n\n$formattedText',
      subject: 'ICD-11 Codes from ALAR ICD App',
    );
  }

  Future<void> _shareSelectedCodes() async {
    if (_selectedCodes.isEmpty) {
      _showSnackBar('No codes selected');
      return;
    }

    final selectedItems = _filteredItems
        .where((item) => _selectedCodes.contains(item.code))
        .toList();

    final formattedText = selectedItems.map((item) {
      return '${item.code} - ${item.description}';
    }).join('\n');

    await Share.share(
      'ICD-11 Codes:\n\n$formattedText',
      subject: 'ICD-11 Codes from ALAR ICD App',
    );

    // Exit selection mode after sharing
    setState(() {
      _isSelectionMode = false;
      _selectedCodes.clear();
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
        _searchController.clear();
        _filterItems();
      }
    });

    if (_isSearching) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedCodes.clear();
      }
    });
  }

  void _toggleItemSelection(String code) {
    setState(() {
      if (_selectedCodes.contains(code)) {
        _selectedCodes.remove(code);
        // Exit selection mode if no items selected
        if (_selectedCodes.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedCodes.add(code);
      }
    });
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (now.year == date.year &&
        now.month == date.month &&
        now.day == date.day) {
      return 'Today, ${DateFormat('h:mm a').format(date)}';
    } else if (now.subtract(const Duration(days: 1)).year == date.year &&
        now.subtract(const Duration(days: 1)).month == date.month &&
        now.subtract(const Duration(days: 1)).day == date.day) {
      return 'Yesterday, ${DateFormat('h:mm a').format(date)}';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  Widget _buildGroupedItems() {
    if (_filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.content_paste_off,
              size: 72,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No results found for "$_searchQuery"'
                  : 'Your clipboard is empty',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            if (_searchQuery.isEmpty)
              Text(
                'Codes you copy will appear here',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            if (_searchQuery.isNotEmpty)
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  _searchQuery = '';
                  _filterItems();
                },
                child: const Text('Clear search'),
              ),
          ],
        ),
      );
    }

    // Group items by date
    final groupedItems = <String, List<ClipboardItem>>{};
    for (var item in _filteredItems) {
      final date = _formatDate(item.timestamp);
      if (groupedItems.containsKey(date)) {
        groupedItems[date]!.add(item);
      } else {
        groupedItems[date] = [item];
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: groupedItems.length,
      itemBuilder: (context, index) {
        final date = groupedItems.keys.elementAt(index);
        final items = groupedItems[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                date,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 14,
                ),
              ),
            ),
            ...items.map((item) => _buildCodeCard(item)),
          ],
        );
      },
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildCodeCard(ClipboardItem item) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            if (_isSelectionMode) {
              _toggleItemSelection(item.code);
            } else {
              await Clipboard.setData(
                  ClipboardData(text: '${item.code} - ${item.description}'));
              _showSnackBar('Code copied to clipboard');
            }
          },
          onLongPress: () {
            if (!_isSelectionMode) {
              _toggleSelectionMode();
              _toggleItemSelection(item.code);
            }
          },
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment
                          .start, // Align to top for better layout
                      children: [
                        Expanded(
                          // Let the code container expand
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                                // Allows the container to shrink if needed
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.code,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: theme
                                          .colorScheme.onSecondaryContainer,
                                    ),
                                    overflow: TextOverflow
                                        .visible, // Allow text to break to next line
                                    softWrap: true, // Enable text wrapping
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Action buttons - keep these at a fixed position
                        if (!_isSelectionMode)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.content_copy, size: 18),
                                onPressed: () async {
                                  // Ensure code is copied without line breaks
                                  await Clipboard.setData(ClipboardData(
                                      text:
                                          '${item.code} - ${item.description}'));
                                  _showSnackBar('Code copied to clipboard');
                                },
                                tooltip: 'Copy code',
                                visualDensity: VisualDensity.compact,
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete_outline, size: 18),
                                onPressed: () => _deleteItem(item.code),
                                tooltip: 'Remove from clipboard',
                                visualDensity: VisualDensity.compact,
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                color: theme.colorScheme.error,
                              ),
                            ],
                          ),
                      ],
                    ),
                   const SizedBox(height: 8),
                    ExpandableDescription(
                      text: item.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.4, // Better line spacing
                        letterSpacing: 0.2, // Slightly improved letter spacing
                      ),
                    ),
                    if (item.category != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.folder_outlined,
                            size: 14,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.category!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('h:mm a').format(item.timestamp),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Selection indicator
              if (_isSelectionMode)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _selectedCodes.contains(item.code)
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: _selectedCodes.contains(item.code)
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                        width: 2,
                      ),
                    ),
                    child: _selectedCodes.contains(item.code)
                        ? Icon(
                            Icons.check,
                            size: 16,
                            color: theme.colorScheme.onPrimary,
                          )
                        : null,
                  ),
                ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: 50.ms * _filteredItems.indexOf(item));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: _isSearching
            ? AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _animationController,
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search codes or descriptions...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5)),
                      ),
                      style: theme.textTheme.titleMedium,
                      onChanged: (value) {
                        _searchQuery = value;
                        _filterItems();
                      },
                    ),
                  );
                },
              )
            : _isSelectionMode
                ? Text('${_selectedCodes.length} selected')
                : const Text('Clipboard'),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectionMode,
              )
            : null,
        actions: [
          if (!_isSelectionMode) ...[
            IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isSearching
                    ? const Icon(Icons.close, key: ValueKey('close'))
                    : const Icon(Icons.search, key: ValueKey('search')),
              ),
              onPressed: _toggleSearch,
            ),
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _toggleSelectionMode,
              tooltip: 'Select items',
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'copy_all':
                    _copyAllCodes();
                    break;
                  case 'share':
                    _shareAllCodes();
                    break;
                  case 'clear':
                    _clearAll();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'copy_all',
                  child: Row(
                    children: [
                      Icon(Icons.copy_all),
                      SizedBox(width: 8),
                      Text('Copy All Codes'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share),
                      SizedBox(width: 8),
                      Text('Share All Codes'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Clear All', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareSelectedCodes,
              tooltip: 'Share selected',
            ),
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: () {
                setState(() {
                  if (_selectedCodes.length == _filteredItems.length) {
                    // Deselect all
                    _selectedCodes.clear();
                    _isSelectionMode = false;
                  } else {
                    // Select all
                    _selectedCodes =
                        _filteredItems.map((item) => item.code).toSet();
                  }
                });
              },
              tooltip: _selectedCodes.length == _filteredItems.length
                  ? 'Deselect all'
                  : 'Select all',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildGroupedItems(),
      floatingActionButton: AnimatedOpacity(
        opacity: _filteredItems.isNotEmpty ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: FloatingActionButton.extended(
          onPressed: _isSelectionMode
              ? _shareSelectedCodes
              : () => _toggleSelectionMode(),
          icon: Icon(_isSelectionMode ? Icons.share : Icons.checklist),
          label: Text(_isSelectionMode
              ? 'Share ${_selectedCodes.length} selected'
              : 'Select to Share'),
          backgroundColor: _isSelectionMode
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          foregroundColor: _isSelectionMode
              ? Theme.of(context).colorScheme.onPrimaryContainer
              : null,
        ),
      ),
    );
  }
}

// Extension method to add clipboard functionality across app
extension ClipboardExtension on BuildContext {
  // Call this method when user wants to save a code to clipboard
  Future<void> saveToClipboardHistory({
    required String code,
    required String description,
    String? category,
  }) async {
    final item = ClipboardItem(
      code: code,
      description: description,
      timestamp: DateTime.now(),
      category: category,
    );

    await ClipboardService.addItem(item);

    ScaffoldMessenger.of(this).showSnackBar(
      const SnackBar(
        content: Text('Code saved to clipboard history'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
