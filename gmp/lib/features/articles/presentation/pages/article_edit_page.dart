import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gmp/core/bgtheme.dart';
import 'package:gmp/core/widgets/app_gradient_next_style_button.dart';
import 'package:gmp/core/theme/app_colors.dart';
import 'package:gmp/core/utils/responsive.dart';
import 'package:gmp/core/widgets/app_feedback_alert.dart';
import 'package:gmp/core/widgets/gradient_page_shell.dart';
import 'package:gmp/features/articles/domain/entities/article.dart';
import 'package:gmp/features/articles/domain/usecases/get_article_by_id.dart';
import 'package:gmp/features/articles/domain/usecases/update_article.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/injection_container.dart';

/// Module 3 – Edit shoe. Uses PUT /api/articles/update/:articleId with prefilled selects.
class ArticleEditPage extends StatefulWidget {
  final String articleId;

  /// When opened from details, skip the loading screen and show the form immediately.
  final Article? initialArticle;

  const ArticleEditPage({
    super.key,
    required this.articleId,
    this.initialArticle,
  });

  @override
  State<ArticleEditPage> createState() => _ArticleEditPageState();
}

class _ArticleEditPageState extends State<ArticleEditPage> {
  static const String _headingFontFamily = 'Boldonse';
  static const String _contentFontFamily = 'Montserrat';
  final _formKey = GlobalKey<FormState>();

  Article? _article;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  String _brand = 'Nike';
  String _model = 'Air Max';
  String _category = 'sports_shoe';
  String _condition = 'good';
  String _color = '';
  int? _purchaseYear;

  final List<Map<String, dynamic>> _materials = [];

  static const List<Map<String, String>> _categories = [
    {'value': 'sports_shoe', 'label': 'Sports shoe'},
    {'value': 'casual', 'label': 'Casual'},
    {'value': 'formal', 'label': 'Formal'},
    {'value': 'sandal', 'label': 'Sandal'},
    {'value': 'boot', 'label': 'Boot'},
    {'value': 'slipper', 'label': 'Slipper'},
    {'value': 'other', 'label': 'Other'},
  ];

  static const List<Map<String, String>> _conditions = [
    {'value': 'excellent', 'label': 'Excellent'},
    {'value': 'good', 'label': 'Good'},
    {'value': 'fair', 'label': 'Fair'},
    {'value': 'worn', 'label': 'Worn'},
  ];

  static const List<String> _materialTypes = [
    'Leather',
    'Synthetic leather',
    'Suede',
    'Canvas',
    'Mesh',
    'Rubber',
    'Foam',
    'Textile',
    'Knit',
    'Gore-Tex',
  ];

  @override
  void initState() {
    super.initState();
    final seed = widget.initialArticle;
    if (seed != null && seed.id == widget.articleId) {
      _applyArticle(seed);
      _loading = false;
    }
    _load();
  }

  void _applyArticle(Article article) {
    _article = article;
    _error = null;
    _brand = article.brand;
    _model = article.model;
    _category = article.category;
    _condition = article.condition.isNotEmpty ? article.condition : 'good';
    _color = article.color;
    _purchaseYear = article.purchaseYear;
    _materials.clear();
    for (final m in article.materials) {
      _materials.add({
        'type': _materialTypes.contains(m.type) ? m.type : _materialTypes.first,
        'percentage': m.percentage,
      });
    }
  }

