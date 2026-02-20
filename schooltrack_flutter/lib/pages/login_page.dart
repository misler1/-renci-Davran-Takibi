import "package:flutter/material.dart";

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.onLogin,
  });
  final Future<bool> Function(String username, String password) onLogin;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final u = TextEditingController();
  final p = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    u.dispose();
    p.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFDBEAFE), Color(0xFFEFF6FF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.school_rounded, size: 52, color: Color(0xFF2563EB)),
                    const Text("Ogrenci Davranis Takip Sistemi", textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 16),
                    TextField(controller: u, decoration: const InputDecoration(labelText: "Kullanici Adi", border: OutlineInputBorder())),
                    const SizedBox(height: 10),
                    TextField(controller: p, obscureText: true, decoration: const InputDecoration(labelText: "Sifre", border: OutlineInputBorder())),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting
                            ? null
                            : () async {
                                final messenger = ScaffoldMessenger.of(context);
                                setState(() => _submitting = true);
                                final ok = await widget.onLogin(u.text.trim(), p.text);
                                if (!mounted) return;
                                setState(() => _submitting = false);
                                if (!ok) {
                                  messenger.showSnackBar(const SnackBar(content: Text("Giris basarisiz")));
                                }
                              },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: _submitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text("Giris Yap"),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text("Canli Surum: 2026-02-19 11:30", style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
