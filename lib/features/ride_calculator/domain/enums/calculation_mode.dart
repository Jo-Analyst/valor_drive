/// Define a fonte para determinação da distância percorrida na corrida.
enum CalculationMode {
  /// Distância calculada em tempo real via sinal de GPS.
  gps,

  /// Média de quilômetros informada manualmente pelo usuário.
  manual,
}
