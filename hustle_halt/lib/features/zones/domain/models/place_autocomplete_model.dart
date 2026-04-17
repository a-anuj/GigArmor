class PlaceAutocompleteSuggestion {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;
  final List<PlaceMatch>? matches;

  const PlaceAutocompleteSuggestion({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
    this.matches,
  });

  factory PlaceAutocompleteSuggestion.fromJson(Map<String, dynamic> json) {
    final prediction = json['placePrediction'];
    final structured = prediction['structuredFormat'];
    
    return PlaceAutocompleteSuggestion(
      placeId: prediction['placeId'] as String,
      description: prediction['text']['text'] as String,
      mainText: structured['mainText']['text'] as String,
      secondaryText: (structured['secondaryText']?['text'] as String?) ?? '',
      matches: (prediction['text']['matches'] as List?)
          ?.map((m) => PlaceMatch.fromJson(m))
          .toList(),
    );
  }
}

class PlaceMatch {
  final int offset;
  final int length;

  const PlaceMatch({required this.offset, required this.length});

  factory PlaceMatch.fromJson(Map<String, dynamic> json) {
    return PlaceMatch(
      offset: json['offset'] as int,
      length: json['length'] as int,
    );
  }
}

class PlaceDetails {
  final String placeId;
  final double latitude;
  final double longitude;
  final String address;

  const PlaceDetails({
    required this.placeId,
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    return PlaceDetails(
      placeId: json['id'] as String,
      latitude: (json['location']['latitude'] as num).toDouble(),
      longitude: (json['location']['longitude'] as num).toDouble(),
      address: json['formattedAddress'] as String,
    );
  }
}
