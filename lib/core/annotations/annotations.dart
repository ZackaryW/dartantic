export 'validators.dart';

class DttModel {
  const DttModel();
}

const dttModel = DttModel();

class DttPreProcess {
  const DttPreProcess();
}

const dttPreProcess = DttPreProcess();

class DttPostProcess {
  const DttPostProcess();
}

const dttPostProcess = DttPostProcess();

class DttValidateMethod {
  final Function func;
  const DttValidateMethod(this.func);
}

const dttValidateMethod = DttValidateMethod;
