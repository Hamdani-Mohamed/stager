import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

// --- AVATAR ---
class UserAvatar extends StatelessWidget {
  final String name;
  final double size;

  const UserAvatar({super.key, required this.name, this.size = 50});

  Color _getColor(String text) => Color.fromARGB(
        255,
        Random(text.hashCode).nextInt(200),
        Random(text.hashCode).nextInt(200),
        Random(text.hashCode).nextInt(200),
      );

  @override
  Widget build(BuildContext context) {
    String initials = "?";
    
    if (name.trim().isNotEmpty) {
      List<String> parts = name.trim().split(" ");
      if (parts.length > 1) {
        initials = "${parts[0][0]}${parts[1][0]}".toUpperCase();
      } else {
        initials = parts[0][0].toUpperCase();
      }
    }
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getColor(name).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _getColor(name),
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
  }
}

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _idx = 0;
  final List<Widget> _pages = [
    const OffersTab(),
    const MyApplicationsTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_idx],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _idx,
          onDestinationSelected: (i) => setState(() => _idx = i),
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFE0F7F6),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.search),
              selectedIcon: Icon(Icons.search, color: Color(0xFF2EC4B6)),
              label: 'Explorer',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment, color: Color(0xFF2EC4B6)),
              label: 'Suivi',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: Color(0xFF2EC4B6)),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}

// --- ONGLET 1 : OFFRES (AVEC RECHERCHE, SANS BOUTON VERT) ---
class OffersTab extends StatefulWidget {
  const OffersTab({super.key});

  @override
  State<OffersTab> createState() => _OffersTabState();
}

class _OffersTabState extends State<OffersTab> {
  String _searchQuery = ""; // Pour stocker ce qu'on tape

  Future<bool> _checkIfAllowed(String uid) async {
    final apps = await FirebaseFirestore.instance
        .collection('applications')
        .where('studentId', isEqualTo: uid)
        .where('status', isEqualTo: 'accepted')
        .get();
    
    return apps.docs.isEmpty;
  }

  void _apply(BuildContext context, String id, String title) async {
    final user = FirebaseAuth.instance.currentUser!;
    
    if (!await _checkIfAllowed(user.uid)) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text("Action impossible"),
            content: const Text("Vous avez déjà un stage accepté !"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
      return;
    }

    final check = await FirebaseFirestore.instance
        .collection('applications')
        .where('internshipId', isEqualTo: id)
        .where('studentId', isEqualTo: user.uid)
        .get();

    if (check.docs.isNotEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Déjà postulé !")),
        );
      }
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    
    final d = doc.data() as Map<String, dynamic>;
    
