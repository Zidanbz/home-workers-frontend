class Availability {
  final String day;
  final List<String> slots;

  Availability({required this.day, required this.slots});

  factory Availability.fromJson(Map<String, dynamic> json) {
    return Availability(
      day: json['day'],
      slots: List<String>.from(json['slots']),
    );
  }
}
