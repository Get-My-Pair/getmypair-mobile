import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gmp/core/bgtheme.dart';
import 'package:gmp/core/widgets/app_gradient_next_style_button.dart';
import 'package:gmp/core/theme/app_colors.dart';
import 'package:gmp/core/widgets/greyed_button_shell.dart';
import 'package:gmp/core/utils/responsive.dart';
import 'package:gmp/core/widgets/gradient_page_shell.dart';
import 'package:gmp/features/articles/domain/entities/article.dart';
import 'package:gmp/features/articles/domain/usecases/get_article_by_id.dart';
import 'package:gmp/features/articles/domain/usecases/update_article.dart';
import 'package:gmp/features/articles/domain/usecases/upload_article_image.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/injection_container.dart';
import 'footwear_camera_capture_page.dart';
import 'upload_footwear_page.dart';

/// Module 3 – Edit shoe. Same footwear upload and size/colour UX as [ArticleCreatePage].
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
  static const String _contentFontFamily = 'Montserrat';
  final _formKey = GlobalKey<FormState>();
  final _modelController = TextEditingController();
  final _brandController = TextEditingController();
  final _customColorController = TextEditingController();

  Article? _article;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  String _category = 'sports_shoe';
  String _condition = 'good';
  String _sizeRegion = 'UK';
  String? _selectedSizeNumber;
  String? _selectedColorName;
  int? _purchaseYear;

  final List<Map<String, dynamic>> _materials = [];
  final List<File> _imageFiles = [];
  List<String> _existingImageUrls = [];

  static const List<Map<String, String>> _categories = [
    {'value': 'sports_shoe', 'label': 'Sports shoe'},
    {'value': 'casual', 'label': 'Casual'},
    {'value': 'formal', 'label': 'Formal'},
    {'value': 'sandal', 'label': 'Sandal'},
    {'value': 'boot', 'label': 'Boot'},
    {'value': 'slipper', 'label': 'Slipper'},
    {'value': 'other', 'label': 'Other'},
  ];

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

  static const int _minFootwearPhotos = FootwearCameraCapturePage.minAngles;
  static const int _maxFootwearPhotos = FootwearCameraCapturePage.maxAngles;

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

  String? get _resolvedColor {
    if (_selectedColorName == null) return null;
    if (_selectedColorName == 'Other') {
      final custom = _customColorController.text.trim();
      return custom.isEmpty ? null : custom;
    }
    return _selectedColorName;
  }

  bool get _hasPhotos =>
      _existingImageUrls.isNotEmpty ||
      (_imageFiles.length >= _minFootwearPhotos &&
          _imageFiles.length <= _maxFootwearPhotos);

  bool get _canSave =>
      !_submitting &&
      _modelController.text.trim().isNotEmpty &&
      _brandController.text.trim().isNotEmpty &&
      _resolvedColor != null &&
      _selectedSizeNumber != null &&
      _purchaseYear != null &&
      _hasPhotos;

  int get _photoCount =>
      _imageFiles.isNotEmpty ? _imageFiles.length : _existingImageUrls.length;

  @override
  void initState() {
    super.initState();
    void onFieldChanged() {
      if (mounted) setState(() {});
    }
    _modelController.addListener(onFieldChanged);
    _brandController.addListener(onFieldChanged);
    _customColorController.addListener(onFieldChanged);

    final seed = widget.initialArticle;
    if (seed != null && seed.id == widget.articleId) {
      _applyArticle(seed);
      _loading = false;
    }
    _load();
  }

  @override
  void dispose() {
    _modelController.dispose();
    _brandController.dispose();
    _customColorController.dispose();
    super.dispose();
  }

  void _parseShoeSize(String? raw) {
    if (raw == null || raw.trim().isEmpty) return;
    final m = RegExp(r'^(UK|US|EU)\s*:\s*(.+)$', caseSensitive: false)
        .firstMatch(raw.trim());
    if (m == null) return;
    _sizeRegion = m.group(1)!.toUpperCase();
    final num = m.group(2)!.trim();
    if (_sizesForRegion.contains(num)) {
      _selectedSizeNumber = num;
    }
  }

  void _applyArticle(Article article) {
    _article = article;
    _error = null;
    _modelController.text = article.model;
    _brandController.text = article.brand;
    _category = article.category;
    _condition = article.condition.isNotEmpty ? article.condition : 'good';
    _purchaseYear = article.purchaseYear;
    _existingImageUrls = List<String>.from(article.images);
    _imageFiles.clear();

    _selectedColorName = null;
    _customColorController.clear();
    final color = article.color.trim();
    if (color.isNotEmpty) {
      if (_colorNames.contains(color)) {
        _selectedColorName = color;
      } else {
        _selectedColorName = 'Other';
        _customColorController.text = color;
      }
    }

    _selectedSizeNumber = null;
    _parseShoeSize(article.shoeSize);

    _materials.clear();
    for (final m in article.materials) {
      _materials.add({
        'type': _materialTypes.contains(m.type) ? m.type : _materialTypes.first,
        'percentage': m.percentage,
      });
    }
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

  Future<void> _openUploadFootwear() async {
    final files = await Navigator.of(context).push<List<File>>(
      MaterialPageRoute(
        builder: (_) => UploadFootwearPage(
          initialFiles: List<File>.from(_imageFiles),
        ),
      ),
    );
    if (!mounted) return;
    if (files == null || files.isEmpty) return;
    setState(() {
      _imageFiles
        ..clear()
        ..addAll(files);
      _error = null;
    });
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _article == null) return;
    if (_purchaseYear == null) {
      setState(() => _error = 'Please select a purchase year.');
      return;
    }
    if (!_hasPhotos) {
      setState(() {
        _error =
            'Please keep existing photos or upload at least $_minFootwearPhotos side-profile photo(s) using Upload Footwear.';
      });
      return;
    }
    if (_selectedSizeNumber == null || _resolvedColor == null) {
      setState(() => _error = 'Please select shoe size and colour.');
      return;
    }

    final tokenResult = await sl<GetValidAccessToken>().call();
    if (!mounted) return;
    await tokenResult.fold(
      (_) async {
        if (!context.mounted) return;
        setState(() => _error = 'Please sign in again');
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

          List<String>? imageUrls;
          if (_imageFiles.isNotEmpty) {
            final uploaded = <String>[];
            for (int i = 0; i < _imageFiles.length; i++) {
              if (!mounted) return;
              final bytes = await _imageFiles[i].readAsBytes();
              final name =
                  'shoe_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
              final url = await sl<UploadArticleImage>().call(
                token,
                articleId: _article!.id,
                imageBytes: bytes,
                fileName: name,
              );
              uploaded.add(url);
            }
            imageUrls = uploaded;
          } else if (_existingImageUrls.isNotEmpty) {
            imageUrls = _existingImageUrls;
          }

          await sl<UpdateArticle>().call(
            token,
            _article!.id,
            brand: _brandController.text.trim(),
            model: _modelController.text.trim(),
            category: _category,
            color: _resolvedColor!,
            purchaseYear: _purchaseYear,
            condition: _condition,
            materials: materials,
            imageUrls: imageUrls,
            shoeSize: _shoeSizePayload,
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

    if (_error != null && _article == null) {
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
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.horizontalPaddingOf(context),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.error,
                  ),
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
                  leading: const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  showTrailingIcon: false,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_article == null) {
      return _buildWithBg(
        body: const Center(child: CircularProgressIndicator(color: Colors.white)),
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
              _dropdownWithLabel(
                'Category',
                _category,
                _categories,
                (v) => setState(() => _category = v ?? _category),
              ),
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

  Widget _field(
    TextEditingController ctrl,
    String label, {
    String? placeholder,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
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
        _glassInputShell(
          child: TextFormField(
            controller: ctrl,
            enabled: !_submitting,
            textCapitalization: textCapitalization,
            style: _inputTextStyle(),
            decoration: _glassInputDecoration(hintText: placeholder),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
        ),
      ],
    );
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
                        color: _purchaseYear != null
                            ? Colors.white
                            : Colors.white70,
                      ),
                    ),
                  ),
                  if (_purchaseYear != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20, color: Colors.white70),
                      onPressed: _submitting
                          ? null
                          : () => setState(() => _purchaseYear = null),
                      style: IconButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(24, 24),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                  else
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 20,
                      color: Colors.white,
                    ),
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
            items: items
                .map(
                  (e) => DropdownMenuItem(
                    value: e['value'],
                    child: Text(e['label']!),
                  ),
                )
                .toList(),
            onChanged: _submitting ? null : onChanged,
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
    );
  }

  TextStyle _inputTextStyle({Color color = Colors.white, double fontSize = 16}) {
    return GoogleFonts.montserrat(
      color: color,
      fontSize: fontSize,
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
        if (_photoCount > 0) ...[
          const SizedBox(height: 8),
          Text(
            _imageFiles.isNotEmpty
                ? '${_imageFiles.length}/$_maxFootwearPhotos new photos ready to save'
                : '${_existingImageUrls.length} existing photo(s)',
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

    final enabled = onPressed != null && !isBusy;

    if (!enabled) {
      return GreyedButtonShell(
        height: 50,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: showLoader && isBusy
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: AppColors.greyedButtonLabel,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    label,
                    style: GoogleFonts.boldonse(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.greyedButtonLabel,
                    ),
                  ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: teal,
          elevation: 2,
          shadowColor: Colors.black26,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          minimumSize: const Size(0, 50),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
            side: const BorderSide(
              color: cyanBorder,
              width: 1,
            ),
          ),
        ),
        child: Text(
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
