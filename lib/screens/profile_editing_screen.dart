import 'package:event_scheduler/other/app_validators.dart';
import 'package:event_scheduler/providers/auth_service_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileEditingScreen extends ConsumerStatefulWidget {
  const ProfileEditingScreen({super.key, required this.currentNickname});

  final String currentNickname;
  @override
  ConsumerState<ProfileEditingScreen> createState() =>
      _ProfileEditingScreenState();
}

class _ProfileEditingScreenState extends ConsumerState<ProfileEditingScreen> {
  TextEditingController nicknameController = TextEditingController();
  @override
  void initState() {
    super.initState();
    nicknameController.text = widget.currentNickname;
  }

  @override
  void dispose() {
    nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profile editing")),
      body: Column(
        children: [
          SizedBox(
            height: 30,
            width: 200,
            child: TextFormField(
              validator: AppValidator.validateNickname,
              controller: nicknameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderSide: BorderSide(width: 2)),
              ),
            ),
          ),
          IconButton(
            onPressed: () async {
              final newNickname = nicknameController.text.trim();
              if (newNickname == widget.currentNickname ||
                  newNickname.length < 5) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Incorrect format"),
                    duration: Duration(seconds: 1),
                  ),
                );
                return;
              }

              bool isChanged = false;
              try {
                await ref
                    .read(authServiceProvider)
                    .updateNickname(
                      currentNickname: widget.currentNickname,
                      newNickname: newNickname,
                    );
                isChanged = true;
                if (context.mounted) {
                  Navigator.pop(context, isChanged);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: Icon(Icons.check),
          ),
        ],
      ),
    );
  }
}
