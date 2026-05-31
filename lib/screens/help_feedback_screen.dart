import 'package:alarm_walker/extensions/context_extensions.dart';
import 'package:alarm_walker/models/support_ticket_model.dart';
import 'package:alarm_walker/services/profile_cubit.dart';
import 'package:alarm_walker/services/support_ticket_service.dart';
import 'package:alarm_walker/theme/app_colors.dart';
import 'package:alarm_walker/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class HelpFeedbackScreen extends StatefulWidget {
  const HelpFeedbackScreen({super.key});

  @override
  State<HelpFeedbackScreen> createState() => _HelpFeedbackScreenState();
}

class _HelpFeedbackScreenState extends State<HelpFeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _service = SupportTicketService();

  String _category = SupportTicketCategory.alarmProblem;
  int _rating = 0;
  bool _isSubmitting = false;
  bool _submitted = false;
  String? _submitError;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _submitError = null;
      _submitted = false;
    });

    final profile = context.read<ProfileCubit>().state;

    try {
      await _service.submitTicket(
        category: _category,
        message: _messageController.text,
        rating: _rating,
        userName: profile?.name ?? '',
      );

      if (!mounted) return;
      _messageController.clear();
      setState(() {
        _isSubmitting = false;
        _rating = 0;
        _submitted = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submitError = 'Unable to submit feedback right now. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBorder : Colors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor:
            isDark ? AppColors.darkScaffold1 : AppColors.lightScaffold1,
        leading: IconButton(
          tooltip: context.localization.back,
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        centerTitle: true,
        title: const Text('Help & Feedback'),
        titleTextStyle: AppTextStyles.heading(context),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                isDark
                    ? [AppColors.darkScaffold1, AppColors.darkScaffold2]
                    : [AppColors.lightContainer1, AppColors.lightContainer2],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _IntroCard(isDark: isDark),
              const SizedBox(height: 14),
              Form(
                key: _formKey,
                child: _FeedbackFormCard(
                  category: _category,
                  rating: _rating,
                  messageController: _messageController,
                  isSubmitting: _isSubmitting,
                  submitError: _submitError,
                  submitted: _submitted,
                  onCategoryChanged: (value) {
                    if (value == null) return;
                    setState(() => _category = value);
                  },
                  onRatingChanged: (value) => setState(() => _rating = value),
                  onSubmit: _submit,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Submitted feedback is saved as a support ticket for admin review. Please avoid sharing passwords or private security details.',
                style: AppTextStyles.caption(context).copyWith(
                  color:
                      isDark
                          ? AppColors.darkBackgroundText
                          : AppColors.lightBackgroundText,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  final bool isDark;

  const _IntroCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: isDark ? AppColors.darkScaffold1 : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.support_agent_outlined,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need help with Alarm Walker?',
                  style: AppTextStyles.heading(context).copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Report alarm problems, account issues, backup trouble, or send improvement ideas to the admin.',
                  style: AppTextStyles.caption(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackFormCard extends StatelessWidget {
  final String category;
  final int rating;
  final TextEditingController messageController;
  final bool isSubmitting;
  final bool submitted;
  final String? submitError;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onSubmit;

  const _FeedbackFormCard({
    required this.category,
    required this.rating,
    required this.messageController,
    required this.isSubmitting,
    required this.submitted,
    required this.submitError,
    required this.onCategoryChanged,
    required this.onRatingChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Card(
      elevation: 0,
      color: isDark ? AppColors.darkScaffold1 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Submit feedback',
              style: AppTextStyles.heading(context).copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: category,
              decoration: InputDecoration(
                labelText: 'Feedback type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              items:
                  SupportTicketCategory.values.map((value) {
                    return DropdownMenuItem(
                      value: value,
                      child: Text(SupportTicketCategory.labelFor(value)),
                    );
                  }).toList(),
              onChanged: isSubmitting ? null : onCategoryChanged,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: messageController,
              enabled: !isSubmitting,
              minLines: 5,
              maxLines: 8,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                labelText: 'Describe the problem or idea',
                alignLabelWithHint: true,
                hintText: 'Example: My alarm did not ring after I restored my backup.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return 'Please enter your feedback.';
                if (text.length < 8) return 'Please describe it a bit more.';
                return null;
              },
            ),
            const SizedBox(height: 14),
            Text(
              'Optional experience rating',
              style: AppTextStyles.body(context).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (var value = 1; value <= 5; value++)
                  ChoiceChip(
                    label: Text('$value'),
                    selected: rating == value,
                    onSelected:
                        isSubmitting
                            ? null
                            : (_) => onRatingChanged(rating == value ? 0 : value),
                  ),
              ],
            ),
            if (submitError != null) ...[
              const SizedBox(height: 14),
              _InlineMessage(
                icon: Icons.error_outline,
                text: submitError!,
                color: Colors.redAccent,
              ),
            ],
            if (submitted) ...[
              const SizedBox(height: 14),
              const _InlineMessage(
                icon: Icons.check_circle_outline,
                text: 'Feedback submitted. The admin can now review it.',
                color: Colors.green,
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isSubmitting ? null : onSubmit,
                icon:
                    isSubmitting
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Icon(Icons.send_outlined),
                label: Text(isSubmitting ? 'Submitting...' : 'Submit Feedback'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InlineMessage({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
