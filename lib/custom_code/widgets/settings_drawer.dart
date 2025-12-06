import 'package:flutter/material.dart';

class SettingsDrawer extends StatefulWidget {
  const SettingsDrawer({Key? key}) : super(key: key);

  @override
  State<SettingsDrawer> createState() => _SettingsDrawerState();
}

class _SettingsDrawerState extends State<SettingsDrawer> {
  double lineSpacing = 20;
  double wordSpacing = 51;
  double letterSpacing = 51;
  
  bool isJustified = true;
  bool isColorMode = true;
  bool isPreventScreen = true;
  bool isPreventName = true;
  bool isFiveMin = true;
  
  bool expandedFontSize = true;
  bool expandedLineSpacing = true;
  bool expandedSpacing = true;
  bool expandedBottomFontSize = true;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
               Text('সেটিংস', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
               const SizedBox(height: 16),
              _buildCheckOption('স্ক্রল মোড', isJustified, (val) {
                setState(() => isJustified = val);
              }),
              // Spacing Section
              _buildExpandableSection(
                title: 'অটো স্ক্রল',
                expanded: expandedSpacing,
                onToggle: () {
                  setState(() {
                    expandedSpacing = !expandedSpacing;
                  });
                },
                children: [                
                  const SizedBox(height: 8),
                  _buildSlider(
                    label: 'নির্দিষ্ট সময় পর পর অটো স্ক্রল করুন',
                    value: wordSpacing,
                    onChanged: (val) {
                      setState(() => wordSpacing = val);
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  _buildSlider(
                    label: 'অবিচ্ছিন্নভাবে অটো স্ক্রল করুন',
                    value: 51,
                    onChanged: (val) {},
                    unit: '%',
                  ),
                  
                  const SizedBox(height: 8),
                  
                  _buildCheckOption(
                    'পৃষ্ঠা পরিবর্তন করতে ভলিউম বাটন ব্যবহার করুন',
                    isPreventScreen,
                    (val) {
                      setState(() => isPreventScreen = val);
                    },
                  ),
                  
                  _buildCheckOption(
                    'স্ক্রিনের উজ্জ্বলতা ঠিক করতে স্ক্রিনের বাম প্রান্ত সোয়াইপ করুন',
                    isPreventName,
                    (val) {
                      setState(() => isPreventName = val);
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    'ব্লু লাইট ফিল্টার',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSlider(
                    value: letterSpacing,
                    onChanged: (val) {
                      setState(() => letterSpacing = val);
                    },
                    unit: '%',
                  ),
                ],
              ),
              
              const Divider(height: 1),
              
              // Bottom Font Size Section
              _buildExpandableSection(
                title: 'স্ক্রিনে আলোর সময় ঠিক করুন',
                expanded: expandedBottomFontSize,
                onToggle: () {
                  setState(() {
                    expandedBottomFontSize = !expandedBottomFontSize;
                  });
                },
                children: [
                  _buildCheckOption('৫ মিনিট', true, (val) {}),
                  _buildCheckOption('১০ মিনিট', false, (val) {}),
                  _buildCheckOption('১৫ মিনিট', false, (val) {}),
                  _buildCheckOption('স্ক্রিনশট নিন', false, (val) {}),
                ],
              ),
              // Justified Alignment
              _buildCheckOption('Justified Alignment', isJustified, (val) {
                setState(() => isJustified = val);
              }),
              
              const Divider(height: 1),
              
              // Line Spacing Section
              _buildExpandableSection(
                title: 'লাইন ব্যবধান',
                expanded: expandedLineSpacing,
                onToggle: () {
                  setState(() {
                    expandedLineSpacing = !expandedLineSpacing;
                  });
                },
                children: [
                  _buildSlider(
                    value: lineSpacing,
                    onChanged: (val) {
                      setState(() => lineSpacing = val);
                    },
                    unit: '%',
                  ),
                ],
              ),
              
              const Divider(height: 1),
              
              // Hyphenation
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Hyphenation',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
    );

  }

  Widget _buildExpandableSection({
    required String title,
    required bool expanded,
    required VoidCallback onToggle,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 200),
                  turns: expanded ? 0.5 : 0,
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
      ],
    );
  }

  Widget _buildCheckOption(
    String label,
    bool checked,
    ValueChanged<bool> onChanged,
  ) {
    return InkWell(
      onTap: () => onChanged(!checked),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: checked ? const Color(0xFF22D3EE) : Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
              child: checked
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider({
    String? label,
    required double value,
    required ValueChanged<double> onChanged,
    String? unit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null || unit != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (label != null)
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                Text(
                  '${value.round()}${unit ?? ''}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove, color: Colors.grey),
              onPressed: () {
                if (value > 0) onChanged(value - 1);
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: const Color(0xFFFCD34D),
                  inactiveTrackColor: Colors.grey[300],
                  thumbColor: const Color(0xFFFCD34D),
                  overlayColor: const Color(0xFFFCD34D).withOpacity(0.2),
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 10,
                  ),
                ),
                child: Slider(
                  value: value,
                  min: 0,
                  max: 100,
                  onChanged: onChanged,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add, color: Colors.grey),
              onPressed: () {
                if (value < 100) onChanged(value + 1);
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ],
    );
  }
}