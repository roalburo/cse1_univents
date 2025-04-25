import 'package:flutter/material.dart';
import '../models/organization_model.dart';

class OrganizationCard extends StatelessWidget {
  final Organization org;

  const OrganizationCard({super.key, required this.org});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      color: Colors.white.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Image.network(
                org.banner,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  backgroundImage: NetworkImage(org.logo),
                  radius: 20,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  org.acronym,
                ),
                const SizedBox(height: 4),
                Text(
                  org.name,
                ),
                const SizedBox(height: 4),
                Text(
                  org.category,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}