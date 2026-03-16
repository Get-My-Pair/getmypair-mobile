import 'package:flutter/material.dart';
import 'package:gmp/core/theme/app_colors.dart';
import 'package:gmp/core/utils/responsive.dart';
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
    tokenResult.fold(
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in again'),
            backgroundColor: AppColors.error,
          ),
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
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Edit Shoe',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'Loading shoe...',
                style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null || _article == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Edit Shoe',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
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
                  child: Icon(Icons.error_outline, size: 48, color: AppColors.error),
                ),
                const SizedBox(height: 20),
                Text(
                  _error ?? 'Shoe not found',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: _submitting ? null : () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Shoe',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 24),
          children: [
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ),
            ],
            _brandDropdown(),
            const SizedBox(height: 14),
            _modelDropdown(),
            const SizedBox(height: 14),
            _dropdownWithLabel('Category', _category, _categories, (v) => setState(() => _category = v ?? _category)),
            const SizedBox(height: 14),
            _colorField(),
            const SizedBox(height: 14),
            _purchaseYearField(),
            const SizedBox(height: 14),
            _dropdownWithLabel('Condition', _condition, _conditions, (v) => setState(() => _condition = v ?? _condition)),
            const SizedBox(height: 20),
            _materialsSection(),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Save changes', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _brandDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            'Brand',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        DropdownButtonFormField<String>(
          value: _brand,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          items: _brands.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
          onChanged: (v) => setState(() => _brand = v ?? _brands.first),
        ),
      ],
    );
  }

  Widget _modelDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            'Model',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        DropdownButtonFormField<String>(
          value: _model,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          items: _models.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
          onChanged: (v) => setState(() => _model = v ?? _models.first),
        ),
      ],
    );
  }

  Widget _dropdownWithLabel(
    String label,
    String value,
    List<Map<String, String>> items,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
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
      ],
    );
  }

  Widget _colorField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            'Color',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        TextFormField(
          initialValue: _color,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Color',
            hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 15),
            filled: true,
            fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          onChanged: (v) => _color = v.trim(),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _purchaseYearField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            'Purchase Year (optional)',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        InkWell(
          onTap: _submitting ? null : _openPurchaseYearPicker,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _purchaseYear?.toString() ?? 'Not specified',
                    style: TextStyle(
                      fontSize: 15,
                      color: _purchaseYear != null ? AppColors.textPrimary : AppColors.textTertiary,
                    ),
                  ),
                ),
                if (_purchaseYear != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20, color: AppColors.textTertiary),
                    onPressed: _submitting ? null : () => setState(() => _purchaseYear = null),
                    style: IconButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(32, 32),
                    ),
                  )
                else
                  const Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ],
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
