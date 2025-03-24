import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class Hospital {
  Hospital({
    required this.name,
    required this.location,
  });

  final String name;
  final GeoPoint location;
}

class HospitalService {
  Future<List<Hospital>> getHospitals() async {
    String overpassUrl =
        "https://overpass-api.de/api/interpreter?data=[out:json];node[amenity=hospital](6.0,79.5,10.0,82.0);out;";

    final response = await http.get(Uri.parse(overpassUrl));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<Hospital> hospitals = [];

      for (var element in data["elements"]) {
        if (element["lat"] != null && element["lon"] != null) {
          hospitals.add(Hospital(
            name: element["tags"]["name"] ?? "Unknown Hospital",
            location: GeoPoint(
              element["lat"],
              element["lon"],
            ),
          ));
        }
      }
      return hospitals;
    } else {
      throw Exception("Failed to fetch hospitals from OSM");
    }
  }
}