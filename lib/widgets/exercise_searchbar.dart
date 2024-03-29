import 'package:flutter/material.dart';
import 'package:gym_partner/data/exercises.dart';
import 'package:gym_partner/models/body_part.dart';
import 'package:gym_partner/models/exercise.dart';

class ExerciseSearchbar extends StatefulWidget {
  const ExerciseSearchbar(
      {super.key, required this.hintText, required this.onSelect});

  final String hintText;
  final void Function(Exercise exercise) onSelect;
  @override
  State<ExerciseSearchbar> createState() => _ExerciseSearchbarState();
}

class _ExerciseSearchbarState extends State<ExerciseSearchbar> {
  @override
  Widget build(BuildContext context) {
    return SearchAnchor(
      builder: (context, controller) {
        return SearchBar(
          backgroundColor: MaterialStateProperty.all(
              Theme.of(context).colorScheme.onPrimary),
          controller: controller,
          leading: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.search),
          ),
          onTap: () {
            controller.openView();
          },
          onChanged: (_) {
            controller.openView();
          },
          hintText: widget.hintText,
        );
      },
      suggestionsBuilder: (context, controller) {
        return allExercises.map(
          (exercise) {
            final bodyPartsString = exercise.bodyParts
                .map((bodyPart) => bodyPartStrings[bodyPart] ?? '')
                .join(', ');
            return ListTile(
              title: Text(exercise.name),
              subtitle: Text(bodyPartsString),
              onTap: () {
                widget.onSelect(exercise);
                setState(() {
                  controller.closeView('');
                });
              },
            );
          },
        );
      },
    );
  }
}
