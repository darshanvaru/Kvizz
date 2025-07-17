if (question.type == QuestionType.multiple)
...List.generate(question.options.length, (index) {
final isSelected = selectedIndexes.contains(index);
final isCorrect = answered && (question.correctAnswer as Set).contains(index);
final isIncorrect = answered && isSelected && !isCorrect;

Color? tileColor = Colors.white;
Color borderColor = Colors.grey.shade300;
Icon leadingIcon = const Icon(Icons.check_box_outline_blank, color: Colors.grey);
Color optionTextColor = Colors.black54;

if (timeUp || answered) {
if (isCorrect) {
tileColor = const Color(0xFFD6F4E7);
borderColor = Colors.teal;
leadingIcon = const Icon(Icons.check_box, color: Colors.teal);
optionTextColor = Colors.teal;
} else if (isIncorrect) {
tileColor = Theme.of(context).primaryColor.withOpacity(0.1);
borderColor = Colors.redAccent;
leadingIcon = const Icon(Icons.cancel, color: Colors.redAccent);
optionTextColor = Colors.redAccent;
} else if (isSelected) {
tileColor = Colors.grey.shade200;
borderColor = const Color(0xFF57A2C3);
leadingIcon = const Icon(Icons.check_box, color: Color(0xFF53BDEB));
optionTextColor = Colors.black87;
}
} else if (!timeUp && isSelected) {
tileColor = Colors.grey.shade200;
borderColor = const Color(0xFF57A2C3);
leadingIcon = const Icon(Icons.check_box, color: Color(0xFF53BDEB));
optionTextColor = Colors.black87;
}

return Container(
margin: const EdgeInsets.only(bottom: 12),
decoration: BoxDecoration(
color: tileColor,
border: Border.all(
color: borderColor,
width: isSelected || isCorrect || isIncorrect ? 2 : 1,
),
borderRadius: BorderRadius.circular(12),
),
child: ListTile(
leading: leadingIcon,
title: Text(
question.options[index],
style: TextStyle(
fontWeight: FontWeight.w500,
color: optionTextColor,
),
),
onTap: (answered || timeUp)
? null
    : () {
setState(() {
if (isSelected) {
selectedIndexes.remove(index);
} else {
selectedIndexes.add(index);
}
});
},
),
);
}),

if (question.type == QuestionType.open)
Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
TextField(
controller: answerController,
enabled: !answered && !timeUp,
maxLines: 3,
decoration: InputDecoration(
hintText: "Type your answer...",
border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
filled: true,
fillColor: Colors.grey.shade100,
),
onChanged: (_) {
setState(() {});
},
),
if (answered || timeUp)
Padding(
padding: const EdgeInsets.only(top: 12),
child: Text(
answerController.text.trim().isEmpty
? "No answer provided."
    : "Your answer: ${answerController.text.trim()}",
style: TextStyle(
color: answerController.text.trim().isEmpty
? Colors.redAccent
    : Colors.teal,
fontWeight: FontWeight.w600,
),
),
),
],
),

if (question.type == QuestionType.reorder)
Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
ReorderableListView(
shrinkWrap: true,
physics: NeverScrollableScrollPhysics(),
onReorder: answered || timeUp
? (_, __) {}
    : (oldIndex, newIndex) {
setState(() {
if (newIndex > oldIndex) newIndex -= 1;
final item = reorderedOptions.removeAt(oldIndex);
reorderedOptions.insert(newIndex, item);
});
},
children: [
for (final entry in reorderedOptions)
ListTile(
key: ValueKey(entry.key),
title: Text(
entry.value,
style: TextStyle(
color: (answered || timeUp)
? (entry.value ==
(question.correctAnswer as List<String>)[
reorderedOptions.indexOf(entry)]
? Colors.teal
    : Colors.redAccent)
    : Colors.black87,
fontWeight: FontWeight.w500,
),
),
tileColor: (answered || timeUp)
? (entry.value ==
(question.correctAnswer as List<String>)[
reorderedOptions.indexOf(entry)]
? const Color(0xFFD6F4E7)
    : const Color(0xFFFBE4DF))
    : Colors.grey.shade100,
trailing: Icon(Icons.drag_handle),
),
],
),
if (answered || timeUp)
Padding(
padding: const EdgeInsets.only(top: 12),
child: Text(
const ListEquality().equals(
reorderedOptions.map((e) => e.value).toList(),
List<String>.from(question.correctAnswer))
? "Correct order!"
    : "Incorrect order.",
style: TextStyle(
color: const ListEquality().equals(
reorderedOptions.map((e) => e.value).toList(),
List<String>.from(question.correctAnswer))
? Colors.teal
    : Colors.redAccent,
fontWeight: FontWeight.w600,
),
),
),
],
),