import 'package:go_router/go_router.dart';

import '../domain/care_models.dart';
import 'screens/allergies_screen.dart';
import 'screens/appointments_screen.dart';
import 'screens/exam_item_screen.dart';
import 'screens/exam_review_screen.dart';
import 'screens/exams_screen.dart';
import 'screens/medication_form_screen.dart';
import 'screens/medications_screen.dart';
import 'screens/prescription_review_screen.dart';
import 'screens/summary_screen.dart';
import 'screens/vaccines_screen.dart';

/// "Meus cuidados" screens are go_router routes (not Navigator pushes) so the
/// global urgent-help button (UrgentHelpOverlay) shows on every one of them.
abstract final class CarePaths {
  static const vaccines = '/care/vaccines';
  static const allergies = '/care/allergies';
  static const medications = '/care/medications';
  static const medicationForm = '/care/medications/form';
  static const appointments = '/care/appointments';
  static const summary = '/care/summary';
  static const exams = '/care/exams';
  static String examReview(String id) => '/care/exams/$id';
  static const examItem = '/care/exams/item';
  static const prescriptions = '/care/prescriptions';
  static String prescription(String id) => '/care/prescriptions/$id';
}

/// Extra for [CarePaths.medicationForm].
class MedicationFormArgs {
  final Medication? medication;
  final PrescribedItem? fromPrescription;
  final String? sourceDocumentId;
  const MedicationFormArgs({this.medication, this.fromPrescription, this.sourceDocumentId});
}

/// The selected history series. String extras still open the legacy item view.
class ExamItemArgs {
  final String item;
  final String group;
  final String unit;
  const ExamItemArgs({required this.item, required this.group, required this.unit});
}

final List<RouteBase> careRoutes = [
  GoRoute(path: CarePaths.vaccines, builder: (_, __) => const VaccinesScreen()),
  GoRoute(path: CarePaths.allergies, builder: (_, __) => const AllergiesScreen()),
  GoRoute(path: CarePaths.medications, builder: (_, __) => const MedicationsScreen()),
  GoRoute(
    path: CarePaths.medicationForm,
    builder: (_, state) => MedicationFormScreen(args: state.extra as MedicationFormArgs? ?? const MedicationFormArgs()),
  ),
  GoRoute(path: CarePaths.appointments, builder: (_, __) => const AppointmentsScreen()),
  GoRoute(path: CarePaths.summary, builder: (_, __) => const SummaryScreen()),
  GoRoute(path: CarePaths.exams, builder: (_, __) => const ExamsScreen()),
  GoRoute(
    path: CarePaths.examItem,
    builder: (_, state) {
      final extra = state.extra;
      return extra is ExamItemArgs
          ? ExamItemScreen(item: extra.item, group: extra.group, unit: extra.unit)
          : ExamItemScreen(item: extra as String? ?? '');
    },
  ),
  GoRoute(path: '/care/exams/:id', builder: (_, state) => ExamReviewScreen(documentId: state.pathParameters['id']!)),
  GoRoute(path: CarePaths.prescriptions, builder: (_, __) => const ExamsScreen(prescriptions: true)),
  GoRoute(
    path: '/care/prescriptions/:id',
    builder: (_, state) => PrescriptionReviewScreen(documentId: state.pathParameters['id']!),
  ),
];
