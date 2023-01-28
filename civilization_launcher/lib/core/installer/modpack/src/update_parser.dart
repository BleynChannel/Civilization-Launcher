class UpdateParser {
  static List<UpdateField> fromUpdate({required String data}) {
    final updateList = <UpdateField>[];

    final fields = data.trim().split('\n');
    for (final field in fields) {
      final elements = field.split(':');

      final id = int.parse(elements[0]);
      final path = elements[1];
      final type = UpdateChangeType.values[int.parse(elements[2])];

      updateList.add(UpdateField(id: id, path: path, type: type));
    }

    return updateList;
  }

  static String toUpdate({required List<UpdateField> updateList}) {
    String data = '';

    for (final field in updateList) {
      String strField =
          '${field.id}:${field.path}:${field.type.name.toUpperCase()}';
      data += '$strField\n';
    }

    return data;
  }
}

enum UpdateChangeType {
  add,
  edit,
  delete,
}

class UpdateField {
  final int id;
  final String path;
  UpdateChangeType type;

  UpdateField({
    required this.id,
    required this.path,
    required this.type,
  });
}
