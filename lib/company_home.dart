import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

// --- AVATAR ---
class UserAvatar extends StatelessWidget {
  final String name;
  final double radius;
  const UserAvatar({super.key, required this.name, this.radius = 20});

  Color _getColor(String text) => Color.fromARGB(255, Random(text.hashCode).nextInt(200), Random(text.hashCode).nextInt(200), Random(text.hashCode).nextInt(200));

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
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: _getColor(name).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(fontWeight: FontWeight.bold, color: _getColor(name), fontSize: radius * 0.8),
        ),
      ),
    );
  }
}

class CompanyHomeScreen extends StatefulWidget {
  const CompanyHomeScreen({super.key});
  @override
  State<CompanyHomeScreen> createState() => _CompanyHomeScreenState();
}

class _CompanyHomeScreenState extends State<CompanyHomeScreen> {
  int _currentIndex = 0;
  final List<Widget> _pages = [const CompanyOffersTab(), const CompanyProfileTab()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE0F7F6),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list_alt_outlined), selectedIcon: Icon(Icons.list_alt, color: Color(0xFF2EC4B6)), label: 'Mes Offres'),
          NavigationDestination(icon: Icon(Icons.business_outlined), selectedIcon: Icon(Icons.business, color: Color(0xFF2EC4B6)), label: 'Mon Profil'),
        ],
      ),
    );
  }
}

// --- ONGLET 1 : OFFRES ---
class CompanyOffersTab extends StatefulWidget {
  const CompanyOffersTab({super.key});
  @override
  State<CompanyOffersTab> createState() => _CompanyOffersTabState();
}

class _CompanyOffersTabState extends State<CompanyOffersTab> {
  Future<String> _getCompanyName() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) return doc.get('name') ?? 'Entreprise';
    } catch (e) { /* Ignorer */ }
    return 'Entreprise';
  }

  void _addInternship() async {
    final tCtrl = TextEditingController();
    final dCtrl = TextEditingController();
    final name = await _getCompanyName();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("✨ Nouvelle Offre"),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: tCtrl, decoration: const InputDecoration(labelText: 'Titre')),
            const SizedBox(height: 10),
            TextField(controller: dCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2EC4B6), foregroundColor: Colors.white),
            onPressed: () {
              if (tCtrl.text.isNotEmpty) {
                FirebaseFirestore.instance.collection('internships').add({
                  'title': tCtrl.text, 'description': dCtrl.text, 'companyId': FirebaseAuth.instance.currentUser!.uid, 'companyName': name, 'status': 'open', 'createdAt': Timestamp.now()
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text("Publier"),
          )
        ],
      ),
    );
  }

  void _editInternship(String id, String t, String d) {
    final tc = TextEditingController(text: t);
    final dc = TextEditingController(text: d);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Modifier"),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: tc, decoration: const InputDecoration(labelText: 'Titre')),
            const SizedBox(height: 10),
            TextField(controller: dc, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            onPressed: () {
              FirebaseFirestore.instance.collection('internships').doc(id).update({'title': tc.text, 'description': dc.text});
              Navigator.pop(ctx);
            },
            child: const Text("Enregistrer"),
          )
        ],
      ),
    );
  }

  void _deleteInternship(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Non")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final apps = await FirebaseFirestore.instance.collection('applications').where('internshipId', isEqualTo: id).get();
              for (var d in apps.docs) await d.reference.delete();
              await FirebaseFirestore.instance.collection('internships').doc(id).delete();
            },
            child: const Text("Oui"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Espace Recruteur", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  FloatingActionButton.small(
                    onPressed: _addInternship,
                    backgroundColor: const Color(0xFF2EC4B6),
                    child: const Icon(Icons.add, color: Colors.white),
                  )
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance.collection('internships').where('companyId', isEqualTo: user.uid).orderBy('createdAt', descending: true).snapshots(),
                builder: (ctx, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snap.data!.docs;
                  if (docs.isEmpty) return const Center(child: Text("Aucune offre."));
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: docs.length,
                    itemBuilder: (ctx, i) {
                      final d = docs[i].data();
                      final id = docs[i].id;
                      final full = d['status'] == 'filled';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]
                        ),
                        child: InkWell(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CandidatesScreen(internshipId: id, internshipTitle: d['title']))),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text(d['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                                    PopupMenuButton(
                                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                                      onSelected: (v) => v == 'e' ? _editInternship(id, d['title'], d['description'] ?? '') : _deleteInternship(id),
                                      itemBuilder: (c) => [
                                        const PopupMenuItem(value: 'e', child: Text("Modifier")),
                                        const PopupMenuItem(value: 'd', child: Text("Supprimer"))
                                      ],
                                    )
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(d['description'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[500])),
                                const SizedBox(height: 15),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(color: full ? Colors.red[50] : const Color(0xFFE0F7F6), borderRadius: BorderRadius.circular(8)),
                                      child: Text(full ? "🔒 CLOS" : "🟢 ACTIF", style: TextStyle(color: full ? Colors.red : const Color(0xFF2EC4B6), fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                    StreamBuilder(
                                      stream: FirebaseFirestore.instance.collection('applications').where('internshipId', isEqualTo: id).snapshots(),
                                      builder: (c, s) => Text("${s.hasData ? s.data!.docs.length : 0} candidat(s)", style: TextStyle(color: Colors.grey[600]))
                                    )
                                  ],
                                )
                              ],
                            ),
                          ),
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

// --- ONGLET 2 : PROFIL ---
class CompanyProfileTab extends StatelessWidget {
  const CompanyProfileTab({super.key});

