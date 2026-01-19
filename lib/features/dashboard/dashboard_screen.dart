// import 'package:flutter/material.dart';
// import '../transaction/new_transaction_screen.dart';
// import '../master_data/farmer/farmer_list_screen.dart';
// import '../master_data/trader/trader_list_screen.dart';
// import '../master_data/produce/produce_list_screen.dart';
// import '../master_data/expense_type/expense_type_list_screen.dart';

// class DashboardScreen extends StatefulWidget {
//   const DashboardScreen({super.key});

//   @override
//   State<DashboardScreen> createState() => _DashboardScreenState();
// }

// class _DashboardScreenState extends State<DashboardScreen> {
//   int _selectedIndex = 0;
//   bool _isDrawerOpen = false;

//   // Navigation items
//   static const List<NavigationItem> _navItems = [
//     NavigationItem(title: 'डॅशबोर्ड', icon: Icons.dashboard),
//     NavigationItem(title: 'नवीन पावती', icon: Icons.add_circle),
//     NavigationItem(title: 'शेतकरी', icon: Icons.people),
//     NavigationItem(title: 'व्यापारी', icon: Icons.business),
//     NavigationItem(title: 'माल', icon: Icons.shopping_basket),
//     NavigationItem(title: 'खर्च प्रकार', icon: Icons.monetization_on),
//     NavigationItem(title: 'अहवाल', icon: Icons.bar_chart),
//     NavigationItem(title: 'सेटिंग्ज', icon: Icons.settings),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     final isMobile = MediaQuery.of(context).size.width < 600;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('भारत मंडी व्यवस्थापन'),
//         centerTitle: true,
//         backgroundColor: Colors.green[700],
//         foregroundColor: Colors.white,
//         elevation: 4,
//         leading: isMobile
//             ? IconButton(
//                 icon: const Icon(Icons.menu),
//                 onPressed: () {
//                   setState(() {
//                     _isDrawerOpen = !_isDrawerOpen;
//                   });
//                 },
//               )
//             : null,
//       ),
//       body: Row(
//         children: [
//           // Side Navigation (Desktop) or Drawer (Mobile)
//           if (!isMobile || _isDrawerOpen) ...[
//             _buildNavigationDrawer(isMobile),
//             if (isMobile)
//               BackdropFilter(
//                 filter: const ColorFilter.mode(
//                   Colors.black54,
//                   BlendMode.darken,
//                 ),
//                 child: Container(
//                   color: Colors.black54,
//                   width: MediaQuery.of(context).size.width * 0.7,
//                 ),
//               ),
//           ],

//           // Main Content
//           Expanded(
//             child: Container(
//               color: Colors.grey[50],
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Welcome Card
//                     Card(
//                       elevation: 2,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.all(20),
//                         child: Row(
//                           children: [
//                             CircleAvatar(
//                               backgroundColor: Colors.green[100],
//                               radius: 30,
//                               child: Icon(
//                                 Icons.store,
//                                 size: 40,
//                                 color: const Color.fromARGB(255, 56, 142, 60),
//                               ),
//                             ),
//                             const SizedBox(width: 20),
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     'स्वागत आहे!',
//                                     style: TextStyle(
//                                       fontSize: 22,
//                                       fontWeight: FontWeight.bold,
//                                       color: const Color.fromARGB(
//                                           255, 46, 125, 50),
//                                     ),
//                                   ),
//                                   const SizedBox(height: 4),
//                                   const Text(
//                                     'व्यवसाय सुरू करा',
//                                     style: TextStyle(
//                                       fontSize: 14,
//                                       color: Colors.grey,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),

//                     const SizedBox(height: 20),

