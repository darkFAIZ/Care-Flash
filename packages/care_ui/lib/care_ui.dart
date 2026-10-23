/// Shared design system for Care-Flash and Care-Merchant.
///
/// Import this one file to get the tokens, the themes and every reusable
/// widget. Screens should never talk to repositories or data sources directly;
/// they build their UI from these pieces. (AGENTS.md §5)
library;

export 'src/l10n/app_localizations.dart';
export 'src/theme/app_theme.dart';
export 'src/theme/semantic_colors.dart';
export 'src/tokens/colors.dart';
export 'src/tokens/radii.dart';
export 'src/tokens/spacing.dart';
export 'src/tokens/typography.dart';
export 'src/widgets/app_button.dart';
export 'src/widgets/app_card.dart';
export 'src/widgets/app_text.dart';
export 'src/widgets/app_text_field.dart';
export 'src/widgets/booking_timeline.dart';
export 'src/widgets/empty_state.dart';
export 'src/widgets/price_breakdown_card.dart';
export 'src/widgets/price_row.dart';
export 'src/widgets/section_header.dart';
export 'src/widgets/skeleton_box.dart';
export 'src/widgets/status_chip.dart';
export 'src/widgets/step_indicator.dart';
export 'src/widgets/user_avatar.dart';
