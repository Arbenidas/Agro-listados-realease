import re
import os

filepath = 'lib/pages/product_management_page.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Remove _distributionList and _importLogs
content = re.sub(r'  // --- NUEVO: Lista para la vista de tarjetas en Distribución ---.*?List<String> _importLogs = \[\];\n\n', '', content, flags=re.DOTALL)

# 2. Update _loadAllLists tab controller index logic
content = content.replace(
'''    // Lógica para determinar qué pestaña abrir
    if (lastActiveListIndex == -1) {
      initialTabIndex = 0;
    } else {
      if (lastActiveListIndex >= _listas.length) lastActiveListIndex = 0;
      initialTabIndex = lastActiveListIndex + 1;
    }

    if (initialPuntoName != null) {
      final existingIndex = _listas.indexWhere((lista) => lista.puntoName == initialPuntoName);
      if (existingIndex != -1) {
        initialTabIndex = existingIndex + 1;
      } else {
        final puntoId = puntosDespacho[initialPuntoName];
        if (puntoId != null) {
          final newList = ManagedList(puntoName: initialPuntoName, puntoId: puntoId);
          setState(() {
            _listas.add(newList); 
          });
          initialTabIndex = _listas.length; 
          await _saveProducts();
        }
      }
    }

    _tabController = TabController(
      length: _listas.length + 1,
      vsync: this,
      initialIndex: initialTabIndex,
    );''',
'''    // Lógica para determinar qué pestaña abrir
    if (lastActiveListIndex == -1) {
      initialTabIndex = 0;
    } else {
      initialTabIndex = lastActiveListIndex;
      if (initialTabIndex >= _listas.length) initialTabIndex = 0;
    }

    if (initialPuntoName != null) {
      final existingIndex = _listas.indexWhere((lista) => lista.puntoName == initialPuntoName);
      if (existingIndex != -1) {
        initialTabIndex = existingIndex;
      } else {
        final puntoId = puntosDespacho[initialPuntoName];
        if (puntoId != null) {
          final newList = ManagedList(puntoName: initialPuntoName, puntoId: puntoId);
          setState(() {
            _listas.add(newList); 
          });
          initialTabIndex = _listas.length - 1; 
          await _saveProducts();
        }
      }
    }

    _tabController = TabController(
      length: _listas.length,
      vsync: this,
      initialIndex: initialTabIndex,
    );'''
)

# 3. Update _handleTabSelection
content = content.replace(
'''      int valueToSave = _tabController.index == 0 ? -1 : _tabController.index - 1;''',
'''      int valueToSave = _tabController.index;'''
)

# 4. Remove _handleGlobalImport, _exportDistributionCsv, _doExportDistributionCsv, _buildDistributionTab
# We will use regex to remove everything from "// 1. Manejar la importación Global (Pestaña 0)" to "  // --- GESTIÓN DE LISTAS Y PRODUCTOS"
content = re.sub(r'  // 1\. Manejar la importación Global \(Pestaña 0\).*?(?=  // --- GESTIÓN DE LISTAS Y PRODUCTOS \(Funcionalidad Existente\) ---)', '', content, flags=re.DOTALL)

# 5. Update _addNewList
content = content.replace(
'''    if (duplicateFromCurrent && _tabController.index > 0) {
      final currentList = _listas[_tabController.index - 1];''',
'''    if (duplicateFromCurrent) {
      final currentList = _listas[_tabController.index];'''
)
content = content.replace(
'''      int newIndex = _listas.length; 
      _tabController.dispose();
      _tabController = TabController(
        length: _listas.length + 1,
        vsync: this,
        initialIndex: newIndex,
      );''',
'''      int newIndex = _listas.length - 1; 
      _tabController.dispose();
      _tabController = TabController(
        length: _listas.length,
        vsync: this,
        initialIndex: newIndex,
      );'''
)

# 6. Update _confirmRemoveList
content = content.replace(
'''                  _tabController = TabController(
                    length: _listas.length + 1,
                    vsync: this,
                    initialIndex: 0,
                  );''',
'''                  _tabController = TabController(
                    length: _listas.length,
                    vsync: this,
                    initialIndex: 0,
                  );'''
)

# 7. Update _promptDuplicateList
content = content.replace(
'''  void _promptDuplicateList() {
    if (_tabController.index == 0) return; 
    final currentPuntoName = _listas[_tabController.index - 1].puntoName;''',
'''  void _promptDuplicateList() {
    final currentPuntoName = _listas[_tabController.index].puntoName;'''
)

# 8. Update _importExcelIndividual
content = content.replace(
'''  Future<void> _importExcelIndividual() async {
    if (_tabController.index == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Usa el botón grande para importación global.")));
      return;
    }
    
    final currentList = _listas[_tabController.index - 1];''',
'''  Future<void> _importExcelIndividual() async {
    final currentList = _listas[_tabController.index];'''
)

# 9. Update _showClearProductsConfirmationDialog
content = content.replace(
'''                for (var l in _listas) l.products.clear();
                _distributionList.clear(); // También limpiamos la lista de distribución''',
'''                for (var l in _listas) l.products.clear();'''
)

# 10. Update build()
content = content.replace(
'''  Widget build(BuildContext context) {
    final isListTab = _tabController.index > 0;
    final currentList = isListTab ? _listas[_tabController.index - 1] : null;''',
'''  Widget build(BuildContext context) {
    final isListTab = true;
    final currentList = _listas.isNotEmpty ? _listas[_tabController.index] : null;'''
)
content = content.replace(
'''          if (!isListTab && _distributionList.isNotEmpty)
            IconButton(
               icon: const Icon(Icons.download),
               tooltip: "Exportar Distribución (CSV)",
               onPressed: _exportDistributionCsv,
            ),''',
''''''
)
content = content.replace(
'''            const Tab(icon: Icon(Icons.hub), text: "DISTRIBUCIÓN"),
            ..._listas.map((lista) {''',
'''            ..._listas.map((lista) {'''
)
content = content.replace(
'''        children: [
          _buildDistributionTab(),
          ..._listas.map((lista) => _buildProductListUI(lista)),
        ],''',
'''        children: [
          ..._listas.map((lista) => _buildProductListUI(lista)),
        ],'''
)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)

