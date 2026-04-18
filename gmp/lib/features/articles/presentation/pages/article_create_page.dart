import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gmp/core/theme/app_colors.dart';
import 'package:gmp/core/utils/responsive.dart';
import 'package:gmp/features/articles/domain/usecases/create_article.dart';
import 'package:gmp/features/articles/domain/usecases/upload_article_image.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/injection_container.dart';
import 'package:image_picker/image_picker.dart';

import 'article_details_page.dart';

/// Module 3 – Add new shoe. Form relies on manual entry only (no auto-fill).
/// POST /api/articles/create on submit, then navigate to ArticleDetailsPage.
class ArticleCreatePage extends StatefulWidget {
  const ArticleCreatePage({super.key});

  @override
  State<ArticleCreatePage> createState() => _ArticleCreatePageState();
}

class _ArticleCreatePageState extends State<ArticleCreatePage> {
  static const String _headingFontFamily = 'Boldonse';
  static const String _contentFontFamily = 'Montserrat';
  final _formKey = GlobalKey<FormState>();
  final _colorController = TextEditingController();

  String _brand = 'Nike';
  String _model = 'Air Max';
  String _category = 'sports_shoe';
  String _condition = 'good';
  int? _purchaseYear;

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
  final List<Map<String, dynamic>> _materials = [];
  final List<File> _imageFiles = [];
  final List<String> _uploadedImageUrls = [];
  bool _submitting = false;
  String? _errorMessage;

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

