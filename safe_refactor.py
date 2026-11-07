import os
import re

filepath = 'lib/pages/product_management_page.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Remove Distribution Lists
target_lists = """  // --- NUEVO: Lista para la vista de tarjetas en Distribución ---
  List<DistributionPoint> _distributionList = [];
  
  // Logs para la pestaña de Distribución (opcional, ahora usamos cards)
  List<String> _importLogs = [];"""
content = content.replace(target_lists, "")

# 2. Fix TabController Logic
# _loadAllLists:
t1 = """    // Lógica para determinar qué pestaña abrir
    if (lastActiveListIndex == -1) {
      initialTabIndex = 0;
    } else {
      if (lastActiveListIndex >= _listas.length) lastActiveListIndex = 0;
      initialTabIndex = lastActiveListIndex + 1;
    }"""
r1 = """    // Lógica para determinar qué pestaña abrir
    if (lastActiveListIndex == -1) {
      initialTabIndex = 0;
    } else {
      initialTabIndex = lastActiveListIndex;
      if (initialTabIndex >= _listas.length) initialTabIndex = 0;
    }"""
content = content.replace(t1, r1)

t2 = """      if (existingIndex != -1) {
        initialTabIndex = existingIndex + 1;
      } else {"""
r2 = """      if (existingIndex != -1) {
        initialTabIndex = existingIndex;
      } else {"""
content = content.replace(t2, r2)

t3 = """          initialTabIndex = _listas.length; 
          await _saveProducts();"""
r3 = """          initialTabIndex = _listas.length - 1; 
          await _saveProducts();"""
content = content.replace(t3, r3)

t4 = """    _tabController = TabController(
      length: _listas.length + 1,
      vsync: this,
      initialIndex: initialTabIndex,
    );"""
r4 = """    _tabController = TabController(
      length: _listas.length,
      vsync: this,
      initialIndex: initialTabIndex,
    );"""
content = content.replace(t4, r4)

t5 = """  void _handleTabSelection() async {
    if (!_tabController.indexIsChanging) {
      final prefs = await SharedPreferences.getInstance();
      int valueToSave = _tabController.index == 0 ? -1 : _tabController.index - 1;
      await prefs.setInt('lastActiveListIndex', valueToSave);
      setState(() {}); 
    }
  }"""
r5 = """  void _handleTabSelection() async {
    if (!_tabController.indexIsChanging) {
      final prefs = await SharedPreferences.getInstance();
      int valueToSave = _tabController.index;
      await prefs.setInt('lastActiveListIndex', valueToSave);
      setState(() {}); 
    }
  }"""
content = content.replace(t5, r5)

# 3. Remove all Import/Export Global Logic
# Starts at "  // --- LÓGICA DE IMPORTACIÓN Y EXPORTACIÓN ---"
# Ends before "  // --- GESTIÓN DE LISTAS Y PRODUCTOS (Funcionalidad Existente) ---"
content = re.sub(r'  // --- LÓGICA DE IMPORTACIÓN Y EXPORTACIÓN ---.*?  // --- GESTIÓN DE LISTAS Y PRODUCTOS \(Funcionalidad Existente\) ---', '  // --- GESTIÓN DE LISTAS Y PRODUCTOS (Funcionalidad Existente) ---', content, flags=re.DOTALL)

# 4. _addNewList
t6 = """    if (duplicateFromCurrent && _tabController.index > 0) {
      final currentList = _listas[_tabController.index - 1];"""
r6 = """    if (duplicateFromCurrent) {
      final currentList = _listas[_tabController.index];"""
content = content.replace(t6, r6)

t7 = """      int newIndex = _listas.length; 
      _tabController.dispose();
      _tabController = TabController(
        length: _listas.length + 1,
        vsync: this,
        initialIndex: newIndex,
      );"""
r7 = """      int newIndex = _listas.length - 1; 
      _tabController.dispose();
      _tabController = TabController(
        length: _listas.length,
        vsync: this,
        initialIndex: newIndex >= 0 ? newIndex : 0,
      );"""
content = content.replace(t7, r7)

# 5. _confirmRemoveList
t8 = """                _tabController = TabController(
                  length: _listas.length + 1,
                  vsync: this,
                  initialIndex: 0,
                );"""
r8 = """                _tabController = TabController(
                  length: _listas.length,
                  vsync: this,
                  initialIndex: 0,
                );"""
content = content.replace(t8, r8)

# 6. _promptDuplicateList
t9 = """  void _promptDuplicateList() {
    if (_tabController.index == 0) return; 
    final currentPuntoName = _listas[_tabController.index - 1].puntoName;"""
r9 = """  void _promptDuplicateList() {
    final currentPuntoName = _listas[_tabController.index].puntoName;"""
content = content.replace(t9, r9)

# 7. _importExcelIndividual
t10 = """  Future<void> _importExcelIndividual() async {
    if (_tabController.index == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Usa el botón grande para importación global.")));
      return;
    }
    
    final currentList = _listas[_tabController.index - 1];"""
r10 = """  Future<void> _importExcelIndividual() async {
    final currentList = _listas[_tabController.index];"""
content = content.replace(t10, r10)

# 8. _showClearProductsConfirmationDialog
t11 = """              Navigator.pop(ctx);
              setState(() {
                for (var l in _listas) l.products.clear();
                _distributionList.clear(); // También limpiamos la lista de distribución
              });"""
r11 = """              Navigator.pop(ctx);
              setState(() {
                for (var l in _listas) l.products.clear();
              });"""
content = content.replace(t11, r11)

# 9. build()
t12 = """  Widget build(BuildContext context) {
    final isListTab = _tabController.index > 0;
    final currentList = isListTab ? _listas[_tabController.index - 1] : null;"""
r12 = """  Widget build(BuildContext context) {
    final isListTab = true;
    final currentList = _listas.isNotEmpty ? _listas[_tabController.index] : null;"""
content = content.replace(t12, r12)

# Remove export distribution icon
t13 = """          if (!isListTab && _distributionList.isNotEmpty)
            IconButton(
               icon: const Icon(Icons.download),
               tooltip: "Exportar Distribución (CSV)",
               onPressed: _exportDistributionCsv,
            ),"""
content = content.replace(t13, "")

# Remove Tab Distribution
t14 = """          tabs: [
            const Tab(icon: Icon(Icons.hub), text: "DISTRIBUCIÓN"),
            ..._listas.map((lista) {"""
r14 = """          tabs: _listas.isEmpty ? [const Tab(text: "")] : _listas.map((lista) {"""
content = content.replace(t14, r14)

# Remove the trailing ] for the tabs list since we mapped directly
t15 = """                  ],
                ),
              );
            }).toList(),
          ],
        ),"""
r15 = """                  ],
                ),
              );
            }).toList(),
        ),"""
content = content.replace(t15, r15)


# Remove TabBarView child
t16 = """        children: [
          _buildDistributionTab(),
          ..._listas.map((lista) => _buildProductListUI(lista)),
        ],"""
r16 = """        children: _listas.isEmpty ? [Container()] : _listas.map((lista) => _buildProductListUI(lista)).toList(),"""
content = content.replace(t16, r16)

# Fix floatingActionButton isListTab
t17 = """      floatingActionButton: isListTab
          ? Column("""
r17 = """      floatingActionButton: _listas.isNotEmpty
          ? Column("""
content = content.replace(t17, r17)

t18 = """          : null,"""
r18 = """          : null,"""
# Keep it.

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)

print("Product management page refactored safely")

