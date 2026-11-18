import 'dart:ui';

import '../widgets/cup/drink_art.dart';
import '../widgets/cup/drink_colors.dart';

/// Money is whole cents, formatted only at the edge.
String money(int cents) => cents < 0 ? '-${_money(-cents)}' : _money(cents);

/// "+\$0.50" or "-\$0.40", for what an option changes.
String moneyDelta(int cents) => cents < 0 ? money(cents) : '+${money(cents)}';

String _money(int cents) => '\$${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';

enum Category { hot, iced, tea }

enum CupSize {
  small('S', 'Small', -40, 0.86),
  medium('M', 'Medium', 0, 1.0),
  large('L', 'Large', 50, 1.12);

  const CupSize(this.short, this.label, this.extra, this.scale);
  final String short, label;
  /// Against the listed price, which is for a medium.
  final int extra;

  /// How much bigger the glass is drawn.
  final double scale;
}

enum Temp { hot, iced }

enum Milk {
  whole('Whole', 0, DrinkColors.wholeMilk),
  oat('Oat', 60, DrinkColors.oatMilk),
  almond('Almond', 60, DrinkColors.almondMilk),
  none('No milk', 0, DrinkColors.wholeMilk);

  const Milk(this.label, this.extra, this.color);
  final String label;
  final int extra;
  final Color color;
}

class Drink {
  const Drink({
    required this.id,
    required this.name,
    required this.category,
    required this.tagline,
    required this.description,
    required this.price,
    required this.rating,
    required this.kcal,
    required this.minutes,
    required this.base,
    required this.baseAmount,
    required this.milk,
    required this.milkAmount,
    required this.foam,
    required this.level,
    required this.art,
    required this.temps,
    this.crema = 0,
  });

  final String id, name, tagline, description;
  final Category category;
  final int price, kcal, minutes;
  final double rating;
  final String base;
  final double baseAmount, milkAmount, foam, level, crema;
  final Milk milk;
  final LatteArt art;
  final List<Temp> temps;

  /// A straight shot takes no milk.
  bool get takesMilk => id != 'espresso';

  Options get defaults => Options(temp: temps.first, milk: milk);

  factory Drink.fromJson(Map<String, Object?> j) => Drink(
        id: j['id'] as String,
        name: j['name'] as String,
        category: Category.values.byName(j['category'] as String),
        tagline: j['tagline'] as String,
        description: j['description'] as String,
        price: j['price'] as int,
        rating: (j['rating'] as num).toDouble(),
        kcal: j['kcal'] as int,
        minutes: j['minutes'] as int,
        base: j['base'] as String,
        baseAmount: (j['baseAmount'] as num).toDouble(),
        milk: Milk.values.byName(j['milk'] as String),
        milkAmount: (j['milkAmount'] as num).toDouble(),
        foam: (j['foam'] as num).toDouble(),
        level: (j['level'] as num).toDouble(),
        art: LatteArt.values.byName(j['art'] as String),
        temps: [for (final t in j['temps'] as List) Temp.values.byName(t as String)],
        crema: (j['crema'] as num?)?.toDouble() ?? 0,
      );

  static const _bases = {
    'espresso': DrinkColors.espresso,
    'coldBrew': DrinkColors.coldBrew,
    'matcha': DrinkColors.matcha,
    'chocolate': DrinkColors.chocolate,
    'chai': DrinkColors.chai,
  };

  /// The drink as poured with [o]: the cup redraws from this alone.
  DrinkArt pour(Options o) {
    final iced = o.temp == Temp.iced;
    final noMilk = o.milk == Milk.none;
    final shots = 1 + (o.shots - 1) * 0.5;
    return DrinkArt(
      baseColor: _bases[base] ?? DrinkColors.espresso,
      base: baseAmount * shots,
      milkColor: o.milk.color,
      milk: noMilk ? 0 : (milkAmount == 0 ? 0.18 : milkAmount),
      foam: iced || noMilk ? 0 : foam,
      level: iced ? (level * 0.95).clamp(0.4, 0.9) : (level + (o.shots - 1) * 0.04).clamp(0.2, 0.92),
      hot: iced ? 0 : 1,
      iced: iced ? 1 : 0,
      art: iced || noMilk ? LatteArt.none : art,
      artAmount: 1,
      crema: noMilk && !iced ? crema : 0,
    );
  }

  int priceWith(Options o) =>
      price + o.size.extra + (o.milk == milk ? 0 : o.milk.extra) + (o.shots - 1) * 80;
}

/// How someone wants their drink.
class Options {
  const Options({
    this.size = CupSize.medium,
    this.temp = Temp.hot,
    this.milk = Milk.whole,
    this.shots = 1,
    this.sweetness = 0,
  });

  final CupSize size;
  final Temp temp;
  final Milk milk;

