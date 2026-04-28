import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';
import 'package:awing_ai_learning/services/auth_service.dart';
import 'package:awing_ai_learning/services/image_service.dart';
import 'package:awing_ai_learning/components/pack_image.dart';

/// Simple Awing sentences for the Medium module
class AwingSentence {
  final String awing;
  final String english;
  final List<AwingWord> words; // word-by-word breakdown

  const AwingSentence({
    required this.awing,
    required this.english,
    required this.words,
  });
}

class AwingWord {
  final String word;
  final String english;

  const AwingWord(this.word, this.english);
}

/// Sentences sourced from AwingOrthography2005.pdf examples (pages 9, 11, 12).
/// Ordered from simplest (2 words) to more complex.
// Sentences verified from AwingOrthography2005.pdf.
// Individual words verified from orthography page 8 tone chart and page 9 noun classes.
const List<AwingSentence> awingSentences = [
  // Simple 2-word sentences — words verified from orthography tone chart (p.8)
  // yə = he (p.8), ko = take (p.8), mǎ = mother (p.9)
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//   AwingSentence(
//     awing: 'Yə nô',
//     english: 'He/she drinks',
//     words: [
//       AwingWord('Yə', 'He/she'),
//       AwingWord('nô', 'drinks'),
//     ],
//   ),
  AwingSentence(
    awing: 'Mǎ ko',
    english: 'Mother takes',
    words: [
      AwingWord('Mǎ', 'Mother'),
      AwingWord('ko', 'takes'),
    ],
  ),
  // 3-word sentence — nkǐə = water (dictionary, n 1/6) — corrected Session 52
  AwingSentence(
    awing: 'Mǎ nô nkǐə',
    english: 'Mother drinks water',
    words: [
      AwingWord('Mǎ', 'Mother'),
      AwingWord('nô', 'drinks'),
      AwingWord('nkǐə', 'water'),
    ],
  ),
  // yǐə = come (p.8, RISING tone ǐ, not falling î)
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//   AwingSentence(
//     awing: 'Yə yǐə',
//     english: 'He/she comes',
//     words: [
//       AwingWord('Yə', 'He/she'),
//       AwingWord('yǐə', 'comes'),
//     ],
//   ),
  // Longer sentences — VERIFIED from orthography PDF
  // Page 11: "Móonə a tə nonnɔ́ a əkwunɔ́."
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//   AwingSentence(
//     awing: "Móonə a tə nonnɔ́ a əkwunɔ́.",
//     english: 'The baby is lying on the bed.',
//     words: [
//       AwingWord('Móonə', 'Baby'),
//       AwingWord('a', '(subject)'),
//       AwingWord('tə', '(progressive)'),
//       AwingWord('nonnɔ́', 'lying'),
//       AwingWord('a', 'on'),
//       AwingWord('əkwunɔ́', 'bed'),
//     ],
//   ),
  // Page 9: "A kə ghɛnɔ́ məteenɔ́."
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//   AwingSentence(
//     awing: "A kə ghɛnɔ́ məteenɔ́.",
//     english: 'He went to the market.',
//     words: [
//       AwingWord('A', 'He'),
//       AwingWord('kə', '(past tense)'),
//       AwingWord('ghɛnɔ́', 'go'),
//       AwingWord('məteenɔ́', 'market'),
//     ],
//   ),
  // Page 12: "Po zí nóolə."
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//   AwingSentence(
//     awing: "Po zí nóolə.",
//     english: 'They have seen a snake.',
//     words: [
//       AwingWord('Po', 'They'),
//       AwingWord('zí', 'have seen'),
//       AwingWord('nóolə', 'snake'),
//     ],
//   ),
  // Page 12: "Ghǒ ghɛnɔ́ lə əfó?" (from quotation marks section)
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//   AwingSentence(
//     awing: "Ghǒ ghɛnɔ́ lə əfó?",
//     english: 'Where are you going?',
//     words: [
//       AwingWord('Ghǒ', 'You'),
//       AwingWord('ghɛnɔ́', 'going'),
//       AwingWord('lə', 'to'),
//       AwingWord('əfó', 'where'),
//     ],
//   ),
  // Page 11: "Po ma ngyǐə lə əfê, po ghɛnɔ́ lə nkǐə."
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//   AwingSentence(
//     awing: "Po ma ngyǐə lə əfê, po ghɛnɔ́ lə nkǐə.",
//     english: 'They are not coming here, they are going to the stream.',
//     words: [
//       AwingWord('Po', 'They'),
//       AwingWord('ma', 'not'),
//       AwingWord('ngyǐə', 'come'),
//       AwingWord('lə', 'to'),
//       AwingWord('əfê', 'here'),
//       AwingWord('po', 'they'),
//       AwingWord('ghɛnɔ́', 'go'),
//       AwingWord('lə', 'to'),
//       AwingWord('nkǐə', 'stream'),
//     ],
//   ),
  // Page 10: "Lɛ̌ nəpɔ'ɔ́."
  AwingSentence(
    awing: "Lɛ̌ nəpɔ'ɔ́.",
    english: 'This is a pumpkin.',
    words: [
      AwingWord('Lɛ̌', 'This is'),
      AwingWord("nəpɔ'ɔ́", 'pumpkin'),
    ],
  ),


  // Auto-extracted from Bible NT (non-biblical-feeling)
  // 1CO.1.19
  AwingSentence(
    awing: 'ə́sɛdkə̂ ajíənuə ngaŋə́ŋwaʼlə a pə́ ənukə́taŋə.”',
    english: 'For it is written,\n“I will destroy the wisdom of the wise,\nI will bring the discernment of the discerning to nothing.”',
    words: [
      AwingWord('ə́sɛdkə̂', 'into'),
      AwingWord('ajíənuə', 'knowledge'),
      AwingWord('ngaŋə́ŋwaʼlə', '—'),
      AwingWord('a', 'he'),
      AwingWord('pə́', '—'),
      AwingWord('ənukə́taŋə', '—'),
      AwingWord('”', '—'),
    ],
  ),
  // 1CO.1.22
  AwingSentence(
    awing: 'Pəjus pó náŋə lə́ əkyeʼmə́nuə, Pəglik pó pə́ ńnáŋə lə́ ayáŋə.',
    english: 'For Jews ask for signs, Greeks seek after wisdom,',
    words: [
      AwingWord('Pəjus', 'jews'),
      AwingWord('pó', 'us'),
      AwingWord('náŋə', 'look at'),
      AwingWord('lə́', 'but'),
      AwingWord('əkyeʼmə́nuə', 'signs'),
      AwingWord('Pəglik', 'greeks'),
      AwingWord('pó', 'us'),
      AwingWord('pə́', '—'),
      AwingWord('ńnáŋə', '—'),
      AwingWord('lə́', 'but'),
      AwingWord('ayáŋə', 'wisdom'),
    ],
  ),
  // 1CO.4.16
  AwingSentence(
    awing: 'Ńdaŋ ə́lɨ́d, zoŋ nə́ ntag məkoolə mə.',
    english: 'I beg you therefore, be imitators of me.',
    words: [
      AwingWord('Ńdaŋ', '—'),
      AwingWord('ə́lɨ́d', '—'),
      AwingWord('zoŋ', '—'),
      AwingWord('nə́', '—'),
      AwingWord('ntag', 'same'),
      AwingWord('məkoolə', 'feet'),
      AwingWord('mə', 'my'),
    ],
  ),
  // 1CO.9.4
  AwingSentence(
    awing: 'Lə́ kě aliʼə́nuə mə ńgə́ pə́ fɛ̂ məjî pópə məloʼ nə́ maŋ ńté afaʼə mə pô?',
    english: 'Have we no right to eat and to drink?',
    words: [
      AwingWord('Lə́', 'but'),
      AwingWord('kě', 'marker of negation'),
      AwingWord('aliʼə́nuə', '—'),
      AwingWord('mə', 'my'),
      AwingWord('ńgə́', 'verb complement'),
      AwingWord('pə́', '—'),
      AwingWord('fɛ̂', '—'),
      AwingWord('məjî', '—'),
      AwingWord('pópə', '—'),
      AwingWord('məloʼ', 'wine'),
      AwingWord('nə́', '—'),
      AwingWord('maŋ', '—'),
      AwingWord('ńté', '—'),
      AwingWord('afaʼə', '—'),
      AwingWord('mə', 'my'),
      AwingWord('pô', 'us'),
    ],
  ),
  // 1CO.10.3
  AwingSentence(
    awing: 'Pó pətsəm nə ńjîə táʼ ntê məjî mə́ ajwiə.',
    english: 'and all ate the same spiritual food;',
    words: [
      AwingWord('Pó', 'us'),
      AwingWord('pətsəm', '—'),
      AwingWord('nə', '—'),
      AwingWord('ńjîə', 'hunger'),
      AwingWord('táʼ', 'one'),
      AwingWord('ntê', '—'),
      AwingWord('məjî', '—'),
      AwingWord('mə́', 'my'),
      AwingWord('ajwiə', 'breath'),
    ],
  ),
  // 1CO.11.31
  AwingSentence(
    awing: 'Lə́ mbɔʼ pɛn peg ńchaʼ mbɨ əzɛ̂n, Mmaʼmbîə a yǐ ńkě áwɛ̂n tsəŋkə̂ pô.',
    english: 'For if we discerned ourselves, we wouldn’t be judged.',
    words: [
      AwingWord('Lə́', 'but'),
      AwingWord('mbɔʼ', '—'),
      AwingWord('pɛn', '—'),
      AwingWord('peg', '—'),
      AwingWord('ńchaʼ', '—'),
      AwingWord('mbɨ', '—'),
      AwingWord('əzɛ̂n', '—'),
      AwingWord('Mmaʼmbîə', 'lord'),
      AwingWord('a', 'he'),
      AwingWord('yǐ', '—'),
      AwingWord('ńkě', '—'),
      AwingWord('áwɛ̂n', '—'),
      AwingWord('tsəŋkə̂', '—'),
      AwingWord('pô', 'us'),
    ],
  ),
  // 1CO.12.20
  AwingSentence(
    awing: 'Ndzaŋ á pɛn ńchî ə́lɨ́d lə́, əlam mbɨ ə́ nə́ənə, ḿbə́ ḿbə́ lə́ tsɔʼə táʼ mbəəmə.',
    english: 'But now they are many members, but one body.',
    words: [
      AwingWord('Ndzaŋ', '—'),
      AwingWord('á', 'he'),
      AwingWord('pɛn', '—'),
      AwingWord('ńchî', '—'),
      AwingWord('ə́lɨ́d', '—'),
      AwingWord('lə́', 'but'),
      AwingWord('əlam', 'body'),
      AwingWord('mbɨ', '—'),
      AwingWord('ə́', 'they'),
      AwingWord('nə́ənə', 'sea'),
      AwingWord('ḿbə́', '—'),
      AwingWord('ḿbə́', '—'),
      AwingWord('lə́', 'but'),
      AwingWord('tsɔʼə', '—'),
      AwingWord('táʼ', 'one'),
      AwingWord('mbəəmə', '—'),
    ],
  ),
  // 1CO.12.25
  AwingSentence(
    awing: 'Ńjî ńgə́ kɔ mbɨ ə́ ghabnə̂, lə́ alamə́ mbəəmə atsəm á pyádnə mɔ́mɛ́ əyǐə.',
    english: 'that there should be no division in the body, but that the members should have the same care for one another.',
    words: [
      AwingWord('Ńjî', '—'),
      AwingWord('ńgə́', 'verb complement'),
      AwingWord('kɔ', '—'),
      AwingWord('mbɨ', '—'),
      AwingWord('ə́', 'they'),
      AwingWord('ghabnə̂', 'separate'),
      AwingWord('lə́', 'but'),
      AwingWord('alamə́', 'members'),
      AwingWord('mbəəmə', '—'),
      AwingWord('atsəm', '—'),
      AwingWord('á', 'he'),
      AwingWord('pyádnə', 'really'),
      AwingWord('mɔ́mɛ́', 'brother'),
      AwingWord('əyǐə', '—'),
    ],
  ),
  // 1CO.12.31
  AwingSentence(
    awing: 'Tə́g nə́ atûə azə́ənə́ á mə́ túg nə́ pətə́kɔʼ pə́ məfɛ̂nə Ajwǐəsê ä fɛ̂ nə́.',
    english: 'But earnestly desire the best gifts. Moreover, I show a most excellent way to you.',
    words: [
      AwingWord('Tə́g', '—'),
      AwingWord('nə́', '—'),
      AwingWord('atûə', 'head'),
      AwingWord('azə́ənə́', '—'),
      AwingWord('á', 'he'),
      AwingWord('mə́', 'my'),
      AwingWord('túg', '—'),
      AwingWord('nə́', '—'),
      AwingWord('pətə́kɔʼ', 'chief'),
      AwingWord('pə́', '—'),
      AwingWord('məfɛ̂nə', 'gift'),
      AwingWord('Ajwǐəsê', 'spirit'),
      AwingWord('ä', '—'),
      AwingWord('fɛ̂', '—'),
      AwingWord('nə́', '—'),
    ],
  ),
  // 1CO.14.8
  AwingSentence(
    awing: 'Mbɔʼ pə́ chî ndɔ́ŋ ntso əshîʼnə tɔ́ŋ pô əwə a fɛ́d ńgɛnə̂ á ntsoolə?',
    english: 'For if the trumpet gave an uncertain sound, who would prepare himself for war?',
    words: [
      AwingWord('Mbɔʼ', '—'),
      AwingWord('pə́', '—'),
      AwingWord('chî', '—'),
      AwingWord('ndɔ́ŋ', 'cup'),
      AwingWord('ntso', 'date palm'),
      AwingWord('əshîʼnə', 'good'),
      AwingWord('tɔ́ŋ', 'city'),
      AwingWord('pô', 'us'),
      AwingWord('əwə', '—'),
      AwingWord('a', 'he'),
      AwingWord('fɛ́d', '—'),
      AwingWord('ńgɛnə̂', '—'),
      AwingWord('á', 'he'),
      AwingWord('ntsoolə', 'mouth'),
    ],
  ),
  // 1CO.14.17
  AwingSentence(
    awing: 'Mbɔʼ gho chígə́ ńtə́ ə́fɛ̂ ndǎ əshîʼnə, lə́ zɨ́d pə́ ńkě yitsə̌ ŋwu tə́ ńkwíŋkə pô.',
    english: 'For you most certainly give thanks well, but the other person is not built up.',
    words: [
      AwingWord('Mbɔʼ', '—'),
      AwingWord('gho', 'you'),
      AwingWord('chígə́', 'real'),
      AwingWord('ńtə́', '—'),
      AwingWord('ə́fɛ̂', '—'),
      AwingWord('ndǎ', '—'),
      AwingWord('əshîʼnə', 'good'),
      AwingWord('lə́', 'but'),
      AwingWord('zɨ́d', '—'),
      AwingWord('pə́', '—'),
      AwingWord('ńkě', '—'),
      AwingWord('yitsə̌', '—'),
      AwingWord('ŋwu', '—'),
      AwingWord('tə́', '—'),
      AwingWord('ńkwíŋkə', '—'),
      AwingWord('pô', 'us'),
    ],
  ),
  // 1CO.14.40
  AwingSentence(
    awing: 'Lə́ nə́ ghɛd mənu mətsəm ndə̌ŋdəŋ ńkə́ ńdzoŋə̂ noŋkə yi əshîʼnə.',
    english: 'Let all things be done decently and in order.',
    words: [
      AwingWord('Lə́', 'but'),
      AwingWord('nə́', '—'),
      AwingWord('ghɛd', '—'),
      AwingWord('mənu', '—'),
      AwingWord('mətsəm', '—'),
      AwingWord('ndə̌ŋdəŋ', '—'),
      AwingWord('ńkə́', '—'),
      AwingWord('ńdzoŋə̂', '—'),
      AwingWord('noŋkə', 'nurse'),
      AwingWord('yi', '—'),
      AwingWord('əshîʼnə', 'good'),
    ],
  ),
  // 1CO.15.26
  AwingSentence(
    awing: 'Ngaŋkəpa pə́ yǒ nə́ lwigtə̂ mə́ tsəŋkə̂ nə́ lə́ nəwûə.',
    english: 'The last enemy that will be abolished is death.',
    words: [
      AwingWord('Ngaŋkəpa', 'enemies'),
      AwingWord('pə́', '—'),
      AwingWord('yǒ', 'his'),
      AwingWord('nə́', '—'),
      AwingWord('lwigtə̂', '—'),
      AwingWord('mə́', 'my'),
      AwingWord('tsəŋkə̂', '—'),
      AwingWord('nə́', '—'),
      AwingWord('lə́', 'but'),
      AwingWord('nəwûə', 'the manner of falling'),
    ],
  ),
  // 1CO.15.30
  AwingSentence(
    awing: 'Ńgɛn nə́ pəg, pə̈g fɛ̂ mbɨ əzəgə́ á ntso nəwû əghâ ətsəm lə́ ńgə́ akə̂?',
    english: 'Why do we also stand in jeopardy every hour?',
    words: [
      AwingWord('Ńgɛn', '—'),
      AwingWord('nə́', '—'),
      AwingWord('pəg', '—'),
      AwingWord('pə̈g', '—'),
      AwingWord('fɛ̂', '—'),
      AwingWord('mbɨ', '—'),
      AwingWord('əzəgə́', '—'),
      AwingWord('á', 'he'),
      AwingWord('ntso', 'date palm'),
      AwingWord('nəwû', '—'),
      AwingWord('əghâ', 'season'),
      AwingWord('ətsəm', '—'),
      AwingWord('lə́', 'but'),
      AwingWord('ńgə́', 'verb complement'),
      AwingWord('akə̂', '—'),
    ],
  ),
  // 1CO.15.33
  AwingSentence(
    awing: 'Kɔ ŋwu tsə̌ a fɨgə̂ áwə́ənə́, “əghɨ təpɔŋ ə́ tsəŋə̂ a mbɔ́ yi əshîʼnə.”',
    english: 'Don’t be deceived! “Evil companionships corrupt good morals.”',
    words: [
      AwingWord('Kɔ', '—'),
      AwingWord('ŋwu', '—'),
      AwingWord('tsə̌', '—'),
      AwingWord('a', 'he'),
      AwingWord('fɨgə̂', '—'),
      AwingWord('áwə́ənə́', '—'),
      AwingWord('“əghɨ', '—'),
      AwingWord('təpɔŋ', '—'),
      AwingWord('ə́', 'they'),
      AwingWord('tsəŋə̂', 'curse'),
      AwingWord('a', 'he'),
      AwingWord('mbɔ́', '—'),
      AwingWord('yi', '—'),
      AwingWord('əshîʼnə', 'good'),
      AwingWord('”', '—'),
    ],
  ),
  // 1CO.15.36
  AwingSentence(
    awing: 'Akəkóg! Ajú páʼ gho pǐ nə́ a kě sáʼə pô tə ńdéʼtə á kwûə.',
    english: 'You foolish one, that which you yourself sow is not made alive unless it dies.',
    words: [
      AwingWord('Akəkóg', 'foolish'),
      AwingWord('Ajú', '—'),
      AwingWord('páʼ', '—'),
      AwingWord('gho', 'you'),
      AwingWord('pǐ', '—'),
      AwingWord('nə́', '—'),
      AwingWord('a', 'he'),
      AwingWord('kě', 'marker of negation'),
      AwingWord('sáʼə', '—'),
      AwingWord('pô', 'us'),
      AwingWord('tə', '—'),
      AwingWord('ńdéʼtə', '—'),
      AwingWord('á', 'he'),
      AwingWord('kwûə', 'die'),
    ],
  ),
  // 1CO.15.55
  AwingSentence(
    awing: 'Nəwû, ə́sɛ̂n gho ə́fó?” 15.55Osya 13.14',
    english: '“Death, where is your sting?\nHades, where is your victory?”',
    words: [
      AwingWord('Nəwû', '—'),
      AwingWord('ə́sɛ̂n', 'today'),
      AwingWord('gho', 'you'),
      AwingWord('ə́fó', '—'),
      AwingWord('”', '—'),
      AwingWord('15', '—'),
      AwingWord('55Osya', '—'),
      AwingWord('13', '—'),
      AwingWord('14', '—'),
    ],
  ),
  // 1CO.16.4
  AwingSentence(
    awing: 'Á kə́ ńkoʼnə̂ pə́ ńgə́ maŋ ghɛn ə́wɨ́, pə̌gpo ghɛnə̂.',
    english: 'If it is appropriate for me to go also, they will go with me.',
    words: [
      AwingWord('Á', 'he'),
      AwingWord('kə́', 'marker of negation'),
      AwingWord('ńkoʼnə̂', '—'),
      AwingWord('pə́', '—'),
      AwingWord('ńgə́', 'verb complement'),
      AwingWord('maŋ', '—'),
      AwingWord('ghɛn', '—'),
      AwingWord('ə́wɨ́', '—'),
      AwingWord('pə̌gpo', '—'),
      AwingWord('ghɛnə̂', '—'),
    ],
  ),
  // 1CO.16.14
  AwingSentence(
    awing: 'Faʼ nə́ afaʼə atsəm nə́ akɔŋnə.',
    english: 'Let all that you do be done in love.',
    words: [
      AwingWord('Faʼ', '—'),
      AwingWord('nə́', '—'),
      AwingWord('afaʼə', '—'),
      AwingWord('atsəm', '—'),
      AwingWord('nə́', '—'),
      AwingWord('akɔŋnə', 'love'),
    ],
  ),
  // 1CO.16.20
  AwingSentence(
    awing: 'Pəlim páʼ pó chî nə́ aliʼə́ nə́ tsɔʼə pətsəm pə́ tə́ ńchaʼtə̂ áwə́ənə́.',
    english: 'All the brothers greet you. Greet one another with a holy kiss.',
    words: [
      AwingWord('Pəlim', 'brothers'),
      AwingWord('páʼ', '—'),
      AwingWord('pó', 'us'),
      AwingWord('chî', '—'),
      AwingWord('nə́', '—'),
      AwingWord('aliʼə́', '—'),
      AwingWord('nə́', '—'),
      AwingWord('tsɔʼə', '—'),
      AwingWord('pətsəm', '—'),
      AwingWord('pə́', '—'),
      AwingWord('tə́', '—'),
      AwingWord('ńchaʼtə̂', 'greet'),
      AwingWord('áwə́ənə́', '—'),
    ],
  ),
  // 1JN.2.3
  AwingSentence(
    awing: 'Təmbɔʼ pɛn zóʼnə məntəgə́ mə́ Əsê, á pyádnə nɨd ńgə́ pɛn jîə yə́.',
    english: 'This is how we know that we know him: if we keep his commandments.',
    words: [
      AwingWord('Təmbɔʼ', '—'),
      AwingWord('pɛn', '—'),
      AwingWord('zóʼnə', '—'),
      AwingWord('məntəgə́', '—'),
      AwingWord('mə́', 'my'),
      AwingWord('Əsê', 'god'),
      AwingWord('á', 'he'),
      AwingWord('pyádnə', 'really'),
      AwingWord('nɨd', '—'),
      AwingWord('ńgə́', 'verb complement'),
      AwingWord('pɛn', '—'),
      AwingWord('jîə', 'eat'),
      AwingWord('yə́', '—'),
    ],
  ),
  // 1JN.3.11
  AwingSentence(
    awing: 'Nkɨ pɨ kə zóʼ nə́ ə́fɛ́lə nəfɛdnə́ lə́ ńgə́, pɛn shib ńkɔŋ məmbɨ mɛ́nə.',
    english: 'For this is the message which you heard from the beginning, that we should love one another;',
    words: [
      AwingWord('Nkɨ', 'good'),
      AwingWord('pɨ', '—'),
      AwingWord('kə', 'marker of negation'),
      AwingWord('zóʼ', '—'),
      AwingWord('nə́', '—'),
      AwingWord('ə́fɛ́lə', '—'),
      AwingWord('nəfɛdnə́', 'beginning'),
      AwingWord('lə́', 'but'),
      AwingWord('ńgə́', 'verb complement'),
      AwingWord('pɛn', '—'),
      AwingWord('shib', '—'),
      AwingWord('ńkɔŋ', '—'),
      AwingWord('məmbɨ', '—'),
      AwingWord('mɛ́nə', 'god'),
    ],
  ),
  // 1JN.4.19
  AwingSentence(
    awing: 'Pɛ̈n kɔŋə̂ lə́ ńté ńgə́ Əsê a nə ḿbeg ńkɔŋə̂ áwɛ̂nə.',
    english: 'We love him, because he first loved us.',
    words: [
      AwingWord('Pɛ̈n', '—'),
      AwingWord('kɔŋə̂', '—'),
      AwingWord('lə́', 'but'),
      AwingWord('ńté', '—'),
      AwingWord('ńgə́', 'verb complement'),
      AwingWord('Əsê', 'god'),
      AwingWord('a', 'he'),
      AwingWord('nə', '—'),
      AwingWord('ḿbeg', '—'),
      AwingWord('ńkɔŋə̂', 'throat'),
      AwingWord('áwɛ̂nə', '—'),
    ],
  ),
  // 1JN.5.7
  AwingSentence(
    awing: 'Lə́ chî pɨ pɛ́n teelə́ pó zɨ́ nə́ ńkə́ ḿbí ńgə́ lə́ ndə̌ŋdəŋə́.',
    english: 'For there are three who testify:',
    words: [
      AwingWord('Lə́', 'but'),
      AwingWord('chî', '—'),
      AwingWord('pɨ', '—'),
      AwingWord('pɛ́n', '—'),
      AwingWord('teelə́', 'three'),
      AwingWord('pó', 'us'),
      AwingWord('zɨ́', '—'),
      AwingWord('nə́', '—'),
      AwingWord('ńkə́', '—'),
      AwingWord('ḿbí', '—'),
      AwingWord('ńgə́', 'verb complement'),
      AwingWord('lə́', 'but'),
      AwingWord('ndə̌ŋdəŋə́', '—'),
    ],
  ),
  // 1JN.5.21
  AwingSentence(
    awing: 'Póonə mə, lə́ʼ nə́ wɨ́ məsê mə́ məfɨgə.',
    english: 'Little children, keep yourselves from idols.',
    words: [
      AwingWord('Póonə', 'children'),
      AwingWord('mə', 'my'),
      AwingWord('lə́ʼ', 'escape'),
      AwingWord('nə́', '—'),
      AwingWord('wɨ́', '—'),
      AwingWord('məsê', 'witchcraft'),
      AwingWord('mə́', 'my'),
      AwingWord('məfɨgə', '—'),
    ],
  ),
  // 1PE.1.16
  AwingSentence(
    awing: 'Aŋwaʼlə Əsê á sóŋ ńgə́, “Nə́ ŋwaʼə̂, ńté ńgə́ maŋ kə́ ŋwaʼə̂.”',
    english: 'because it is written, “You shall be holy; for I am holy.”',
    words: [
      AwingWord('Aŋwaʼlə', '—'),
      AwingWord('Əsê', 'god'),
      AwingWord('á', 'he'),
      AwingWord('sóŋ', '—'),
      AwingWord('ńgə́', 'verb complement'),
      AwingWord('“Nə́', 'said'),
      AwingWord('