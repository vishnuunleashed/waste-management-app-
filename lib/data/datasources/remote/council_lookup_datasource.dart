import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import '../../../core/error/failure.dart';
import '../../../domain/entities/council.dart';

abstract class CouncilLookupDataSource {
  /// Resolves a UK postcode to its local authority via postcodes.io
  /// (free, no API key required).
  Future<Council> resolveUkCouncilFromPostcode(String postcode);

  /// The 31 Irish local authorities, bundled as static reference data since
  /// no free postcode/Eircode-to-council lookup API exists for Ireland.
  Future<List<Council>> irelandCouncils();

  /// The 361 UK local authorities that actually run kerbside bin
  /// collection (district/borough/unitary/metropolitan/London boroughs
  /// and the Scottish/Welsh/NI unitary equivalents) — bundled as static
  /// reference data, sourced from mySociety's uk_local_authority_names_and
  /// _codes dataset. Deliberately excludes English counties (the district
  /// tier collects bins, not the county) and combined/strategic
  /// authorities (transport/policing bodies, not bin collection).
  Future<List<Council>> ukCouncils();
}

class CouncilLookupDataSourceImpl implements CouncilLookupDataSource {
  final http.Client client;

  CouncilLookupDataSourceImpl({http.Client? client}) : client = client ?? http.Client();

  @override
  Future<Council> resolveUkCouncilFromPostcode(String postcode) async {
    final normalized = postcode.trim();
    if (normalized.isEmpty) {
      throw const ServerFailure('Enter a postcode to look up your council.');
    }

    final uri = Uri.https('api.postcodes.io', '/postcodes/$normalized');
    final http.Response response;
    try {
      response = await client.get(uri);
    } catch (e) {
      throw ServerFailure('Could not reach postcode lookup service: $e');
    }

    if (response.statusCode == 404) {
      throw ServerFailure('"$normalized" is not a recognised UK postcode.');
    }
    if (response.statusCode != 200) {
      throw ServerFailure(
        'Postcode lookup failed (${response.statusCode})',
        code: response.statusCode.toString(),
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final result = body['result'] as Map<String, dynamic>?;
    final adminDistrict = result?['admin_district'] as String?;
    if (adminDistrict == null || adminDistrict.isEmpty) {
      throw const ServerFailure('Could not determine a council for that postcode.');
    }

    return Council(
      id: slugifyCouncilName(adminDistrict),
      name: adminDistrict,
      country: Country.uk,
    );
  }

  @override
  Future<List<Council>> irelandCouncils() async {
    final raw = await rootBundle.loadString('assets/data/ireland_councils.json');
    final names = (jsonDecode(raw) as List).cast<String>();
    return names
        .map((name) => Council(
              id: slugifyCouncilName(name),
              name: name,
              country: Country.ireland,
            ))
        .toList();
  }

  @override
  Future<List<Council>> ukCouncils() async {
    final raw = await rootBundle.loadString('assets/data/uk_councils.json');
    final names = (jsonDecode(raw) as List).cast<String>();
    return names
        .map((name) => Council(
              id: slugifyCouncilName(name),
              name: name,
              country: Country.uk,
            ))
        .toList();
  }
}
