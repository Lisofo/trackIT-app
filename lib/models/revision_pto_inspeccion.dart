import 'dart:convert';

RevisionPtoInspeccion revisionPtoInspeccionFromMap(String str) =>
    RevisionPtoInspeccion.fromJson(json.decode(str));

String revisionPtoInspeccionToMap(RevisionPtoInspeccion data) =>
    json.encode(data.toMap());

class RevisionPtoInspeccion {
  late int? otPuntoInspeccionId;
  late int ordenTrabajoId;
  late int otRevisionId;
  late int puntoInspeccionId;
  late int planoId;
  late int tipoPuntoInspeccionId;
  late String codTipoPuntoInspeccion;
  late String descTipoPuntoInspeccion;
  late int plagaObjetivoId;
  late String codPuntoInspeccion;
  late String codigoBarra;
  late String zona;
  late String sector;
  late int? piAccionId;
  late String? codAccion;
  late String? descPiAccion;
  late String comentario;
  late List<PtoMaterial> materiales;
  late List<PtoPlaga> plagas;
  late List<PtoTarea> tareas;
  late List<TrasladoNuevo> trasladoNuevo;
  late int idPIAccion;
  late bool seleccionado;

  RevisionPtoInspeccion({
    required this.otPuntoInspeccionId,
    required this.ordenTrabajoId,
    required this.otRevisionId,
    required this.puntoInspeccionId,
    required this.planoId,
    required this.tipoPuntoInspeccionId,
    required this.codTipoPuntoInspeccion,
    required this.descTipoPuntoInspeccion,
    required this.plagaObjetivoId,
    required this.codPuntoInspeccion,
    required this.codigoBarra,
    required this.zona,
    required this.sector,
    required this.piAccionId,
    required this.codAccion,
    required this.descPiAccion,
    required this.comentario,
    required this.materiales,
    required this.plagas,
    required this.tareas,
    required this.trasladoNuevo,
    required this.idPIAccion,
    required this.seleccionado,
  });

  factory RevisionPtoInspeccion.fromJson(Map<String, dynamic> json) =>
      RevisionPtoInspeccion(
        otPuntoInspeccionId: json["otPuntoInspeccionId"] as int? ?? 0,
        ordenTrabajoId: json["ordenTrabajoId"] as int? ?? 0,
        otRevisionId: json["otRevisionId"] as int? ?? 0,
        puntoInspeccionId: json["puntoInspeccionId"] as int? ?? 0,
        planoId: json["planoId"] as int? ?? 0,
        tipoPuntoInspeccionId: json["tipoPuntoInspeccionId"] as int? ?? 0,
        codTipoPuntoInspeccion: json["codTipoPuntoInspeccion"] as String? ?? '',
        descTipoPuntoInspeccion:
            json["descTipoPuntoInspeccion"] as String? ?? '',
        plagaObjetivoId: json["plagaObjetivoId"] as int? ?? 0,
        codPuntoInspeccion: json["codPuntoInspeccion"] as String? ?? '',
        codigoBarra: json["codigoBarra"] as String? ?? '',
        zona: json["zona"] as String? ?? '',
        sector: json["sector"] as String? ?? '',
        idPIAccion: json["piAccionId"] as int? ?? 0,
        piAccionId: json["piAccionId"] as int? ?? 0,
        codAccion: json["codAccion"] as String? ?? '',
        descPiAccion: json["desPIAccion"] as String? ?? '',
        comentario: json["comentario"] as String? ?? '',
        materiales: List<PtoMaterial>.from(
            json["materiales"].map((x) => PtoMaterial.fromMap(x))),
        plagas:
            List<PtoPlaga>.from(json["plagas"].map((x) => PtoPlaga.fromMap(x))),
        tareas:
            List<PtoTarea>.from(json["tareas"].map((x) => PtoTarea.fromMap(x))),
        trasladoNuevo: List<TrasladoNuevo>.from(
            json["trasladoNuevo"].map((x) => TrasladoNuevo.fromMap(x))),
        seleccionado: false,
      );

  Map<String, dynamic> toMap() => {
        "otPuntoInspeccionId": otPuntoInspeccionId,
        "ordenTrabajoId": ordenTrabajoId,
        "otRevisionId": otRevisionId,
        "puntoInspeccionId": puntoInspeccionId,
        "planoId": planoId,
        "tipoPuntoInspeccionId": tipoPuntoInspeccionId,
        "codTipoPuntoInspeccion": codTipoPuntoInspeccion,
        "descTipoPuntoInspeccion": descTipoPuntoInspeccion,
        "plagaObjetivoId": plagaObjetivoId,
        "codPuntoInspeccion": codPuntoInspeccion,
        "codigoBarra": codigoBarra,
        "zona": zona,
        "piAccionId": idPIAccion,
        "sector": sector,
        "codAccion": codAccion,
        "desPIAccion": descPiAccion,
        "comentario": comentario,
        "materiales": List<dynamic>.from(materiales.map((x) => x.toMap())),
        "plagas": List<dynamic>.from(plagas.map((x) => x.toMap())),
        "tareas": List<dynamic>.from(tareas.map((x) => x.toMap())),
        "trasladoNuevo":
            List<dynamic>.from(trasladoNuevo.map((x) => x.toMap())),
        "seleccionado": false,
      };

