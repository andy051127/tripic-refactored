import 'package:flutter/material.dart';
import '../models/post_model.dart';

class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "차단된 계정",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: ValueListenableBuilder<List<String>>(
        valueListenable: blockedUsersNotifier,
        builder: (context, blockedUsers, child) {
          if (blockedUsers.isEmpty) {
            return const Center(
              child: Text(
                "차단된 계정이 없습니다.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: blockedUsers.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final user = blockedUsers[index];
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(
                  user,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                trailing: SizedBox(
                  height: 35,
                  child: ElevatedButton(
                    onPressed: () {
                      // 차단 해제 로직
                      final currentList = List<String>.from(
                        blockedUsersNotifier.value,
                      );
                      currentList.remove(user);
                      blockedUsersNotifier.value = currentList;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("$user 님의 차단이 해제되었습니다.")),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "차단 해제",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
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
