import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'note.dart';

class NoteDatabase extends ChangeNotifier {
  static const String _notesKey = 'notes';
  static late SharedPreferences _prefs;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  final List<Note> currentNotes = [];

  Future<void> addNote(String textFromUser) async {
    final trimmed = textFromUser.trim();
    if (trimmed.isEmpty) return;

    final nextId = currentNotes.isEmpty
        ? 1
        : currentNotes.map((note) => note.id).reduce((a, b) => a > b ? a : b) +
              1;

    final newNote = Note(id: nextId, text: trimmed);
    currentNotes.add(newNote);

    await _persistNotes();
    notifyListeners();
  }

  Future<void> fetchNotes() async {
    final rawJson = _prefs.getString(_notesKey);
    if (rawJson == null || rawJson.isEmpty) {
      currentNotes.clear();
      notifyListeners();
      return;
    }

    final decoded = jsonDecode(rawJson) as List<dynamic>;
    final loadedNotes = decoded
        .map((item) => Note.fromJson(item as Map<String, dynamic>))
        .toList();

    currentNotes
      ..clear()
      ..addAll(loadedNotes);
    notifyListeners();
  }

  Future<void> updateNote(int id, String newText) async {
    final trimmed = newText.trim();
    if (trimmed.isEmpty) return;

    final index = currentNotes.indexWhere((note) => note.id == id);
    if (index == -1) return;

    currentNotes[index] = currentNotes[index].copyWith(text: trimmed);
    await _persistNotes();
    notifyListeners();
  }

  Future<void> deleteNote(int id) async {
    currentNotes.removeWhere((note) => note.id == id);
    await _persistNotes();
    notifyListeners();
  }

  Future<void> clearAllNotes() async {
    currentNotes.clear();
    await _prefs.remove(_notesKey);
    notifyListeners();
  }

  Future<void> _persistNotes() async {
    final encoded = jsonEncode(
      currentNotes.map((note) => note.toJson()).toList(),
    );
    await _prefs.setString(_notesKey, encoded);
  }
}
