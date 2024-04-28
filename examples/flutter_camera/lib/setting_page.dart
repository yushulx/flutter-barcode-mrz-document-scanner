import 'package:barcodescanner/global.dart';
import 'package:flutter/material.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: colorMainTheme,
          title: const Text('Settings'),
        ),
        body: const ExpansionPanelListFormats(),
      ),
    );
  }
}

class ExpansionPanelListFormats extends StatefulWidget {
  const ExpansionPanelListFormats({super.key});

  @override
  State<ExpansionPanelListFormats> createState() =>
      _ExpansionPanelListFormatsState();
}

class _ExpansionPanelListFormatsState extends State<ExpansionPanelListFormats> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        child: _buildPanel(),
      ),
    );
  }

  Widget _buildPanel() {
    return ExpansionPanelList(
      expandIconColor: Colors.white,
      dividerColor: Colors.grey[800],
      expansionCallback: (int index, bool isExpanded) {
        setState(() {
          allFormats[index].isExpanded = !isExpanded;
        });
      },
      children: allFormats.map<ExpansionPanel>((Item item) {
        return ExpansionPanel(
          backgroundColor: Colors.black,
          headerBuilder: (BuildContext context, bool isExpanded) {
            return SizedBox(
                height: 60,
                child: Container(
                  padding: const EdgeInsets.only(left: 20, right: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        color: colorOrange,
                        child: Checkbox(
                          fillColor: MaterialStateColor.resolveWith(
                              (states) => colorOrange),
                          checkColor: Colors.black,
                          activeColor: Colors.white,
                          value: item.isAllSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              item.isAllSelected = value!;
                              if (item.isAllSelected) {
                                item.selectedOptions.clear();
                                item.selectedOptions.addAll(item.expandedValue);
                              } else {
                                item.selectedOptions.clear();
                              }
                            });
                            updateFormats();
                          },
                        ),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        item.headerValue,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                      )
                    ],
                  ),
                ));
          },
          body: ListView(
            shrinkWrap:
                true, // add this to ensure that the ListView fits within the expansion panel
            physics:
                const NeverScrollableScrollPhysics(), // to disable scrolling within the ListView
            children: item.expandedValue.map<Widget>((String value) {
              return SizedBox(
                  height: 40,
                  child: Container(
                      padding: const EdgeInsets.only(left: 20, right: 20),
                      child: Row(
                        children: [
                          Text(
                            value,
                            style: TextStyle(color: colorText, fontSize: 14),
                          ),
                          Expanded(child: Container()),
                          Container(
                            width: 24,
                            height: 24,
                            color: Colors.white,
                            child: Checkbox(
                              fillColor: MaterialStateColor.resolveWith(
                                  (states) => Colors.white),
                              checkColor: item.selectedOptions.contains(value)
                                  ? Colors.black
                                  : null,
                              activeColor: Colors.white,
                              value: item.selectedOptions.contains(value),
                              onChanged: (bool? changedValue) {
                                setState(() {
                                  item.selectedOptions.contains(value)
                                      ? item.selectedOptions.remove(value)
                                      : item.selectedOptions.add(value);
                                });
                                updateFormats();
                              },
                            ),
                          ),
                        ],
                      )));
            }).toList(),
          ),
          isExpanded: item.isExpanded,
        );
      }).toList(),
    );
  }
}
