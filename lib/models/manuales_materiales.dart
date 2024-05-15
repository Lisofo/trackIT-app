import 'dart:convert';

List<ManualesMateriales> manualesMaterialesFromMap(String str) => List<ManualesMateriales>.from(json.decode(str).map((x) => ManualesMateriales.fromJson(x)));

String manualesMaterialesToMap(List<ManualesMateriales> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class ManualesMateriales {
  late String filename;
  late String filepath;

  ManualesMateriales({
    required this.filename,
    required this.filepath,
  });

  factory ManualesMateriales.fromJson(Map<String, dynamic> json) => ManualesMateriales(
    filename: json["filename"],
    filepath: json["filepath"],
  );

  Map<String, dynamic> toMap() => {
    "filename": filename,
    "filepath": filepath,
  };

  ManualesMateriales.empty(){
    filename = '';
    filepath = '';
  }
}