  void _editProfile(BuildContext context, String name, String email, String phone) {
    final n = TextEditingController(text: name);
    final e = TextEditingController(text: email);
    final p = TextEditingController(text: phone);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Modifier Profil"),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: n, decoration: const InputDecoration(labelText: "Nom Entreprise")),
            TextField(controller: e, decoration: const InputDecoration(labelText: "Email")),
            TextField(controller: p, decoration: const InputDecoration(labelText: "Téléphone")),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2EC4B6), foregroundColor: Colors.white),
            onPressed: () async {
              try {
                final user = FirebaseAuth.instance.currentUser!;
                if (e.text != email) await user.verifyBeforeUpdateEmail(e.text);
                await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'name': n.text, 'email': e.text, 'phone': p.text});
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (err) {
                if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text("Erreur: $err"), backgroundColor: Colors.red));
              }
            },
            child: const Text("Enregistrer"),
          )
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
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (c, s) {
          if (!s.hasData) return const Center(child: CircularProgressIndicator());
          final d = s.data!.data() as Map<String, dynamic>;
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    UserAvatar(name: d['name'] ?? 'E', radius: 50),
                    const SizedBox(height: 20),
                    Text(d['name'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: const Color(0xFFF8F9FD), borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        children: [
                          const Icon(Icons.phone, color: Color(0xFF2EC4B6)),
                          const SizedBox(width: 15),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Téléphone", style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text(d['phone'] ?? '-', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2EC4B6), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                        onPressed: () => _editProfile(context, d['name'] ?? '', d['email'] ?? '', d['phone'] ?? ''),
                        child: const Text("Modifier le profil", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(onPressed: () => FirebaseAuth.instance.signOut(), child: const Text("Se déconnecter", style: TextStyle(color: Colors.red, fontSize: 16)))
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- ECRAN CANDIDATS (AVEC LA VRAIE SÉCURITÉ) ---
class CandidatesScreen extends StatelessWidget {
  final String internshipId;
  final String internshipTitle;
  const CandidatesScreen({super.key, required this.internshipId, required this.internshipTitle});

  // FONCTION ROBUSTE
  Future<void> _act(BuildContext context, String aid, String sid, String studentName, bool accept) async {
    if (accept) {
      // 1. Vérification de sécurité (Est-il déjà pris ?)
      final check = await FirebaseFirestore.instance.collection('applications')
          .where('studentId', isEqualTo: sid)
          .where('status', isEqualTo: 'accepted')
          .get();

      if (check.docs.isNotEmpty) {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Impossible 🚫"),
              content: Text("$studentName a déjà un stage accepté ailleurs !"),
              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
            ),
          );
        }
        return; // STOP
      }

      // 2. Validation
      await FirebaseFirestore.instance.collection('applications').doc(aid).update({'status': 'accepted'});
      await FirebaseFirestore.instance.collection('internships').doc(internshipId).update({'status': 'filled', 'acceptedStudentId': sid});
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Candidat recruté !"), backgroundColor: Colors.green));
      }

    } else {
      // Annulation
      await FirebaseFirestore.instance.collection('applications').doc(aid).update({'status': 'pending'});
      await FirebaseFirestore.instance.collection('internships').doc(internshipId).update({'status': 'open', 'acceptedStudentId': FieldValue.delete()});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Recrutement annulé.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(title: Column(children: [Text("Candidats", style: const TextStyle(fontSize: 16)), Text(internshipTitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal))])),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('applications').where('internshipId', isEqualTo: internshipId).snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final apps = snap.data!.docs;
          if (apps.isEmpty) return const Center(child: Text("Aucun candidat pour le moment."));

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: apps.length,
            itemBuilder: (ctx, i) {
              final a = apps[i].data();
              final acc = a['status'] == 'accepted';
              final sName = a['studentName'] ?? 'Inconnu';

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: acc ? Border.all(color: Colors.green, width: 2) : null, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)]),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(children: [
                        UserAvatar(name: sName, radius: 25),
                        const SizedBox(width: 15),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(sName, style: const TextStyle(fontWeight: FontWeight.bold)), Text("${a['studentLevel'] ?? ''} • ${a['studentSkills'] ?? ''}", style: TextStyle(color: Colors.grey[600], fontSize: 12))])),
                        if (acc) const Icon(Icons.check_circle, color: Colors.green, size: 30)
                      ]),
                      const SizedBox(height: 15),
                      if (acc) ...[
                        FutureBuilder(
                          future: FirebaseFirestore.instance.collection('users').doc(a['studentId']).get(),
                          builder: (c, us) {
                            final userData = us.data?.data() as Map<String, dynamic>?;
                            return Text(us.hasData && userData != null ? "📞 ${userData['phone'] ?? '-'}  📧 ${userData['email'] ?? '-'}" : "...");
                          },
                        ),
                        const SizedBox(height: 10),
                        TextButton(onPressed: () => _act(context, apps[i].id, a['studentId'], sName, false), child: const Text("Annuler recrutement", style: TextStyle(color: Colors.red)))
                      ] else
                        StreamBuilder(
                          stream: FirebaseFirestore.instance.collection('internships').doc(internshipId).snapshots(),
                          builder: (c, st) {
                            if (st.hasData && st.data!['status'] == 'filled') return const Text("Stage déjà pourvu.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic));
                            return SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _act(context, apps[i].id, a['studentId'], sName, true), child: const Text("RECRUTER")));
                          },
                        )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
