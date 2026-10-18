import '../enums.dart';
import '../models/account.dart';
import '../models/payment.dart';

/// Seed data for the mock platform. Replace with real data when a backend
/// exists. (AGENTS.md §4, §5)
abstract final class MockData {
  /// Verified caregivers the mock can match against.
  static const List<Caregiver> caregivers = [
    Caregiver(
      id: 'cg-001',
      name: 'Ayu Lestari',
      gender: Gender.female,
      rating: 4.9,
      reviewCount: 132,
    ),
    Caregiver(
      id: 'cg-002',
      name: 'Budi Santoso',
      gender: Gender.male,
      rating: 4.7,
      reviewCount: 88,
    ),
    Caregiver(
      id: 'cg-003',
      name: 'Citra Dewi',
      gender: Gender.female,
      rating: 4.8,
      reviewCount: 64,
    ),
    Caregiver(
      id: 'cg-004',
      name: 'Dimas Pratama',
      gender: Gender.male,
      rating: 4.6,
      reviewCount: 41,
    ),
  ];

  /// Payment methods shown on the payment screen. (AGENTS.md §5)
  ///
  /// The label only; no card number is stored. (DC-CS-2)
  static const List<PaymentMethod> paymentMethods = [
    PaymentMethod(
      id: 'pay-gopay',
      type: PaymentMethodType.gopay,
      displayLabel: 'GoPay balance',
    ),
    PaymentMethod(
      id: 'pay-dana',
      type: PaymentMethodType.dana,
      displayLabel: 'DANA balance',
    ),
    PaymentMethod(
      id: 'pay-ovo',
      type: PaymentMethodType.ovo,
      displayLabel: 'OVO balance',
    ),
    PaymentMethod(
      id: 'pay-mastercard',
      type: PaymentMethodType.mastercard,
      displayLabel: 'Mastercard ending 4242',
    ),
  ];

  /// The first caregiver whose gender matches [filter], if any. (FR-P-4)
  static Caregiver? firstMatching(GenderFilter filter) {
    for (final caregiver in caregivers) {
      if (filter.matches(caregiver.gender)) {
        return caregiver;
      }
    }
    return null;
  }
}