//                     // Stats Cards (3 columns)
//                     GridView.count(
//                       shrinkWrap: true,
//                       physics: const NeverScrollableScrollPhysics(),
//                       crossAxisCount: isMobile ? 2 : 4,
//                       crossAxisSpacing: 16,
//                       mainAxisSpacing: 16,
//                       childAspectRatio: 1.5,
//                       children: [
//                         _buildStatCard(
//                           'एकूण शेतकरी',
//                           '12',
//                           Icons.people,
//                           Colors.blue,
//                         ),
//                         _buildStatCard(
//                           'एकूण व्यापारी',
//                           '8',
//                           Icons.business,
//                           Colors.orange,
//                         ),
//                         _buildStatCard(
//                           'आजच्या पावत्या',
//                           '5',
//                           Icons.receipt,
//                           Colors.green,
//                         ),
//                         _buildStatCard(
//                           'एकूण थकबाकी',
//                           '₹25,430',
//                           Icons.account_balance_wallet,
//                           Colors.red,
//                         ),
//                       ],
//                     ),

//                     const SizedBox(height: 30),

//                     // Quick Actions Title
//                     const Padding(
//                       padding: EdgeInsets.only(left: 8, bottom: 12),
//                       child: Text(
//                         'त्वरित क्रिया',
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.grey,
//                         ),
//                       ),
//                     ),

