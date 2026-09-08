enum ClientTextScale {
  standard(1),
  large(1.15),
  extraLarge(1.3);

  const ClientTextScale(this.factor);

  final double factor;
}
