import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gmp/core/bgtheme.dart';
import 'package:gmp/core/theme/app_colors.dart';
import 'package:gmp/core/utils/responsive.dart';
import 'package:gmp/features/articles/domain/usecases/create_article.dart';
import 'package:gmp/features/articles/domain/usecases/upload_article_image.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/injection_container.dart';
import 'article_details_page.dart';
import 'footwear_camera_capture_page.dart';
import 'upload_footwear_page.dart';

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
  final _modelController = TextEditingController(text: 'Air Max');
  final _brandController = TextEditingController(text: 'Nike');

  String _category = 'sports_shoe';
  String _sizeRegion = 'UK';
  String? _selectedSizeNumber;
  String? _selectedColorName;
  final _customColorController = TextEditingController();

  static const List<String> _ukSizes = [
    '03', '04', '05', '06', '07', '08', '09', '10', '11', '12', '13', '14',
  ];
  static const List<String> _usSizes = [
    '06', '07', '08', '09', '10', '11', '12', '13',
  ];
  static const List<String> _euSizes = [
    '35', '36', '37', '38', '39', '40', '41', '42', '43', '44', '45', '46', '47',
  ];
  static const List<String> _sizeRegions = ['UK', 'US', 'EU'];
  static const List<String> _colorNames = [
    'Black',
    'White',
    'Brown',
    'Navy',
    'Denim',
    'Grey',
    'Green',
    'Red',
    'Blue',
    'Tan',
    'Pink',
    'Yellow',
    'Orange',
    'Other',
  ];
  String _condition = 'good';
  int? _purchaseYear;
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
  void initState() {
    super.initState();
    void onFieldChanged() {
      if (mounted) setState(() {});
    }
    _modelController.addListener(onFieldChanged);
    _brandController.addListener(onFieldChanged);
  }

  List<String> get _sizesForRegion {
    switch (_sizeRegion) {
      case 'US':
        return _usSizes;
      case 'EU':
        return _euSizes;
      default:
        return _ukSizes;
    }
  }

  String? get _shoeSizePayload {
    final num = _selectedSizeNumber?.trim();
    if (num == null || num.isEmpty) return null;
    return '$_sizeRegion: $num';
  }

  void _setSizeRegion(String region) {
    setState(() {
      _sizeRegion = region;
      if (_selectedSizeNumber != null &&
          !_sizesForRegion.contains(_selectedSizeNumber)) {
        _selectedSizeNumber = null;
      }
    });
  }

  String? get _resolvedColor {
    if (_selectedColorName == null) return null;
    if (_selectedColorName == 'Other') {
      final custom = _customColorController.text.trim();
      return custom.isEmpty ? null : custom;
    }
    return _selectedColorName;
  }

  @override
  void dispose() {
    _modelController.dispose();
    _brandController.dispose();
    _customColorController.dispose();
    super.dispose();
  }

  static const int _minFootwearPhotos = FootwearCameraCapturePage.minAngles;
  static const int _maxFootwearPhotos = FootwearCameraCapturePage.maxAngles;

  bool get _canSave =>
      !_submitting &&
      _modelController.text.trim().isNotEmpty &&
      _brandController.text.trim().isNotEmpty &&
      _resolvedColor != null &&
      _selectedSizeNumber != null &&
      _purchaseYear != null &&
      _imageFiles.length >= _minFootwearPhotos &&
      _imageFiles.length <= _maxFootwearPhotos;

  Future<void> _openUploadFootwear() async {
    final files = await Navigator.of(context).push<List<File>>(
      MaterialPageRoute(
        builder: (_) => UploadFootwearPage(initialFiles: List<File>.from(_imageFiles)),
      ),
    );
    if (!mounted) return;
    if (files == null || files.isEmpty) return;
    setState(() {
      _imageFiles
        ..clear()
        ..addAll(files);
      _uploadedImageUrls.clear();
      _errorMessage = null;
    });
  }

  Future<void> _submit() async {
    _errorMessage = null;
    if (!_formKey.currentState!.validate()) return;
    if (_purchaseYear == null) {
      setState(() {
        _errorMessage =
            'Please select a purchase year. The API requires this to register your footwear.';
      });
      return;
    }
    if (_imageFiles.length < _minFootwearPhotos) {
      setState(() {
        _errorMessage =
            'Please upload at least $_minFootwearPhotos side-profile photos using Upload Footwear.';
      });
      return;
    }
    if (_selectedSizeNumber == null || _resolvedColor == null) {
      setState(() {
        _errorMessage = 'Please select shoe size and colour.';
      });
      return;
    }

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
            brand: _brandController.text.trim(),
            model: _modelController.text.trim(),
            category: _category,
            color: _resolvedColor!,
            purchaseYear: _purchaseYear,
            condition: _condition,
            materials: materials,
            imageUrls: [], // Images added via upload-image after create
            shoeSize: _shoeSizePayload,
          );
          if (!mounted) return;

          // Upload each image to the new article
          for (int i = 0; i < _imageFiles.length; i++) {
            if (!mounted) return;
            final bytes = await _imageFiles[i].readAsBytes();
            final path = _imageFiles[i].path.toLowerCase();
            final ext = path.endsWith('.png') ? 'png' : 'jpg';
            final name =
                'shoe_${DateTime.now().millisecondsSinceEpoch}_$i.$ext';
            await sl<UploadArticleImage>().call(token,
              articleId: article.id,
              imageBytes: bytes,
              fileName: name,
            );
          }

          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ArticleDetailsPage(
                articleId: article.id,
                initialArticle: article,
              ),
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
      body: Stack(
        children: [
          ...BgTheme.background(),
          SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.fromLTRB(horizontal, 30, horizontal, 28),
                children: [
                Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(width: 26, height: 26),
                      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                      onPressed: _submitting ? null : () => Navigator.pop(context),
                      icon: SvgPicture.asset(
                        'assets/images/chevron-left.svg',
                        width: 26,
                        height: 26,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'Add footwear content',
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
                _field(
                  _modelController,
                  'Name your footwear',
                  placeholder: 'Nike Shoes',
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 20),
                _field(
                  _brandController,
                  'Brand',
                  placeholder: 'Nike',
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 20),
                _purchaseYearDropdown(),
                const SizedBox(height: 20),
                _dropdownWithLabel('Category', _category, _categories, (v) => setState(() => _category = v!)),
                const SizedBox(height: 24),
                _uploadFootwearTopSection(),
                const SizedBox(height: 20),
                _sizeAndColorSection(),
                const SizedBox(height: 24),
                _buildActionButton(
                  label: 'Save Footwear',
                  onPressed: _canSave ? _submit : null,
                  isBusy: _submitting,
                  showLoader: true,
                ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String hint, {
    String? placeholder,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            hint,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
        _glassInputShell(
          child: TextFormField(
            controller: ctrl,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            style: _inputTextStyle(),
            decoration: _glassInputDecoration(hintText: placeholder),
            validator: (v) {
              if (hint.startsWith('Purchase')) return null;
              return (v == null || v.trim().isEmpty) ? 'Required' : null;
            },
          ),
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
            'Purchased On (required)',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontFamily: _contentFontFamily,
            ),
          ),
        ),
        _glassInputShell(
          child: InkWell(
            onTap: _submitting ? null : _openPurchaseYearPicker,
            borderRadius: BorderRadius.circular(100),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _purchaseYear?.toString() ?? 'Not specified',
                      style: _inputTextStyle(
                        color: _purchaseYear != null ? Colors.white : Colors.white70,
                      ),
                    ),
                  ),
                  if (_purchaseYear != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20, color: Colors.white70),
                      onPressed: _submitting ? null : () => setState(() => _purchaseYear = null),
                      style: IconButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(24, 24),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                  else
                    const Icon(Icons.calendar_today_outlined, size: 20, color: Colors.white),
                ],
              ),
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
        _glassInputShell(
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: _glassInputDecoration(),
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
        ),
      ],
    );
  }

  Widget _glassInputShell({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          ),
          child: child,
        ),
      ),
    );
  }

  InputDecoration _glassInputDecoration({String? hintText}) {
    return InputDecoration(
      isDense: true,
      hintText: hintText,
      hintStyle: GoogleFonts.montserrat(
        color: Colors.white70,
        fontSize: 16,
      ),
      filled: true,
      fillColor: Colors.transparent,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
    );
  }

  TextStyle _inputTextStyle({Color color = Colors.white, double fontSize = 16}) {
    return GoogleFonts.montserrat(
      color: color,
      fontSize: fontSize,
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
                      style: const TextStyle(
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
                      decoration: InputDecoration(
                        hintText: '%',
                        filled: true,
                        hintStyle: GoogleFonts.montserrat(color: Colors.white70),
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
                      style: _inputTextStyle(),
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

  Widget _sizeAndColorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sizeDropdown(),
        const SizedBox(height: 20),
        _colorDropdown(),
      ],
    );
  }

  Future<void> _openColorPickerSheet() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF0D5B68),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Select colour',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(
                height: 320,
                child: ListView.builder(
                  itemCount: _colorNames.length,
                  itemBuilder: (context, index) {
                    final name = _colorNames[index];
                    final selected = _selectedColorName == name;
                    return ListTile(
                      title: Text(
                        name,
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      trailing: selected
                          ? const Icon(Icons.check, color: Color(0xFF09DFFF))
                          : null,
                      onTap: () => Navigator.pop(ctx, name),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _selectedColorName = picked);
    }
  }

  Widget _colorDropdown() {
    final presetSelected = _selectedColorName != null &&
        _colorNames.contains(_selectedColorName);
    final displayLabel = _selectedColorName == 'Other'
        ? (_customColorController.text.trim().isEmpty
            ? 'Other (type below)'
            : _customColorController.text.trim())
        : _selectedColorName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            'Colour',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
        _glassInputShell(
          child: InkWell(
            onTap: _submitting ? null : _openColorPickerSheet,
            borderRadius: BorderRadius.circular(100),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      displayLabel ?? 'Select colour',
                      style: _inputTextStyle(
                        color: displayLabel != null
                            ? Colors.white
                            : Colors.white70,
                      ),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
        if (_selectedColorName == 'Other') ...[
          const SizedBox(height: 10),
          _glassInputShell(
            child: TextFormField(
              controller: _customColorController,
              enabled: !_submitting,
              style: _inputTextStyle(),
              textCapitalization: TextCapitalization.words,
              decoration: _glassInputDecoration(
                hintText: 'Type colour name',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ] else if (presetSelected) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              'Selected: $_selectedColorName',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _sizeDropdown() {
    final numbers = _sizesForRegion;
    final sizeValue = _selectedSizeNumber != null &&
            numbers.contains(_selectedSizeNumber)
        ? _selectedSizeNumber
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            'Size',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 4,
              child: _glassInputShell(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _sizeRegion,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    dropdownColor: const Color(0xFF0D5B68),
                    style: _inputTextStyle(),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                    ),
                    items: _sizeRegions
                        .map(
                          (r) => DropdownMenuItem<String>(
                            value: r,
                            child: Text(r),
                          ),
                        )
                        .toList(),
                    onChanged: _submitting
                        ? null
                        : (v) {
                            if (v != null) _setSizeRegion(v);
                          },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 6,
              child: _glassInputShell(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: sizeValue,
                    hint: Text(
                      'Number',
                      style: _inputTextStyle(color: Colors.white70),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    dropdownColor: const Color(0xFF0D5B68),
                    style: _inputTextStyle(),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                    ),
                    items: numbers
                        .map(
                          (n) => DropdownMenuItem<String>(
                            value: n,
                            child: Text(n),
                          ),
                        )
                        .toList(),
                    onChanged: _submitting
                        ? null
                        : (v) => setState(() => _selectedSizeNumber = v),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (sizeValue != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              'Selected: $_sizeRegion $sizeValue',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _uploadFootwearTopSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildActionButton(
          label: 'Upload Footwear',
          onPressed: _submitting ? null : _openUploadFootwear,
          isBusy: _submitting,
        ),
        if (_imageFiles.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '${_imageFiles.length}/$_maxFootwearPhotos photos added',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback? onPressed,
    required bool isBusy,
    bool showLoader = false,
  }) {
    const teal = Color(0xFF12899B);
    const cyanBorder = Color(0xFF09DFFF);
    const disabledFill = Color(0xFF6B7B80);
    const disabledBorder = Color(0xFF8A9A9F);
    const disabledLabel = Color(0xFFB8C4C8);

    final enabled = onPressed != null && !isBusy;

    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? Colors.white : disabledFill,
          foregroundColor: enabled ? teal : disabledLabel,
          disabledBackgroundColor: disabledFill,
          disabledForegroundColor: disabledLabel,
          elevation: enabled ? 2 : 0,
          shadowColor: Colors.black26,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          minimumSize: const Size(0, 50),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
            side: BorderSide(
              color: enabled ? cyanBorder : disabledBorder,
              width: 1,
            ),
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
                  color: enabled ? teal : disabledLabel,
                ),
              ),
      ),
    );
  }
}