  Future<void> _load() async {
    final keepExisting = _article != null;
    if (!keepExisting && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    final tokenResult = await sl<GetValidAccessToken>().call();
    if (!mounted) return;
    tokenResult.fold(
      (_) {
        setState(() {
          _error = 'Please sign in again';
          _loading = false;
        });
      },
      (token) async {
        try {
          final article = await sl<GetArticleById>().call(token, widget.articleId);
          if (!mounted) return;
          setState(() {
            _applyArticle(article);
            _loading = false;
          });
        } catch (e) {
          if (!mounted) return;
          setState(() {
            if (!keepExisting) {
              _error = e.toString().replaceFirst('Exception: ', '');
            }
            _loading = false;
          });
        }
      },
    );
  }

  Future<void> _openPurchaseYearPicker() async {
    final now = DateTime.now();
    final initial = _purchaseYear != null
        ? DateTime(_purchaseYear!, 6, 1)
        : DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1800),
      lastDate: now,
      helpText: 'Select purchase year',
    );
    if (picked != null && mounted) {
      setState(() => _purchaseYear = picked.year);
    }
  }

  void _addMaterialRow() {
    setState(() {
      _materials.add({'type': _materialTypes.first, 'percentage': 0});
    });
  }

  void _removeMaterialRow(int index) {
    setState(() => _materials.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _article == null) return;

    final tokenResult = await sl<GetValidAccessToken>().call();
    if (!mounted) return;
    await tokenResult.fold(
      (_) async {
        if (!context.mounted) return;
        await showAppFeedbackAlert(
          context,
          message: 'Please sign in again',
          type: AppFeedbackType.failure,
        );
      },
      (token) async {
        setState(() => _submitting = true);
        try {
          final materials = _materials
              .map((m) => {
                    'type': m['type'] as String? ?? '',
                    'percentage': (m['percentage'] as num?)?.toInt() ?? 0,
                  })
              .toList();

          await sl<UpdateArticle>().call(
            token,
            _article!.id,
            brand: _brand,
            model: _model,
            category: _category,
            color: _color,
            purchaseYear: _purchaseYear,
            condition: _condition,
            materials: materials,
          );

          if (!mounted) return;
          Navigator.of(context).pop(true);
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _submitting = false;
            _error = e.toString().replaceFirst('Exception: ', '');
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_article == null && _loading) {
      return _buildWithBg(
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_error != null || _article == null) {
      return _buildWithBg(
        appBar: buildGradientAppBar(
          title: 'Edit Shoe',
          leading: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 30, height: 30),
            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
            icon: SvgPicture.asset(
              'assets/images/chevron-left.svg',
              width: 30,
              height: 30,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          automaticallyImplyLeading: false,
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: Responsive.horizontalPaddingOf(context)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                ),
                const SizedBox(height: 20),
                Text(
                  _error ?? 'Shoe not found',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.onGradientBody,
                  ),
                ),
                const SizedBox(height: 24),
                AppGradientNextStyleButton(
                  label: 'Retry',
                  onPressed: _load,
                  leading: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                  showTrailingIcon: false,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final horizontal = Responsive.horizontalPaddingOf(context);

    return _buildWithBg(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(horizontal, 30, horizontal, 24),
            children: [
              Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(width: 30, height: 30),
                    visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                    onPressed: _submitting ? null : () => Navigator.pop(context),
                    icon: SvgPicture.asset(
                      'assets/images/chevron-left.svg',
                      width: 30,
                      height: 30,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Edit Footwear',
                      style: GoogleFonts.boldonse(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
              _modelField(),
              const SizedBox(height: 20),
              _brandField(),
              const SizedBox(height: 20),
              _purchaseYearField(),
              const SizedBox(height: 20),
              _colorField(),
              const SizedBox(height: 20),
              _dropdownWithLabel(
                'Category',
                _category,
                _categories,
                (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 24),
              _buildActionButton(
                label: 'Upload Footwear',
                isBusy: _submitting,
                onPressed: () async {
                  if (!context.mounted) return;
                  await showAppFeedbackAlert(
                    context,
                    message: 'Upload flow will be added in next step',
                    type: AppFeedbackType.info,
                  );
                },
              ),
              const SizedBox(height: 24),
              AppGradientNextStyleButton(
                label: 'Save Footwear',
                onPressed: _submit,
                isBusy: _submitting,
                minWidth: 200,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWithBg({
    required Widget body,
    PreferredSizeWidget? appBar,
  }) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: appBar,
      body: Stack(
        children: [
          ...BgTheme.background(),
          Positioned.fill(child: body),
        ],
      ),
    );
  }

  Widget _modelField() {
    return _glassFieldShell(
      label: 'Name your footwear',
      child: TextFormField(
        initialValue: _model,
        textCapitalization: TextCapitalization.words,
        style: _inputTextStyle(),
        decoration: _glassInputDecoration(hintText: 'Nike Shoes'),
        onChanged: (v) => _model = v.trim(),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
      ),
    );
  }

  Widget _brandField() {
    return _glassFieldShell(
      label: 'Brand',
      child: TextFormField(
        initialValue: _brand,
        textCapitalization: TextCapitalization.words,
        style: _inputTextStyle(),
        decoration: _glassInputDecoration(hintText: 'Nike'),
        onChanged: (v) => _brand = v.trim(),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
      ),
    );
  }

  Widget _glassFieldShell({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
        child,
      ],
    );
  }

  InputDecoration _glassInputDecoration({String? hintText, Widget? suffixIcon}) {
    return InputDecoration(
      isDense: true,
      hintText: hintText,
      hintStyle: GoogleFonts.montserrat(
        color: Colors.white70,
        fontSize: 16,
      ),
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      suffixIcon: suffixIcon,
      suffixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100),
        borderSide: const BorderSide(color: Color(0xFF09E0FF), width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100),
        borderSide: const BorderSide(color: Color(0xFFFFB4B4)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100),
        borderSide: const BorderSide(color: Color(0xFFFFB4B4), width: 1.2),
      ),
    );
  }

  TextStyle _inputTextStyle({Color color = Colors.white, double fontSize = 16}) {
    return GoogleFonts.montserrat(
      color: color,
      fontSize: fontSize,
    );
  }

  Widget _dropdownWithLabel(
    String label,
    String value,
    List<Map<String, String>> items,
    ValueChanged<String?> onChanged,
  ) {
    return _glassFieldShell(
      label: label,
      child: DropdownButtonFormField<String>(
        value: value,
        iconEnabledColor: Colors.white,
        dropdownColor: const Color(0xFF0C5B67),
        style: _inputTextStyle(),
        decoration: _glassInputDecoration(),
        items: items
            .map(
              (e) => DropdownMenuItem<String>(
                value: e['value'],
                child: Text(e['label']!),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _colorField() {
    return _glassFieldShell(
      label: 'Colour',
      child: TextFormField(
        initialValue: _color,
        textCapitalization: TextCapitalization.words,
        style: _inputTextStyle(),
        decoration: _glassInputDecoration(hintText: 'Denim'),
        onChanged: (v) => _color = v.trim(),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
      ),
    );
  }

  Widget _purchaseYearField() {
    return _glassFieldShell(
      label: 'Purchased On',
      child: InkWell(
        onTap: _submitting ? null : _openPurchaseYearPicker,
        borderRadius: BorderRadius.circular(100),
        child: InputDecorator(
          decoration: _glassInputDecoration(
            suffixIcon: IconButton(
              icon: Icon(
                _purchaseYear != null ? Icons.close : Icons.calendar_today_outlined,
                size: 18,
                color: Colors.white,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              onPressed: _submitting
                  ? null
                  : _purchaseYear != null
                      ? () => setState(() => _purchaseYear = null)
                      : _openPurchaseYearPicker,
            ),
          ),
          child: Text(
            _purchaseYear?.toString() ?? '2023',
            style: _inputTextStyle(),
          ),
        ),
      ),
    );
  }

  Widget _materialsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Material composition',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: _addMaterialRow,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                '+ Add',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'Optional. Add material type and percentage (e.g. Rubber 40%).',
            style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
          ),
        ),
        if (_materials.isNotEmpty)
          ...List.generate(_materials.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: (_materials[i]['type'] as String?)?.isNotEmpty == true
                          ? _materials[i]['type'] as String
                          : _materialTypes.first,
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontFamily: _contentFontFamily,
                      ),
                      items: _materialTypes
                          .map(
                            (t) => DropdownMenuItem<String>(
                              value: t,
                              child: Text(t),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        _materials[i]['type'] = v;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 80,
                    child: TextFormField(
                      initialValue: _materials[i]['percentage']?.toString() ?? '',
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '%',
                        hintStyle: GoogleFonts.montserrat(color: Colors.white70),
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      style: _inputTextStyle(fontSize: 15),
                      onChanged: (v) => _materials[i]['percentage'] = int.tryParse(v) ?? 0,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 22),
                    onPressed: () => _removeMaterialRow(i),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required bool isBusy,
    required VoidCallback onPressed,
    bool showLoader = false,
  }) {
    const teal = Color(0xFF12899B);
    const cyanBorder = Color(0xFF09DFFF);

    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: isBusy ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: teal,
          disabledBackgroundColor: Colors.white,
          disabledForegroundColor: teal,
          elevation: 2,
          shadowColor: Colors.black26,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          minimumSize: const Size(0, 50),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
            side: const BorderSide(color: cyanBorder, width: 1),
          ),
        ),
        child: showLoader && isBusy
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: teal,
                  strokeWidth: 2,
                ),
              )
            : Text(
                label,
                style: GoogleFonts.boldonse(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: teal,
                ),
              ),
      ),
    );
  }
}
