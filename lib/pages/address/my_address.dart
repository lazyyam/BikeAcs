import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../appUsers/users.dart';
import '../../services/address_database.dart';
import 'address_model.dart';
import 'address_view_model.dart'; // Import the new ViewModel

class MyAddressScreen extends StatefulWidget {
  const MyAddressScreen({Key? key}) : super(key: key);

  @override
  State<MyAddressScreen> createState() => _MyAddressState();
}

class _MyAddressState extends State<MyAddressScreen> {
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
          final defaultAddressId =
              AddressViewModel.getDefaultAddressId(addresses);

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
                            if (address.id == defaultAddressId)
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
                                AddressViewModel.navigateToEditAddress(
                                    context, currentUser.uid, address);
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
          AddressViewModel.navigateToEditAddress(context, currentUser.uid);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
