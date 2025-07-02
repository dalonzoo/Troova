
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'CreateAdPage.dart';

class UserAdsPage extends StatefulWidget {
  final String userId;

  UserAdsPage({required this.userId});
  @override
  _UserAdsPageState createState() => _UserAdsPageState();
}

class _UserAdsPageState extends State<UserAdsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> _adsStream;

  @override
  void initState() {
    super.initState();
    _adsStream = _firestore
        .collection('ads')
        .where('userId', isEqualTo: widget.userId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("I miei annunci", style: TextStyle(color: Colors.black87)),
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: IconThemeData(color: Colors.black87),
      ),
    body: StreamBuilder<QuerySnapshot>(
        stream: _adsStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Si è verificato un errore'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Non hai ancora creato annunci'));
          }

          return ListView(
            padding: EdgeInsets.all(16.0),
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data = document.data() as Map<String, dynamic>;
              return Column(
                children: [
                  _buildAdCard(context, document.id, data),
                  SizedBox(height: 16.0), // Aumenta lo spazio tra le card
                ],
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Naviga alla pagina di creazione annuncio
          Navigator.push(context,MaterialPageRoute(builder: (context) => CreateAdPage(userId: widget.userId)));
        },
        child: Icon(Icons.add, color: Colors.white,),
        backgroundColor: Colors.blue[700],
      ),
    );
  }

  Widget _buildAdCard(BuildContext context, String adId, Map<String, dynamic> data) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data['imageUrl'] != null)
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
              child: Image.network(
                data['imageUrl'],
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'] ?? 'Titolo non disponibile',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('${data['rate']} €/h'),
                SizedBox(height: 8),
                Text(
                  data['description'] ?? 'Nessuna descrizione',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                Text('Giorni disponibili: ${(data['daysAvailable'] as List).join(", ")}'),
                SizedBox(height: 8),
                Text('Orario: ${_formatTime(data['startTime'])} - ${_formatTime(data['endTime'])}'),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _editAd(context, adId, data),
                      child: Text('Modifica'),
                      style: TextButton.styleFrom(foregroundColor: Colors.blue[700]),
                    ),
                    SizedBox(width: 8),
                    TextButton(
                      onPressed: () => _deleteAd(context, adId),
                      child: Text('Elimina'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(dynamic time) {
    if (time is Timestamp) {
      DateTime dateTime = time.toDate();
      return DateFormat('HH:mm').format(dateTime);
    } else if (time is String) {
      return time; // Assumiamo che la stringa sia già nel formato corretto
    } else {
      return 'Orario non disponibile'; // Gestione di casi imprevisti
    }
  }
  void _editAd(BuildContext context, String adId, Map<String, dynamic> data) {
    // Naviga alla pagina di modifica dell'annuncio
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAdPage(adId: adId, adData: data),
      ),
    );
  }

  void _deleteAd(BuildContext context, String adId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Conferma eliminazione'),
          content: Text('Sei sicuro di voler eliminare questo annuncio?'),
          actions: [
            TextButton(
              child: Text('Annulla'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Elimina'),
              onPressed: () async {
                await _firestore.collection('ads').doc(adId).delete();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Annuncio eliminato con successo')),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class EditAdPage extends StatefulWidget {
  final String adId;
  final Map<String, dynamic> adData;

  EditAdPage({required this.adId, required this.adData});

  @override
  _EditAdPageState createState() => _EditAdPageState();
}

class _EditAdPageState extends State<EditAdPage> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _rateController;
  late Map<String, bool> _selectedDays;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.adData['title']);
    _descriptionController = TextEditingController(text: widget.adData['description']);
    _rateController = TextEditingController(text: widget.adData['rate'].toString());
    _selectedDays = {
      'Lunedì': false,
      'Martedì': false,
      'Mercoledì': false,
      'Giovedì': false,
      'Venerdì': false,
      'Sabato': false,
      'Domenica': false,
    };
    for (String day in widget.adData['daysAvailable']) {
      _selectedDays[day] = true;
    }
    _startTime = _parseTimeOfDay(widget.adData['startTime'] is Timestamp ? _formatTime(widget.adData['startTime']) : widget.adData['startTime']);
    _endTime = _parseTimeOfDay(widget.adData['endTime'] is Timestamp ? _formatTime(widget.adData['endTime']) : widget.adData['endTime']);

  }

  String _formatTime(dynamic time) {
    if (time is Timestamp) {
      DateTime dateTime = time.toDate();
      return DateFormat('HH:mm').format(dateTime);
    } else if (time is String) {
      return time; // Assumiamo che la stringa sia già nel formato corretto
    } else {
      return 'Orario non disponibile'; // Gestione di casi imprevisti
    }
  }
  TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return TimeOfDay(hour: hour, minute: minute);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Modifica Annuncio'),
        backgroundColor: Colors.blue[700],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Titolo'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Descrizione'),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _rateController,
              decoration: InputDecoration(labelText: 'Tariffa oraria (€)'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            Text('Giorni disponibili:', style: TextStyle(fontWeight: FontWeight.bold)),
            ..._selectedDays.entries.map((entry) {
              return CheckboxListTile(
                title: Text(entry.key),
                value: entry.value,
                onChanged: (bool? value) {
                  setState(() {
                    _selectedDays[entry.key] = value!;
                  });
                },
              );
            }),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: _startTime,
                      );
                      if (picked != null) {
                        setState(() {
                          _startTime = picked;
                        });
                      }
                    },
                    child: Text('Ora inizio: ${_startTime.format(context)}'),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: _endTime,
                      );
                      if (picked != null) {
                        setState(() {
                          _endTime = picked;
                        });
                      }
                    },
                    child: Text('Ora fine: ${_endTime.format(context)}'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            Center(
            child:
            ElevatedButton(
              onPressed: _updateAd,
              child: Text('Aggiorna Annuncio', style: TextStyle(color: Colors.white),),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _updateAd() async {
    // Verifica che tutti i campi siano compilati
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _rateController.text.isEmpty ||
        !_selectedDays.containsValue(true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Compila tutti i campi e seleziona almeno un giorno')),
      );
      return;
    }

    // Prepara i dati aggiornati
    Map<String, dynamic> updatedData = {
      'title': _titleController.text,
      'description': _descriptionController.text,
      'rate': int.parse(_rateController.text),
      'daysAvailable': _selectedDays.entries.where((e) => e.value).map((e) => e.key).toList(),
      'startTime': Timestamp.fromDate(DateTime(2022, 1, 1, _startTime.hour, _startTime.minute)),
      'endTime': Timestamp.fromDate(DateTime(2022, 1, 1, _endTime.hour, _endTime.minute)),
    };

    // Aggiorna il documento nel Firestore
    try {
      await FirebaseFirestore.instance.collection('ads').doc(widget.adId).update(updatedData);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Annuncio aggiornato con successo')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante l\'aggiornamento dell\'annuncio')),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _rateController.dispose();
    super.dispose();
  }
}