//                     // Quick Actions Grid
//                     GridView.count(
//                       shrinkWrap: true,
//                       physics: const NeverScrollableScrollPhysics(),
//                       crossAxisCount: isMobile ? 2 : 4,
//                       crossAxisSpacing: 16,
//                       mainAxisSpacing: 16,
//                       childAspectRatio: 1.2,
//                       children: [
//                         _buildActionCard(
//                           context,
//                           'नवीन पावती',
//                           Icons.add_circle_outline,
//                           Colors.green,
//                           'नवीन व्यवहार तयार करा',
//                           () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) =>
//                                     const NewTransactionScreen(),
//                               ),
//                             );
//                           },
//                         ),
//                         _buildActionCard(
//                           context,
//                           'शेतकरी जोडा',
//                           Icons.person_add,
//                           Colors.blue,
//                           'नवीन शेतकरी नोंद करा',
//                           () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => const FarmerListScreen(),
//                               ),
//                             );
//                           },
//                         ),
//                         _buildActionCard(
//                           context,
//                           'व्यापारी जोडा',
//                           Icons.business_center,
//                           Colors.orange,
//                           'नवीन व्यापारी नोंद करा',
//                           () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => const TraderListScreen(),
//                               ),
//                             );
//                           },
//                         ),
//                         _buildActionCard(
//                           context,
//                           'अहवाल',
//                           Icons.assessment,
//                           Colors.purple,
//                           'विविध अहवाल पहा',
//                           () {
//                             // Reports screen
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               const SnackBar(
//                                 content: Text('अहवाल स्क्रीन लवकरच येईल'),
//                               ),
//                             );
//                           },
//                         ),
//                       ],
//                     ),

//                     const SizedBox(height: 30),

//                     // Master Data Title
//                     const Padding(
//                       padding: EdgeInsets.only(left: 8, bottom: 12),
//                       child: Text(
//                         'मास्टर डेटा व्यवस्थापन',
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.grey,
//                         ),
//                       ),
//                     ),

//                     // Master Data Grid
//                     GridView.count(
//                       shrinkWrap: true,
//                       physics: const NeverScrollableScrollPhysics(),
//                       crossAxisCount: isMobile ? 2 : 4,
//                       crossAxisSpacing: 16,
//                       mainAxisSpacing: 16,
//                       childAspectRatio: 1.3,
//                       children: [
//                         _buildMasterCard(
//                           context,
//                           'शेतकरी',
//                           Icons.people,
//                           Colors.blue,
//                           'शेतकरी व्यवस्थापन',
//                           () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => const FarmerListScreen(),
//                               ),
//                             );
//                           },
//                         ),
//                         _buildMasterCard(
//                           context,
//                           'व्यापारी',
//                           Icons.business,
//                           Colors.orange,
//                           'व्यापारी व्यवस्थापन',
//                           () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => const TraderListScreen(),
//                               ),
//                             );
//                           },
//                         ),
//                         _buildMasterCard(
//                           context,
//                           'माल',
//                           Icons.shopping_basket,
//                           Colors.purple,
//                           'माल व्यवस्थापन',
//                           () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => const ProduceListScreen(),
//                               ),
//                             );
//                           },
//                         ),
//                         _buildMasterCard(
//                           context,
//                           'खर्च प्रकार',
//                           Icons.monetization_on,
//                           Colors.red,
//                           'खर्च प्रकार व्यवस्थापन',
//                           () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => ExpenseTypeListScreen(),
//                               ),
//                             );
//                           },
//                         ),
//                       ],
//                     ),

//                     const SizedBox(height: 40),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//       // Bottom Navigation for Mobile
//       bottomNavigationBar: isMobile
//           ? BottomNavigationBar(
//               currentIndex: _selectedIndex,
//               onTap: (index) {
//                 setState(() {
//                   _selectedIndex = index;
//                   _handleNavigation(index);
//                 });
//               },
//               type: BottomNavigationBarType.fixed,
//               selectedItemColor: const Color.fromARGB(255, 56, 142, 60),
//               items: const [
//                 BottomNavigationBarItem(
//                   icon: Icon(Icons.dashboard),
//                   label: 'डॅशबोर्ड',
//                 ),
//                 BottomNavigationBarItem(
//                   icon: Icon(Icons.add_circle),
//                   label: 'पावती',
//                 ),
//                 BottomNavigationBarItem(
//                   icon: Icon(Icons.people),
//                   label: 'शेतकरी',
//                 ),
//                 BottomNavigationBarItem(
//                   icon: Icon(Icons.more_horiz),
//                   label: 'अधिक',
//                 ),
//               ],
//             )
//           : null,
//     );
//   }

//   // Navigation Drawer
//   Widget _buildNavigationDrawer(bool isMobile) {
//     return Container(
//       width: isMobile ? MediaQuery.of(context).size.width * 0.7 : 250,
//       color: Colors.white,
//       child: Column(
//         children: [
//           // App Logo/Header
//           Container(
//             height: 150,
//             color: const Color.fromARGB(255, 56, 142, 60),
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 CircleAvatar(
//                   backgroundColor: Colors.white,
//                   radius: 30,
//                   child: Icon(
//                     Icons.store,
//                     size: 40,
//                     color: const Color.fromARGB(255, 56, 142, 60),
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 const Text(
//                   'भारत मंडी',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Navigation Items
//           Expanded(
//             child: ListView.builder(
//               padding: EdgeInsets.zero,
//               itemCount: _navItems.length,
//               itemBuilder: (context, index) {
//                 final item = _navItems[index];
//                 final isSelected = _selectedIndex == index;

//                 return Container(
//                   margin:
//                       const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: isSelected ? Colors.green[50] : Colors.transparent,
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: ListTile(
//                     leading: Icon(
//                       item.icon,
//                       color: isSelected
//                           ? const Color.fromARGB(255, 56, 142, 60)
//                           : Colors.grey[600],
//                     ),
//                     title: Text(
//                       item.title,
//                       style: TextStyle(
//                         fontWeight:
//                             isSelected ? FontWeight.bold : FontWeight.normal,
//                         color: isSelected
//                             ? const Color.fromARGB(255, 56, 142, 60)
//                             : const Color.fromARGB(255, 97, 97, 97),
//                       ),
//                     ),
//                     onTap: () {
//                       setState(() {
//                         _selectedIndex = index;
//                         if (isMobile) {
//                           _isDrawerOpen = false;
//                         }
//                       });
//                       _handleNavigation(index);
//                     },
//                   ),
//                 );
//               },
//             ),
//           ),

//           // Footer
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               border: Border(top: BorderSide(color: Colors.grey[300]!)),
//             ),
//             child: Column(
//               children: [
//                 const Text(
//                   'आवृत्ती 1.0.0',
//                   style: TextStyle(fontSize: 12, color: Colors.grey),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   '© 2024 भारत मंडी',
//                   style: TextStyle(
//                       fontSize: 12,
//                       color: const Color.fromARGB(255, 117, 117, 117)),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Stat Card
//   Widget _buildStatCard(
//       String title, String value, IconData icon, Color color) {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: color.withValues(),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Icon(icon, color: color, size: 24),
//                 ),
//                 Text(
//                   value,
//                   style: TextStyle(
//                     fontSize: 22,
//                     fontWeight: FontWeight.bold,
//                     color: color,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Text(
//               title,
//               style: const TextStyle(
//                 fontSize: 14,
//                 color: Colors.grey,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // Action Card
//   Widget _buildActionCard(
//     BuildContext context,
//     String title,
//     IconData icon,
//     Color color,
//     String subtitle,
//     VoidCallback onTap,
//   ) {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(12),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: color.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Icon(icon, color: color, size: 28),
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 title,
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 subtitle,
//                 style: TextStyle(
//                   fontSize: 12,
//                   color: const Color.fromARGB(255, 117, 117, 117),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // Master Card
//   Widget _buildMasterCard(
//     BuildContext context,
//     String title,
//     IconData icon,
//     Color color,
//     String subtitle,
//     VoidCallback onTap,
//   ) {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(12),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(icon, size: 40, color: color),
//               const SizedBox(height: 12),
//               Text(
//                 title,
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 subtitle,
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 12,
//                   color: Colors.grey[600],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // Handle Navigation
//   void _handleNavigation(int index) {
//     switch (index) {
//       case 0: // Dashboard
//         // Already on dashboard
//         break;
//       case 1: // New Transaction
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => const NewTransactionScreen(),
//           ),
//         );
//         break;
//       case 2: // Farmers
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => const FarmerListScreen(),
//           ),
//         );
//         break;
//       case 3: // Traders
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => const TraderListScreen(),
//           ),
//         );
//         break;
//       case 4: // Produce
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => const ProduceListScreen(),
//           ),
//         );
//         break;
//       case 5: // Expense Types
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => ExpenseTypeListScreen(),
//           ),
//         );
//         break;
//       case 6: // Reports
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('अहवाल स्क्रीन लवकरच येईल')),
//         );
//         break;
//       case 7: // Settings
//         Navigator.pushNamed(context, '/settings');
//         break;
//     }
//   }
// }

// // Navigation Item Model
// class NavigationItem {
//   final String title;
//   final IconData icon;

//   const NavigationItem({required this.title, required this.icon});
// }
import 'package:flutter/material.dart';
import '../transaction/new_transaction_screen.dart';
import '../master_data/master_entry_screen.dart'; // नवीन मास्टर एन्ट्री स्क्रीन
import '../reports/reports_screen.dart'; // अहवाल स्क्रीन (पुढे बनवू)
import '../settings/settings_screen.dart';
import '../transaction/pavti_list_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('डॅशबोर्ड'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.green),
              child: const Text(
                'भारत मंडी',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('डॅशबोर्ड'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt),
              title: const Text('नवीन पावती'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NewTransactionScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('मास्टर एन्ट्री'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MasterEntryScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.assessment),
              title: const Text('अहवाल'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ReportsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('पावती यादी'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PavtiListScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'त्वरित क्रिया',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: isMobile ? 2 : 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildQuickActionCard(
                  icon: Icons.receipt,
                  title: 'नवीन पावती',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const NewTransactionScreen()),
                  ),
                ),
                _buildQuickActionCard(
                  icon: Icons.payment,
                  title: 'जमा एन्ट्री',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('जमा एन्ट्री लवकरच उपलब्ध होईल')),
                    );
                  },
                ),
                _buildQuickActionCard(
                  icon: Icons.category,
                  title: 'मास्टर एन्ट्री',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MasterEntryScreen()),
                  ),
                ),
                _buildQuickActionCard(
                  icon: Icons.assessment,
                  title: 'अहवाल',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ReportsScreen()),
                  ),
                ),
                _buildQuickActionCard(
                  icon: Icons.list,
                  title: 'पावती यादी',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PavtiListScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // तुझ्या जुन्या डॅशबोर्ड कार्ड्स (आजचा सारांश) – तसेच ठेवले
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('आजचा सारांश',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('एकूण पावत्या:'),
                        const Text('१२',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('एकूण रक्कम:'),
                        const Text('₹१,२५,०००',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('थकबाकी:'),
                        const Text('₹१५,०००',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.green),
            const SizedBox(height: 8),
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
