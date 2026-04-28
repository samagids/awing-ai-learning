import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';
import 'package:awing_ai_learning/services/progress_service.dart';
import 'package:awing_ai_learning/services/image_service.dart';
import 'package:awing_ai_learning/components/pack_image.dart';

/// Data class for a single story
class AwingStory {
  final String titleEnglish;
  final String titleAwing;
  final String illustration; // emoji/icon placeholder
  final List<StorySentence> sentences;
  final List<StoryVocabulary> vocabulary;
  final List<ComprehensionQuestion> questions;
  bool isCompleted;

  AwingStory({
    required this.titleEnglish,
    required this.titleAwing,
    required this.illustration,
    required this.sentences,
    required this.vocabulary,
    required this.questions,
    this.isCompleted = false,
  });
}

/// A sentence in a story
class StorySentence {
  final String awing;
  final String english;

  const StorySentence({
    required this.awing,
    required this.english,
  });
}

/// Vocabulary item with Awing and English
class StoryVocabulary {
  final String awing;
  final String english;

  const StoryVocabulary({
    required this.awing,
    required this.english,
  });
}

/// Multiple choice comprehension question
class ComprehensionQuestion {
  final String question;
  final String correctAnswer;
  final List<String> options; // includes correct answer, already shuffled

  const ComprehensionQuestion({
    required this.question,
    required this.correctAnswer,
    required this.options,
  });
}

/// ============================================================================
/// STORY DATA — 4 short Awing stories for kids
/// ============================================================================

