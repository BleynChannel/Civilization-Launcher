class ModpackInfo {
  final int modpackID;
  final String modpackVersion;
  final String minecraftVersion;
  final String forgeVersion;

  const ModpackInfo({
    required this.modpackID,
    required this.modpackVersion,
    required this.minecraftVersion,
    required this.forgeVersion,
  });

  factory ModpackInfo.fromJson(Map<String, dynamic> json) {
    return ModpackInfo(
      modpackID: json["modpackID"] as int,
      modpackVersion: json["modpackVersion"] as String,
      minecraftVersion: json["minecraftVersion"] as String,
      forgeVersion: json["forgeVersion"] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "modpackID": modpackID,
      "modpackVersion": modpackVersion,
      "minecraftVersion": minecraftVersion,
      "forgeVersion": forgeVersion,
    };
  }
}