  RevisionPtoInspeccion.empty() {
    otPuntoInspeccionId = 0;
    ordenTrabajoId = 0;
    otRevisionId = 0;
    puntoInspeccionId = 0;
    planoId = 0;
    tipoPuntoInspeccionId = 0;
    codTipoPuntoInspeccion = '';
    descTipoPuntoInspeccion = '';
    plagaObjetivoId = 0;
    codPuntoInspeccion = '';
    codigoBarra = '';
    zona = '';
    sector = '';
    piAccionId = 0;
    codAccion = '';
    descPiAccion = '';
    comentario = '';
    materiales = [];
    plagas = [];
    tareas = [];
    trasladoNuevo = [];
    seleccionado = false;
  }
}

class PtoMaterial {
  late int otPiMaterialId;
  late int otPuntoInspeccionId;
  late int materialId;
  late String codMaterial;
  late String descripcion;
  late String dosis;
  late String unidad;
  late int cantidad;
  late int? materialLoteId;
  late String? lote;

  PtoMaterial({
    required this.otPiMaterialId,
    required this.otPuntoInspeccionId,
    required this.materialId,
    required this.codMaterial,
    required this.descripcion,
    required this.dosis,
    required this.unidad,
    required this.cantidad,
    required this.materialLoteId,
    required this.lote,
  });

  factory PtoMaterial.fromMap(Map<String, dynamic> json) => PtoMaterial(
        otPiMaterialId: json["otPIMaterialId"] as int? ?? 0,
        otPuntoInspeccionId: json["otPuntoInspeccionId"] as int? ?? 0,
        materialId: json["materialId"] as int? ?? 0,
        codMaterial: json["codMaterial"] as String? ?? '',
        descripcion: json["descripcion"] as String? ?? '',
        dosis: json["dosis"] as String? ?? '',
        unidad: json["unidad"] as String? ?? '',
        cantidad: json["cantidad"] as int? ?? 0,
        materialLoteId: json["materialLoteId"] as int? ?? 0,
        lote: json["lote"] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        "otPIMaterialId": otPiMaterialId,
        "otPuntoInspeccionId": otPuntoInspeccionId,
        "materialId": materialId,
        "codMaterial": codMaterial,
        "descripcion": descripcion,
        "dosis": dosis,
        "unidad": unidad,
        "cantidad": cantidad,
        "materialLoteId": materialLoteId == 0 ? null : materialLoteId,
        "lote": lote,
      };

  PtoMaterial.empty() {
    otPiMaterialId = 0;
    otPuntoInspeccionId = 0;
    materialId = 0;
    codMaterial = '';
    descripcion = '';
    dosis = '';
    unidad = '';
    cantidad = 0;
    materialLoteId = 0;
    lote = '';
  }

  @override
  String toString() {
    return descripcion;
  }
}

class PtoPlaga {
  late int otPiPlagaId;
  late int otPuntoInspeccionId;
  late int plagaId;
  late String codPlaga;
  late String descPlaga;
  late int cantidad;

  PtoPlaga({
    required this.otPiPlagaId,
    required this.otPuntoInspeccionId,
    required this.plagaId,
    required this.codPlaga,
    required this.descPlaga,
    required this.cantidad,
  });

  factory PtoPlaga.fromMap(Map<String, dynamic> json) => PtoPlaga(
        otPiPlagaId: json["otPIPlagaId"] as int? ?? 0,
        otPuntoInspeccionId: json["otPuntoInspeccionId"] as int? ?? 0,
        plagaId: json["plagaId"] as int? ?? 0,
        codPlaga: json["codPlaga"] as String? ?? '',
        descPlaga: json["descPlaga"] as String? ?? '',
        cantidad: json["cantidad"] as int? ?? 0,
      );

  Map<String, dynamic> toMap() => {
        "otPIPlagaId": otPiPlagaId,
        "otPuntoInspeccionId": otPuntoInspeccionId,
        "plagaId": plagaId,
        "codPlaga": codPlaga,
        "descPlaga": descPlaga,
        "cantidad": cantidad,
      };

  PtoPlaga.empty() {
    otPiPlagaId = 0;
    otPuntoInspeccionId = 0;
    plagaId = 0;
    codPlaga = '';
    descPlaga = '';
    cantidad = 0;
  }

  @override
  String toString() {
    return descPlaga;
  }
}

class PtoTarea {
  late int otPiTareaId;
  late int otPuntoInspeccionId;
  late int tareaId;
  late String codTarea;
  late String descTarea;