final List<AwingStory> awingStories = [
  AwingStory(
    titleEnglish: 'The Owl and the Fish',
    titleAwing: 'Koŋə ne əshûə',
    illustration: '🦉',
    sentences: [
      StorySentence(
        awing: 'Koŋə yǐə alá\'ə.',
        english: 'The owl came to the village.',
      ),
      StorySentence(
        awing: 'Yə zó\'ə wâakɔ́ ne nkǐə.',
        english: 'She heard sounds at the water.',
      ),
      StorySentence(
        awing: 'Əshûə nyɛ́ə wâakɔ́.',
        english: 'The fish was in the water.',
      ),
      StorySentence(
        // Session 52: pímə = believe/confess (dict), not "see". Switched to náŋə (look at).
        awing: 'Koŋə náŋə əshûə.',
        english: 'The owl looked at the fish.',
      ),
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//       StorySentence(
//         awing: 'Yə cha\'tɔ́ əshûə ne mîə nô.',
//         english: 'She greeted the fish, who swallowed water.',
//       ),
    ],
    vocabulary: [
      StoryVocabulary(awing: 'koŋə', english: 'owl'),
      StoryVocabulary(awing: 'əshûə', english: 'fish'),
      StoryVocabulary(awing: 'alá\'ə', english: 'village'),
      StoryVocabulary(awing: 'yǐə', english: 'come'),
      StoryVocabulary(awing: 'zó\'ə', english: 'hear'),
      StoryVocabulary(awing: 'wâakɔ́', english: 'water'),
      StoryVocabulary(awing: 'náŋə', english: 'look at'),
      StoryVocabulary(awing: 'cha\'tɔ́', english: 'greet'),
      StoryVocabulary(awing: 'mîə', english: 'swallow'),
      StoryVocabulary(awing: 'nô', english: 'drink'),
    ],
    questions: [
      ComprehensionQuestion(
        question: 'Where did the owl go?',
        correctAnswer: 'to the village',
        options: ['to the village', 'to the forest', 'to the tree'],
      ),
      ComprehensionQuestion(
        question: 'What animal did the owl see in the water?',
        correctAnswer: 'a fish',
        options: ['a fish', 'a snake', 'a bird'],
      ),
      ComprehensionQuestion(
        question: 'What did the owl do with the fish?',
        correctAnswer: 'She greeted it',
        options: ['She greeted it', 'She caught it', 'She danced with it'],
      ),
    ],
  ),
  AwingStory(
    titleEnglish: 'Mother\'s Hands',
    titleAwing: 'Mǎ ne apô',
    illustration: '👩',
    sentences: [
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//       StorySentence(
//         awing: 'Mǎ nkadtə nə nəgoomɔ́.',
//         english: 'Mother prepared plantain.',
//       ),
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//       StorySentence(
//         awing: 'Apô yə kwágə pɛ́nə.',
//         english: 'Her hands worked and danced.',
//       ),
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//       StorySentence(
//         awing: 'Yə ko afûə ne ngwáŋə.',
//         english: 'She took leaves and salt.',
//       ),
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//       StorySentence(
//         awing: 'Məkəŋɔ́ yə nyɛ́ə atîə.',
//         english: 'The pots sat on the fire.',
//       ),
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//       StorySentence(
        // Simplified — Session 52: removed məndě (means "necks", not "each other")
        // and pímə (dictionary: believe/confess, not "food").
//         awing: 'Pəmǎ cha\'tɔ́ yə.',
//         english: 'The mothers greeted her.',
//       ),
    ],
    vocabulary: [
      StoryVocabulary(awing: 'mǎ', english: 'mother'),
      StoryVocabulary(awing: 'apô', english: 'hand'),
      StoryVocabulary(awing: 'nəgoomɔ́', english: 'plantain'),
      StoryVocabulary(awing: 'afûə', english: 'leaf/medicine'),
      StoryVocabulary(awing: 'ngwáŋə', english: 'salt'),
      StoryVocabulary(awing: 'nəkəŋɔ́', english: 'pot'),
      StoryVocabulary(awing: 'atîə', english: 'tree/fire'),
      StoryVocabulary(awing: 'ko', english: 'take'),
      StoryVocabulary(awing: 'pɛ́nə', english: 'dance'),
      StoryVocabulary(awing: 'cha\'tɔ́', english: 'greet'),
    ],
    questions: [
      ComprehensionQuestion(
        question: 'What did Mother prepare?',
        correctAnswer: 'plantain',
        options: ['plantain', 'fish', 'beans'],
      ),
      ComprehensionQuestion(
        question: 'What ingredients did Mother use?',
        correctAnswer: 'leaves and salt',
        options: ['leaves and salt', 'sand and water', 'stones and wood'],
      ),
      ComprehensionQuestion(
        question: 'Why did the mothers greet each other?',
        correctAnswer: 'They saw her good food',
        options: ['They saw her good food', 'They heard music', 'They danced together'],
      ),
    ],
  ),
  AwingStory(
    titleEnglish: 'The Village',
    titleAwing: 'Alá\'ə ne pɛ́nə',
    illustration: '🏘️',
    sentences: [
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//       StorySentence(
//         awing: 'Alá\'ə nyɛ́ə pəlɛ́ə ne asɨ́ə.',
//         english: 'The village had many people and houses.',
//       ),
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//       StorySentence(
//         awing: 'Mbe\'tə pɛ́nə pimə akoobɔ́.',
//         english: 'The young people danced and looked at the forest.',
//       ),
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//       StorySentence(
//         awing: 'Cha\'tɔ́ nyɛ́ə ngye pəmǎ ne pəyə.',
//         english: 'Greetings were the voices of mothers and fathers.',
//       ),
      StorySentence(
        // Session 52: was 'Pəndě nəkəŋɔ́…' — Pəndě is voc 1/2 plural ("elders"),
        // not "pots." Replaced with the correct n 1/6 plural for nəkəŋɔ́.
        awing: 'Məkəŋɔ́ nyɛ́ə pə alá\'ə.',
        english: 'Pots were in the village.',
      ),
      StorySentence(
        // Session 52: removed unverified "pə ndě" locative construction.
        awing: 'Ayáŋə pə alá\'ə.',
        english: 'Wisdom is in the village.',
      ),
    ],
    vocabulary: [
      StoryVocabulary(awing: 'alá\'ə', english: 'village'),
      StoryVocabulary(awing: 'pəlɛ́ə', english: 'people'),
      StoryVocabulary(awing: 'asɨ́ə', english: 'houses'),
      StoryVocabulary(awing: 'mbe\'tə', english: 'shoulder/young person'),
      StoryVocabulary(awing: 'pɛ́nə', english: 'dance'),
      StoryVocabulary(awing: 'akoobɔ́', english: 'forest'),
      StoryVocabulary(awing: 'cha\'tɔ́', english: 'greet'),
      StoryVocabulary(awing: 'ngye', english: 'voice'),
      StoryVocabulary(awing: 'nəkəŋɔ́', english: 'pot'),
      StoryVocabulary(awing: 'ayáŋə', english: 'wisdom'),
    ],
    questions: [
      ComprehensionQuestion(
        question: 'What was in the village?',
        correctAnswer: 'people and houses',
        options: ['people and houses', 'only trees', 'only water'],
      ),
      ComprehensionQuestion(
        question: 'What did the young people do?',
        correctAnswer: 'danced and looked at the forest',
        options: ['danced and looked at the forest', 'worked in the pots', 'ran to the water'],
      ),
      ComprehensionQuestion(
        question: 'What was in the pots?',
        correctAnswer: 'soup and groundnuts',
        options: ['soup and groundnuts', 'water and sand', 'leaves and stones'],
      ),
    ],
  ),
  AwingStory(
    titleEnglish: 'Learning to Heal',
    titleAwing: 'Tsó\'ə ne afûə',
    illustration: '🌿',
    sentences: [
      StorySentence(
        awing: 'Apɛ̌ɛlə ko mǎ yǐə akoobɔ́.',
        english: 'A young person came with mother to the forest.',
      ),
      StorySentence(
        awing: 'Mǎ zó\'ə atîə ne afûə.',
        english: 'Mother heard the trees and the leaves.',
      ),
      StorySentence(
        awing: 'Yə nô nkǐə pə atîə nyɛ́ə tsó\'ə.',
        english: 'She drank water—the tree is healing.',
      ),
      StorySentence(
        // Session 52: pímə "see" was wrong (dict: believe). Replaced with náŋə "look at".
        awing: 'Apɛ̌ɛlə náŋə afûə nəlwîə ne nkǐə.',
        english: 'The young person looked at the medicine leaf for the nose and water.',
      ),
      StorySentence(
        awing: 'Tsó\'ə pə alá\'ə ne ayáŋə pə mǎ.',
        english: 'Healing came to the village—wisdom from mother.',
      ),
    ],
    vocabulary: [
      StoryVocabulary(awing: 'tsó\'ə', english: 'heal'),
      StoryVocabulary(awing: 'afûə', english: 'leaf/medicine'),
      StoryVocabulary(awing: 'akoobɔ́', english: 'forest'),
      StoryVocabulary(awing: 'mǎ', english: 'mother'),
      StoryVocabulary(awing: 'atîə', english: 'tree'),
      StoryVocabulary(awing: 'zó\'ə', english: 'hear'),
      StoryVocabulary(awing: 'nô', english: 'drink'),
      StoryVocabulary(awing: 'náŋə', english: 'look at'),
      StoryVocabulary(awing: 'nəlwîə', english: 'nose'),
      StoryVocabulary(awing: 'ayáŋə', english: 'wisdom'),
    ],
    questions: [
      ComprehensionQuestion(
        question: 'Where did they go to learn?',
        correctAnswer: 'to the forest',
        options: ['to the forest', 'to the village', 'to the water'],
      ),
      ComprehensionQuestion(
        question: 'What does the tree provide?',
        correctAnswer: 'healing',
        options: ['healing', 'food', 'homes'],
      ),
      ComprehensionQuestion(
        question: 'Who teaches the young person about healing?',
        correctAnswer: 'Mother',
        options: ['Mother', 'the forest', 'the owl'],
      ),
    ],
  ),
  AwingStory(
    titleEnglish: 'The Dog and the Chicken',
    titleAwing: 'Ngwûə ne ngɔ́bə',
    illustration: '🐕',
    sentences: [
      StorySentence(
        awing: 'Ngwûə a kə lê ndê.',
        english: 'The dog was sleeping at the house.',
      ),
      StorySentence(
        awing: 'Ngɔ́bə yǐə nchîndê.',
        english: 'The chicken came to the compound.',
      ),
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//       StorySentence(
//         awing: 'Ngɔ́bə a kə jíə ngəsáŋɔ́.',
//         english: 'The chicken was eating corn.',
//       ),
      StorySentence(
        awing: 'Ngwûə zó\'ə ngɔ́bə.',
        english: 'The dog heard the chicken.',
      ),
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//       StorySentence(
//         awing: 'Yə kə́ərə kə ngɔ́bə.',
//         english: 'It ran to the chicken.',
//       ),
      StorySentence(
        awing: 'Ngɔ́bə shɔ́ŋə atîə wíŋɔ́!',
        english: 'The chicken climbed a big tree!',
      ),
      StorySentence(
        // Session 52: pímə "see" was wrong (dict: believe). Replaced with náŋə "look at".
        awing: 'Ngwûə náŋə ngɔ́bə atîə.',
        english: 'The dog looked at the chicken in the tree.',
      ),
      StorySentence(
        awing: 'Ngwûə ŋwàŋə ndê, a lê ndèe.',
        english: 'The dog returned home and slept again.',
      ),
    ],
    vocabulary: [
      StoryVocabulary(awing: 'ngwûə', english: 'dog'),
      StoryVocabulary(awing: 'ngɔ́bə', english: 'chicken'),
      StoryVocabulary(awing: 'lê', english: 'sleep'),
      StoryVocabulary(awing: 'ngəsáŋɔ́', english: 'corn'),
      StoryVocabulary(awing: 'kə́ərə', english: 'run'),
      StoryVocabulary(awing: 'shɔ́ŋə', english: 'climb'),
      StoryVocabulary(awing: 'atîə', english: 'tree'),
      StoryVocabulary(awing: 'ŋwàŋə', english: 'return'),
    ],
    questions: [
      ComprehensionQuestion(
        question: 'What was the chicken eating?',
        correctAnswer: 'corn',
        options: ['corn', 'beans', 'bananas'],
      ),
      ComprehensionQuestion(
        question: 'Where did the chicken go to escape?',
        correctAnswer: 'A big tree',
        options: ['A big tree', 'The river', 'The farm'],
      ),
      ComprehensionQuestion(
        question: 'What did the dog do at the end?',
        correctAnswer: 'Went home and slept',
        options: ['Went home and slept', 'Caught the chicken', 'Climbed the tree'],
      ),
    ],
  ),
  AwingStory(
    titleEnglish: 'The Farmer and the Rain',
    titleAwing: 'Tǎ afoonə ne mbəŋə',
    illustration: '🌧️',
    sentences: [
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//       StorySentence(
//         awing: 'Tǎ ghɛnɔ́ afoonə kə̂ŋə.',
//         english: 'Father went to the farm early.',
//       ),
      StorySentence(
        awing: 'Yə tɔ̀ə ngəsáŋɔ́ ne azó\'ə.',
        english: 'He planted corn and yam.',
      ),
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//       StorySentence(
//         awing: 'Mɔ́numə a kə tɔnɔ́ sagɔ́.',
//         english: 'The sun was very hot.',
//       ),
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//       StorySentence(
//         awing: 'Yə nô nkǐə.',
//         english: 'He drank water.',
//       ),
      StorySentence(
        awing: 'Aləmə yǐə nəpóolə.',
        english: 'Clouds came in the sky.',
      ),
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//       StorySentence(
//         awing: 'Mbəŋə a kə pə̀ə wíŋɔ́!',
//         english: 'The rain fell heavily!',
//       ),
      StorySentence(
        awing: 'Tǎ wiŋɔ́, yə sóŋə: "Ashî\'nə sagɔ́!"',
        english: 'Father was happy, he said: "Very good!"',
      ),
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//       StorySentence(
//         awing: 'Mbəŋə ko pə nkǐə kə afoonə.',
//         english: 'The rain brought water to the farm.',
//       ),
    ],
    vocabulary: [
      StoryVocabulary(awing: 'afoonə', english: 'farm'),
      StoryVocabulary(awing: 'tɔ̀ə', english: 'plant'),
      StoryVocabulary(awing: 'mɔ́numə', english: 'sun'),
      StoryVocabulary(awing: 'tɔnɔ́', english: 'hot'),
      StoryVocabulary(awing: 'aləmə', english: 'cloud'),
      StoryVocabulary(awing: 'mbəŋə', english: 'rain'),
      StoryVocabulary(awing: 'wiŋɔ́', english: 'happy/big'),
      StoryVocabulary(awing: 'ashî\'nə', english: 'good'),
    ],
    questions: [
      ComprehensionQuestion(
        question: 'What did Father plant?',
        correctAnswer: 'Corn and yam',
        options: ['Corn and yam', 'Bananas', 'Cocoyam and beans'],
      ),
      ComprehensionQuestion(
        question: 'What happened when clouds came?',
        correctAnswer: 'It rained heavily',
        options: ['It rained heavily', 'The sun got hotter', 'Father went home'],
      ),
      ComprehensionQuestion(
        question: 'Why was Father happy?',
        correctAnswer: 'Rain watered the farm',
        options: ['Rain watered the farm', 'He found treasure', 'He finished planting'],
      ),
    ],
  ),
  AwingStory(
    titleEnglish: 'The Child at the Market',
    titleAwing: 'Mɔ́ŋkə kə mətéenɔ́',
    illustration: '🛍️',
    sentences: [
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//       StorySentence(
//         awing: 'Mǎ sóŋə: "Yîə, ghɛnɔ́ mətéenɔ́."',
//         english: 'Mother said: "Come, let\'s go to the market."',
//       ),
      StorySentence(
        awing: 'Mɔ́ŋkə wiŋɔ́ sagɔ́!',
        english: 'The child was very happy!',
      ),
    // FABRICATED — REMOVED by cleanup_fabricated_content.py
//       StorySentence(
        // Session 52: pímə "see" was wrong (dict: believe). Replaced with náŋə "look at".
//         awing: 'Yə náŋə amú\'ɔ́ ne lámɔ́sə.',
//         english: 'He looked at bananas and oranges.',
//       ),
      StorySentence(
        awing: 'Mǎ júnə ngəsáŋɔ́ ne ndzě.',
        english: 'Mother bought corn and vegetables.',
      ),
      StorySentence(
        awing: 'Mɔ́ŋkə kwɨ̌nə: "Mǎ, ko pə amú\'ɔ́!"',
        english: 'The child asked: "Mother, give me a banana!"',
      ),
      StorySentence(
        awing: 'Mǎ fê pə amú\'ɔ́ əmɔ́.',
        english: 'Mother gave him one banana.',
      ),
      StorySentence(
        awing: 'Mɔ́ŋkə jíə, yə sóŋə: "Mbɔ́ɔnɔ́, Mǎ!"',
        english: 'The child ate and said: "Thank you, Mother!"',
      ),
      StorySentence(
        awing: 'Yə ŋwàŋə ndê ne mǎ.',
        english: 'They returned home with Mother.',
      ),
    ],
    vocabulary: [
      StoryVocabulary(awing: 'mətéenɔ́', english: 'market'),
      StoryVocabulary(awing: 'amú\'ɔ́', english: 'banana'),
      StoryVocabulary(awing: 'lámɔ́sə', english: 'orange'),
      StoryVocabulary(awing: 'júnə', english: 'buy'),
      StoryVocabulary(awing: 'ndzě', english: 'vegetable'),
      StoryVocabulary(awing: 'kwɨ̌nə', english: 'ask'),
      StoryVocabulary(awing: 'Mbɔ́ɔnɔ́', english: 'thank you'),
      StoryVocabulary(awing: 'ŋwàŋə', english: 'return'),
    ],
    questions: [
      ComprehensionQuestion(
        question: 'Where did Mother and the child go?',
        correctAnswer: 'The market',
        options: ['The market', 'The farm', 'The school'],
      ),
      ComprehensionQuestion(
        question: 'What did the child ask for?',
        correctAnswer: 'A banana',
        options: ['A banana', 'An orange', 'Corn'],
      ),
      ComprehensionQuestion(
        question: 'What did the child say after eating?',
        correctAnswer: 'Thank you',
        options: ['Thank you', 'More please', 'Goodbye'],
      ),
    ],
  ),


  // Auto-extracted from Bible NT (non-biblical-feeling)
  // 1CO.13.5-7 — Story 1
  AwingStory(
    titleEnglish: 'Story 1',
    titleAwing: 'ńkě ntso yi',
    illustration: '📖',
    sentences: [
      StorySentence(
        awing: 'ńkě ntso yi féŋ nə́ túg pô, ńkě aŋwɛ túg pô, ńkě ndě zaŋkə̂ ńdzáŋə pô, ńkě təpɔŋ lɔʼkə̂ pô.',
        english: 'doesn’t behave itself inappropriately, doesn’t seek its own way, is not provoked, takes no account of evil;',
      ),
      StorySentence(
        awing: 'Akɔŋnə á kě kɔŋtə̂ əghâ páʼ təpɔŋə a chî nə́ pô, ḿbə́ ńkɔŋtə̂ əghâ páʼ ndə̌ŋdəŋə́ a chî nə́.',
        english: 'doesn’t rejoice in unrighteousness, but rejoices with the truth;',
      ),
      StorySentence(
        awing: 'Akɔŋnə á kě anu waamə̂ ḿbəənə̂ ḿmyaʼə̂ pô, a tə́gə atû nə́ mbimə́, nə́ akwaŋ ńtə́ ḿbyáabə, pó awaamə́ntə́əmə.',
        english: 'bears all things, believes all things, hopes all things, endures all things.',
      ),
    ],
    vocabulary: [
      StoryVocabulary(awing: 'ntso', english: 'date palm'),
      StoryVocabulary(awing: 'pô', english: 'us'),
      StoryVocabulary(awing: 'ndě', english: 'neck'),
      StoryVocabulary(awing: 'zaŋkə̂', english: 'light'),
      StoryVocabulary(awing: 'ńdzáŋə', english: 'color'),
      StoryVocabulary(awing: 'Akɔŋnə', english: 'love'),
    ],
    questions: [],
  ),
  // 1CO.15.35-37 — Story 2
  AwingStory(
    titleEnglish: 'Story 2',
    titleAwing: 'Lə́ ŋwu tsə̌',
    illustration: '📖',
    sentences: [
      StorySentence(
        awing: 'Lə́ ŋwu tsə̌ a chî təmbɔʼ a pítə ńgə́, “Təmbɔʼ pəkwû pə́ júmnə nəwû lə́ ə́lɛ́? Pó yǒ tíʼ túg lə́ zə́ənə́ ntê mbəəmə?”',
        english: 'But someone will say, “How are the dead raised?” and, “With what kind of body do they come?”',
      ),
      StorySentence(
        awing: 'Akəkóg! Ajú páʼ gho pǐ nə́ a kě sáʼə pô tə ńdéʼtə á kwûə.',
        english: 'You foolish one, that which you yourself sow is not made alive unless it dies.',
      ),
      StorySentence(
        awing: 'Ajú páʼ gho pǐ nə́ á ndəsê lə́ tsɔʼə mbi əjǐə. Əghâ tsə́ a pə́ pə́ mbi ngəsáŋ kəənə ajúmə ndaʼə.',
        english: 'That which you sow, you don’t sow the body that will be, but a bare grain, maybe of wheat, or of some other kind.',
      ),
    ],
    vocabulary: [
      StoryVocabulary(awing: 'Lə́', english: 'but'),
      StoryVocabulary(awing: 'a', english: 'he'),
      StoryVocabulary(awing: 'pítə', english: 'ask'),
      StoryVocabulary(awing: 'ńgə́', english: 'verb complement'),
      StoryVocabulary(awing: '“Təmbɔʼ', english: 'said'),
      StoryVocabulary(awing: 'pəkwû', english: 'dead'),
    ],
    questions: [],
  ),
  // 1TH.5.4-7 — Story 3
  AwingStory(
    titleEnglish: 'Story 3',
    titleAwing: 'Lə́ pɨ nə́',
    illustration: '📖',
    sentences: [
      StorySentence(
        awing: 'Lə́ pɨ nə́ pəlimə́ mə, pɨ kě lə́ á mə́m ndzəmə́ chî təmbɔʼ alě yəwə́ á yǒ ńgabkə̂ ńgyǐəə á mbô pəənə́ ándó ndzə̌ pô.',
        english: 'But you, brothers, aren’t in darkness, that the day should overtake you like a thief.',
      ),
      StorySentence(
        awing: 'Pɨ lə́ pɨ pə́ nkyaʼə, ḿbə́ pi pə́ əliʼ pə́ ŋwaʼ nə́. Pɛn kě lə́ á mbô nətúʼ pópə əliʼ pipə sɛ́n nə́ chî pô.',
        english: 'You are all children of light, and children of the day. We don’t belong to the night, nor to darkness,',
      ),
      StorySentence(
        awing: 'Lə́ələ́ á pə́ ńgə́ kɔ pɛn tə́ ńdê ándó pətsə́ pəənə. Pɛn tə́ ńjwə́ʼtə əliʼə́, atûə azɛ̂nə a kə́ ńdá əghâ atsəmə.',
        english: 'so then let’s not sleep, as the rest do, but let’s watch and be sober.',
      ),
      StorySentence(
        awing: 'Ńté ńgə́ pɨ pö lê nə́ pó lê lə́ á nətúʼə, pɨ pö pɛ́ nə́ məloʼ pó kə́ ḿbɛ́ɛlə lə́ á nətúʼə.',
        english: 'For those who sleep, sleep in the night; and those who are drunk are drunk in the night.',
      ),
    ],
    vocabulary: [
      StoryVocabulary(awing: 'Lə́', english: 'but'),
      StoryVocabulary(awing: 'pəlimə́', english: 'brothers'),
      StoryVocabulary(awing: 'mə', english: 'my'),
      StoryVocabulary(awing: 'kě', english: 'marker of negation'),
      StoryVocabulary(awing: 'á', english: 'he'),
      StoryVocabulary(awing: 'ndzəmə́', english: 'back'),
    ],
    questions: [],
  ),
  // 1TI.2.10-13 — Story 4
  AwingStory(
    titleEnglish: 'Story 4',
    titleAwing: 'lə́ pó lɔgə̂',
    illustration: '📖',
    sentences: [
      StorySentence(
        awing: 'lə́ pó lɔgə̂ pə́ məfaʼ mimə əshîʼnə ándó məmɔ́b məshumə́, ándó pəngyě pó sóŋ nə́ ńgə́ pó jî Əsê.',
        english: 'but (which becomes women professing godliness) with good works.',
      ),
      StorySentence(
        awing: 'Məngyě ntsəmə a naʼ nə́ ntso yí ńkə́ ńdzóʼnə əghâ páʼ a tə́ nə́ ńdzéʼə.',
        english: 'Let a woman learn in quietness with full submission.',
      ),
      StorySentence(
        awing: 'Maŋ kě əsa yitsə̌ á mbô məngyě fɛ̂ ńgə́ a zéʼkə kɨ ńtúg mətəənə á ndú mbyâŋnə pô, pó shib ńnaʼ nə́ ntso əghóobə́.',
        english: 'But I don’t permit a woman to teach, nor to exercise authority over a man, but to be in quietness.',
      ),
      StorySentence(
        awing: 'Ńté ńgə́ pə́ nə ḿbeg ńtsoŋkə̂ lə́ Adam záʼ ḿbɔŋə̂ tsoŋkə̂ Ifə.',
        english: 'For Adam was first formed, then Eve.',
      ),
    ],
    vocabulary: [
      StoryVocabulary(awing: 'lə́', english: 'but'),
      StoryVocabulary(awing: 'pó', english: 'us'),
      StoryVocabulary(awing: 'məfaʼ', english: 'works'),
      StoryVocabulary(awing: 'əshîʼnə', english: 'good'),
      StoryVocabulary(awing: 'ándó', english: 'approximately'),
      StoryVocabulary(awing: 'məshumə́', english: 'pearls'),
    ],
    questions: [],
  ),
  // 1TI.5.1-3 — Story 5
  AwingStory(
    titleEnglish: 'Story 5',
    titleAwing: 'Kɔ gho sáʼə',
    illustration: '📖',
    sentences: [
      StorySentence(
        awing: 'Kɔ gho sáʼə ntəŋkaŋə́, tséebə mbô yə́ ándó tǎ əgho. Túg nkaŋŋwu yi mbyâŋnə ándó pəlim pô,',
        english: 'Don’t rebuke an older man, but exhort him as a father; the younger men as brothers;',
      ),
      StorySentence(
        awing: 'ńtúg pətəkaŋ pə́ pəngyě ándó pəmǎ pô, ńkə́ ńtúg nkaŋŋwu pəngyě ándó pəlim pô pipə́ pəngyě tə kɔntə yitsə̌.',
        english: 'the elder women as mothers; the younger as sisters, in all purity.',
      ),
      StorySentence(
        awing: 'Pəkogə́ ándó pó pə́ nə́ chigə pəkog gho nɨd ngóʼkə nə́ pó.',
        english: 'Honor widows who are widows indeed.',
      ),
    ],
    vocabulary: [
      StoryVocabulary(awing: 'gho', english: 'you'),
      StoryVocabulary(awing: 'tséebə', english: 'talk'),
      StoryVocabulary(awing: 'mbô', english: 'people of'),
      StoryVocabulary(awing: 'ándó', english: 'approximately'),
      StoryVocabulary(awing: 'tǎ', english: 'five'),
      StoryVocabulary(awing: 'əgho', english: 'possessive pronoun yours'),
    ],
    questions: [],
  ),
  // 2CO.2.6-8 — Story 6
  AwingStory(
    titleEnglish: 'Story 6',
    titleAwing: 'Atsáŋ jɨ páʼ',
    illustration: '📖',
    sentences: [
      StorySentence(
        awing: 'Atsáŋ jɨ páʼ ŋwu yi nɨ́ nə́ a fɛ̂ nə́ lə́, á koʼnə̂ á mbô ńté ŋwu zə̂.',
        english: 'This punishment which was inflicted by the many is sufficient for such a one;',
      ),
      StorySentence(
        awing: 'Nə́ pə əghâ nə́ pɨ tíʼ ńchî lə́ á mə́ ləgnə̂ təpɔŋ əyǐ ə́ tû pwɔ́dkə ntɨ́ əyə́, ńjî ńgə́ kɔ a tə́ fɨnə̂ tə́shúnə́.',
        english: 'so that on the contrary you should rather forgive him and comfort him, lest by any means such a one should be swallowed up with his excessive sorrow.',
      ),
      StorySentence(
        awing: 'Lə́ á pə́ ńgə́ maŋ póʼ mbô nə́ pɨ ńgə́ nə́ ghɛlə̂ a jî ńgə́ pɨ chígə́ ńkɔŋə̂ yə́.',
        english: 'Therefore I beg you to confirm your love toward him.',
      ),
    ],
    vocabulary: [
      StoryVocabulary(awing: 'nɨ́', english: 'many'),
      StoryVocabulary(awing: 'a', english: 'he'),
      StoryVocabulary(awing: 'lə́', english: 'but'),
      StoryVocabulary(awing: 'mbô', english: 'people of'),
      StoryVocabulary(awing: 'əghâ', english: 'season'),
      StoryVocabulary(awing: 'mə́', english: 'my'),
    ],
    questions: [],
  ),
];

