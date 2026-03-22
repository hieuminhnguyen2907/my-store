import 'package:flutter/material.dart';

import '../services/user_service.dart';
import '../utils/storage_service.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  List<Map<String, dynamic>> _addresses = [];
  bool _isLoading = true;
  bool _isSaving = false;

  void _showMessage(String message, {Color? backgroundColor}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: backgroundColor),
      );
  }

  Future<void> _persistAddresses({
    bool showSuccessMessage = false,
    bool popOnDone = false,
  }) async {
    final userData = await StorageService.getUserData() ?? {};
    userData['addresses'] = _addresses;

    // Always persist locally first so checkout can use addresses even if API sync fails.
    await StorageService.saveUserData(userData);

    final token = await StorageService.getToken();
    final userId = await StorageService.getUserId();
    String? syncError;

    if (token != null &&
        token.isNotEmpty &&
        userId != null &&
        userId.isNotEmpty) {
      try {
        await UserService.updateProfile(
          userId: userId,
          token: token,
          userData: {'addresses': _addresses},
        );
      } catch (e) {
        syncError = e.toString();
      }
    }

    if (!mounted) return;

    if (showSuccessMessage && !popOnDone) {
      final message = syncError == null
          ? 'Lưu địa chỉ thành công'
          : 'Đã lưu trên máy. Đồng bộ lên server thất bại: $syncError';
      _showMessage(
        message,
        backgroundColor: syncError == null ? null : Colors.orange,
      );
    }

    if (popOnDone) {
      Navigator.pop(context, true);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final userData = await StorageService.getUserData() ?? {};
    final raw = userData['addresses'];

    final parsed = <Map<String, dynamic>>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          parsed.add(Map<String, dynamic>.from(item));
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _addresses = parsed;
      _isLoading = false;
    });
  }

  Future<void> _saveAddresses() async {
    setState(() => _isSaving = true);

    try {
      await _persistAddresses(showSuccessMessage: true, popOnDone: true);
    } catch (e) {
      _showMessage(e.toString(), backgroundColor: Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _openAddressForm({
    Map<String, dynamic>? initial,
    int? index,
  }) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _AddressFormScreen(
          title: index == null ? 'Thêm địa chỉ' : 'Chỉnh sửa địa chỉ',
          initial: initial,
        ),
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      if (result['isDefault'] == true) {
        for (final address in _addresses) {
          address['isDefault'] = false;
        }
      }

      if (index == null) {
        _addresses.add(result);
      } else {
        _addresses[index] = result;
      }
    });

    try {
      await _persistAddresses();
    } catch (_) {
      // Manual save remains available if background sync fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Địa chỉ'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveAddresses,
            child: _isSaving
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Lưu'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddressForm(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
          ? const Center(child: Text('Chưa có địa chỉ nào'))
          : ListView.separated(
              itemCount: _addresses.length,
              separatorBuilder: (_, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _addresses[index];
                final isDefault = item['isDefault'] == true;
                return ListTile(
                  title: Text(item['fullname']?.toString() ?? '-'),
                  subtitle: Text(
                    '${item['address'] ?? ''}, ${item['city'] ?? ''}, ${item['country'] ?? ''}\n${item['phoneNumber'] ?? ''}',
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _openAddressForm(initial: item, index: index);
                        return;
                      }

                      setState(() {
                        _addresses.removeAt(index);
                      });

                      _persistAddresses();
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
                      PopupMenuItem(value: 'delete', child: Text('Xóa')),
                    ],
                  ),
                  leading: Icon(
                    isDefault ? Icons.location_on : Icons.location_on_outlined,
                    color: isDefault ? Colors.black : Colors.grey,
                  ),
                );
              },
            ),
    );
  }
}

class _AddressFormScreen extends StatefulWidget {
  final String title;
  final Map<String, dynamic>? initial;

  const _AddressFormScreen({required this.title, this.initial});

  @override
  State<_AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<_AddressFormScreen> {
  late final TextEditingController _fullnameController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _countryController;
  late final TextEditingController _phoneController;
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    _fullnameController = TextEditingController(
      text: widget.initial?['fullname']?.toString() ?? '',
    );
    _addressController = TextEditingController(
      text: widget.initial?['address']?.toString() ?? '',
    );
    _cityController = TextEditingController(
      text: widget.initial?['city']?.toString() ?? '',
    );
    _countryController = TextEditingController(
      text: widget.initial?['country']?.toString() ?? 'Việt Nam',
    );
    _phoneController = TextEditingController(
      text: widget.initial?['phoneNumber']?.toString() ?? '',
    );
    _isDefault = widget.initial?['isDefault'] == true;
  }

  @override
  void dispose() {
    _fullnameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _save() {
    final address = {
      'fullname': _fullnameController.text.trim(),
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'country': _countryController.text.trim(),
      'phoneNumber': _phoneController.text.trim(),
      'isDefault': _isDefault,
    };

    if ((address['fullname'] as String).isEmpty ||
        (address['address'] as String).isEmpty ||
        (address['city'] as String).isEmpty ||
        (address['phoneNumber'] as String).isEmpty) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Vui lòng điền đầy đủ thông tin bắt buộc'),
          ),
        );
      return;
    }

    Navigator.pop(context, address);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _fullnameController,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'Thành phố',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _countryController,
                decoration: const InputDecoration(
                  labelText: 'Quốc gia',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  border: OutlineInputBorder(),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Đặt làm địa chỉ mặc định'),
                value: _isDefault,
                onChanged: (value) {
                  setState(() => _isDefault = value);
                },
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                  ),
                  child: const Text(
                    'Lưu',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
