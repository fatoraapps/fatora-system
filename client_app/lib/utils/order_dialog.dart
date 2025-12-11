import 'package:flutter/material.dart';

Future<void> showSubmitOrderDialog({
  required BuildContext context,
  required double totalAmount,
  required int supplierId,
  required String supplierName,
}) async {
  bool includeNote = false;
  TextEditingController noteController = TextEditingController();

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),

            title: Text(
              "إرسال الطلب إلى $supplierName",
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: includeNote,
                      onChanged: (v) {
                        setState(() {
                          includeNote = v ?? false;
                        });
                      },
                    ),
                    const Expanded(
                      child: Text(
                        "إضافة ملاحظة للمورد",
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),

                TextField(
                  enabled: includeNote,
                  controller: noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "اكتب ملاحظتك هنا...",
                    fillColor: includeNote ? Colors.white : Colors.grey.shade200,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: const [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 26, // ← أكبر
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "تنبيه هام: إضافة ملاحظة يؤدي إلى تأخير وصول طلبك إلى المورد.",
                        style: TextStyle(
                          fontSize: 13.5, // ← أكبر
                          color: Colors.orange,
                          fontWeight: FontWeight.w900, // ← أوضح
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),

              ],
            ),

            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("إلغاء"),
              ),

              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);

                  // هنا تستدعي API
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "تم إرسال الطلب بنجاح!",
                        textAlign: TextAlign.center,
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Text("إرسال الطلب"),
              ),
            ],
          );
        },
      );
    },
  );
}
