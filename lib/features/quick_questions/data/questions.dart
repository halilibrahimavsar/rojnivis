class QuickQuestionsRepository {
  static List<String> questions = [
    "Bugün seni ne mutlu etti?",
    "Bugün öğrendiğin yeni bir şey var mı?",
    "Bugün seni en çok ne zorladı?",
    "Yarın için neyi dört gözle bekliyorsun?",
    "Şu anki ruh halini tek kelimeyle nasıl tanımlarsın?",
    "Bugün kime teşekkür etmek istersin?",
    "Kendinle gurur duyduğun bir anı anlat.",
    "Bugün yediğin en güzel şey neydi?",
    "Hangi şarkı bugünkü modunu yansıtıyor?",
    "Eğer bugünü baştan yaşasaydın neyi değiştirirdin?",
  ];

  static String getRandomQuestion() {
    return (questions..shuffle()).first;
  }
}
