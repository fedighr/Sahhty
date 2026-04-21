replacements = {
    'Icons.check_circle': 'Iconsax.tick_circle',
    'Icons.arrow_back_ios_new': 'Iconsax.arrow_left',
    'Icons.error_outline': 'Iconsax.close_circle',
    'Icons.person_outline': 'Iconsax.user',
    'Icons.phone_outlined': 'Iconsax.call',
    'Icons.cake_outlined': 'Iconsax.calendar',
    'Icons.calendar_today': 'Iconsax.calendar',
    'Icons.save_outlined': 'Iconsax.tick_circle',
    'Icons.medical_information_outlined': 'Iconsax.hospital',
    'Icons.height': 'Iconsax.ruler',
    'Icons.monitor_weight_outlined': 'Iconsax.weight',
    'Icons.bloodtype': 'Iconsax.health',
    'Icons.healing': 'Iconsax.hospital',
    'Icons.warning_amber': 'Iconsax.warning_2',
    'Icons.medication': 'Iconsax.medicine',
    'Icons.local_hospital_outlined': 'Iconsax.hospital',
}

files = [
    'C:/Sahhty/frontend/lib/features/settings/screens/edit_profile_screen.dart',
    'C:/Sahhty/frontend/lib/features/settings/screens/edit_medical_screen.dart',
]

for fpath in files:
    with open(fpath, 'r', encoding='utf-8') as f:
        content = f.read()
    if 'iconsax/iconsax.dart' not in content:
        content = content.replace(
            "import 'package:sahhty/core/theme/app_theme.dart';",
            "import 'package:iconsax/iconsax.dart';\nimport 'package:sahhty/core/theme/app_theme.dart';"
        )
    for old, new in replacements.items():
        content = content.replace(old, new)
    with open(fpath, 'w', encoding='utf-8') as f:
        f.write(content)
    print('Done:', fpath)
