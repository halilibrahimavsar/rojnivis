import 'dart:math';

class QuickQuestionsRepository {
  static const Map<String, List<String>> categorizedQuestions = {
    'gratitude': [
      "Bugün seni ne mutlu etti?",
      "Bugün kime teşekkür etmek istersin?",
      "Bugün yediğin en güzel şey neydi?",
      "Bugün yaşadığın en huzurlu an hangisiydi?",
      "Şu an hayatında minnettar olduğun 3 şey nedir?",
    ],
    'growth': [
      "Bugün öğrendiğin yeni bir şey var mı?",
      "Kendinle gurur duyduğun bir anı anlat.",
      "Bugün seni en çok ne zorladı ve ondan ne öğrendin?",
      "Yarın için neyi dört gözle bekliyorsun?",
      "Bugün konfor alanından çıktığın bir an oldu mu?",
    ],
    'philosophical': [
      "Bugün seni en çok ne düşündürdü?",
      "Hayatındaki en büyük motivasyon kaynağın nedir?",
      "Kendini 5 yıl sonra nerede ve nasıl görüyorsun?",
      "Senin için 'başarı' tam olarak ne anlama geliyor?",
      "Bugün dünyaya bıraktığın iz neydi?",
    ],
    'mood': [
      "Şu anki ruh halini tek kelimeyle nasıl tanımlarsın?",
      "Hangi şarkı bugünkü modunu yansıtıyor?",
      "Eğer bugünü baştan yaşasaydın neyi değiştirirdin?",
      "Bugün seni en çok güldüren şey neydi?",
      "Şu an hissettiğin en baskın duygu nedir?",
    ],
    'action': [
      "Bugün hedeflerine bir adım daha yaklaşmak için ne yaptın?",
      "Yarın daha verimli olmak için ne yapabilirsin?",
      "Bugün ertelediğin bir şeyi neden erteledin?",
      "Şu an hemen yapabileceğin en küçük iyilik nedir?",
    ],
  };

  static List<String> get allQuestions =>
      categorizedQuestions.values.expand((x) => x).toList();

  static String getRandomQuestion() {
    final questions = allQuestions;
    return questions[Random().nextInt(questions.length)];
  }

  static String getRandomFromCategory(String category) {
    final questions = categorizedQuestions[category] ?? allQuestions;
    return questions[Random().nextInt(questions.length)];
  }

  /// AI Foundation: In the future, this can be used to recommend questions
  /// based on user goals, behavior, and personality profile.
  static List<String> getRecommendationsForUser({
    required List<String> userGoals,
    required String personalityType,
  }) {
    // This is a prototype implementation.
    // AI service would typically call a model here.
    if (userGoals.contains('success')) {
      return categorizedQuestions['growth']! + categorizedQuestions['action']!;
    }
    return allQuestions;
  }
}
