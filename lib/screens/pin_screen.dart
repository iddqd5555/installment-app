import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../services/api_service.dart';

class PinScreen extends StatefulWidget {
  final bool isSetup;
  const PinScreen({this.isSetup = false, Key? key}) : super(key: key);

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  String _confirmPin = '';
  String? _error;
  bool _isConfirmMode = false;
  bool _isLoading = false;
  final TextEditingController _pinController = TextEditingController();
  final ApiService apiService = ApiService();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _animController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Color get _accent => Theme.of(context).colorScheme.primary;
  Color get _bgCard => Theme.of(context).cardColor;
  TextStyle get _headline => GoogleFonts.prompt(
      color: _accent, fontWeight: FontWeight.bold, fontSize: 26, letterSpacing: 0.2);

  void _handlePinCompleted(String value) async {
    setState(() {
      _error = null;
      _isLoading = true;
    });

    try {
      if (widget.isSetup) {
        if (_isConfirmMode) {
          _confirmPin = value;
          if (_enteredPin == _confirmPin) {
            bool ok = false;
            try {
              ok = await apiService.setPin(_confirmPin);
            } catch (e) {
              setState(() { _error = "เกิดข้อผิดพลาด (ตั้ง PIN)"; });
              _isLoading = false;
              _pinController.clear();
              return;
            }
            if (ok) {
              Navigator.pop(context, true);
            } else {
              setState(() {
                _error = "ตั้ง PIN ไม่สำเร็จ ลองใหม่";
                _isConfirmMode = false;
                _enteredPin = '';
                _confirmPin = '';
              });
              _pinController.clear();
            }
          } else {
            setState(() {
              _error = "PIN ไม่ตรงกัน ลองใหม่";
              _isConfirmMode = false;
              _enteredPin = '';
              _confirmPin = '';
            });
            _pinController.clear();
          }
        } else {
          setState(() {
            _enteredPin = value;
            _isConfirmMode = true;
            _error = null;
          });
          Future.delayed(const Duration(milliseconds: 250), () {
            _pinController.clear();
          });
        }
      } else {
        bool ok = false;
        String? serverError;
        try {
          ok = await apiService.checkPin(value);
        } catch (e) {
          serverError = e.toString();
          print("PIN CHECK ERROR: $e");
        }

        if (ok) {
          Navigator.pop(context, true);
        } else {
          setState(() {
            if (serverError != null && serverError.contains("422")) {
              _error = "ยังไม่ได้ตั้งรหัส PIN หรือ PIN ไม่ถูกต้อง";
            } else if (serverError != null && serverError.contains("500")) {
              _error = "เซิร์ฟเวอร์มีปัญหา กรุณาลองใหม่";
            } else if (serverError != null) {
              _error = "เกิดข้อผิดพลาด: $serverError";
            } else {
              _error = "PIN ไม่ถูกต้อง";
            }
          });
          _pinController.clear();
        }
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.isSetup ? "ตั้งรหัส PIN" : "กรอกรหัส PIN",
          style: GoogleFonts.prompt(
              color: _accent, fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 0.2),
        ),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: _accent),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              child: Container(
                constraints: BoxConstraints(maxWidth: 410),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                decoration: BoxDecoration(
                  color: _bgCard,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black26 : Colors.black12,
                      blurRadius: 22,
                      offset: Offset(0, 7),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_rounded, color: _accent, size: 40),
                    SizedBox(height: 14),
                    Text(
                      widget.isSetup
                          ? (_isConfirmMode ? "ยืนยันรหัส PIN อีกครั้ง" : "ตั้งรหัส PIN 6 หลัก")
                          : "ใส่รหัส PIN เพื่อเข้าใช้งาน",
                      style: _headline.copyWith(fontSize: 19),
                    ),
                    SizedBox(height: 30),
                    PinCodeTextField(
                      appContext: context,
                      controller: _pinController,
                      length: 6,
                      obscureText: true,
                      blinkWhenObscuring: true,
                      animationType: AnimationType.fade,
                      keyboardType: TextInputType.number,
                      pinTheme: PinTheme(
                        shape: PinCodeFieldShape.box,
                        borderRadius: BorderRadius.circular(16),
                        fieldHeight: 52,
                        fieldWidth: 44,
                        activeColor: _accent,
                        selectedColor: _accent,
                        inactiveColor: Colors.grey[300]!,
                        activeFillColor: isDark ? Colors.black12 : Colors.grey[100]!,
                        selectedFillColor: Colors.white,
                        inactiveFillColor: isDark ? Colors.grey[850]! : Colors.grey[100]!,
                        borderWidth: 1.8,
                      ),
                      textStyle: GoogleFonts.prompt(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        letterSpacing: 2.5,
                      ),
                      cursorColor: _accent,
                      enableActiveFill: true,
                      onChanged: (value) {},
                      onCompleted: _handlePinCompleted,
                      animationDuration: Duration(milliseconds: 260),
                    ),
                    if (_isLoading)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: CircularProgressIndicator(),
                      ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 18),
                        child: Text(_error!, style: GoogleFonts.prompt(color: Colors.red, fontSize: 15)),
                      ),
                    if (widget.isSetup && _isConfirmMode)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: TextButton.icon(
                          icon: Icon(Icons.edit, color: _accent, size: 20),
                          label: Text("กลับไปแก้ไข PIN",
                              style: GoogleFonts.prompt(color: _accent, fontWeight: FontWeight.w500)),
                          onPressed: () {
                            setState(() {
                              _isConfirmMode = false;
                              _enteredPin = '';
                              _confirmPin = '';
                              _error = null;
                            });
                            _pinController.clear();
                          },
                        ),
                      )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
