import 'package:flutter/material.dart';
import '../models/organization_model.dart';
import 'package:google_fonts/google_fonts.dart';


class OrganizationCard extends StatelessWidget {
  final Organization org;

  const OrganizationCard({super.key, required this.org});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image: NetworkImage(org.banner),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
              // Optional: dark overlay
              Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 300, // Adjust the height as needed
                decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                  Colors.transparent, // Made the gradient lighter
                  Color.fromARGB(250, 0, 0, 0), // Made the gradient darker
                  ],
                ),
                ),
              ),
              ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(204, 0, 0, 0), // White glow
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
                ],
              ),
              child: CircleAvatar(
                backgroundColor: Colors.white, // Add a white background for the border
                radius: 22, // Slightly larger radius for the border effect
                child: CircleAvatar(
                backgroundImage: NetworkImage(org.logo),
                radius: 20, // Inner avatar radius
                ),
              ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        boxShadow: const [
                          BoxShadow(
                          color: Colors.black38, // Lighter black color
                          blurRadius: 6, // Softer blur
                          spreadRadius: 1, // Reduced spread
                          ),
                        ],
                        gradient: LinearGradient(
                          colors: [Colors.black, Colors.blue[900]!],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(8), // Rounded corners
                      ),
                        child: Row(
                        children: [
                          Icon(
                          Icons.bookmark,
                          color: Colors.white,
                          size: 18, // Adjust size as needed
                          ),
                          const SizedBox(width: 4), // Add spacing between icon and text
                          Text(
                          org.acronym,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontSize: 18,
                          ),
                          ),
                        ],
                      ),
                    ), 
                  const SizedBox(height: 130),
                  Text(
                  org.name,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                  ),
                  const SizedBox(height: 4),
                    Row(
                    children: [
                      Icon(
                      Icons.group, // Club or organization icon
                      color: Colors.blue,
                      size: 16, // Adjust size as needed
                      ),
                      const SizedBox(width: 4), // Add spacing between icon and text
                      Text(
                      org.category.toUpperCase(),
                      style: GoogleFonts.poppins(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                      ),
                    ],
                    ),
                    Row(
                    children: [
                      Icon(
                      Icons.email, // Email icon
                      color: Colors.white,
                      size: 16, // Adjust size as needed
                      ),
                      const SizedBox(width: 4), // Add spacing between icon and text
                      Text(
                      org.email,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 12,),
                      ),
                    ],
                    ),
                  Row(
                    children: [
                    Icon(
                      Icons.phone, // Phone or contact icon
                      color: Colors.white,
                      size: 16, // Adjust size as needed
                    ),
                    const SizedBox(width: 4), // Add spacing between icon and text
                    Text(
                      org.mobile.toUpperCase(),
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 12,),
                    ),
                    ],
                  ),
                  Row(
                    children: [
                    Icon(
                        Icons.facebook, // Facebook icon
                      color: Colors.white,
                      size: 16, // Adjust size as needed
                    ),
                    const SizedBox(width: 4),                       
                      Text(
                      org.facebook,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 12,),
                      ),
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
}
