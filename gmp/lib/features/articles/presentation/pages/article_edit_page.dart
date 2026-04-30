import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gmp/core/bgtheme.dart';
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

  const ArticleEditPage({super.key, required this.articleId});

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

  static const List<String> _brands = [
    'Nike',
    'Adidas',
    'Puma',
    'New Balance',
    'Converse',
    'Reebok',
    'Asics',
    'Vans',
    'Jordan',
    'Skechers',
  ];

  static const List<String> _models = [
    'Air Max',
    'Stan Smith',
    'Classic',
    'Runner',
    'Sneaker',
    'Chuck Taylor',
    'Ultraboost',
    'Gel-Kayano',
    'Old Skool',
    'Pegasus',
  ];

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
    _load();
  }

  Future<void> _load() async {
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
            _article = article;
            _loading = false;
            _error = null;

            _brand = _brands.contains(article.brand) ? article.brand : _brands.first;
            _model = _models.contains(article.model) ? article.model : _models.first;
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
          });
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _error = e.toString().replaceFirst('Exception: ', '');
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
    if (_loading) {
      return _buildWithBg(
        appBar: buildGradientAppBar(
          title: 'Edit Shoe',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          automaticallyImplyLeading: false,
          centerTitle: true,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Loading shoe...',
                style: TextStyle(fontSize: 14, color: AppColors.onGradientBody),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null || _article == null) {
      return _buildWithBg(
        appBar: buildGradientAppBar(
          title: 'Edit Shoe',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                ElevatedButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
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
                    onPressed: _submitting ? null : () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 6),
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
              const SizedBox(height: 16),
              _brandDropdown(),
              const SizedBox(height: 16),
              _purchaseYearField(),
              const SizedBox(height: 16),
              _colorField(),
              const SizedBox(height: 16),
              _dropdownWithLabel(
                'Category',
                _category,
                _categories,
                (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: _submitting
                      ? null
                      : () {
                          showAppFeedbackAlert(
                            context,
                            message: 'Upload flow will be added in next step',
                            type: AppFeedbackType.info,
                          );
                        },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.95),
                    foregroundColor: const Color(0xFF12899B),
                    side: const BorderSide(color: Color(0xFF09DFFF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontFamily: _headingFontFamily,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  child: const Text('Upload Footwear'),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFABABAB),
                    foregroundColor: const Color(0xFF5A5A5A),
                    disabledBackgroundColor: const Color(0xFFABABAB),
                    disabledForegroundColor: const Color(0xFF5A5A5A),
                    side: const BorderSide(color: Color(0xFF09DFFF)),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontFamily: _headingFontFamily,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Color(0xFF5A5A5A),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Save Footwear'),
                ),
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
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white,
          fontFamily: _contentFontFamily,
        ),
        decoration: _glassInputDecoration(hintText: 'Nike Shoes'),
        onChanged: (v) => _model = v.trim(),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
      ),
    );
  }

  Widget _brandDropdown() {
    return _glassFieldShell(
      label: 'Brand',
      child: DropdownButtonFormField<String>(
        value: _brand,
        iconEnabledColor: Colors.white,
        dropdownColor: const Color(0xFF0C5B67),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontFamily: _contentFontFamily,
        ),
        decoration: _glassInputDecoration(),
        items: _brands.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
        onChanged: (v) => setState(() => _brand = v ?? _brands.first),
      ),
    );
  }

  Widget _glassFieldShell({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              fontFamily: _contentFontFamily,
            ),
          ),
        ),
        child,
      ],
    );
  }

  InputDecoration _glassInputDecoration({String? hintText, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Colors.white70,
        fontSize: 16,
        fontFamily: _contentFontFamily,
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.10),
      errorStyle: const TextStyle(color: Colors.white),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      suffixIcon: suffixIcon,
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
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontFamily: _contentFontFamily,
        ),
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
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white,
          fontFamily: _contentFontFamily,
        ),
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
                size: 20,
                color: Colors.white,
              ),
              onPressed: _submitting
                  ? null
                  : _purchaseYear != null
                      ? () => setState(() => _purchaseYear = null)
                      : _openPurchaseYearPicker,
            ),
          ),
          child: Text(
            _purchaseYear?.toString() ?? '2023',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontFamily: _contentFontFamily,
            ),
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
                      decoration: const InputDecoration(
                        hintText: '%',
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
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
}
