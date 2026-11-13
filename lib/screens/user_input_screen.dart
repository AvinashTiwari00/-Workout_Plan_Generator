import 'package:college_project/models/user_models.dart';
import 'package:college_project/providers/user_provider.dart';
import 'package:college_project/repositories/dashboard_user_builder.dart';
import 'package:college_project/repositories/user_repository.dart';
import 'package:college_project/repositories/weight_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class UserInputScreen extends StatefulWidget {
  const UserInputScreen({super.key});

  @override
  State<UserInputScreen> createState() => _UserInputScreenState();
}

class _UserInputScreenState extends State<UserInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _users = UserRepository();
  final _weights = WeightRepository();

  final nameCtrl = TextEditingController();
  final ageCtrl = TextEditingController();
  final weightCtrl = TextEditingController();
  final heightCtrl = TextEditingController();

  String gender = "Male";
  String goal = "Muscle Gain";
  bool _isFormValid = false;
  bool _isSaving = false;
  bool _isLoadingProfile = true;
  bool _profileLoadFailed = false;
  ExperienceLevel _experience = ExperienceLevel.beginner;
  WorkoutLocation _location = WorkoutLocation.home;
  int _daysPerWeek = 3;

  @override
  void initState() {
    super.initState();
    // Add listeners to validate form on input change
    nameCtrl.addListener(_validateForm);
    ageCtrl.addListener(_validateForm);
    weightCtrl.addListener(_validateForm);
    heightCtrl.addListener(_validateForm);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingProfile();
    });
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    ageCtrl.dispose();
    weightCtrl.dispose();
    heightCtrl.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _isFormValid =
          _isNameValid(nameCtrl.text) &&
          _isAgeValid(ageCtrl.text) &&
          _isWeightValid(weightCtrl.text) &&
          _isHeightValid(heightCtrl.text);
    });
  }

  bool _isNameValid(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return false;
    return true;
  }

  bool _isAgeValid(String raw) {
    final n = int.tryParse(raw.trim());
    return n != null && n >= 1 && n <= 120;
  }

  bool _isWeightValid(String raw) {
    final d = double.tryParse(raw.trim());
    return d != null && d > 0 && d <= 500;
  }

  bool _isHeightValid(String raw) {
    final d = double.tryParse(raw.trim());
    return d != null && d > 0 && d <= 300;
  }

  String? _validateName(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'Enter your name';
    return null;
  }

  String? _validateAge(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'Enter your age';
    final n = int.tryParse(t);
    if (n == null) return 'Age must be a whole number';
    if (n < 1 || n > 120) return 'Enter a realistic age (1–120)';
    return null;
  }

  String? _validateWeight(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'Enter your weight';
    final d = double.tryParse(t);
    if (d == null) return 'Use numbers only (e.g. 70 or 70.5)';
    if (!d.isFinite || d <= 0 || d > 500) {
      return 'Enter weight between 1 and 500 kg';
    }
    return null;
  }

  String? _validateHeight(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'Enter your height';
    final d = double.tryParse(t);
    if (d == null) return 'Use numbers only (e.g. 175 or 175.5)';
    if (!d.isFinite || d <= 0 || d > 300) {
      return 'Enter height between 1 and 300 cm';
    }
    return null;
  }

  Future<void> _loadExistingProfile() async {
    if (!mounted) return;
    setState(() {
      _isLoadingProfile = true;
      _profileLoadFailed = false;
    });
    try {
      final provider = context.read<UserProvider>();
      final account = provider.account;
      final profile = provider.profile;

      if (account != null && nameCtrl.text.isEmpty) {
        nameCtrl.text = account.username;
      }
      if (profile != null) {
        if (profile.age != null && ageCtrl.text.isEmpty) {
          ageCtrl.text = '${profile.age}';
        }
        if (profile.heightCm != null && heightCtrl.text.isEmpty) {
          heightCtrl.text = _formatNumber(profile.heightCm!);
        }
        setState(() {
          if (profile.gender != null) gender = profile.gender!.label;
          if (profile.goal != null) goal = profile.goal!.label;
          _experience = profile.experienceLevel ?? _experience;
          _location = profile.workoutLocation ?? _location;
          final days = profile.daysPerWeek;
          if (days != null && days >= 1 && days <= 7) _daysPerWeek = days;
        });
      }

      if (account == null) return;
      final latest = await _weights.latest(account.id);
      if (!mounted || latest == null || weightCtrl.text.trim().isNotEmpty) {
        return;
      }
      weightCtrl.text = _formatNumber(latest.weightKg);
    } catch (_) {
      if (mounted) setState(() => _profileLoadFailed = true);
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toString();
  }

  Future<void> _submit() async {
    if (_isSaving ||
        _isLoadingProfile ||
        _profileLoadFailed ||
        !_formKey.currentState!.validate()) {
      return;
    }

    final selectedGoal = UserGoalLabel.byLabel(goal);
    final selectedGender = Gender.byLabel(gender);
    if (selectedGoal == null || selectedGender == null) return;

    setState(() => _isSaving = true);
    try {
      final account = context.read<UserProvider>().account;
      final weightKg = double.parse(weightCtrl.text.trim());
      // Preserve prefilled fitness choices unless the user changes them.
      final profile = UserProfile(
        userId: account?.id ?? 0,
        age: int.parse(ageCtrl.text.trim()),
        gender: selectedGender,
        heightCm: double.parse(heightCtrl.text.trim()),
        goal: selectedGoal,
        experienceLevel: _experience,
        workoutLocation: _location,
        daysPerWeek: _daysPerWeek,
      );

      final User dashboardUser;
      if (account != null) {
        final savedProfile = profile.copyWith(userId: account.id);
        final error = await _users.completeProfile(
          username: nameCtrl.text,
          profile: savedProfile,
          weightKg: weightKg,
        );
        if (!mounted) return;
        if (error != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)));
          return;
        }
        final loaded = await _users.loadDashboardUser(account.id);
        final refreshedAccount = await _users.getAccount(account.id);
        if (!mounted) return;
        if (loaded == null || refreshedAccount == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not save your profile')),
          );
          return;
        }
        dashboardUser = loaded;
        context.read<UserProvider>().setSession(
          user: dashboardUser,
          account: refreshedAccount,
          profile: savedProfile,
        );
      } else {
        // There is no account yet, so the profile cannot be stored.
        // Today's workout still comes from the goal selected on this form.
        dashboardUser = buildDashboardUser(
          name: nameCtrl.text.trim(),
          profile: profile,
          weightKg: weightKg,
        );
        if (!mounted) return;
        context.read<UserProvider>().setUser(dashboardUser, profile: profile);
      }

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/dashboard',
        (_) => false,
        arguments: dashboardUser,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save profile. Please retry.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSaving,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FC),
        body: SafeArea(
          bottom: false,
          child: _isLoadingProfile
              ? const Center(child: CircularProgressIndicator())
              : _profileLoadFailed
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Could not load your profile. Please retry.'),
                      TextButton(
                        onPressed: _loadExistingProfile,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isWeb = constraints.maxWidth > 600;
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 700),
                        child: Column(
                          children: [
                            _buildHeader(isWeb),
                            Expanded(
                              child: SingleChildScrollView(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isWeb ? 30 : 20,
                                  vertical: 20,
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildSectionTitle(
                                        "Personal Information",
                                      ),
                                      const SizedBox(height: 15),
                                      _buildPersonalInfoCard(isWeb),
                                      const SizedBox(height: 30),

                                      _buildSectionTitle("Workout Preferences"),
                                      const SizedBox(height: 15),
                                      _buildWorkoutPreferences(),
                                      const SizedBox(height: 30),
                                      _buildSectionTitle("Gender"),
                                      const SizedBox(height: 15),
                                      _buildGenderSelection(),
                                      const SizedBox(height: 30),

                                      _buildSectionTitle("Goal"),
                                      const Text(
                                        "Choose what you want to focus on",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 15),
                                      _buildGoalSelection(),

                                      const SizedBox(height: 40),
                                      // On web, we put button here. On mobile, it's sticky.
                                      if (isWeb) _buildContinueButton(),
                                      if (isWeb) const SizedBox(height: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // On mobile, sticky button at bottom
                            if (!isWeb)
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, -4),
                                    ),
                                  ],
                                ),
                                child: SafeArea(child: _buildContinueButton()),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildWorkoutPreferences() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          DropdownButtonFormField<ExperienceLevel>(
            initialValue: _experience,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Experience Level'),
            items: [
              for (final value in ExperienceLevel.values)
                DropdownMenuItem(value: value, child: Text(value.label)),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _experience = value);
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<WorkoutLocation>(
            initialValue: _location,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Workout Location'),
            items: [
              for (final value in WorkoutLocation.values)
                DropdownMenuItem(value: value, child: Text(value.label)),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _location = value);
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: _daysPerWeek,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Days per week'),
            items: [
              for (var value = 1; value <= 7; value++)
                DropdownMenuItem(value: value, child: Text(value.toString())),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _daysPerWeek = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isWeb) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(22, 24, 22, 25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade900],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Your Fitness Profile",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Let’s Get Started",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildPersonalInfoCard(bool isWeb) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInput(
            "Full Name",
            nameCtrl,
            Icons.person,
            fieldValidator: _validateName,
          ),
          const SizedBox(height: 16),
          if (isWeb)
            Row(
              children: [
                Expanded(
                  child: _buildInput(
                    "Age",
                    ageCtrl,
                    Icons.cake,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    fieldValidator: _validateAge,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInput(
                    "Weight (kg)",
                    weightCtrl,
                    Icons.monitor_weight,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [_DecimalTextInputFormatter()],
                    fieldValidator: _validateWeight,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInput(
                    "Height (cm)",
                    heightCtrl,
                    Icons.height,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [_DecimalTextInputFormatter()],
                    fieldValidator: _validateHeight,
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                _buildInput(
                  "Age",
                  ageCtrl,
                  Icons.cake,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  fieldValidator: _validateAge,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInput(
                        "Weight (kg)",
                        weightCtrl,
                        Icons.monitor_weight,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [_DecimalTextInputFormatter()],
                        fieldValidator: _validateWeight,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInput(
                        "Height (cm)",
                        heightCtrl,
                        Icons.height,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [_DecimalTextInputFormatter()],
                        fieldValidator: _validateHeight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInput(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    FormFieldValidator<String>? fieldValidator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator:
          fieldValidator ?? (v) => (v == null || v.isEmpty) ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue.shade700, size: 20),
        filled: true,
        fillColor: const Color(0xFFF8F9FD),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildGenderSelection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: ["Male", "Female", "Other"].map((g) {
          final isSelected = gender == g;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => gender = g),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue.shade700 : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    g,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGoalSelection() {
    return Column(
      children: [
        _buildGoalOption("Muscle Gain", "Build stronger muscles", "💪"),
        const SizedBox(height: 12),
        _buildGoalOption("Fat Loss", "Burn fat and get lean", "🔥"),
        const SizedBox(height: 12),
        _buildGoalOption("Stay Fit", "Maintain current weight", "⚖️"),
      ],
    );
  }

  Widget _buildGoalOption(String title, String subtitle, String icon) {
    bool isSelected = goal == title;
    return GestureDetector(
      onTap: () => setState(() => goal = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.blue.shade700 : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? Colors.blue.shade100.withOpacity(0.5)
                  : Colors.grey.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.blue.shade700 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: Colors.blue.shade700)
            else
              Icon(Icons.circle_outlined, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed:
            _isFormValid &&
                !_isSaving &&
                !_isLoadingProfile &&
                !_profileLoadFailed
            ? _submit
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade800,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: _isFormValid ? 8 : 0,
        ),
        child: const Text(
          "Continue",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Allows digits and at most one decimal point (e.g. 70, 70.5).
class _DecimalTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final t = newValue.text;
    if (t.isEmpty) return newValue;
    if (RegExp(r'^\d*\.?\d*$').hasMatch(t)) return newValue;
    return oldValue;
  }
}
