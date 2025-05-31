import 'package:dartantic/asg/asg.dart';

// VALIDATORS
abstract class DttValidator {
  const DttValidator(); 
  ASG asg(Map<String, dynamic> map);

  Map<String, dynamic> get params;

}

class DttvNotNull extends DttValidator {
  const DttvNotNull();

  @override
  ASG asg(Map<String, dynamic> map) {
    final fieldName = map['fieldName'];

    // create var assignments
    String varAssignments = ASG.assignVar(
      "${fieldName}_is_null",
      "values[\'$fieldName\'] == null",
    );
    ASG ifCond = ASG.IF(
      condition: "${fieldName}_is_null",
      then: ASG.fromLines([
        'throw DttValidationError(\'$fieldName\', \'Must not be null\');',
      ]),
    );
    return ASG.merge([varAssignments, ifCond]);
  }

  @override
  Map<String, dynamic> get params => {};

}

class DttvMinLength extends DttValidator {
  final int minLength;
  const DttvMinLength(this.minLength);

  @override
  ASG asg(Map<String, dynamic> map) {
    final fieldName = map['fieldName'];

    // create var assignments
    String varAssignments = ASG.assignVar(
      "${fieldName}_length",
      "values['$fieldName'].length",
    );
    ASG ifCond = ASG.IF(
      condition: "${fieldName}_length < $minLength",
      then: ASG.fromLines([
        'throw DttValidationError(\'$fieldName\', \'Must be at least $minLength characters long\');',
      ]),
    );
    return ASG.merge([varAssignments, ifCond]);
  }

  @override
  Map<String, dynamic> get params => {'minLength': minLength};
}

class DttvMaxLength extends DttValidator {
  final int maxLength;
  const DttvMaxLength(this.maxLength);

  @override
  ASG asg(Map<String, dynamic> map) {
    final fieldName = map['fieldName'];

    // create var assignments
    String varAssignments = ASG.assignVar(
      "${fieldName}_length",
      "values['$fieldName'].length",
    );
    ASG ifCond = ASG.IF(
      condition: "${fieldName}_length > $maxLength",
      then: ASG.fromLines([
        'throw DttValidationError(\'$fieldName\', \'Must be at most $maxLength characters long\');',
      ]),
    );
    return ASG.merge([varAssignments, ifCond]);
  }

  @override
  Map<String, dynamic> get params => {'maxLength': maxLength};
}
