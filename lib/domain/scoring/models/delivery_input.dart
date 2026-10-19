import '../enums/delivery_type.dart';
import 'wicket.dart';

class DeliveryInput {
  const DeliveryInput({
    required this.deliveryType,
    this.batterRuns = 0,
    this.byeRuns = 0,
    this.legByeRuns = 0,
    this.wideRuns = 0,
    this.noBallRuns = 0,
    this.wicket,
  });

  final DeliveryType deliveryType;
  final int batterRuns;
  final int byeRuns;
  final int legByeRuns;
  final int wideRuns;
  final int noBallRuns;
  final Wicket? wicket;
}