/// ============================================================================
/// SCREENS
/// ============================================================================

class StoriesScreen extends StatelessWidget {
  const StoriesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Awing Stories'),
          backgroundColor: Colors.teal,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Stories', icon: Icon(Icons.library_books)),
              Tab(text: 'Vocabulary', icon: Icon(Icons.list)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            StoryListView(),
            StoryVocabularyView(),
          ],
        ),
      ),
    );
  }
}

class StoryListView extends StatefulWidget {
  const StoryListView({Key? key}) : super(key: key);

  @override
  State<StoryListView> createState() => _StoryListViewState();
}

class _StoryListViewState extends State<StoryListView> {
  late List<AwingStory> _stories = List.from(awingStories);

  void _markStoryComplete(int index) {
    setState(() {
      _stories[index].isCompleted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _stories.length,
      itemBuilder: (context, index) {
        final story = _stories[index];
        return StoryCard(
          story: story,
          onTap: () async {
            final completed = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => StoryViewerScreen(story: story),
              ),
            );
            if (completed == true) {
              _markStoryComplete(index);
            }
          },
        );
      },
    );
  }
}

class StoryCard extends StatelessWidget {
  final AwingStory story;
  final VoidCallback onTap;

  const StoryCard({
    Key? key,
    required this.story,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.teal.shade100,
                Colors.cyan.shade100,
              ],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                story.illustration,
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story.titleEnglish,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      story.titleAwing,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.teal,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${story.sentences.length} sentences',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              if (story.isCompleted)
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 24,
                  ),
                )
              else
                const Icon(
                  Icons.arrow_forward,
                  color: Colors.teal,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class StoryViewerScreen extends StatefulWidget {
  final AwingStory story;

  const StoryViewerScreen({
    Key? key,
    required this.story,
  }) : super(key: key);

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  final PronunciationService _pronunciation = PronunciationService();
  int _currentSentenceIndex = 0;
  bool _showEnglish = false;
  bool _storyCompleted = false;

  @override
  void initState() {
    super.initState();
    _pronunciation.init();
    _pronunciation.setVoiceForLevel('expert');
  }

  void _nextSentence() {
    if (_currentSentenceIndex < widget.story.sentences.length - 1) {
      setState(() {
        _currentSentenceIndex++;
        _showEnglish = false;
      });
    } else {
      setState(() {
        _storyCompleted = true;
      });
    }
  }

  void _prevSentence() {
    if (_currentSentenceIndex > 0) {
      setState(() {
        _currentSentenceIndex--;
        _showEnglish = false;
      });
    }
  }

  Future<void> _speakSentence() async {
    final sentence = widget.story.sentences[_currentSentenceIndex];
    await _pronunciation.speakAwing(sentence.awing);
  }

  @override
  Widget build(BuildContext context) {
    if (_storyCompleted) {
      return StoryQuizScreen(
        story: widget.story,
        onComplete: () {
          context.read<ProgressService>().completeLesson(
            'story_${widget.story.titleEnglish.toLowerCase().replaceAll(' ', '_')}',
          );
          Navigator.pop(context, true);
        },
      );
    }

    final sentence = widget.story.sentences[_currentSentenceIndex];
    final progress = (_currentSentenceIndex + 1) / widget.story.sentences.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.story.titleEnglish),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.teal.shade50,
              Colors.cyan.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Large illustration area — per-sentence image from PAD pack
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: PackImage.path(
                    packPath: ImageService.storyPackPath(sentence.awing),
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    placeholder: Container(
                      height: 180,
                      color: Colors.teal.shade100,
                    ),
                    errorWidget: Container(
                      height: 180,
                      color: Colors.teal.shade100,
                      alignment: Alignment.center,
                      child: Text(
                        widget.story.illustration,
                        style: const TextStyle(fontSize: 72),
                      ),
                    ),
                  ),
                ),
              ),
              // Sentence card
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.white, Colors.cyan.shade50],
                          ),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Awing sentence (always visible)
                            Text(
                              sentence.awing,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                                height: 1.6,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            // English translation (tap to reveal)
                            if (_showEnglish)
                              Text(
                                sentence.english,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.teal,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              )
                            else
                              Text(
                                'Tap to reveal English',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            const SizedBox(height: 32),
                            // Speaker button
                            FloatingActionButton(
                              onPressed: _speakSentence,
                              backgroundColor: Colors.teal,
                              child: const Icon(Icons.volume_up),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Progress dots
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.story.sentences.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index <= _currentSentenceIndex
                            ? Colors.teal
                            : Colors.grey.shade300,
                      ),
                    ),
                  ),
                ),
              ),
              // Navigation buttons
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _currentSentenceIndex > 0 ? _prevSentence : null,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _showEnglish = !_showEnglish);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
                      ),
                      child: Text(
                        _showEnglish ? 'Hide English' : 'Show English',
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _nextSentence,
                      label: const Text('Next'),
                      icon: const Icon(Icons.arrow_forward),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pronunciation.dispose();
    super.dispose();
  }
}

class StoryQuizScreen extends StatefulWidget {
  final AwingStory story;
  final VoidCallback onComplete;

  const StoryQuizScreen({
    Key? key,
    required this.story,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<StoryQuizScreen> createState() => _StoryQuizScreenState();
}

class _StoryQuizScreenState extends State<StoryQuizScreen> {
  int _currentQuestion = 0;
  int _score = 0;
  bool _answered = false;
  String? _selectedAnswer;
  bool _quizCompleted = false;

  void _selectAnswer(String answer) {
    if (_answered) return;

    final i