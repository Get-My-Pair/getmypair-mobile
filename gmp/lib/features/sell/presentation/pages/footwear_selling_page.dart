import 'package:flutter/material.dart';
import 'package:gmp/core/widgets/app_feedback_alert.dart';
import 'package:gmp/features/articles/domain/entities/article.dart';
import 'package:gmp/features/auth/domain/usecases/get_valid_access_token.dart';
import 'package:gmp/features/sell/data/sell_remote_datasource.dart';
import 'package:gmp/features/sell/presentation/pages/my_footwear_rack_page.dart';
import 'package:gmp/features/sell/presentation/widgets/sell_shell.dart';
import 'package:gmp/injection_container.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

/// Luxury / Everyday selling flow: price, condition, proofs, then auction submit.
class FootwearSellingPage extends StatefulWidget {
  final Article article;
  final String footwearType;

  const FootwearSellingPage({
    super.key,
    required this.article,
    required this.footwearType,
  });

  @override
  State<FootwearSellingPage> createState() => _FootwearSellingPageState();
}

class _FootwearSellingPageState extends State<FootwearSellingPage> {
  static const _grades = [
    ('brand_new_in_box', 'Brand New in Box'),
    ('like_new', 'Like New'),
    ('gently_used', 'Gently Used'),
  ];

  static const _proofs = [
    ('receipt', 'Original Receipt / Invoice'),
    ('purchaseEmail', 'Proof of Purchase Email'),
    ('authenticityCard', 'Authenticity Certificate / Card'),
    ('boxLabel', 'Box Label & Serial Code Photo'),
  ];

  final _retailController = TextEditingController();
  final _baseController = TextEditingController();
  final _picker = ImagePicker();

  String _grade = 'like_new';
  bool _gradeOpen = false;
  int _step = 0;
  bool _busy = false;
  String? _error;
  final Map<String, String> _proofUrls = {};
  DateTime? _start;
  DateTime? _end;

  bool get _isLuxury => widget.footwearType == 'luxury';
  bool get _proofsComplete => _proofs.every((item) => _proofUrls.containsKey(item.$1));

  @override
  void dispose() {
    _retailController.dispose();
    _baseController.dispose();
    super.dispose();
  }

