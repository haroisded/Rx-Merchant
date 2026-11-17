import '../../../core/numbers/flt.dart';

/// Valuation rates inside the ledger keep 9 decimals, so an average such as
/// 113.333… is not truncated (00-overview 6.3).
const ratePrecision = 9;

/// How an item's stock is valued (STK-R29). Serialised items always use
/// [serial] (STK-R32).
enum ValuationMethod {
  fifo,
  movingAverage,
  serial;

  /// From `item.valuation_method` or Stock Settings: 'FIFO' or 'Moving
  /// Average'.
  static ValuationMethod fromSetting(String? value) =>
      value == 'Moving Average' ? movingAverage : fifo;
}

/// The running stock of one item in one warehouse while its ledger is
/// replayed (STK-R30 to R32). Quantities are in the Stock UOM.
class StockBalance {
  StockBalance(
    this.method, {
    required this.precision,
    this.rounding = RoundingMethod.bankers,
    List<List<double>>? queue,
  }) : queue = queue ?? [];

  final ValuationMethod method;

  /// Currency Precision: stock values are rounded to it.
  final int precision;
  final RoundingMethod rounding;

  double qty = 0;

  /// Valuation rate per Stock UOM, 9 decimals.
  double rate = 0;

  /// Stock value, rounded to [precision].
  double value = 0;

  /// FIFO layers `[qty, rate]`, oldest first. Empty for the other methods.
  final List<List<double>> queue;

  double _q(double v) => flt(v, ratePrecision, rounding);

  /// Stock coming in at [incomingRate]. A serialised receipt passes the sum
  /// of its units' own rates as [serialValue].
  void receive(double inQty, double incomingRate, {double? serialValue}) {
    switch (method) {
      case ValuationMethod.fifo:
        _addLayer(inQty, incomingRate);
        _fromQueue(incomingRate);
      case ValuationMethod.movingAverage:
        // STK-R31; with no stock (or negative stock) on hand the incoming
        // rate becomes the rate, as in ERPNext.
        final newQty = _q(qty + inQty);
        if (qty <= 0 || newQty <= 0) {
          rate = incomingRate;
        } else {
          rate = flt(
            (qty * rate + inQty * incomingRate) / newQty,
            ratePrecision,
            rounding,
          );
        }
        qty = newQty;
        value = flt(qty * rate, precision, rounding);
      case ValuationMethod.serial:
        _bySerial(inQty, serialValue ?? inQty * incomingRate);
    }
  }

  /// Stock going out. A serialised issue passes the sum of its units' rates
  /// as [serialValue]. Units beyond the stock on hand are costed at the last
  /// rate, or [fallbackRate] when there is none (STK-R34).
  void issue(double outQty, {double? serialValue, double fallbackRate = 0}) {
    switch (method) {
      case ValuationMethod.fifo:
        _removeLayers(outQty, rate != 0 ? rate : fallbackRate);
        _fromQueue(fallbackRate);
      case ValuationMethod.movingAverage:
        if (rate == 0) rate = fallbackRate;
        qty = _q(qty - outQty);
        value = flt(qty * rate, precision, rounding);
      case ValuationMethod.serial:
        _bySerial(-outQty, -(serialValue ?? outQty * rate));
    }
  }

  /// A Stock Reconciliation sets the balance outright: [newQty] at
  /// [newRate]; FIFO keeps one layer (STK-R42).
  void reset(double newQty, double newRate) {
    qty = newQty;
    rate = newRate;
    queue
      ..clear()
      ..addAll([
        if (newQty != 0) [newQty, newRate],
      ]);
    value = flt(newQty * newRate, precision, rounding);
  }

  void _bySerial(double change, double valueChange) {
    qty = _q(qty + change);
    value = flt(value + valueChange, precision, rounding);
    if (qty > 0) rate = flt(value / qty, ratePrecision, rounding);
  }

  void _fromQueue(double fallbackRate) {
    qty = _q(queue.fold(0.0, (s, l) => s + l[0]));
    value = flt(
      queue.fold(0.0, (s, l) => s + l[0] * l[1]),
      precision,
      rounding,
    );
    if (qty != 0) {
      rate = flt(value / qty, ratePrecision, rounding);
    } else if (rate == 0) {
      rate = fallbackRate;
    }
  }

  // ERPNext's FIFOValuation.add_stock: a negative last layer is settled
  // first and the remainder takes the incoming rate.
  void _addLayer(double inQty, double inRate) {
    if (queue.isEmpty) {
      queue.add([inQty, inRate]);
    } else if (queue.last[1] == inRate) {
      queue.last[0] = _q(queue.last[0] + inQty);
    } else if (queue.last[0] > 0) {
      queue.add([inQty, inRate]);
    } else {
      final left = _q(queue.last[0] + inQty);
      queue.last
        ..[0] = left
        ..[1] = left > 0 ? inRate : queue.last[1];
    }
    if (queue.last[0] == 0) queue.removeLast();
  }

  // ERPNext's FIFOValuation.remove_stock: oldest layer first; once the queue
  // is empty, what is still owed stays as a negative layer at the last rate.
  void _removeLayers(double outQty, double lastRate) {
    var owed = outQty;
    var rateNow = lastRate;
    while (owed > 0) {
      if (queue.isEmpty) {
        queue.add([-owed, rateNow]);
        return;
      }
      final first = queue.first;
      rateNow = first[1];
      if (owed >= first[0]) {
        owed = _q(owed - first[0]);
        queue.removeAt(0);
      } else {
        first[0] = _q(first[0] - owed);
        owed = 0;
      }
    }
  }
}
