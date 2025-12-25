enum PlantType {
  corn(18.0, 30.0),    // mısır
  tomato(20.0, 30.0),  // domates
  apple(15.0, 25.0),   // elma
  grape(15.0, 35.0);   // üzüm

  final double minTemp;
  final double maxTemp;

  const PlantType(this.minTemp, this.maxTemp);
}