  void _formatPrice(TextEditingController controller, String value) {
    final amount = parseInr(value);
    final formatted = amount == null ? '' : formatInr(amount);
    if (formatted == controller.text) return;
    controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  Future<void> _pickProof(String proofType) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take picture'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Upload photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final file = await _picker.pickImage(source: source, imageQuality: 82);
    if (file == null || !mounted) return;

    final tokenResult = await sl<GetValidAccessToken>().call();
    if (!mounted) return;
    await tokenResult.fold(
      (_) async {
        setState(() => _error = 'Please sign in again');
      },
      (token) async {
        setState(() {
          _busy = true;
          _error = null;
        });
        try {
          final bytes = await file.readAsBytes();
          final url = await sl<SellRemoteDataSource>().uploadProof(
            token,
            proofType: proofType,
            imageBytes: bytes,
            fileName: 'proof_$proofType.jpg',
          );
          if (!mounted) return;
          setState(() {
            _proofUrls[proofType] = url;
            _busy = false;
          });
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _busy = false;
            _error = e.toString();
          });
        }
      },
    );
  }

  Future<void> _uploadNext() async {
    for (final item in _proofs) {
      if (!_proofUrls.containsKey(item.$1)) {
        await _pickProof(item.$1);
        return;
      }
    }
  }

  void _goToAuction() {
    final price = parseInr(_retailController.text);
    if (price == null || price < 1) {
      setState(() => _error = 'Enter the original retail price');
      return;
    }
    if (!_proofsComplete) {
      setState(() => _error = 'Please upload images.');
      return;
    }
    _baseController.text = formatInr(price);
    setState(() {
      _step = 1;
      _error = null;
    });
  }

  Future<void> _pickDate({required bool start}) async {
    final now = DateTime.now();
    final initial = start ? (_start ?? now) : (_end ?? _start ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 3),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _start = picked;
        if (_end != null && !_end!.isAfter(picked)) _end = null;
      } else {
        _end = picked;
      }
    });
  }

  String _dateLabel(DateTime? date) {
    if (date == null) return 'dd/mm/yyyy';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  Future<void> _submit() async {
    final retail = parseInr(_retailController.text);
    final base = parseInr(_baseController.text);
    if (retail == null || base == null) {
      setState(() => _error = 'Enter the base price');
      return;
    }
    if (_start == null || _end == null || !_end!.isAfter(_start!)) {
      setState(() => _error = 'Choose a start date and a later end date');
      return;
    }

    final tokenResult = await sl<GetValidAccessToken>().call();
    if (!mounted) return;
    await tokenResult.fold(
      (_) async {
        setState(() => _error = 'Please sign in again');
      },
      (token) async {
        setState(() {
          _busy = true;
          _error = null;
        });
        try {
          await sl<SellRemoteDataSource>().createListing(
            token,
            articleId: widget.article.id,
            footwearType: widget.footwearType,
            originalRetailPrice: retail,
            conditionGrade: _grade,
            proofs: Map<String, String>.from(_proofUrls),
            basePrice: base,
            auctionStartDate: _start!,
            auctionEndDate: _end!,
          );
          if (!mounted) return;
          await showAppFeedbackAlert(
            context,
            title: 'Submitted',
            message: 'Your footwear is in review. It shows in yellow on your rack until it is approved or rejected.',
            type: AppFeedbackType.success,
          );
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => MyFootwearRackPage(footwearType: widget.footwearType),
            ),
          );
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _busy = false;
            _error = e.toString();
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SellFlowScaffold(
      children: [
        SellPageHeader(
          title: _isLuxury ? 'Luxury' : 'Everyday',
          onBack: _step == 0
              ? null
              : () => setState(() {
                    _step = 0;
                    _error = null;
                  }),
        ),
        const SizedBox(height: 8),
        _productHeader(),
        const SizedBox(height: 18),
        if (_error != null) ...[
          Text(_error!, style: GoogleFonts.montserrat(color: Colors.red, fontSize: 13)),
          const SizedBox(height: 10),
        ],
        if (_step == 0) ..._detailsStep() else ..._auctionStep(),
      ],
    );
  }

  Widget _productHeader() {
    final image = widget.article.rackHeroImagePath;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.article.model,
                style: GoogleFonts.boldonse(
                  color: SellColors.teal,
                  fontSize: 22,
                  height: 1.15,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.article.brand,
                style: GoogleFonts.montserrat(fontSize: 14, color: Colors.black87),
              ),
            ],
          ),
        ),
        SellShoeThumb(imageUrl: image),
      ],
    );
  }

  List<Widget> _detailsStep() {
    final gradeLabel = _grades.firstWhere((item) => item.$1 == _grade).$2;
    return [
      Text('Original Retail Price', style: GoogleFonts.montserrat(fontSize: 15)),
      const SizedBox(height: 8),
      _priceField(_retailController),
      const SizedBox(height: 16),
      Text('Condition Grading', style: GoogleFonts.montserrat(fontSize: 15)),
      const SizedBox(height: 8),
      _gradeField(gradeLabel),
      if (_gradeOpen) _gradeMenu(),
      const SizedBox(height: 16),
      Text(
        'Help us confirm your footwear is authentic by uploading:',
        style: GoogleFonts.montserrat(fontSize: 14, height: 1.35),
      ),
      const SizedBox(height: 8),
      for (final item in _proofs)
        InkWell(
          onTap: _busy ? null : () => _pickProof(item.$1),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Icon(
                  _proofUrls.containsKey(item.$1) ? Icons.check : Icons.circle,
                  size: _proofUrls.containsKey(item.$1) ? 18 : 7,
                  color: SellColors.teal,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(item.$2, style: GoogleFonts.montserrat(fontSize: 14)),
                ),
              ],
            ),
          ),
        ),
      if (!_proofsComplete) ...[
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.error, color: Color(0xFFE53935), size: 16),
            const SizedBox(width: 6),
            Text(
              'Please upload images.',
              style: GoogleFonts.montserrat(color: const Color(0xFFE53935), fontSize: 13),
            ),
          ],
        ),
      ],
      const SizedBox(height: 14),
      _outlineButton(
        label: 'Upload Photos or Take Pictures',
        onPressed: _busy ? null : _uploadNext,
      ),
      if (_proofsComplete) ...[
        const SizedBox(height: 16),
        Center(
          child: FilledButton(
            onPressed: _busy ? null : _goToAuction,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0B3E46),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: const StadiumBorder(),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Next', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                SizedBox(width: 8),
                Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ],
    ];
  }

  List<Widget> _auctionStep() {
    return [
      Text('Base Price', style: GoogleFonts.montserrat(fontSize: 15)),
      const SizedBox(height: 8),
      _priceField(_baseController),
      const SizedBox(height: 16),
      Text(
        'Set Auction Duration',
        style: GoogleFonts.boldonse(color: SellColors.ink, fontSize: 16),
      ),
      const SizedBox(height: 10),
      Text('Start Date', style: GoogleFonts.montserrat(fontSize: 14)),
      const SizedBox(height: 6),
      _dateField(_dateLabel(_start), () => _pickDate(start: true)),
      const SizedBox(height: 12),
      Text('End Date', style: GoogleFonts.montserrat(fontSize: 14)),
      const SizedBox(height: 6),
      _dateField(_dateLabel(_end), () => _pickDate(start: false)),
      const SizedBox(height: 22),
      _submitButton(),
    ];
  }

  Widget _priceField(TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      onChanged: (value) => _formatPrice(controller, value),
      style: GoogleFonts.montserrat(
        color: SellColors.price,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        prefixText: '₹ ',
        prefixStyle: GoogleFonts.montserrat(
          color: SellColors.price,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: SellColors.line, width: 1.4),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: SellColors.teal, width: 1.6),
        ),
      ),
    );
  }

  Widget _gradeField(String label) {
    return InkWell(
      onTap: () => setState(() => _gradeOpen = !_gradeOpen),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: SellColors.line, width: 1.4),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.montserrat(color: SellColors.teal, fontSize: 16),
              ),
            ),
            Icon(
              _gradeOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: SellColors.teal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradeMenu() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Column(
        children: [
          for (final item in _grades)
            InkWell(
              onTap: () => setState(() {
                _grade = item.$1;
                _gradeOpen = false;
              }),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE6E6E6))),
                ),
                child: Text(item.$2, style: GoogleFonts.montserrat(fontSize: 15)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dateField(String label, VoidCallback onTap) {
    final empty = label == 'dd/mm/yyyy';
    return InkWell(
      onTap: _busy ? null : onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: SellColors.line, width: 1.4),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.montserrat(
                  color: empty ? SellColors.teal.withValues(alpha: 0.7) : SellColors.teal,
                  fontSize: 16,
                ),
              ),
            ),
            const Icon(Icons.calendar_today_outlined, color: SellColors.teal, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _outlineButton({required String label, required VoidCallback? onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: SellColors.teal,
          side: const BorderSide(color: SellColors.line, width: 1.4),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
        ),
        child: _busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: SellColors.teal),
              )
            : Text(
                label,
                style: GoogleFonts.montserrat(
                  color: SellColors.teal,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xFF062F35), Color(0xFF12D0E4)],
          ),
        ),
        child: TextButton(
          onPressed: _busy ? null : _submit,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  'Submit for Authenticity Review',
                  style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700),
                ),
        ),
      ),
    );
  }
}
