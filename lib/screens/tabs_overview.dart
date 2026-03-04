import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/browser_provider.dart';

class TabsOverviewScreen extends StatefulWidget {
  const TabsOverviewScreen({super.key});

  @override
  State<TabsOverviewScreen> createState() => _TabsOverviewScreenState();
}

class _TabsOverviewScreenState extends State<TabsOverviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final browserProvider = context.watch<BrowserProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Tabs', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              browserProvider.createNewTab();
              Navigator.pop(context);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blueAccent,
          unselectedLabelColor: Colors.white54,
          indicatorColor: Colors.blueAccent,
          tabs: const [Tab(text: 'All Tabs'), Tab(text: 'Groups')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // All Tabs Grid
          _buildAllTabsGrid(browserProvider),
          // Groups View
          _buildGroupsView(browserProvider),
        ],
      ),
    );
  }

  Widget _buildAllTabsGrid(BrowserProvider provider) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: provider.tabs.length,
      itemBuilder: (context, index) {
        final tab = provider.tabs[index];
        final isActive = index == provider.activeTabIndex;
        return GestureDetector(
          onTap: () {
            provider.setActiveTab(index);
            Navigator.pop(context);
          },
          child: Container(
            decoration: BoxDecoration(
              color:
                  isActive ? const Color(0xFF1A3F6F) : const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
              border:
                  isActive
                      ? Border.all(color: Colors.blueAccent, width: 2)
                      : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Icon(
                        tab.isIncognito ? Icons.privacy_tip : Icons.public,
                        color: Colors.white54,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          tab.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (provider.tabs.length > 1)
                        GestureDetector(
                          onTap: () => provider.closeTab(index),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white38,
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        _getDomain(tab.url),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupsView(BrowserProvider provider) {
    if (provider.tabGroups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.tab, color: Colors.white24, size: 48),
            const SizedBox(height: 16),
            const Text(
              'No tab groups yet',
              style: TextStyle(color: Colors.white38, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
              onPressed: () => _showCreateGroupDialog(provider),
              icon: const Icon(Icons.add),
              label: const Text('Create Group'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Create new group button
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
            ),
            onPressed: () => _showCreateGroupDialog(provider),
            icon: const Icon(Icons.add),
            label: const Text('New Group'),
          ),
        ),
        // Groups
        ...provider.tabGroups.map((group) {
          final tabsInGroup = provider.getTabsInGroup(group.id);
          return Card(
            color: const Color(0xFF1E1E1E),
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.circle, color: group.color, size: 12),
                  title: Text(
                    '${group.name} (${tabsInGroup.length})',
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          group.isCollapsed
                              ? Icons.expand_more
                              : Icons.expand_less,
                          color: Colors.white54,
                        ),
                        onPressed:
                            () => provider.toggleGroupCollapsed(group.id),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        onPressed: () => provider.deleteTabGroup(group.id),
                      ),
                    ],
                  ),
                ),
                if (!group.isCollapsed)
                  ...tabsInGroup.map((tab) {
                    final tabIndex = provider.tabs.indexOf(tab);
                    return ListTile(
                      title: Text(
                        tab.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        _getDomain(tab.url),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                      onTap: () {
                        provider.setActiveTab(tabIndex);
                        Navigator.pop(context);
                      },
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Colors.white38,
                          size: 18,
                        ),
                        onPressed: () => provider.removeTabFromGroup(tabIndex),
                      ),
                    );
                  }),
              ],
            ),
          );
        }),
        // Ungrouped tabs
        if (provider.ungroupedTabs.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Ungrouped',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ),
          ...provider.ungroupedTabs.map((tab) {
            final tabIndex = provider.tabs.indexOf(tab);
            return Card(
              color: const Color(0xFF1E1E1E),
              child: ListTile(
                title: Text(
                  tab.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                subtitle: Text(
                  _getDomain(tab.url),
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                onTap: () {
                  provider.setActiveTab(tabIndex);
                  Navigator.pop(context);
                },
                trailing: PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.white38,
                    size: 18,
                  ),
                  color: const Color(0xFF2C2C2C),
                  onSelected: (value) {
                    if (value.startsWith('group_')) {
                      provider.addTabToGroup(
                        tabIndex,
                        value.replaceFirst('group_', ''),
                      );
                    }
                  },
                  itemBuilder:
                      (ctx) =>
                          provider.tabGroups.map((g) {
                            return PopupMenuItem<String>(
                              value: 'group_${g.id}',
                              child: Row(
                                children: [
                                  Icon(Icons.circle, color: g.color, size: 10),
                                  const SizedBox(width: 8),
                                  Text(
                                    g.name,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  void _showCreateGroupDialog(BrowserProvider provider) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text(
              'Create Tab Group',
              style: TextStyle(color: Colors.white),
            ),
            content: TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Group name',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF2C2C2C),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                ),
                onPressed: () {
                  if (nameController.text.trim().isNotEmpty) {
                    provider.createTabGroup(nameController.text.trim());
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Create'),
              ),
            ],
          ),
    );
  }

  String _getDomain(String url) {
    try {
      if (url == 'about:blank') return 'New Tab';
      return Uri.parse(url).host;
    } catch (_) {
      return url;
    }
  }
}