  @override
  void dispose() {
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isEmpty || !mounted) return;
    setState(() {
      for (final x in picked) {
        _imageFiles.add(File(x.path));
      }
    });
  }

  void _removeImage(int index) {
    setState(() {
      _imageFiles.removeAt(index);
      if (index < _uploadedImageUrls.length) {
        _uploadedImageUrls.removeAt(index);
      }
    });
  }

  Future<void> _submit() async {
    _errorMessage = null;
    if (!_formKey.currentState!.validate()) return;

    final tokenResult = await sl<GetValidAccessToken>().call();
    if (!mounted) return;
    tokenResult.fold(
      (_) {
        setState(() => _errorMessage = 'Please sign in again');
        return;
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

          // Create article first (API requires article to exist before upload-image)
          final article = await sl<CreateArticle>().call(token,
            brand: _brand,
            model: _model,
            category: _category,
            color: _colorController.text.trim(),
            purchaseYear: _purchaseYear,
            condition: _condition,
            materials: materials,
            imageUrls: [], // Images added via upload-image after create
          );
          if (!mounted) return;

          // Upload each image to the new article
          for (int i = 0; i < _imageFiles.length; i++) {
            if (!mounted) return;
            final bytes = await _imageFiles[i].readAsBytes();
            final name = 'shoe_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
            await sl<UploadArticleImage>().call(token,
              articleId: article.id,
              imageBytes: bytes,
              fileName: name,
            );
          }

          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ArticleDetailsPage(articleId: article.id),
            ),
          );
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _submitting = false;
            _errorMessage = e.toString().replaceFirst('Exception: ', '');
          });
        }
      },
    );
  }

  void _addMaterialRow() {
    setState(() {
      _materials.add({'type': _materialTypes.first, 'percentage': 0});
    });
  }

  void _removeMaterialRow(int index) {
    setState(() => _materials.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = Responsive.horizontalPaddingOf(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: SweepGradient(
            center: Alignment(0.22, -1.07),
            startAngle: -0.55,
            endAngle: 5.73,
            colors: [
              Color(0xFF09E0FF),
              Color(0xFF0F6876),
              Color(0xFF062F35),
              Color(0xFF062F35),
            ],
            stops: [0.05, 0.44, 0.57, 1],
            transform: GradientRotation(-0.55),
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 28),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: _submitting ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Add New Footwear',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          height: 1.1,
                          fontFamily: _headingFontFamily,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
                _modelDropdown(),
                const SizedBox(height: 14),
                _brandDropdown(),
                const SizedBox(height: 14),
                _purchaseYearDropdown(),
                const SizedBox(height: 14),
                _field(_colorController, 'Colour', textCapitalization: TextCapitalization.words),
                const SizedBox(height: 14),
                _dropdownWithLabel('Category', _category, _categories, (v) => setState(() => _category = v!)),
                const SizedBox(height: 14),
                _dropdownWithLabel('Condition', _condition, _conditions, (v) => setState(() => _condition = v!)),
                const SizedBox(height: 14),
                _materialsSection(horizontal),
                const SizedBox(height: 18),
                _imagesSection(),
                const SizedBox(height: 28),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _pickImages,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF12899B),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      side: const BorderSide(color: Color(0xFF09DFFF), width: 1),
                    ),
                    child: const Text(
                      'Upload Footwear',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: _headingFontFamily,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _submitting ? const Color(0xFFABABAB) : const Color(0xFFABABAB),
                      foregroundColor: const Color(0xFF5A5A5A),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      side: const BorderSide(color: Color(0xFF09DFFF), width: 1),
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
                        : const Text(
                            'Save Footwear',
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: _headingFontFamily,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String hint, {
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontFamily: _contentFontFamily,
      ),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontFamily: _contentFontFamily,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        hintText: '',
        hintStyle: const TextStyle(color: Colors.white70, fontSize: 16),
        filled: true,
        fillColor: Colors.white.withOpacity(0.10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100),
          borderSide: const BorderSide(color: Color(0xFF09DFFF), width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      validator: (v) {
        if (hint.startsWith('Purchase')) return null;
        return (v == null || v.trim().isEmpty) ? 'Required' : null;
      },
    );
  }

  Widget _brandDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            'Brand',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontFamily: _contentFontFamily,
            ),
          ),
        ),
        DropdownButtonFormField<String>(
          value: _brand,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(100),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(100),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(100),
              borderSide: const BorderSide(color: Color(0xFF09DFFF), width: 1.2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          dropdownColor: const Color(0xFF0D5B68),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: _contentFontFamily,
          ),
          iconEnabledColor: Colors.white,
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
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            'Name your footwear',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontFamily: _contentFontFamily,
            ),
          ),
        ),
        DropdownButtonFormField<String>(
          value: _model,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(100),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(100),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(100),
              borderSide: const BorderSide(color: Color(0xFF09DFFF), width: 1.2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          dropdownColor: const Color(0xFF0D5B68),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: _contentFontFamily,
          ),
          iconEnabledColor: Colors.white,
          items: _models.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
          onChanged: (v) => setState(() => _model = v ?? _models.first),
        ),
      ],
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

  Widget _purchaseYearDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            'Purchased On',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontFamily: _contentFontFamily,
            ),
          ),
        ),
        InkWell(
          onTap: _submitting ? null : _openPurchaseYearPicker,
          borderRadius: BorderRadius.circular(100),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _purchaseYear?.toString() ?? 'Not specified',
                    style: TextStyle(
                      fontSize: 16,
                      color: _purchaseYear != null ? Colors.white : Colors.white70,
                      fontFamily: _contentFontFamily,
                    ),
                  ),
                ),
                if (_purchaseYear != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20, color: Colors.white70),
                    onPressed: _submitting ? null : () => setState(() => _purchaseYear = null),
                    style: IconButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(32, 32),
                    ),
                  )
                else
                  const Icon(Icons.calendar_today_outlined, size: 20, color: Colors.white),
              ],
            ),
          ),
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
              fontSize: 16,
              color: Colors.white,
              fontFamily: _contentFontFamily,
            ),
          ),
        ),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(100),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(100),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(100),
              borderSide: const BorderSide(color: Color(0xFF09DFFF), width: 1.2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          dropdownColor: const Color(0xFF0D5B68),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: _contentFontFamily,
          ),
          iconEnabledColor: Colors.white,
          items: items.map((e) => DropdownMenuItem(value: e['value'], child: Text(e['label']!))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _materialsSection(double horizontal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Material composition',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                fontFamily: _contentFontFamily,
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
                  fontFamily: _contentFontFamily,
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'Optional. Add material type and percentage (e.g. Rubber 40%).',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.82),
              fontFamily: _contentFontFamily,
            ),
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
                        fillColor: Color(0x2BFFFFFF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(100)),
                          borderSide: BorderSide(color: Color(0x33FFFFFF)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(100)),
                          borderSide: BorderSide(color: Color(0x33FFFFFF)),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      dropdownColor: Color(0xFF0D5B68),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontFamily: _contentFontFamily,
                      ),
                      iconEnabledColor: Colors.white,
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
                        hintStyle: TextStyle(color: Colors.white70),
                        fillColor: Color(0x2BFFFFFF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(100)),
                          borderSide: BorderSide(color: Color(0x33FFFFFF)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(100)),
                          borderSide: BorderSide(color: Color(0x33FFFFFF)),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: _contentFontFamily,
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

  Widget _imagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Photos',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            fontFamily: _contentFontFamily,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              GestureDetector(
                onTap: _submitting ? null : _pickImages,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.22)),
                  ),
                  child: const Icon(Icons.add_photo_alternate_outlined, color: Colors.white, size: 40),
                ),
              ),
              const SizedBox(width: 8),
              ...List.generate(_imageFiles.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _imageFiles[i],
                          width: 88,
                          height: 88,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(i),
                          child: const CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.error,
                            child: Icon(Icons.close, color: AppColors.textOnPrimary, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