    await FirebaseFirestore.instance.collection('applications').add({
      'internshipId': id,
      'studentId': user.uid,
      'studentEmail': user.email,
      'studentName': d['name'],
      'studentLevel': d['level'],
      'studentSkills': d['skills'],
      'status': 'pending',
      'appliedAt': Timestamp.now(),
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Candidature envoyée !"),
          backgroundColor: Color(0xFF2EC4B6),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- BARRE DE RECHERCHE (SEULE) ---
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.toLowerCase();
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: "Rechercher un stage...",
                    icon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Offres disponibles",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            
            const SizedBox(height: 10),
            
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('internships')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (ctx, s) {
                  if (!s.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final allDocs = s.data!.docs;
                  
                  // FILTRAGE LOCAL
                  final docs = allDocs.where((doc) {
                    final title = (doc['title'] ?? '').toString().toLowerCase();
                    final company = (doc['companyName'] ?? '').toString().toLowerCase();
                    
                    return title.contains(_searchQuery) || 
                           company.contains(_searchQuery);
                  }).toList();

                  if (docs.isEmpty) {
                    return const Center(child: Text("Aucune offre trouvée."));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: docs.length,
                    itemBuilder: (ctx, i) {
                      final d = docs[i].data();
                      final filled = d['status'] == 'filled';
                      final isMe = filled && 
                          d['acceptedStudentId'] == FirebaseAuth.instance.currentUser!.uid;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: isMe
                              ? Border.all(color: const Color(0xFF2EC4B6), width: 2)
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(15),
                          leading: UserAvatar(
                            name: d['companyName'] ?? 'E',
                            size: 50,
                          ),
                          title: Text(
                            d['title'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 5),
                              Text(
                                d['companyName'] ?? '',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              if (isMe)
                                const Text(
                                  "🎉 VOUS AVEZ CE POSTE",
                                  style: TextStyle(
                                    color: Color(0xFF2EC4B6),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                )
                              else if (filled)
                                const Text(
                                  "🔒 CLOS",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                )
                              else
                                Text(
                                  d['description'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              isMe
                                  ? Icons.star
                                  : (filled ? Icons.lock : Icons.arrow_forward_ios),
                              size: 18,
                              color: Colors.grey,
                            ),
                            onPressed: filled
                                ? null
                                : () => _apply(context, docs[i].id, d['title']),
                          ),
                          onTap: filled
                              ? null
                              : () => _apply(context, docs[i].id, d['title']),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- ONGLET 2 : SUIVI ---
class MyApplicationsTab extends StatelessWidget {
  const MyApplicationsTab({super.key});

  void _cancel(BuildContext context, String aid, String id, bool acc) async {
    await FirebaseFirestore.instance
        .collection('applications')
        .doc(aid)
        .delete();
    
    if (acc) {
      await FirebaseFirestore.instance
          .collection('internships')
          .doc(id)
          .update({
        'status': 'open',
        'acceptedStudentId': FieldValue.delete(),
      });
    }
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Annulé")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  "Suivi des candidatures",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('applications')
                    .where('studentId', isEqualTo: uid)
                    .snapshots(),
                builder: (ctx, s) {
                  if (!s.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final apps = s.data!.docs;
                  
                  if (apps.isEmpty) {
                    return const Center(child: Text("Aucune candidature."));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: apps.length,
                    itemBuilder: (ctx, i) {
                      final a = apps[i].data();
                      final acc = a['status'] == 'accepted';

                      return FutureBuilder(
                        future: FirebaseFirestore.instance
                            .collection('internships')
                            .doc(a['internshipId'])
                            .get(),
                        builder: (c, st) {
                          if (!st.hasData) return const SizedBox();
                          
                          final d = st.data!.data() as Map<String, dynamic>;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 15),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.05),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      d['title'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: acc
                                            ? const Color(0xFFE0F7F6)
                                            : Colors.orange[50],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        acc ? "Accepté" : "En attente",
                                        style: TextStyle(
                                          color: acc
                                              ? const Color(0xFF2EC4B6)
                                              : Colors.orange,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 10),
                                
                                if (acc) ...[
                                  const Text(
                                    "Contactez l'entreprise :",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  FutureBuilder(
                                    future: FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(d['companyId'])
                                        .get(),
                                    builder: (c, u) => Text(
                                      u.hasData
                                          ? "${u.data!['email']} | ${u.data!['phone']}"
                                          : "...",
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                                
                                const SizedBox(height: 15),
                                
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    onPressed: () => _cancel(
                                      context,
                                      apps[i].id,
                                      a['internshipId'],
                                      acc,
                                    ),
                                    child: Text(acc ? "Se désister" : "Annuler"),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- ONGLET 3 : PROFIL ---
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  void _edit(
    BuildContext context,
    String name,
    String email,
    String phone,
    String lvl,
    String ski,
  ) {
    final n = TextEditingController(text: name);
    final e = TextEditingController(text: email);
    final p = TextEditingController(text: phone);
    final l = TextEditingController(text: lvl);
    final s = TextEditingController(text: ski);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Modifier Profil"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: n,
                decoration: const InputDecoration(labelText: "Nom"),
              ),
              TextField(
                controller: e,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              TextField(
                controller: p,
                decoration: const InputDecoration(labelText: "Tél"),
              ),
              TextField(
                controller: l,
                decoration: const InputDecoration(labelText: "Niveau"),
              ),
              TextField(
                controller: s,
                decoration: const InputDecoration(labelText: "Skills"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2EC4B6),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              try {
                final user = FirebaseAuth.instance.currentUser!;
                
                if (e.text != email) {
                  await user.verifyBeforeUpdateEmail(e.text);
                }
                
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .update({
                  'name': n.text,
                  'email': e.text,
                  'phone': p.text,
                  'level': l.text,
                  'skills': s.text,
                });
                
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (err) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text("Erreur (Reconnectez-vous): $err"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final d = snapshot.data!.data() as Map<String, dynamic>;
          
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(30),
                child: Column(
                  children: [
                    UserAvatar(name: d['name'] ?? 'E', size: 100),
                    
                    const SizedBox(height: 20),
                    
                    Text(
                      d['name'] ?? '',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    Text(
                      d['email'] ?? '',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FD),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          _row(Icons.phone, "Téléphone", d['phone']),
                          const Divider(height: 25),
                          _row(Icons.school, "Niveau", d['level']),
                          const Divider(height: 25),
                          _row(Icons.code, "Compétences", d['skills']),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2EC4B6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: () => _edit(
                          context,
                          d['name'] ?? '',
                          d['email'] ?? '',
                          d['phone'] ?? '',
                          d['level'] ?? '',
                          d['skills'] ?? '',
                        ),
                        child: const Text(
                          "Modifier le profil",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    TextButton(
                      onPressed: () => FirebaseAuth.instance.signOut(),
                      child: const Text(
                        "Se déconnecter",
                        style: TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _row(IconData i, String l, String? v) => Row(
        children: [
          Icon(i, color: const Color(0xFF2EC4B6), size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  v ?? '-',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}