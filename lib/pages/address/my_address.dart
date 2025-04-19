import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/users.dart';
import '../../services/address_database.dart';
import 'address_model.dart';
import 'edit_address.dart';

class MyAddressScreen extends StatefulWidget {
  const MyAddressScreen({Key? key}) : super(key: key);

  @override
  State<MyAddressScreen> createState() => _MyAddressState();
}

class _MyAddressState extends State<MyAddressScreen> {
  String? _defaultAddressId; // Track the default address ID

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AppUsers?>(context);
    if (currentUser == null) {
      return const Center(child: Text("Please log in to view your addresses."));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Address'),
      ),
      body: StreamBuilder<List<Address>>(
        stream: AddressDatabase().getAddresses(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No addresses found.'));
          }
          final addresses = snapshot.data!;
          _defaultAddressId = addresses
              .firstWhere(
                (a) => a.isDefault,
                orElse: () => Address(
                    id: '', name: '', phone: '', address: '', isDefault: false),
              )
              .id;

          return ListView.builder(
            padding: const EdgeInsets.all(20.0),
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final address = addresses[index];
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 5.0,
                      spreadRadius: 2.0,
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
                          address.name,
                          style: const TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            if (address.id == _defaultAddressId)
                              const Text(
                                "[Default]",
                                style: TextStyle(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFFBA3B),
                                ),
                              ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditAddressScreen(
                                      uid: currentUser.uid,
                                      address: address,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      address.phone,
                      style: const TextStyle(fontSize: 16.0),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      address.address,
                      style: const TextStyle(fontSize: 16.0),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditAddressScreen(uid: currentUser.uid),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