  PtoTarea({
    required this.otPiTareaId,
    required this.otPuntoInspeccionId,
    required this.tareaId,
    required this.codTarea,
    required this.descTarea,
  });

  factory PtoTarea.fromMap(Map<String, dynamic> json) => PtoTarea(
        otPiTareaId: json["otPITareaId"] as int? ?? 0,
        otPuntoInspeccionId: json["otPuntoInspeccionId"] as int? ?? 0,
        tareaId: json["tareaId"] as int? ?? 0,
        codTarea: json["codTarea"] as String? ?? '',
        descTarea: json["descTarea"] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        "otPITareaId": otPiTareaId,
        "otPuntoInspeccionId": otPuntoInspeccionId,
        "tareaId": tareaId,
        "codTarea": codTarea,
        "descTarea": descTarea,
      };

  PtoTarea.empty() {
    otPiTareaId = 0;
    otPuntoInspeccionId = 0;
    tareaId = 0;
    codTarea = '';
    descTarea = '';
  }
}

class TrasladoNuevo {
  late int otPiTrasladoNuevoId;
  late int otPuntoInspeccionId;
  late String codPuntoInspeccion;
  late String codigoBarra;
  late String zona;
  late String sector;
  late int tipoPuntoInspeccionId;
  late String codTipoPuntoInspeccion;
  late String tipoPuntoInspeccion;
  late int plagaObjetivoId;
  late String codPlagaObjetivo;
  late String plagaObjetivo;

  TrasladoNuevo({
    required this.otPiTrasladoNuevoId,
    required this.otPuntoInspeccionId,
    required this.codPuntoInspeccion,
    required this.codigoBarra,
    required this.zona,
    required this.sector,
    required this.tipoPuntoInspeccionId,
    required this.codTipoPuntoInspeccion,
    required this.tipoPuntoInspeccion,
    required this.plagaObjetivoId,
    required this.codPlagaObjetivo,
    required this.plagaObjetivo,
  });

  factory TrasladoNuevo.fromMap(Map<String, dynamic> json) => TrasladoNuevo(
        otPiTrasladoNuevoId: json["otPITrasladoNuevoId"] as int? ?? 0,
        otPuntoInspeccionId: json["otPuntoInspeccionId"] as int? ?? 0,
        codPuntoInspeccion: json["codPuntoInspeccion"] as String? ?? '',
        codigoBarra: json["codigoBarra"] as String? ?? '',
        zona: json["zona"] as String? ?? '',
        sector: json["sector"] as String? ?? '',
        tipoPuntoInspeccionId: json["tipoPuntoInspeccionId"] as int? ?? 0,
        codTipoPuntoInspeccion: json["codTipoPuntoInspeccion"] as String? ?? '',
        tipoPuntoInspeccion: json["tipoPuntoInspeccion"] as String? ?? '',
        plagaObjetivoId: json["plagaObjetivoId"] as int? ?? 0,
        codPlagaObjetivo: json["codPlagaObjetivo"] as String? ?? '',
        plagaObjetivo: json["plagaObjetivo"] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        "otPITrasladoNuevoId": otPiTrasladoNuevoId,
        "otPuntoInspeccionId": otPuntoInspeccionId,
        "codPuntoInspeccion": codPuntoInspeccion,
        "codigoBarra": codigoBarra,
        "zona": zona,
        "sector": sector,
        "tipoPuntoInspeccionId": tipoPuntoInspeccionId,
        "codTipoPuntoInspeccion": codTipoPuntoInspeccion,
        "tipoPuntoInspeccion": tipoPuntoInspeccion,
        "plagaObjetivoId": plagaObjetivoId,
        "codPlagaObjetivo": codPlagaObjetivo,
        "plagaObjetivo": plagaObjetivo,
      };

  TrasladoNuevo.empty() {
    otPiTrasladoNuevoId = 0;
    otPuntoInspeccionId = 0;
    codPuntoInspeccion = '';
    codigoBarra = '';
    zona = '';
    sector = '';
    tipoPuntoInspeccionId = 0;
    codTipoPuntoInspeccion = '';
    tipoPuntoInspeccion = '';
    plagaObjetivoId = 0;
    codPlagaObjetivo = '';
    plagaObjetivo = '';
  }
}

class PtoAccion {
  late int piAccionId;
  late String codAccion;
  late String descPiAccion;

  PtoAccion({
    required this.piAccionId,
    required this.codAccion,
    required this.descPiAccion,
  });

  factory PtoAccion.fromMap(Map<String, dynamic> json) => PtoAccion(
      piAccionId: json["piAccionId"] as int? ?? 0,
      codAccion: json["codAccion"] as String? ?? '',
      descPiAccion: json["desPIAccion"] as String? ?? '');

  Map<String, dynamic> toMap() => {
        "piAccionId": piAccionId,
        "codAccion": codAccion,
        "desPIAccion": descPiAccion
      };

  PtoAccion.empty() {
    piAccionId = 0;
    codAccion = '';
    descPiAccion = '';
  }
}
