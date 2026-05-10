import re
import os

def shift_steps(file_path, threshold=4):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    def replacer(match):
        num = int(match.group(1))
        if num >= threshold:
            return match.group(0).replace(str(num), str(num + 1))
        return match.group(0)

    # Shift 'case N:'
    content = re.sub(r'case (\d+):', replacer, content)
    # Shift '_currentStep == N'
    content = re.sub(r'_currentStep == (\d+)', replacer, content)
    # Shift '_currentStep >= N'
    content = re.sub(r'_currentStep >= (\d+)', replacer, content)
    # Shift '_currentStep < N'
    content = re.sub(r'_currentStep < (\d+)', replacer, content)
    # Shift '_currentStep = N'
    content = re.sub(r'_currentStep = (\d+)', replacer, content)
    # Shift 'viewModel.currentStep == N'
    content = re.sub(r'viewModel\.currentStep == (\d+)', replacer, content)
    # Shift 'step == N'
    content = re.sub(r'step == (\d+)', replacer, content)
    # Shift 'step >= N'
    content = re.sub(r'step >= (\d+)', replacer, content)

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

files = [
    r'c:\Users\ta062\Desktop\app\dice\battle_for_the_cats\lib\screens\tutorial\tutorial_view_model.dart',
    r'c:\Users\ta062\Desktop\app\dice\battle_for_the_cats\lib\screens\tutorial\tutorial_screen.dart',
    r'c:\Users\ta062\Desktop\app\dice\battle_for_the_cats\lib\screens\tutorial\views\tutorial_round_result_view.dart'
]

for f in files:
    if os.path.exists(f):
        shift_steps(f)
        print(f"Shifted {f}")
    else:
        print(f"File not found: {f}")
