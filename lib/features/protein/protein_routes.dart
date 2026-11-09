import 'package:go_router/go_router.dart';

import 'presentation/screens/protein_screen.dart';

abstract final class ProteinRoutes {
  static const protein = '/protein';

  static final route = GoRoute(path: protein, builder: (context, state) => const ProteinScreen());
}
