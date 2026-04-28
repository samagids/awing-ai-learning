import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/services/analytics_service.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';
import 'package:awing_ai_learning/services/auth_service.dart';
import 'package:awing_ai_learning/services/parent_notification_service.dart';

/// Expert quiz — paragraph fill-in-the-blank.
/// 10 quizzes, each with 2 paragraphs containing blanks to fill in.
/// Each paragraph has 2-4 blanks chosen from 4 options.

class _ParagraphBlank {
  final String correctWord;
  final List<String> choices; // 4 choices including correct

  const _ParagraphBlank({required this.correctWord, required this.choices});
}

class _QuizParagraph {
  final String title;
  final String context;
  final String awingText; // paragraph text with {0}, {1}, {2}... as blank markers
  final String englishText;
  final List<_ParagraphBlank> blanks;

  const _QuizParagraph({
    required this.title,
    required this.context,
    required this.awingText,
    required this.englishText,
    required this.blanks,
  });
}

// 40 paragraphs total. Random() picks 2 per attempt — enough variety so kids
// can't memorize the sequence across 20 quizzes × 2 paragraphs each.
// All Awing text recombines vocabulary from AwingOrthography2005.pdf and
// conversation data — no new word coinages.
final List<_QuizParagraph> _allParagraphs = [
  // Quiz 1
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//   _QuizParagraph(
//     title: 'At the Market',
//     context: 'A person goes shopping at the market.',
//     awingText: 'A kə {0} məteenɔ\u0301. A kə {1} nəfa\u0301ŋə. A kə tuə {2} nə əfua\u0301.',
//     englishText: 'He went to the market. He sold things. He bought clothes and food.',
//     blanks: [
//       _ParagraphBlank(correctWord: 'ghɛnɔ\u0301', choices: ['ghɛnɔ\u0301', 'yi\u030Cə', 'nonɔ\u0301', 'ko\u0301\u0027ə']),
//       _ParagraphBlank(correctWord: 'nəfa\u0301ŋə', choices: ['nəfa\u0301ŋə', 'nəpɔ\u0027ɔ\u0301', 'ati\u030Cə', 'nchi\u0301ə']),
//       _ParagraphBlank(correctWord: 'ŋku\u0301', choices: ['ŋku\u0301', 'apo\u0302', 'nto\u0302', 'nde\u0300']),
//     ],
//   ),
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//   _QuizParagraph(
//     title: 'The Baby',
//     context: 'Describing what a baby is doing.',
//     awingText: '{0} a tə nonnɔ\u0301 a {1}. A tə nonɔ\u0301 nde\u0300e. Ma\u030C a tə {2} Mo\u0301onə.',
//     englishText: 'The baby is lying on the bed. He is sleeping well. Mother is watching the baby.',
//     blanks: [
//       _ParagraphBlank(correctWord: 'Mo\u0301onə', choices: ['Mo\u0301onə', 'Ta\u0301ta', 'Fwa\u0301', 'Nge\u0301ŋə']),
//       _ParagraphBlank(correctWord: 'əkwunɔ\u0301', choices: ['əkwunɔ\u0301', 'ati\u030Cə', 'nchi\u0301ə', 'məteenɔ\u0301']),
//       _ParagraphBlank(correctWord: 'lɔ\u0301', choices: ['lɔ\u0301', 'ko\u0301', 'zi\u0301', 'pə']),
//     ],
//   ),

  // Quiz 2
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//   _QuizParagraph(
//     title: 'Greeting a Friend',
//     context: 'Two friends meet and exchange greetings.',
//     awingText: "Cha'tɔ\u0301! Yə {0}? Nde\u0300e, ma\u030C wə nə mə {1}. A kə {2} a nchi\u0301ə.",
//     englishText: 'Hello! How are you? Well, mother is fine. She came home.',
//     blanks: [
//       _ParagraphBlank(correctWord: 'yi\u030Cə?', choices: ['yi\u030Cə?', 'ghɛnɔ\u0301?', 'nonɔ\u0301?', 'lɔ\u0301?']),
//       _ParagraphBlank(correctWord: 'kwa\u0301tə.', choices: ['kwa\u0301tə.', 'ghɛnɔ\u0301.', 'nonnɔ\u0301.', 'fɛ\u0301ə.']),
//       _ParagraphBlank(correctWord: 'yi\u030Cə', choices: ['yi\u030Cə', 'ghɛnɔ\u0301', 'nonɔ\u0301', 'tuə']),
//     ],
//   ),
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//   _QuizParagraph(
//     title: 'The Snake',
//     context: 'People discover a snake near the path.',
//     awingText: 'Po {0} no\u0301olə. Po kə {1}. A kə {2} a mbə\u0301.',
//     englishText: 'They saw a snake. They ran. It went into the bush.',
//     blanks: [
//       _ParagraphBlank(correctWord: 'zi\u0301', choices: ['zi\u0301', 'ko\u0301', 'tuə', 'lɔ\u0301']),
//       _ParagraphBlank(correctWord: 'tso\u0301ŋə', choices: ['tso\u0301ŋə', 'nonɔ\u0301', 'la\u0301', 'zo']),
//       _ParagraphBlank(correctWord: 'ghɛnɔ\u0301', choices: ['ghɛnɔ\u0301', 'yi\u030Cə', 'nonɔ\u0301', 'zo']),
//     ],
//   ),

  // Quiz 3
  _QuizParagraph(
    title: 'Going to School',
    context: 'A child prepares for and goes to school.',
    awingText: 'Mo\u0301onə a tə {0} a əshu\u0301ə. A kə ko {1} a apo\u0302. A kə {2} nde\u0300e.',
    englishText: 'The child is going to school. He took the book in his hand. He learned well.',
    blanks: [
      _ParagraphBlank(correctWord: 'ghɛnɔ\u0301', choices: ['ghɛnɔ\u0301', 'nonɔ\u0301', 'yi\u030Cə', 'tuə']),
      _ParagraphBlank(correctWord: 'əshu\u0301ə', choices: ['əshu\u0301ə', 'əfua\u0301', 'ŋku\u0301', 'nde\u0300']),
      _ParagraphBlank(correctWord: 'zɛ\u0301', choices: ['zɛ\u0301', 'ghɛnɔ\u0301', 'ko\u0301', 'fɛ\u0301ə']),
    ],
  ),
  _QuizParagraph(
    title: 'Building a House',
    context: 'A man builds a house for his family.',
    awingText: '{0} a kə zo {1}. A kə ko mbi\u0301 nə ati\u030Cə. {2} wə nə mə ntɛ\u0301.',
    englishText: 'Father built a house. He used stones and trees. The house is strong.',
    blanks: [
      _ParagraphBlank(correctWord: 'Ta\u0301ta', choices: ['Ta\u0301ta', 'Mo\u0301onə', 'Ma\u030C', 'Fwa\u0301']),
      _ParagraphBlank(correctWord: 'nchi\u0301ə.', choices: ['nchi\u0301ə.', 'ati\u030Cə.', 'nde\u0300.', 'məteenɔ\u0301.']),
      _ParagraphBlank(correctWord: 'Nchi\u0301ə', choices: ['Nchi\u0301ə', 'Ati\u030Cə', 'Apo\u0302', 'No\u0301olə']),
    ],
  ),

  // Quiz 4
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//   _QuizParagraph(
//     title: 'Cooking Food',
//     context: 'A woman prepares a meal.',
//     awingText: 'Ma\u030C a kə {0} əfua\u0301. A kə ko {1} a nde\u0300. A kə {2} mo\u0301onə.',
//     englishText: 'Mother cooked food. She fetched water from the river. She fed the child.',
//     blanks: [
//       _ParagraphBlank(correctWord: 'nya\u0301ŋə', choices: ['nya\u0301ŋə', 'ghɛnɔ\u0301', 'tuə', 'zo']),
//       _ParagraphBlank(correctWord: 'nkwi\u0301ə', choices: ['nkwi\u0301ə', 'ŋku\u0301', 'əfua\u0301', 'nto\u0302']),
//       _ParagraphBlank(correctWord: 'nyɛ\u0301', choices: ['nyɛ\u0301', 'la\u0301', 'zi\u0301', 'ko\u0301']),
//     ],
//   ),
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//   _QuizParagraph(
//     title: 'The Chief Speaks',
//     context: 'The village chief addresses the people.',
//     awingText: '{0} a tə la\u0301 nge\u0301ŋə. Po a tə {1}. A kə la\u0301 lɔ\u0301 {2}.',
//     englishText: 'The chief is saying something. They are listening. He said the truth.',
//     blanks: [
//       _ParagraphBlank(correctWord: 'Fwa\u0301', choices: ['Fwa\u0301', 'Ta\u0301ta', 'Ma\u030C', 'Mo\u0301onə']),
//       _ParagraphBlank(correctWord: 'yuə', choices: ['yuə', 'la\u0301', 'ghɛnɔ\u0301', 'tuə']),
//       _ParagraphBlank(correctWord: 'anuə.', choices: ['anuə.', 'nge\u0301ŋə.', 'ndo.', 'fɛ\u0301ə.']),
//     ],
//   ),

  // Quiz 5
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//   _QuizParagraph(
//     title: 'At the River',
//     context: 'Children play near the river.',
//     awingText: 'Po kə ghɛnɔ\u0301 a {0}. Po kə {1} nkwi\u0301ə. Mo\u0301onə a kə {2}.',
//     englishText: 'They went to the river. They washed in the water. The child laughed.',
//     blanks: [
//       _ParagraphBlank(correctWord: 'nki\u030Cə.', choices: ['nki\u030Cə.', 'nchi\u0301ə.', 'məteenɔ\u0301.', 'əshu\u0301ə.']),
//       _ParagraphBlank(correctWord: 'su\u0301ə', choices: ['su\u0301ə', 'tuə', 'ghɛnɔ\u0301', 'nonɔ\u0301']),
//       _ParagraphBlank(correctWord: 'we\u0301ə', choices: ['we\u0301ə', 'nonɔ\u0301', 'la\u0301', 'ghɛnɔ\u0301']),
//     ],
//   ),
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//   _QuizParagraph(
//     title: 'Morning Time',
//     context: 'The start of a new day.',
//     awingText: 'Nzuə a kə {0}. Mo\u0301onə a kə {1}. A kə ghɛnɔ\u0301 a {2}.',
//     englishText: 'The sun rose. The child woke up. He went to the farm.',
//     blanks: [
//       _ParagraphBlank(correctWord: 'fuə', choices: ['fuə', 'nonɔ\u0301', 'ghɛnɔ\u0301', 'yi\u030Cə']),
//       _ParagraphBlank(correctWord: 'pfe\u0301ə', choices: ['pfe\u0301ə', 'nonɔ\u0301', 'we\u0301ə', 'la\u0301']),
//       _ParagraphBlank(correctWord: 'ŋgə\u0301.', choices: ['ŋgə\u0301.', 'nchi\u0301ə.', 'əshu\u0301ə.', 'nki\u030Cə.']),
//     ],
//   ),

  // Quiz 6
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//   _QuizParagraph(
//     title: 'Saying Goodbye',
//     context: 'A visitor leaves a friend\'s house.',
//     awingText: '{0} nə pə zə wa\u030C lɛ\u0301ə. Wə {1} nde\u0300e. Cha\u0027tɔ\u0301 {2}!',
//     englishText: 'I will go now. Come back please. Goodbye!',
//     blanks: [
//       _ParagraphBlank(correctWord: 'Tifwə', choices: ['Tifwə', 'Ache', 'Nde\u0300e', 'Lɔ\u0301']),
//       _ParagraphBlank(correctWord: 'yi\u030Cə', choices: ['yi\u030Cə', 'ghɛnɔ\u0301', 'nonɔ\u0301', 'tuə']),
//       _ParagraphBlank(correctWord: 'nde\u0300e!', choices: ['nde\u0300e!', 'fɛ\u0301ə!', 'ko\u0301!', 'pə!']),
//     ],
//   ),
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//   _QuizParagraph(
//     title: 'The Pumpkin',
//     context: 'Describing a pumpkin in the garden.',
//     awingText: 'Lɛ\u030C {0}. A wə nə mə {1}. A kə {2} a ŋgə\u0301.',
//     englishText: 'This is a pumpkin. It is big. It grew on the farm.',
//     blanks: [
//       _ParagraphBlank(correctWord: 'nəpɔ\u0027ɔ\u0301.', choices: ['nəpɔ\u0027ɔ\u0301.', 'no\u0301olə.', 'ati\u030Cə.', 'nchi\u0301ə.']),
//       _ParagraphBlank(correctWord: 'ntɛ\u0301.', choices: ['ntɛ\u0301.', 'nde\u0300e.', 'fɛ\u0301ə.', 'ko\u0301.']),
//       _ParagraphBlank(correctWord: 'me\u0301ə', choices: ['me\u0301ə', 'ghɛnɔ\u0301', 'yi\u030Cə', 'tuə']),
//     ],
//   ),

  // Quiz 7
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//   _QuizParagraph(
//     title: 'A Friend Visits',
//     context: 'A friend arrives at your compound.',
//     awingText: "Cha'tɔ\u0301! Yə yi\u030Cə? Ee wə nə mə {0}. Ko pə {1}. Ache {2} ndo?",
//     englishText: 'Hello! How are you? It is well. Come sit down. What is that thing?',
//     blanks: [
//       _ParagraphBlank(correctWord: 'fɛ\u0301ə.', choices: ['fɛ\u0301ə.', 'nchi\u0301ə.', 'ko\u0301.', 'ŋgə\u0301.']),
//       _ParagraphBlank(correctWord: 'ase\u0301.', choices: ['ase\u0301.', 'apo\u0302.', 'nto\u0302.', 'yi\u030Cə.']),
//       _ParagraphBlank(correctWord: 'fɛ\u0301ə', choices: ['fɛ\u0301ə', 'ghɛnɔ\u0301', 'yi\u030Cə', 'nonɔ\u0301']),
//     ],
//   ),
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//   _QuizParagraph(
//     title: 'Learning Awing',
//     context: 'A student learns new Awing words.',
//     awingText: 'Ache fɛ\u0301ə ndo? Ee wə nə {0}. A {1}. A kə {2} nde\u0300e.',
//     englishText: 'What is this thing? It is a hand. A hand. He learned well.',
//     blanks: [
//       _ParagraphBlank(correctWord: 'apo\u0302.', choices: ['apo\u0302.', 'nto\u0302.', 'ati\u030Cə.', 'nchi\u0301ə.']),
//       _ParagraphBlank(correctWord: 'apo\u0302.', choices: ['apo\u0302.', 'əfua\u0301.', 'nde\u0300.', 'ŋku\u0301.']),
//       _ParagraphBlank(correctWord: 'zɛ\u0301', choices: ['zɛ\u0301', 'ghɛnɔ\u0301', 'tuə', 'ko\u0301']),
//     ],
//   ),

  // Quiz 8
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//   _QuizParagraph(
//     title: 'The Tree',
//     context: 'Children climbing a tree.',
//     awingText: 'Mba\u0301\u0027chi nə Apɛnə tə {0} ati\u030Cə. Ati\u030Cə wə nə mə {1}. Po a tə {2}.',
//     englishText: 'Mbachia and Apena are climbing a tree. The tree is tall. They are playing.',
//     blanks: [
//       _ParagraphBlank(correctWord: 'ko\u0301\u0027ə', choices: ['ko\u0301\u0027ə', 'ghɛnɔ\u0301', 'nonɔ\u0301', 'yi\u030Cə']),
//       _ParagraphBlank(correctWord: 'ta\u0301ŋə.', choices: ['ta\u0301ŋə.', 'nde\u0300e.', 'fɛ\u0301ə.', 'ntɛ\u0301.']),
//       _ParagraphBlank(correctWord: 'mbu\u0301ə', choices: ['mbu\u0301ə', 'ghɛnɔ\u0301', 'la\u0301', 'tuə']),
//     ],
//   ),
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//   _QuizParagraph(
//     title: 'Rain is Coming',
//     context: 'The weather changes before rain.',
//     awingText: 'Mbə\u0301ŋə a tə {0}. Nzuə a kə {1}. Po kə tso\u0301ŋə a {2}.',
//     englishText: 'The wind is blowing. The sun disappeared. They ran to the house.',
//     blanks: [
//       _ParagraphBlank(correctWord: 'fuə', choices: ['fuə', 'ghɛnɔ\u0301', 'nonɔ\u0301', 'la\u0301']),
//       _ParagraphBlank(correctWord: 'bɛ\u0301.', choices: ['bɛ\u0301.', 'yi\u030Cə.', 'fuə.', 'me\u0301ə.']),
//       _ParagraphBlank(correctWord: 'nchi\u0301ə.', choices: ['nchi\u0301ə.', 'ŋgə\u0301.', 'nki\u030Cə.', 'əshu\u0301ə.']),
//     ],
//   ),

  // Quiz 9
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//   _QuizParagraph(
//     title: 'The Farm',
//     context: 'Working on the farm.',
//     awingText: 'Ta\u0301ta a kə ghɛnɔ\u0301 a {0}. A kə {1} nəgoomɔ\u0301. A kə {2} əfua\u0301 nde\u0300e.',
//     englishText: 'Father went to the farm. He planted plantain. He harvested food well.',
//     blanks: [
//       _ParagraphBlank(correctWord: 'ŋgə\u0301.', choices: ['ŋgə\u0301.', 'nchi\u0301ə.', 'məteenɔ\u0301.', 'nki\u030Cə.']),
//       _ParagraphBlank(correctWord: 'tsə\u0301', choices: ['tsə\u0301', 'tuə', 'ghɛnɔ\u0301', 'nonɔ\u0301']),
//       _ParagraphBlank(correctWord: 'kwɛ\u0301', choices: ['kwɛ\u0301', 'la\u0301', 'zo', 'pə']),
//     ],
//   ),
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//   _QuizParagraph(
//     title: 'Animals',
//     context: 'Animals in the village.',
//     awingText: '{0} a tə a nchi\u0301ə. {1} a tə a ŋgə\u0301. {2} a kə la\u0301 nge\u0301ŋə.',
//     englishText: 'The dog is in the house. The chicken is on the farm. The bird sang.',
//     blanks: [
//       _ParagraphBlank(correctWord: 'Mbwa\u0301', choices: ['Mbwa\u0301', 'Ŋgu\u0301ə', 'Nso\u0301ŋə', 'No\u0301olə']),
//       _ParagraphBlank(correctWord: 'Ŋgu\u0301ə', choices: ['Ŋgu\u0301ə', 'Mbwa\u0301', 'No\u0301olə', 'Nso\u0301ŋə']),
//       _ParagraphBlank(correctWord: 'Nso\u0301ŋə', choices: ['Nso\u0301ŋə', 'No\u0301olə', 'Mbwa\u0301', 'Ŋgu\u0301ə']),
//     ],
//   ),

  // Quiz 10
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//   _QuizParagraph(
//     title: 'The Story',
//     context: 'An elder tells a story to children.',
//     awingText: 'Ntə\u0301 ŋwə a kə la\u0301 {0}. Mo\u0301onə po a tə {1}. A kə la\u0301 lɔ\u0301 {2}.',
//     englishText: 'An old person told a story. The children were listening. He told the truth.',
//     blanks: [
//       _ParagraphBlank(correctWord: 'nka\u0301mə.', choices: ['nka\u0301mə.', 'nge\u0301ŋə.', 'nchi\u0301ə.', 'fɛ\u0301ə.']),
//       _ParagraphBlank(correctWord: 'yuə.', choices: ['yuə.', 'ghɛnɔ\u0301.', 'la\u0301.', 'nonɔ\u0301.']),
//       _ParagraphBlank(correctWord: 'anuə.', choices: ['anuə.', 'ndo.', 'fɛ\u0301ə.', 'ko\u0301.']),
//     ],
//   ),
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//   _QuizParagraph(
//     title: 'Coming Home',
//     context: 'A family member returns after a long journey.',
//     awingText: 'A kə {0} nde\u0300e. Po kə {1} nə əso\u0301ŋə. Ma\u030C a kə {2} əfua\u0301.',
//     englishText: 'He came back well. They celebrated with joy. Mother prepared food.',
//     blanks: [
//       _ParagraphBlank(correctWord: 'yi\u030Cə', choices: ['yi\u030Cə', 'ghɛnɔ\u0301', 'nonɔ\u0301', 'tuə']),
//       _ParagraphBlank(correctWord: 'mbu\u0301ə', choices: ['mbu\u0301ə', 'tso\u0301ŋə', 'la\u0301', 'zo']),
//       _ParagraphBlank(correctWord: 'nya\u0301ŋə', choices: ['nya\u0301ŋə', 'tuə', 'ghɛnɔ\u0301', 'su\u0301ə']),
//     ],
//   ),

  // Quiz 11
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//   _QuizParagraph(
//     title: 'At the Church',
//     context: 'People go to church on Sunday.',
//     awingText: 'Po kə {0} a nchi\u0301ə Ntə\u0301. Ntə\u0301 ŋwə a kə {1} nka\u0301mə. A kə la\u0301 {2}.',
//     englishText: 'They went to the house of God. The elder told a story. He spoke the truth.',
//     blanks: [
//       _ParagraphBlank(correctWord: 'ghɛnɔ\u0301', choices: ['ghɛnɔ\u0301', 'nonɔ\u0301', 'tuə', 'kwa\u0301tə']),
//       _ParagraphBlank(correctWord: 'la\u0301', choices: ['la\u0301', 'ghɛnɔ\u0301', 'mbu\u0301ə', 'yi\u030Cə']),
//       _ParagraphBlank(correctWord: 'anuə.', choices: ['anuə.', 'fɛ\u0301ə.', 'ndo.', 'ko\u0301.']),
//     ],
//   ),
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//   _QuizParagraph(
//     title: 'Working the Farm',
//     context: 'Family members work together on the farm.',
//     awingText: 'Ta\u0301ta a kə {0} nəfa\u0301ŋə. Ma\u030C a tə {1} əfua\u0301. Po a tə {2} nde\u0300e.',
//     englishText: 'Father went to the farm. Mother is preparing food. They are working well.',
//     blanks: [
//       _ParagraphBlank(correctWord: 'ghɛnɔ\u0301', choices: ['ghɛnɔ\u0301', 'yi\u030Cə', 'la\u0301', 'zo']),
//       _ParagraphBlank(correctWord: 'nya\u0301ŋə', choices: ['nya\u0301ŋə', 'nonɔ\u0301', 'tuə', 'ghɛnɔ\u0301']),
//       _ParagraphBlank(correctWord: 'kwa\u0301tə', choices: ['kwa\u0301tə', 'mbu\u0301ə', 'yuə', 'pə']),
//     ],
//   ),

  // Quiz 12
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//   _QuizParagraph(
//     title: 'The Children Play',
//     context: 'Children run and play in the compound.',
//     awingText: 'Mo\u0301onə po a tə {0}. Po kə {1} nge\u0301ŋə. A tə {2} əso\u0301ŋə.',
//     englishText: 'The children are playing. They sang a song. There is joy.',
//     blanks: [
//       _ParagraphBlank(correctWord: 'yuə', choices: ['yuə', 'nonɔ\u0301', 'ghɛnɔ\u0301', 'kwa\u0301tə']),
//       _ParagraphBlank(correctWord: 'la\u0301', choices: ['la\u0301', 'ghɛnɔ\u0301', 'tuə', 'nya\u0301ŋə']),
//       _ParagraphBlank(correctWord: 'lɔ\u0301', choices: ['lɔ\u0301', 'pə', 'ko\u0301', 'zi\u0301']),
//     ],
//   ),
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//   _QuizParagraph(
//     title: 'Going to the Stream',
//     context: 'A child goes to fetch water from the stream.',
//     awingText: 'A kə ghɛnɔ\u0301 lə {0}. A kə {1} ŋku\u0301. A kə yi\u030Cə {2}.',
//     englishText: 'He went to the stream. He drew water. He came back.',
//     blanks: [
//       _ParagraphBlank(correctWord: 'nki\u0301ə', choices: ['nki\u0301ə', 'məteenɔ\u0301', 'nchi\u0301ə', 'nəfa\u0301ŋə']),
//       _ParagraphBlank(correctWord: 'tuə', choices: ['tuə', 'la\u0301', 'ghɛnɔ\u0301', 'nonɔ\u0301']),
//       _ParagraphBlank(correctWord: 'nde\u0300e', choices: ['nde\u0300e', 'lɔ\u0301', 'anuə', 'pə']),
//     ],
//   ),

  // Quiz 13
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//   _QuizParagraph(
//     title: 'The Evening Meal',
//     context: 'The family shares a meal in the evening.',
//     awingText: 'Ma\u030C a kə {0} əfua\u0301. Po kə {1} nə Ta\u0301ta. Əfua\u0301 a tə {2}.',
//     englishText: 'Mother prepared food. They ate with father. The food is good.',
//     blanks: [
//       _ParagraphBlank(correctWord: 'nya\u0301ŋə', choices: ['nya\u0301ŋə', 'ghɛnɔ\u0301', 'nonɔ\u0301', 'la\u0301']),
//       _ParagraphBlank(correctWord: 'yuə', choices: ['yuə', 'ghɛnɔ\u0301', 'mbu\u0301ə', 'tuə']),
//       _ParagraphBlank(correctWord: 'kwa\u0301tə', choices: ['kwa\u0301tə', 'pə', 'ndo', 'ko\u0301']),
//     ],
//   ),
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//   _QuizParagraph(
//     title: 'The Journey',
//     context: 'A traveler walks along the road.',
//     awingText: 'A kə {0} a akə\u0301. A kə {1} nə mo\u0301onə. Po kə {2} məteenɔ\u0301.',
//     englishText: 'He walked on the road. He traveled with a child. They reached the market.',
//     blanks: [
//       _ParagraphBlank(correctWord: 'ghɛnɔ\u0301', choices: ['ghɛnɔ\u0301', 'nonɔ\u0301', 'kwa\u0301tə', 'la\u0301']),
//       _ParagraphBlank(correctWord: 'tuə', choices: ['tuə', 'yuə', 'ghɛnɔ\u0301', 'la\u0301']),
//       _ParagraphBlank(correctWord: 'yi\u030Cə', choices: ['yi\u030Cə', 'nonɔ\u0301', 'su\u0301ə', 'pə']),
//     ],
//   ),

  // Quiz 14
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//   _QuizParagraph(
//     title: 'At the Palace',
//     context: 'People gather at the chief\u0027s palace.',
//     awingText: 'Fwa\u0301 a kə la\u0301 a {0}. Po kə yi\u030Cə nə {1}. A kə {2} po.',
//     englishText: 'The chief spoke at the palace. The people came with joy. He greeted them.',
//     blanks: [
//       _ParagraphBlank(correctWord: 'nchi\u0301ə', choices: ['nchi\u0301ə', 'nki\u0301ə', 'məteenɔ\u0301', 'akə\u0301']),
//       _ParagraphBlank(correctWord: 'əso\u0301ŋə', choices: ['əso\u0301ŋə', 'ŋku\u0301', 'anuə', 'əfua\u0301']),
//       _ParagraphBlank(correctWord: 'tso\u0301ŋə', choices: ['tso\u0301ŋə', 'la\u0301', 'ghɛnɔ\u0301', 'nonɔ\u0301']),
//     ],
//   ),
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//   _QuizParagraph(
//     title: 'The Visitor',
//     context: 'A guest arrives at the compound.',
//     awingText: 'Ntə\u0301 ŋwə a kə {0}. Ta\u0301ta a kə {1} ye. Po a tə yuə nə {2}.',
//     englishText: 'An old person came. Father greeted him. They are eating with joy.',
//     blanks: [
//       _ParagraphBlank(correctWord: 'yi\u030Cə', choices: ['yi\u030Cə', 'nonɔ\u0301', 'la\u0301', 'ghɛnɔ\u0301']),
//       _ParagraphBlank(correctWord: 'tso\u0301ŋə', choices: ['tso\u0301ŋə', 'tuə', 'ghɛnɔ\u0301', 'nonɔ\u0301']),
//       _ParagraphBlank(correctWord: 'əso\u0301ŋə', choices: ['əso\u0301ŋə', 'ŋku\u0301', 'nəpɔ\u0027ɔ\u0301', 'məteenɔ\u0301']),
//     ],
//   ),

  // Quiz 15
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//   _QuizParagraph(
//     title: 'The Morning',
//     context: 'Early morning in the village.',
//     awingText: 'Ma\u030C a kə {0} ti\u0301tə. A kə {1} Mo\u0301onə. Mo\u0301onə a tə {2}.',
//     englishText: 'Mother got up early. She woke the child. The child is eating.',
//     blanks: [
//       _ParagraphBlank(correctWord: 'yi\u030Cə', choices: ['yi\u030Cə', 'nonɔ\u0301', 'la\u0301', 'ghɛnɔ\u0301']),
//       _ParagraphBlank(correctWord: 'tuə', choices: ['tuə', 'ghɛnɔ\u0301', 'mbu\u0301ə', 'yuə']),
//       _ParagraphBlank(correctWord: 'yuə', choices: ['yuə', 'nonɔ\u0301', 'la\u0301', 'ghɛnɔ\u0301']),
//     ],
//   ),
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//   _QuizParagraph(
//     title: 'The Song at Night',
//     context: 'Singing around the fire at night.',
//     awingText: 'Po a tə {0} nge\u0301ŋə. Mo\u0301onə po a kə {1}. A tə {2} nde\u0300e.',
//     englishText: 'They are singing a song. The children listened. It is good.',
//     blanks: [
//       _ParagraphBlank(correctWord: 'la\u0301', choices: ['la\u0301', 'ghɛnɔ\u0301', 'nonɔ\u0301', 'yuə']),
//       _ParagraphBlank(correctWord: 'yuə', choices: ['yuə', 'ghɛnɔ\u0301', 'tuə', 'la\u0301']),
//       _ParagraphBlank(correctWord: 'lɔ\u0301', choices: ['lɔ\u0301', 'ko\u0301', 'pə', 'zi\u0301']),
//     ],
//   ),

  // Quiz 16
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//   _QuizParagraph(
//     title: 'The New Day',
//     context: 'Planning activities for the day.',
//     awingText: 'Ta\u0301ta a tə {0} məteenɔ\u0301. Ma\u030C a tə {1} nəfa\u0301ŋə. Po a tə {2} nde\u0300e.',
//     englishText: 'Father is going to the market. Mother is going to the farm. They are doing well.',
//     blanks: [
//       _ParagraphBlank(correctWord: 'ghɛnɔ\u0301', choices: ['ghɛnɔ\u0301', 'yi\u030Cə', 'nonɔ\u0301', 'la\u0301']),
//       _ParagraphBlank(correctWord: 'ghɛnɔ\u0301', choices: ['ghɛnɔ\u0301', 'la\u0301', 'yuə', 'tso\u0301ŋə']),
//       _ParagraphBlank(correctWord: 'kwa\u0301tə', choices: ['kwa\u0301tə', 'pə', 'zo', 'ndo']),
//     ],
//   ),
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//   _QuizParagraph(
//     title: 'Fetching Firewood',
//     context: 'Going to the forest for firewood.',
//     awingText: 'Mo\u0301onə a kə ghɛnɔ\u0301 a {0}. A kə {1} ati\u030Cə. A kə yi\u030Cə a {2}.',
//     englishText: 'The child went to the forest. He cut a tree. He came to the house.',
//     blanks: [
//       _ParagraphBlank(correctWord: 'nəfa\u0301ŋə', choices: ['nəfa\u0301ŋə', 'məteenɔ\u0301', 'nki\u0301ə', 'nchi\u0301ə']),
//       _ParagraphBlank(correctWord: 'tuə', choices: ['tuə', 'la\u0301', 'ghɛnɔ\u0301', 'nonɔ\u0301']),
//       _ParagraphBlank(correctWord: 'nchi\u0301ə', choices: ['nchi\u0301ə', 'akə\u0301', 'nki\u0301ə', 'məteenɔ\u0301']),
//     ],
//   ),

  // Quiz 17
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//   _QuizParagraph(
//     title: 'The Family Gathering',
//     context: 'Family members gather for a special day.',
//     awingText: 'Po kə {0} nə əso\u0301ŋə. Fwa\u0301 a kə la\u0301 {1}. Po a tə {2} nde\u0300e.',
//     englishText: 'They came with joy. The chief spoke the truth. They are happy well.',
//     blanks: [
//       _ParagraphBlank(correctWord: 'yi\u030Cə', choices: ['yi\u030Cə', 'ghɛnɔ\u0301', 'tuə', 'nonɔ\u0301']),
//       _ParagraphBlank(correctWord: 'anuə.', choices: ['anuə.', 'ko\u0301.', 'pə.', 'zi\u0301.']),
//       _ParagraphBlank(correctWord: 'nya\u0301ŋə', choices: ['nya\u0301ŋə', 'la\u0301', 'ghɛnɔ\u0301', 'tso\u0301ŋə']),
//     ],
//   ),
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//   _QuizParagraph(
//     title: 'The Travel Story',
//     context: 'An elder tells about a journey.',
//     awingText: 'Ntə\u0301 ŋwə a kə {0} a nka\u0301mə. A kə {1} nde\u0300e. Mo\u0301onə po a tə {2}.',
//     englishText: 'An old person told a story. He told it well. The children are listening.',
//     blanks: [
//       _ParagraphBlank(correctWord: 'la\u0301', choices: ['la\u0301', 'ghɛnɔ\u0301', 'tuə', 'yuə']),
//       _ParagraphBlank(correctWord: 'la\u0301', choices: ['la\u0301', 'ghɛnɔ\u0301', 'mbu\u0301ə', 'yi\u030Cə']),
//       _ParagraphBlank(correctWord: 'yuə', choices: ['yuə', 'nonɔ\u0301', 'ghɛnɔ\u0301', 'la\u0301']),
//     ],
//   ),

  // Quiz 18
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//   _QuizParagraph(
//     title: 'The Garden',
//     context: 'Planting vegetables in the garden.',
//     awingText: 'Ma\u030C a kə ghɛnɔ\u0301 a {0}. A kə {1} əfua\u0301. A kə yi\u030Cə {2}.',
//     englishText: 'Mother went to the farm. She planted food. She came home.',
//     blanks: [
//       _ParagraphBlank(correctWord: 'nəfa\u0301ŋə', choices: ['nəfa\u0301ŋə', 'məteenɔ\u0301', 'nki\u0301ə', 'nchi\u0301ə']),
//       _ParagraphBlank(correctWord: 'tuə', choices: ['tuə', 'la\u0301', 'ghɛnɔ\u0301', 'nya\u0301ŋə']),
//       _ParagraphBlank(correctWord: 'nde\u0300e', choices: ['nde\u0300e', 'lɔ\u0301', 'anuə', 'pə']),
//     ],
//   ),
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//   _QuizParagraph(
//     title: 'The Chickens',
//     context: 'Feeding the chickens in the morning.',
//     awingText: '{0} a tə a nchi\u0301ə. Mo\u0301onə a kə {1} nsoŋə. A tə {2} nde\u0300e.',
//     englishText: 'The chicken is at the house. The child gave them food. They are well.',
//     blanks: [
//       _ParagraphBlank(correctWord: 'Ŋgu\u0301ə', choices: ['Ŋgu\u0301ə', 'Mbwa\u0301', 'No\u0301olə', 'Nso\u0301ŋə']),
//       _ParagraphBlank(correctWord: 'tso\u0301ŋə', choices: ['tso\u0301ŋə', 'nonɔ\u0301', 'la\u0301', 'ghɛnɔ\u0301']),
//       _ParagraphBlank(correctWord: 'kwa\u0301tə', choices: ['kwa\u0301tə', 'pə', 'ndo', 'zi\u0301']),
//     ],
//   ),

  // Quiz 19
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//   _QuizParagraph(
//     title: 'Returning Home',
//     context: 'Family members come back from the market.',
//     awingText: 'Ta\u0301ta a kə {0} məteenɔ\u0301. A kə {1} nəpɔ\u0027ɔ\u0301. Ma\u030C a tə {2} əfua\u0301.',
//     englishText: 'Father went to the market. He bought a pumpkin. Mother is preparing food.',
//     blanks: [
//       _ParagraphBlank(correctWord: 'ghɛnɔ\u0301', choices: ['ghɛnɔ\u0301', 'yi\u030Cə', 'la\u0301', 'nonɔ\u0301']),
//       _ParagraphBlank(correctWord: 'tuə', choices: ['tuə', 'yuə', 'ghɛnɔ\u0301', 'la\u0301']),
//       _ParagraphBlank(correctWord: 'nya\u0301ŋə', choices: ['nya\u0301ŋə', 'yuə', 'ghɛnɔ\u0301', 'tso\u0301ŋə']),
//     ],
//   ),
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//   _QuizParagraph(
//     title: 'The Elder\u0027s Wisdom',
//     context: 'An elder shares wisdom with children.',
//     awingText: 'Ntə\u0301 ŋwə a kə la\u0301 {0}. A kə {1} mo\u0301onə. Po kə {2} nde\u0300e.',
//     englishText: 'The elder told the truth. He taught the children. They listened well.',
//     blanks: [
//       _ParagraphBlank(correctWord: 'anuə.', choices: ['anuə.', 'ko\u0301.', 'fɛ\u0301ə.', 'pə.']),
//       _ParagraphBlank(correctWord: 'la\u0301', choices: ['la\u0301', 'ghɛnɔ\u0301', 'tso\u0301ŋə', 'tuə']),
//       _ParagraphBlank(correctWord: 'yuə', choices: ['yuə', 'ghɛnɔ\u0301', 'nonɔ\u0301', 'la\u0301']),
//     ],
//   ),

  // Quiz 20
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//   _QuizParagraph(
//     title: 'The Moon at Night',
//     context: 'Children admire the moon together.',
//     awingText: 'Mo\u0301onə po a kə {0} Su\u0301ə. Su\u0301ə a tə {1}. Po a tə la\u0301 nə {2}.',
//     englishText: 'The children saw the moon. The moon is bright. They are speaking with joy.',
//     blanks: [
//       _ParagraphBlank(correctWord: 'zi\u0301', choices: ['zi\u0301', 'ghɛnɔ\u0301', 'nonɔ\u0301', 'la\u0301']),
//       _ParagraphBlank(correctWord: 'kwa\u0301tə', choices: ['kwa\u0301tə', 'pə', 'ko\u0301', 'ndo']),
//       _ParagraphBlank(correctWord: 'əso\u0301ŋə', choices: ['əso\u0301ŋə', 'ŋku\u0301', 'anuə', 'məteenɔ\u0301']),
//     ],
//   ),
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//   _QuizParagraph(
//     title: 'Greeting the Morning',
//     context: 'Saying hello at sunrise.',
//     awingText: "Cha'tɔ\u0301! A tə {0}. Mo\u0301onə a kə {1} Ma\u030C. Ma\u030C a tə {2} ye.",
//     englishText: 'Good morning! It is good. The child saw mother. Mother is greeting him.',
//     blanks: [
//       _ParagraphBlank(correctWord: 'kwa\u0301tə', choices: ['kwa\u0301tə', 'pə', 'ghɛnɔ\u0301', 'ndo']),
//       _ParagraphBlank(correctWord: 'zi\u0301', choices: ['zi\u0301', 'nonɔ\u0301', 'la\u0301', 'ghɛnɔ\u0301']),
//       _ParagraphBlank(correctWord: 'tso\u0301ŋə', choices: ['tso\u0301ŋə', 'yi\u030Cə', 'tuə', 'nya\u0301ŋə']),
//     ],
//   ),


  // Auto-extracted from Bible NT (non-biblical-feeling)
  // 1CO.1.15-19
  _QuizParagraph(
    title: 'Practice 1',
    context: 'so that no one should say that I had baptized you into my own name. (I also bapt…',
    awingText: 'ńjî ńgə́ kɔ ŋwu tsə̌ á mə́m pəənə́ á sóŋ ńgə́ yə́ nə ńkwá nkǐ nə́ əlɛ́nə mə. (Maŋ nə ńkə́ ə́fɛ̂ nkǐ nə́ ngwud Stefanasə, tə ńdéʼtə ə́lɨ́d maŋ kě pɨ ńkwúmtə ńgə́ maŋ nə ńdáʼ ə́fɛ̂ nkǐ nə́ ŋwu əwɨ yitsə̌ pô). ə́sɛdkə̂ ajíənuə ngaŋə́ŋwaʼlə a pə́ ənukə́taŋə.”',
    englishText: 'so that no one should say that I had baptized you into my own name. (I also baptized the household of Stephanas; besides them, I don’t know whether I baptized any other.) For it is written,\n“I will destroy the wisdom of the wise,\nI will bring the discernment of the discerning to nothing.”',
    blanks: [
      _ParagraphBlank(correctWord: 'ńgə́', choices: ['mooto', 'əlelo', 'ńgə́', 'tɔŋ']),
      _ParagraphBlank(correctWord: 'á', choices: ['á', 'məkwɛ', 'ngɛdtəpɔŋə', 'ngaŋtsabpe']),
      _ParagraphBlank(correctWord: 'pəənə́', choices: ['“məji', 'pəənə́', 'fɔnə', 'nyegnə']),
    ],
  ),
  // 1CO.1.16-22
  _QuizParagraph(
    title: 'Practice 2',
    context: '(I also baptized the household of Stephanas; besides them, I don’t know whether …',
    awingText: '(Maŋ {0} ńkə́ ə́fɛ̂ nkǐ nə́ ngwud Stefanasə, {1} ńdéʼtə ə́lɨ́d maŋ kě pɨ ńkwúmtə ńgə́ maŋ nə ńdáʼ ə́fɛ̂ nkǐ nə́ ŋwu əwɨ yitsə̌ pô). ə́sɛdkə̂ ajíənuə ngaŋə́ŋwaʼlə a pə́ ənukə́taŋə.” Pəjus pó náŋə lə́ əkyeʼmə́nuə, Pəglik pó pə́ ńnáŋə lə́ ayáŋə.',
    englishText: '(I also baptized the household of Stephanas; besides them, I don’t know whether I baptized any other.) For it is written,\n“I will destroy the wisdom of the wise,\nI will bring the discernment of the discerning to nothing.” For Jews ask for signs, Greeks seek after wisdom,',
    blanks: [
      _ParagraphBlank(correctWord: 'nə', choices: ['tä pətä pətä', 'nə', 'nəpəənə', 'anəma']),
      _ParagraphBlank(correctWord: 'tə', choices: ['to\'kə nkadtə', 'kəʼlə', 'ape\'ə', 'tə']),
      _ParagraphBlank(correctWord: 'kě', choices: ['kě', 'apimnə', 'ndəse təpəŋə', 'ntoŋə']),
    ],
  ),
  // 1PE.3.10-13
  _QuizParagraph(
    title: 'Practice 3',
    context: 'For,\n“He who would love life,\nand see good days,\nlet him keep his tongue from ev…',
    awingText: '“Ŋwu ntsəm páʼ {0} lɔ nə́ á mə́ chî nə́ nchîmbî yi əshîʼnə Pó chîə á mə́ shib nə́ ə́fɛ́lə á {2}m təpɔŋ ə́ tə́ faʼ əshîʼnə; Lə́ əwə mbɔʼ á límkə áwɨ́ páʼ təmbɔʼ nə́ tə́gə atûə á mə́ faʼ nə́ anu yə əshîʼnə?',
    englishText: 'For,\n“He who would love life,\nand see good days,\nlet him keep his tongue from evil,\nand his lips from speaking deceit. Let him turn away from evil, and do good.\nLet him seek peace, and pursue it. Now who is he who will harm you, if you become imitators of that which is good?',
    blanks: [
      _ParagraphBlank(correctWord: 'a', choices: ['a', 'pega', 'nəpab no əshuə', 'fid nəlwiə']),
      _ParagraphBlank(correctWord: 'nə́', choices: ['ŋkəə', 'ale atsəmə', 'nnaakə', 'nə́']),
      _ParagraphBlank(correctWord: 'mə́', choices: ['za\'ə', 'səg', 'əfunə', 'mə́']),
    ],
  ),
  // 1TH.5.16-21
  _QuizParagraph(
    title: 'Practice 4',
    context: 'Rejoice always. Don’t despise prophesies. Test all things, and hold firmly that …',
    awingText: 'Tə́ nə́ ńkɔŋtə̂ əghâ ətsəmə, Kɔ sóŋ ńgə́ nkɨ Əsê páʼ ntûsê a náŋkə nə́ lə́ ənukə́taŋə. Jwə́ʼ nə́ mənu mətsəm mə́ yǐ nə́ á mbô pəənə́, mimə́ pɔŋ nə́ pɨ wam ńtyantə̂.',
    englishText: 'Rejoice always. Don’t despise prophesies. Test all things, and hold firmly that which is good.',
    blanks: [
      _ParagraphBlank(correctWord: 'Tə́', choices: ['Tə́', 'ləgnə', 'əshwaŋə', 'əfɔnə']),
      _ParagraphBlank(correctWord: 'nə́', choices: ['ale məteenə', 'nə́', 'əsɛd', 'sogə akwubə']),
      _ParagraphBlank(correctWord: 'ńkɔŋtə̂', choices: ['ijibə', 'ŋgɔɔmə', 'ńkɔŋtə̂', 'awaaməmbɨ']),
    ],
  ),
  // 1TH.5.20-22
  _QuizParagraph(
    title: 'Practice 5',
    context: 'Don’t despise prophesies. Test all things, and hold firmly that which is good. A…',
    awingText: 'Kɔ sóŋ ńgə́ {1} Əsê páʼ ntûsê a náŋkə nə́ lə́ ənukə́taŋə. Jwə́ʼ nə́ mənu mətsəm mə́ yǐ nə́ á mbô pəənə́, mimə́ pɔŋ nə́ pɨ wam ńtyantə̂. Lə́ʼ nə́ ndzaŋ təpɔŋ ntsəmə.',
    englishText: 'Don’t despise prophesies. Test all things, and hold firmly that which is good. Abstain from every form of evil.',
    blanks: [
      _ParagraphBlank(correctWord: 'ńgə́', choices: ['əzoonə', 'lednə', 'ńgə́', 'ngɔ\'ə']),
      _ParagraphBlank(correctWord: 'nkɨ', choices: ['soŋə ndəse', 'no ndəpa\'ə', 'kwublə', 'nkɨ']),
      _ParagraphBlank(correctWord: 'Əsê', choices: ['feŋkə', 'Əsê', 'əfagə atiə', 'nkyeetə']),
    ],
  ),
  // 1TH.5.21-24
  _QuizParagraph(
    title: 'Practice 6',
    context: 'Test all things, and hold firmly that which is good. Abstain from every form of …',
    awingText: 'Jwə́ʼ nə́ mənu mətsəm mə́ yǐ nə́ á mbô pəənə́, mimə́ pɔŋ nə́ pɨ wam ńtyantə̂. Lə́ʼ nə́ ndzaŋ təpɔŋ ntsəmə. Yí páʼ ä fóŋ nə́ {2}wɨ́ lə́ a yǐ faʼə̂ zɨ́d zə̂, ńté ńgə́ lə́ ŋwu páʼ mbɔʼ á sóŋ ńgə́ a yǐ faʼə̂ anu á faʼə̂ zə́ələ́.',
    englishText: 'Test all things, and hold firmly that which is good. Abstain from every form of evil. He who calls you is faithful, who will also do it.',
    blanks: [
      _ParagraphBlank(correctWord: 'nə́', choices: ['nəkwinə', 'nə́', 'moonə', 'ŋa\' nkwumə']),
      _ParagraphBlank(correctWord: 'mə́', choices: ['chuʼ', 'chwi\'tə', 'mə́', 'kwu\'kə']),
      _ParagraphBlank(correctWord: 'á', choices: ['anjwa', 'ali\' gheno', 'á', 'neemə']),
    ],
  ),
  // 1TH.5.22-26
  _QuizParagraph(
    title: 'Practice 7',
    context: 'Abstain from every form of evil. He who calls you is faithful, who will also do …',
    awingText: '{0} nə́ ndzaŋ təpɔŋ {2}. Yí páʼ ä fóŋ nə́ áwɨ́ lə́ a yǐ faʼə̂ zɨ́d zə̂, ńté ńgə́ lə́ ŋwu páʼ mbɔʼ á sóŋ ńgə́ a yǐ faʼə̂ anu á faʼə̂ zə́ələ́. Chaʼtə̂ nə́ pəlim pɨ́ pətsəmə á mə́m Yesö, ńchwegə̂ ághɔ́b nə́ ndu páʼ ə́ ŋwaʼ nə́.',
    englishText: 'Abstain from every form of evil. He who calls you is faithful, who will also do it. Greet all the brothers with a holy kiss.',
    blanks: [
      _ParagraphBlank(correctWord: 'Lə́ʼ', choices: ['Lə́ʼ', 'əkəəbə', 'alwaalə', '“shiəə']),
      _ParagraphBlank(correctWord: 'nə́', choices: ['nə́', 'gleb', 'ŋŋaʼə', 'nkaŋki']),
      _ParagraphBlank(correctWord: 'ntsəmə', choices: ['ntsəmə', 'ntɨmmaə', 'ko\'kə', 'ndim']),
    ],
  ),
  // 1TI.5.1-3
  _QuizParagraph(
    title: 'Practice 8',
    context: 'Don’t rebuke an older man, but exhort him as a father; the younger men as brothe…',
    awingText: 'Kɔ {0} sáʼə ntəŋkaŋə́, {1} mbô yə́ ándó tǎ əgho. Túg nkaŋŋwu yi mbyâŋnə ándó pəlim pô, ńtúg pətəkaŋ pə́ pəngyě ándó pəmǎ pô, ńkə́ ńtúg nkaŋŋwu pəngyě ándó pəlim pô pipə́ pəngyě tə kɔntə yitsə̌. Pəkogə́ ándó pó pə́ nə́ chigə pəkog gho nɨd ngóʼkə nə́ pó.',
    englishText: 'Don’t rebuke an older man, but exhort him as a father; the younger men as brothers; the elder women as mothers; the younger as sisters, in all purity. Honor widows who are widows indeed.',
    blanks: [
      _ParagraphBlank(correctWord: 'gho', choices: ['nəpeenə', 'log ngiə', 'aləŋə', 'gho']),
      _ParagraphBlank(correctWord: 'tséebə', choices: ['jekɔb', 'əlen təpəŋə', 'chwitə ngonə', 'tséebə']),
      _ParagraphBlank(correctWord: 'mbô', choices: ['fəələ', 'asəələ', 'mbô', 'soŋ nkəla']),
    ],
  ),
  // 1TI.5.3-7
  _QuizParagraph(
    title: 'Practice 9',
    context: 'Honor widows who are widows indeed. But she who gives herself to pleasure is dea…',
    awingText: 'Pəkogə́ ándó pó pə́ nə́ chigə pəkog gho nɨd ngóʼkə nə́ pó. Lə́ nkog páʼ a fɛ̂ nə́ mbɨ əjǐ nə́ əpú mbî a pɛ́dtə ńkwûə, páʼə a pə́ nə́ mbǎtə ḿbɛ́lə mbî lə́. Fɛ̂ ntəgə́ zəənə́ á mbô po ńjî ńgə́ kɔ ŋwu əghɔb yitsə̌ á yi ńtúgə filə.',
    englishText: 'Honor widows who are widows indeed. But she who gives herself to pleasure is dead while she lives. Also command these things, that they may be without reproach.',
    blanks: [
      _ParagraphBlank(correctWord: 'ándó', choices: ['mətsa', 'əfeŋ fiə apo', 'ale', 'ándó']),
      _ParagraphBlank(correctWord: 'pó', choices: ['akwəŋo', 'əfi məjiə', 'ntu əse', 'pó']),
      _ParagraphBlank(correctWord: 'pə́', choices: ['chwi\'nə', 'nələŋ no kɔ\'ə aŋkandə', 'panapəələ', 'pə́']),
    ],
  ),
  // ACT.2.8-13
  _QuizParagraph(
    title: 'Practice 10',
    context: 'How do we hear, everyone in our own native language? They were all amazed, and w…',
    awingText: 'Lə́ pə́ ńtíʼ ńgɛlə̂ akə̂ pɛn pətsəm zóʼ ndzaŋ pó tsáb nə́ nə́ ətsáb əláʼ əpɛ́nə? A kɨʼnə̂ ághɔ́b tə́ pó jwaʼlə̂ ńtíʼə ḿbítə məmbɨ mɔ́b ńgə́, “Ndɛn mənu ghɛn ə́ sóŋə lɛ̌ ńgə́ akə̂?” Lə́ pətsə́ pɨ pə́ pə́ ńnyegnə̂ ághɔ́b ə́sóŋə ńgə́, “Pɨ pɨ pə́ pɛ́ lə́ məloʼə!”',
    englishText: 'How do we hear, everyone in our own native language? They were all amazed, and were perplexed, saying to one another, “What does this mean?” Others, mocking, said, “They are filled with new wine.”',
    blanks: [
      _ParagraphBlank(correctWord: 'Lə́', choices: ['me', 'asəgəndzɔʼə', 'əghaa', 'Lə́']),
      _ParagraphBlank(correctWord: 'pə́', choices: ['chwaakə nkyeetə', 'talətaalə', 'dote', 'pə́']),
      _ParagraphBlank(correctWord: 'pó', choices: ['alaŋo maŋgo\'ə', 'ti\'ə', 'ŋgwanə', 'pó']),
    ],
  ),
  // ACT.2.13-19
  _QuizParagraph(
    title: 'Practice 11',
    context: 'Others, mocking, said, “They are filled with new wine.” For these aren’t drunken…',
    awingText: 'Lə́ pətsə́ pɨ pə́ pə́ ńnyegnə̂ ághɔ́b {2} ńgə́, “Pɨ pɨ pə́ pɛ́ lə́ məloʼə!” Pɨ pɨ pə́ kě məloʼ pɛ́ ndzaŋ nə́ kwaŋ nə́ lə̂ pô. Lɛ̌ tsɔʼə pəmə́nu pɛ́n nəpuʼə́ á məsânə. Maŋ yǒ nɨd mənu mə́ yɛ́d nə́ yɛ́d nə́ á nəpóolə atǐə',
    englishText: 'Others, mocking, said, “They are filled with new wine.” For these aren’t drunken, as you suppose, seeing it is only the third hour of the day. I will show wonders in the sky above,\nand signs on the earth beneath;\nblood, and fire, and billows of smoke.',
    blanks: [
      _ParagraphBlank(correctWord: 'Lə́', choices: ['nəsoŋə', 'əghəənə', 'Lə́', 'apitə atseebə']),
      _ParagraphBlank(correctWord: 'pə́', choices: ['kyika', 'pə́', 'ali\'ofya\'onuə', 'plisila']),
      _ParagraphBlank(correctWord: 'ə́sóŋə', choices: ['alaŋo maŋgo\'ə', 'ndzəəmə', 'ngwumnə', 'ə́sóŋə']),
    ],
  ),
  // ACT.2.15-26
  _QuizParagraph(
    title: 'Practice 12',
    context: 'For these aren’t drunken, as you suppose, seeing it is only the third hour of th…',
    awingText: 'Pɨ pɨ pə́ kě {2} pɛ́ ndzaŋ nə́ kwaŋ nə́ lə̂ pô. Lɛ̌ tsɔʼə pəmə́nu pɛ́n nəpuʼə́ á məsânə. Maŋ yǒ nɨd mənu mə́ yɛ́d nə́ yɛ́d nə́ á nəpóolə atǐə Ńdaŋ ə́lɨ́d ntə́əmə mə ə́ chî nə́ akɔŋtə, atséebə ntsoolə mə a ləəmə̂,',
    englishText: 'For these aren’t drunken, as you suppose, seeing it is only the third hour of the day. I will show wonders in the sky above,\nand signs on the earth beneath;\nblood, and fire, and billows of smoke. Therefore my heart was glad, and my tongue rejoiced.\nMoreover my flesh also will dwell in hope;',
    blanks: [
      _ParagraphBlank(correctWord: 'pə́', choices: ['pə́', 'fagtə', 'sidɔn', 'məfenə']),
      _ParagraphBlank(correctWord: 'kě', choices: ['ntsəb pe', 'kě', '“əgha', 'əkiə']),
      _ParagraphBlank(correctWord: 'məloʼ', choices: ['ala\'ə pəŋwiŋə', 'ze\'ka', 'məloʼ', 'tɨə']),
    ],
  ),
  // ACT.2.19-27
  _QuizParagraph(
    title: 'Practice 13',
    context: 'I will show wonders in the sky above,\nand signs on the earth beneath;\nblood, and…',
    awingText: 'Maŋ yǒ nɨd mənu mə́ {2} nə́ yɛ́d nə́ á nəpóolə atǐə Ńdaŋ ə́lɨ́d ntə́əmə mə ə́ chî nə́ akɔŋtə, atséebə ntsoolə mə a ləəmə̂, ńté ńgə́ gho yǒ kě mə á {1}m mbî pəkwû ghɔ́ŋkə pô;',
    englishText: 'I will show wonders in the sky above,\nand signs on the earth beneath;\nblood, and fire, and billows of smoke. Therefore my heart was glad, and my tongue rejoiced.\nMoreover my flesh also will dwell in hope; because you will not leave my soul in Hades,\nneither will you allow your Holy One to see decay.',
    blanks: [
      _ParagraphBlank(correctWord: 'yǒ', choices: ['nkoŋ', 'yǒ', 'jumnə', 'asəələkwuneemə']),
      _ParagraphBlank(correctWord: 'mə́', choices: ['mə́', 'afɔbla', 'ndəmə', 'sala']),
      _ParagraphBlank(correctWord: 'yɛ́d', choices: ['po\'nə', 'mɔŋkə', 'yɛ́d', 'mbi təŋkə\'ə']),
    ],
  ),
  // ACT.2.26-28
  _QuizParagraph(
    title: 'Practice 14',
    context: 'Therefore my heart was glad, and my tongue rejoiced.\nMoreover my flesh also will…',
    awingText: 'Ńdaŋ {1}lɨ́d ntə́əmə {0} ə́ chî nə́ akɔŋtə, atséebə ntsoolə mə a ləəmə̂, ńté ńgə́ gho yǒ kě mə á mə́m mbî pəkwû ghɔ́ŋkə pô; Gho nəələ̂ mə nə́ məsémə́ndú páʼ mə̈ fɛ̂ nə́ nchîmbîə,',
    englishText: 'Therefore my heart was glad, and my tongue rejoiced.\nMoreover my flesh also will dwell in hope; because you will not leave my soul in Hades,\nneither will you allow your Holy One to see decay. You made known to me the ways of life.\nYou will make me full of gladness with your presence.’',
    blanks: [
      _ParagraphBlank(correctWord: 'mə', choices: ['ndzaŋə a laŋ na', 'mə', 'alublə', 'tsonkə']),
      _ParagraphBlank(correctWord: 'ə́', choices: ['ə́', 'koshamə', 'atumə məyeŋa', 'nkəm']),
      _ParagraphBlank(correctWord: 'nə́', choices: ['nənyaglə', 'nə́', 'pətɔŋ', 'kwed ndotia']),
    ],
  ),
  // ACT.2.27-35
  _QuizParagraph(
    title: 'Practice 15',
    context: 'because you will not leave my soul in Hades,\nneither will you allow your Holy On…',
    awingText: 'ńté ńgə́ {1} yǒ kě mə á mə́m mbî pəkwû ghɔ́ŋkə pô; Gho nəələ̂ mə nə́ məsémə́ndú páʼ mə̈ fɛ̂ nə́ nchîmbîə, tə maŋ láʼ ńgɛd ngaŋkə́pa əzô ə́ tíʼ ḿbə́ pə́ ajúmə tə́gtə məkoolə azô.',
    englishText: 'because you will not leave my soul in Hades,\nneither will you allow your Holy One to see decay. You made known to me the ways of life.\nYou will make me full of gladness with your presence.’ until I make your enemies a footstool for your feet.”’',
    blanks: [
      _ParagraphBlank(correctWord: 'ńgə́', choices: ['tabita', 'ńgə́', 'kəʼlə', 'mɔmɛ']),
      _ParagraphBlank(correctWord: 'gho', choices: ['achaʼtə', 'chɔsə mbəlalo\'ə', 'gho', 'nəkeelə']),
      _ParagraphBlank(correctWord: 'yǒ', choices: ['yǒ', 'galiliə', 'paŋ sɔnte', 'ndedta']),
    ],
  ),
  // ACT.7.28-50
  _QuizParagraph(
    title: 'Practice 16',
    context: 'Do you want to kill me, as you killed the Egyptian yesterday?’ But Solomon built…',
    awingText: '{0} kə́ ńdoonə̂ lə́ á mə́ jwítə nə́ mə ndzaŋ páʼ gho nə ńjwítə nə́ ŋwu Ijib wə̂ á əzoonə́ lə̂? Lə́ ndɛ̂ yi wɨ́ lə́ nə ńtíʼ ḿbɔ́ Solomun ə́fɛ̂ nə́ yə́. Əpú pɨ ətsəm lə́ nə ńkě maŋ nə́ mbô mə tsoŋkə̂?',
    englishText: 'Do you want to kill me, as you killed the Egyptian yesterday?’ But Solomon built him a house. Didn’t my hand make all these things?’',
    blanks: [
      _ParagraphBlank(correctWord: 'Gho', choices: ['ako\'nə nkeelə', 'Gho', 'məkeemə', 'əteelə']),
      _ParagraphBlank(correctWord: 'kə́', choices: ['chantə', 'kə́', 'alednə', 'ndaəshə']),
      _ParagraphBlank(correctWord: 'ńdoonə̂', choices: ['nde melo\'ə', 'ńdoonə̂', 'nkog', '“gho']),
    ],
  ),
  // ACT.7.47-54
  _QuizParagraph(
    title: 'Practice 17',
    context: 'But Solomon built him a house. Didn’t my hand make all these things?’ Now when t…',
    awingText: 'Lə́ ndɛ̂ yi wɨ́ lə́ {2} ńtíʼ ḿbɔ́ Solomun ə́fɛ̂ nə́ yə́. Əpú pɨ ətsəm lə́ nə ńkě maŋ nə́ mbô mə tsoŋkə̂? Ndzaŋ ngaŋə́sáʼə́məsáʼ ə́ nə ńdzóʼ nə́ anu páʼ Stifənə a nə sóŋ nə́ lə́, məndě mɔ́b mə́ záŋ lɛ̌ tətə pó kɔ́d məsɔŋ mɔ́b ńté yə́.',
    englishText: 'But Solomon built him a house. Didn’t my hand make all these things?’ Now when they heard these things, they were cut to the heart, and they gnashed at him with their teeth.',
    blanks: [
      _ParagraphBlank(correctWord: 'Lə́', choices: ['Lə́', 'ngonə', '“aŋkəʼə', 'akwaŋonuə']),
      _ParagraphBlank(correctWord: 'ndɛ̂', choices: ['akəfə', 'ŋwu\'kə', 'ndɛ̂', 'əfooghəəmə']),
      _ParagraphBlank(correctWord: 'nə', choices: ['atseebase', 'tegnə', 'əkaŋ', 'nə']),
    ],
  ),
  // ACT.16.2-11
  _QuizParagraph(
    title: 'Practice 18',
    context: 'The brothers who were at Lystra and Iconium gave a good testimony about him. Pas…',
    awingText: '{0} pətsəmə á mə́m {2} pó Ikonum tsáb əshîʼnə ńté Timoti. Pó tíʼ ńgɛn nə́ mbi ńdaŋə̂ á mə́m Mysya ńtsó ńgɛnə̂ aláʼ Təlowasə. Pəg məgtə̂ Təlowas ńnyinə̂ á mə́m nkǐ ńgɛn ndə̌ŋdəŋ á Samodlasə, mbî fóg pəg ghɛnə̂ a Nyapolisə.',
    englishText: 'The brothers who were at Lystra and Iconium gave a good testimony about him. Passing by Mysia, they came down to Troas. Setting sail therefore from Troas, we made a straight course to Samothrace, and the day following to Neapolis;',
    blanks: [
      _ParagraphBlank(correctWord: 'Pəlim', choices: ['lamosə', 'fuəloʼ', 'achina', 'Pəlim']),
      _ParagraphBlank(correctWord: 'á', choices: ['əfooghaəma', 'pəzeʼkə', 'nkog ŋwu mbyaŋnə', 'á']),
      _ParagraphBlank(correctWord: 'Listəla', choices: ['fablo', 'Listəla', 'nənta', 'po\'əpa\'ə']),
    ],
  ),
  // COL.3.14-21
  _QuizParagraph(
    title: 'Practice 19',
    context: 'Above all these things, walk in love, which is the bond of perfection. Husbands,…',
    awingText: 'Á {2}m mənu mɨ mətsəm nə́ chîə á mə́ wê nə́ akɔŋnə páʼ á tsɛntə̂ nə́ ajúmə atsəmə a tíʼ ḿbə́ táʼə Pəlú, kɔŋ nə́ pəngyě pə́ənə́, kɔ nə́ tə́ ńtsə́gə ághóobə́. Pətǎ, kɔ nə́ tə́ ńjwaʼə̂ pɔ́ pə́ənə́, zə́ələ́ á yǐ ghɛd mbɨ əzɔb ə́ tə ḿbə́gə.',
    englishText: 'Above all these things, walk in love, which is the bond of perfection. Husbands, love your wives, and don’t be bitter against them. Fathers, don’t provoke your children, so that they won’t be discouraged.',
    blanks: [
      _ParagraphBlank(correctWord: 'Á', choices: ['apeŋ', 'Á', 'neebo', 'əpa']),
      _ParagraphBlank(correctWord: 'nə́', choices: ['ko əsoənə', 'ndo', 'aju yə pa\' nə', 'nə́']),
      _ParagraphBlank(correctWord: 'mə́', choices: ['pwonə', 'əfi ndase', 'mə́', 'nkadtə']),
    ],
  ),
  // COL.3.19-25
  _QuizParagraph(
    title: 'Practice 20',
    context: 'Husbands, love your wives, and don’t be bitter against them. Fathers, don’t prov…',
    awingText: 'Pəlú, kɔŋ nə́ pəngyě pə́ənə́, kɔ nə́ tə́ ńtsə́gə ághóobə́. Pətǎ, kɔ nə́ tə́ ńjwaʼə̂ pɔ́ pə́ənə́, zə́ələ́ á yǐ ghɛd mbɨ əzɔb ə́ tə ḿbə́gə. Ngaŋə́ghɛlə təpɔŋ yǒ kwá ntsɔ́ʼəfaʼ əzɔb nə́ təpɔŋ pö ghɛd nə́, ńté ńgə́ Əsê a tsɔ́ʼtə əsáʼ ŋwu ntsəm lə́ ndə̌ŋdəŋə́.',
    englishText: 'Husbands, love your wives, and don’t be bitter against them. Fathers, don’t provoke your children, so that they won’t be discouraged. But he who does wrong will receive again for the wrong that he has done, and there is no partiality.',
    blanks: [
      _ParagraphBlank(correctWord: 'Pəlú', choices: ['komtə', 'ənaŋnə majiə', 'aghəŋə', 'Pəlú']),
      _ParagraphBlank(correctWord: 'nə́', choices: ['nto\'ə', 'nə́', 'sagə', 'kaatə']),
      _ParagraphBlank(correctWord: 'pəngyě', choices: ['pəngyě', 'əli\' pipa lum no', 'tumə', 'sinagoga']),
    ],
  ),
  // HEB.3.8-10
  _QuizParagraph(
    title: 'Practice 21',
    context: 'don’t harden your hearts, as in the