  /// 1 to 3.
  final int shots;

  /// 0 none to 3 extra sweet.
  final int sweetness;

  static const sweetWords = ['Not sweet', 'A little', 'Sweet', 'Extra sweet'];

  Options copyWith({CupSize? size, Temp? temp, Milk? milk, int? shots, int? sweetness}) => Options(
        size: size ?? this.size,
        temp: temp ?? this.temp,
        milk: milk ?? this.milk,
        shots: shots ?? this.shots,
        sweetness: sweetness ?? this.sweetness,
      );

  /// "Large · Iced · Oat · 2 shots"
  String get summary => [
        size.label,
        temp == Temp.iced ? 'Iced' : 'Hot',
        if (milk != Milk.none) milk.label else 'No milk',
        '$shots ${shots == 1 ? 'shot' : 'shots'}',
        if (sweetness > 0) sweetWords[sweetness],
      ].join(' · ');

  Map<String, Object?> toJson() =>
      {'size': size.name, 'temp': temp.name, 'milk': milk.name, 'shots': shots, 'sweetness': sweetness};

  factory Options.fromJson(Map<String, Object?> j) => Options(
        size: CupSize.values.byName(j['size'] as String),
        temp: Temp.values.byName(j['temp'] as String),
        milk: Milk.values.byName(j['milk'] as String),
        shots: j['shots'] as int,
        sweetness: j['sweetness'] as int,
      );

  @override
  bool operator ==(Object other) =>
      other is Options &&
      other.size == size &&
      other.temp == temp &&
      other.milk == milk &&
      other.shots == shots &&
      other.sweetness == sweetness;

  @override
  int get hashCode => Object.hash(size, temp, milk, shots, sweetness);
}

class BagLine {
  const BagLine({required this.id, required this.drinkId, required this.options, this.qty = 1});

  final String id, drinkId;
  final Options options;
  final int qty;

  BagLine copyWith({int? qty}) => BagLine(id: id, drinkId: drinkId, options: options, qty: qty ?? this.qty);

  Map<String, Object?> toJson() => {'id': id, 'drinkId': drinkId, 'options': options.toJson(), 'qty': qty};

  factory BagLine.fromJson(Map<String, Object?> j) => BagLine(
        id: j['id'] as String,
        drinkId: j['drinkId'] as String,
        options: Options.fromJson(j['options'] as Map<String, Object?>),
        qty: j['qty'] as int,
      );
}

enum Pickup {
  now('As soon as it is ready', 'ASAP', 0),
  in15('In 15 minutes', '15 min', 15),
  in30('In 30 minutes', '30 min', 30);

  const Pickup(this.label, this.short, this.minutes);
  final String label, short;
  final int minutes;
}

enum Stage {
  received('Order received', 'We have your order'),
  grinding('Grinding', 'Fresh beans going in'),
  brewing('Brewing', 'Pulling your shots'),
  ready('Ready', 'Waiting for you at the bar');

  const Stage(this.title, this.detail);
  final String title, detail;
}

class Order {
  const Order({
    required this.id,
    required this.number,
    required this.placedAt,
    required this.lines,
    required this.total,
    required this.pickup,
    this.collected = false,
  });

  final String id;
  final int number;
  final DateTime placedAt;
  final List<BagLine> lines;
  final int total;
  final Pickup pickup;
  final bool collected;

  int get cups => lines.fold(0, (n, l) => n + l.qty);

  Order copyWith({bool? collected}) => Order(
        id: id,
        number: number,
        placedAt: placedAt,
        lines: lines,
        total: total,
        pickup: pickup,
        collected: collected ?? this.collected,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'number': number,
        'placedAt': placedAt.toIso8601String(),
        'lines': [for (final l in lines) l.toJson()],
        'total': total,
        'pickup': pickup.name,
        'collected': collected,
      };

  factory Order.fromJson(Map<String, Object?> j) => Order(
        id: j['id'] as String,
        number: j['number'] as int,
        placedAt: DateTime.parse(j['placedAt'] as String),
        lines: [for (final l in j['lines'] as List) BagLine.fromJson(l as Map<String, Object?>)],
        total: j['total'] as int,
        pickup: Pickup.values.byName(j['pickup'] as String),
        collected: j['collected'] as bool? ?? false,
      );
}

/// The signed-in person and their card.
class Profile {
  const Profile({required this.name, required this.email, required this.store, required this.stamps, this.avatar});

  final String name, email, store;
  final String? avatar;

  /// Stamps on the card before any order placed in the app.
  final int stamps;

  String get firstName => name.split(' ').first;

  factory Profile.fromJson(Map<String, Object?> j) => Profile(
        name: j['name'] as String,
        email: j['email'] as String,
        store: j['store'] as String,
        stamps: j['stamps'] as int,
        avatar: j['avatar'] as String?,
      );
}
