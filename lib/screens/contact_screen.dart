import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  Future<void> _launchPhone(String phoneNumber) async {
    
    final String sanitizedNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    final Uri phoneUri = Uri(scheme: 'tel', path: sanitizedNumber);

    try {
      
      final bool launched = await launchUrl(phoneUri, mode: LaunchMode.externalApplication);

      if (!launched) {
        throw 'Could not launch $sanitizedNumber';
      }
    } catch (e) {
      throw 'Could not launch $sanitizedNumber: $e';
    }
  }

  
  void _showPhoneDialog(BuildContext context, List<String> phoneNumbers) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select a Number'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: phoneNumbers.map((number) {
              return ListTile(
                title: Text(number),
                onTap: () {
                  _launchPhone(number); 
                  Navigator.pop(context); 
                },
              );
            }).toList(),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context); 
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildContactCard('EMS-QRT', ['0985-212-2565', '0927-755-5625'], context),
            _buildContactCard('MSWD', ['0995-728-5214'], context),
            _buildContactCard('BFP', ['0954-245-0660', '0951-112-8688'], context),
            _buildContactCard('PNP', ['0998-598-5944', '0999-696-3211'], context),
            _buildContactCard('RHU', ['0915-406-0353'], context),
            _buildContactCard('MDRRMO-POLANGUI', ['0961-051-2959'], context),
            
          ],
        ),
      ),
    );
  }

  
  Widget _buildContactCard(String name, List<String> phoneNumbers, BuildContext context) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: Icon(
          Icons.contact_phone,
          color: Color.fromARGB(255, 28, 112, 244),
          size: 40,
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Tap to choose number',
          style: const TextStyle(
            fontSize: 16,
            color: Color.fromARGB(255, 28, 112, 244),
            decoration: TextDecoration.underline,
          ),
        ),
        onTap: () {
          _showPhoneDialog(context, phoneNumbers); 
        },
      ),
    );
  }
}
