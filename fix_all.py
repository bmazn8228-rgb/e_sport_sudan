import os
import re

lib_dir = r"c:\Users\Data\Downloads\stitch_e_sport_sudan_ui_ux_design_system (1)\e_sport_sudan\lib"

patterns = [
    (r"import\s+['\"]\.\./\.\./\.\./core/([^'\"]+)['\"];", r"import 'package:e_sport_sudan/core/\1';"),
    (r"import\s+['\"]\.\./\.\./core/([^'\"]+)['\"];", r"import 'package:e_sport_sudan/core/\1';"),
    (r"import\s+['\"]\.\./core/([^'\"]+)['\"];", r"import 'package:e_sport_sudan/core/\1';"),
    (r"import\s+['\"]\.\./\.\./([^'\"]+)['\"];", r"import 'package:e_sport_sudan/features/\1';"),
]

count = 0
for root, _, files in os.walk(lib_dir):
    for file in files:
        if file.endswith(".dart"):
            path = os.path.join(root, file)
            with open(path, "r", encoding="utf-8") as f:
                content = f.read()
            
            new_content = content
            for pat, repl in patterns:
                new_content = re.sub(pat, repl, new_content)
            
            if new_content != content:
                with open(path, "w", encoding="utf-8") as f:
                    f.write(new_content)
                count += 1
                print(f"Updated: {file}")

print(f"Total files updated in lib: {count}")

# Fix test/widget_test.dart
test_path = r"c:\Users\Data\Downloads\stitch_e_sport_sudan_ui_ux_design_system (1)\e_sport_sudan\test\widget_test.dart"
if os.path.exists(test_path):
    with open(test_path, "r", encoding="utf-8") as f:
        test_content = f.read()
    test_content = test_content.replace("const MyApp()", "const ESportSudanApp()")
    with open(test_path, "w", encoding="utf-8") as f:
        f.write(test_content)
    print("Updated test/widget_test.dart")
