import 'package:foot_rdc/features/domain/entities/match.dart';
import 'package:foot_rdc/features/domain/repositories/match_repository.dart';

class GetMatches {
  final MatchRepository repository;

  GetMatches(this.repository);

  // This function will be called automatically when the class is instantiated
  Future<List<Match>> call(String pagination) {
    return repository.fetchMatchesData(pagination);
  }
}
