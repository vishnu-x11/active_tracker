
part of 'daily_log_summary.dart';

extension GetDailyLogSummaryCollection on Isar {
  IsarCollection<DailyLogSummary> get dailyLogSummarys => this.collection();
}

const dailyLogSummarySchema = CollectionSchema(
  name: r'DailyLogSummary',
  id: 1116229844259465739,
  properties: {
    r'caloriesConsumed': PropertySchema(
      id: 0,
      name: r'caloriesConsumed',
      type: IsarType.double,
    ),
    r'carbsConsumed': PropertySchema(
      id: 1,
      name: r'carbsConsumed',
      type: IsarType.double,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'dateKey': PropertySchema(
      id: 3,
      name: r'dateKey',
      type: IsarType.string,
    ),
    r'fatConsumed': PropertySchema(
      id: 4,
      name: r'fatConsumed',
      type: IsarType.double,
    ),
    r'goalsMet': PropertySchema(
      id: 5,
      name: r'goalsMet',
      type: IsarType.stringList,
    ),
    r'goalsMetCount': PropertySchema(
      id: 6,
      name: r'goalsMetCount',
      type: IsarType.long,
    ),
    r'noteWritten': PropertySchema(
      id: 7,
      name: r'noteWritten',
      type: IsarType.bool,
    ),
    r'proteinConsumed': PropertySchema(
      id: 8,
      name: r'proteinConsumed',
      type: IsarType.double,
    ),
    r'updatedAt': PropertySchema(
      id: 9,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'waterConsumed': PropertySchema(
      id: 10,
      name: r'waterConsumed',
      type: IsarType.double,
    ),
    r'workoutCompleted': PropertySchema(
      id: 11,
      name: r'workoutCompleted',
      type: IsarType.bool,
    )
  },
  estimateSize: _dailyLogSummaryEstimateSize,
  serialize: _dailyLogSummarySerialize,
  deserialize: _dailyLogSummaryDeserialize,
  deserializeProp: _dailyLogSummaryDeserializeProp,
  idName: r'id',
  indexes: {
    r'dateKey': IndexSchema(
      id: 7975223786082927131,
      name: r'dateKey',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'dateKey',
          type: IndexType.value,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _dailyLogSummaryGetId,
  getLinks: _dailyLogSummaryGetLinks,
  attach: _dailyLogSummaryAttach,
  version: '3.1.0+1',
);

int _dailyLogSummaryEstimateSize(
  DailyLogSummary object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.dateKey.length * 3;
  bytesCount += 3 + object.goalsMet.length * 3;
  {
    for (var i = 0; i < object.goalsMet.length; i++) {
      final value = object.goalsMet[i];
      bytesCount += value.length * 3;
    }
  }
  return bytesCount;
}

void _dailyLogSummarySerialize(
  DailyLogSummary object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.caloriesConsumed);
  writer.writeDouble(offsets[1], object.carbsConsumed);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeString(offsets[3], object.dateKey);
  writer.writeDouble(offsets[4], object.fatConsumed);
  writer.writeStringList(offsets[5], object.goalsMet);
  writer.writeLong(offsets[6], object.goalsMetCount);
  writer.writeBool(offsets[7], object.noteWritten);
  writer.writeDouble(offsets[8], object.proteinConsumed);
  writer.writeDateTime(offsets[9], object.updatedAt);
  writer.writeDouble(offsets[10], object.waterConsumed);
  writer.writeBool(offsets[11], object.workoutCompleted);
}

DailyLogSummary _dailyLogSummaryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DailyLogSummary();
  object.caloriesConsumed = reader.readDouble(offsets[0]);
  object.carbsConsumed = reader.readDouble(offsets[1]);
  object.createdAt = reader.readDateTime(offsets[2]);
  object.dateKey = reader.readString(offsets[3]);
  object.fatConsumed = reader.readDouble(offsets[4]);
  object.goalsMet = reader.readStringList(offsets[5]) ?? [];
  object.goalsMetCount = reader.readLong(offsets[6]);
  object.id = id;
  object.noteWritten = reader.readBool(offsets[7]);
  object.proteinConsumed = reader.readDouble(offsets[8]);
  object.updatedAt = reader.readDateTime(offsets[9]);
  object.waterConsumed = reader.readDouble(offsets[10]);
  object.workoutCompleted = reader.readBool(offsets[11]);
  return object;
}

P _dailyLogSummaryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readDouble(offset)) as P;
    case 5:
      return (reader.readStringList(offset) ?? []) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readDouble(offset)) as P;
    case 9:
      return (reader.readDateTime(offset)) as P;
    case 10:
      return (reader.readDouble(offset)) as P;
    case 11:
      return (reader.readBool(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _dailyLogSummaryGetId(DailyLogSummary object) {
  return object.id ?? Isar.autoIncrement;
}

List<IsarLinkBase<dynamic>> _dailyLogSummaryGetLinks(DailyLogSummary object) {
  return [];
}

void _dailyLogSummaryAttach(
    IsarCollection<dynamic> col, Id id, DailyLogSummary object) {
  object.id = id;
}

extension DailyLogSummaryByIndex on IsarCollection<DailyLogSummary> {
  Future<DailyLogSummary?> getByDateKey(String dateKey) {
    return getByIndex(r'dateKey', [dateKey]);
  }

  DailyLogSummary? getByDateKeySync(String dateKey) {
    return getByIndexSync(r'dateKey', [dateKey]);
  }

  Future<bool> deleteByDateKey(String dateKey) {
    return deleteByIndex(r'dateKey', [dateKey]);
  }

  bool deleteByDateKeySync(String dateKey) {
    return deleteByIndexSync(r'dateKey', [dateKey]);
  }

  Future<List<DailyLogSummary?>> getAllByDateKey(List<String> dateKeyValues) {
    final values = dateKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'dateKey', values);
  }

  List<DailyLogSummary?> getAllByDateKeySync(List<String> dateKeyValues) {
    final values = dateKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'dateKey', values);
  }

  Future<int> deleteAllByDateKey(List<String> dateKeyValues) {
    final values = dateKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'dateKey', values);
  }

  int deleteAllByDateKeySync(List<String> dateKeyValues) {
    final values = dateKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'dateKey', values);
  }

  Future<Id> putByDateKey(DailyLogSummary object) {
    return putByIndex(r'dateKey', object);
  }

  Id putByDateKeySync(DailyLogSummary object, {bool saveLinks = true}) {
    return putByIndexSync(r'dateKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByDateKey(List<DailyLogSummary> objects) {
    return putAllByIndex(r'dateKey', objects);
  }

  List<Id> putAllByDateKeySync(List<DailyLogSummary> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'dateKey', objects, saveLinks: saveLinks);
  }
}

extension DailyLogSummaryQueryWhereSort
    on QueryBuilder<DailyLogSummary, DailyLogSummary, QWhere> {
  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterWhere> anyDateKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'dateKey'),
      );
    });
  }
}

extension DailyLogSummaryQueryWhere
    on QueryBuilder<DailyLogSummary, DailyLogSummary, QWhereClause> {
  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterWhereClause>
      dateKeyEqualTo(String dateKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'dateKey',
        value: [dateKey],
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterWhereClause>
      dateKeyNotEqualTo(String dateKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dateKey',
              lower: [],
              upper: [dateKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dateKey',
              lower: [dateKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dateKey',
              lower: [dateKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dateKey',
              lower: [],
              upper: [dateKey],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterWhereClause>
      dateKeyGreaterThan(
    String dateKey, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'dateKey',
        lower: [dateKey],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterWhereClause>
      dateKeyLessThan(
    String dateKey, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'dateKey',
        lower: [],
        upper: [dateKey],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterWhereClause>
      dateKeyBetween(
    String lowerDateKey,
    String upperDateKey, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'dateKey',
        lower: [lowerDateKey],
        includeLower: includeLower,
        upper: [upperDateKey],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterWhereClause>
      dateKeyStartsWith(String DateKeyPrefix) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'dateKey',
        lower: [DateKeyPrefix],
        upper: ['$DateKeyPrefix\u{FFFFF}'],
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterWhereClause>
      dateKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'dateKey',
        value: [''],
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterWhereClause>
      dateKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.lessThan(
              indexName: r'dateKey',
              upper: [''],
            ))
            .addWhereClause(IndexWhereClause.greaterThan(
              indexName: r'dateKey',
              lower: [''],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.greaterThan(
              indexName: r'dateKey',
              lower: [''],
            ))
            .addWhereClause(IndexWhereClause.lessThan(
              indexName: r'dateKey',
              upper: [''],
            ));
      }
    });
  }
}

extension DailyLogSummaryQueryFilter
    on QueryBuilder<DailyLogSummary, DailyLogSummary, QFilterCondition> {
  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      caloriesConsumedEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'caloriesConsumed',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      caloriesConsumedGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'caloriesConsumed',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      caloriesConsumedLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'caloriesConsumed',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      caloriesConsumedBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'caloriesConsumed',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      carbsConsumedEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'carbsConsumed',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      carbsConsumedGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'carbsConsumed',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      carbsConsumedLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'carbsConsumed',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      carbsConsumedBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'carbsConsumed',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      dateKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      dateKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      dateKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      dateKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dateKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      dateKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      dateKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      dateKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      dateKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'dateKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      dateKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dateKey',
        value: '',
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      dateKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'dateKey',
        value: '',
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      fatConsumedEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fatConsumed',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      fatConsumedGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fatConsumed',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      fatConsumedLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fatConsumed',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      fatConsumedBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fatConsumed',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      goalsMetElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'goalsMet',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      goalsMetElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'goalsMet',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      goalsMetElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'goalsMet',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      goalsMetElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'goalsMet',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      goalsMetElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'goalsMet',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      goalsMetElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'goalsMet',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      goalsMetElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'goalsMet',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      goalsMetElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'goalsMet',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      goalsMetElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'goalsMet',
        value: '',
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      goalsMetElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'goalsMet',
        value: '',
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      goalsMetLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'goalsMet',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      goalsMetIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'goalsMet',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      goalsMetIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'goalsMet',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      goalsMetLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'goalsMet',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      goalsMetLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'goalsMet',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      goalsMetLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'goalsMet',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      goalsMetCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'goalsMetCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      goalsMetCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'goalsMetCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      goalsMetCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'goalsMetCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      goalsMetCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'goalsMetCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      idIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      idIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      idEqualTo(Id? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      idGreaterThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      idLessThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      idBetween(
    Id? lower,
    Id? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      noteWrittenEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'noteWritten',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      proteinConsumedEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'proteinConsumed',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      proteinConsumedGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'proteinConsumed',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      proteinConsumedLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'proteinConsumed',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      proteinConsumedBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'proteinConsumed',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      waterConsumedEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'waterConsumed',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      waterConsumedGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'waterConsumed',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      waterConsumedLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'waterConsumed',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      waterConsumedBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'waterConsumed',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterFilterCondition>
      workoutCompletedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'workoutCompleted',
        value: value,
      ));
    });
  }
}

extension DailyLogSummaryQueryObject
    on QueryBuilder<DailyLogSummary, DailyLogSummary, QFilterCondition> {}

extension DailyLogSummaryQueryLinks
    on QueryBuilder<DailyLogSummary, DailyLogSummary, QFilterCondition> {}

extension DailyLogSummaryQuerySortBy
    on QueryBuilder<DailyLogSummary, DailyLogSummary, QSortBy> {
  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy>
      sortByCaloriesConsumed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'caloriesConsumed', Sort.asc);
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy>
      sortByCaloriesConsumedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'caloriesConsumed', Sort.desc);
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy>
      sortByCarbsConsumed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbsConsumed', Sort.asc);
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy>
      sortByCarbsConsumedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbsConsumed', Sort.desc);
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy> sortByDateKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.asc);
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy>
      sortByDateKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.desc);
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy>
      sortByFatConsumed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fatConsumed', Sort.asc);
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy>
      sortByFatConsumedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fatConsumed', Sort.desc);
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy>
      sortByGoalsMetCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goalsMetCount', Sort.asc);
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy>
      sortByGoalsMetCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goalsMetCount', Sort.desc);
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy>
      sortByNoteWritten() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noteWritten', Sort.asc);
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy>
      sortByNoteWrittenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noteWritten', Sort.desc);
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy>
      sortByProteinConsumed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proteinConsumed', Sort.asc);
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy>
      sortByProteinConsumedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proteinConsumed', Sort.desc);
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy>
      sortByWaterConsumed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waterConsumed', Sort.asc);
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy>
      sortByWaterConsumedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waterConsumed', Sort.desc);
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy>
      sortByWorkoutCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutCompleted', Sort.asc);
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy>
      sortByWorkoutCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutCompleted', Sort.desc);
    });
  }
}

extension DailyLogSummaryQuerySortThenBy
    on QueryBuilder<DailyLogSummary, DailyLogSummary, QSortThenBy> {
  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy>
      thenByCaloriesConsumed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'caloriesConsumed', Sort.asc);
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy>
      thenByCaloriesConsumedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'caloriesConsumed', Sort.desc);
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy>
      thenByCarbsConsumed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbsConsumed', Sort.asc);
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy>
      thenByCarbsConsumedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbsConsumed', Sort.desc);
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy> thenByDateKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.asc);
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy>
      thenByDateKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.desc);
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy>
      thenByFatConsumed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fatConsumed', Sort.asc);
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy>
      thenByFatConsumedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fatConsumed', Sort.desc);
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy>
      thenByGoalsMetCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goalsMetCount', Sort.asc);
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy>
      thenByGoalsMetCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goalsMetCount', Sort.desc);
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy>
      thenByNoteWritten() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noteWritten', Sort.asc);
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy>
      thenByNoteWrittenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noteWritten', Sort.desc);
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy>
      thenByProteinConsumed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proteinConsumed', Sort.asc);
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy>
      thenByProteinConsumedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proteinConsumed', Sort.desc);
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy>
      thenByWaterConsumed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waterConsumed', Sort.asc);
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy>
      thenByWaterConsumedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waterConsumed', Sort.desc);
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy>
      thenByWorkoutCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutCompleted', Sort.asc);
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QAfterSortBy>
      thenByWorkoutCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workoutCompleted', Sort.desc);
    });
  }
}

extension DailyLogSummaryQueryWhereDistinct
    on QueryBuilder<DailyLogSummary, DailyLogSummary, QDistinct> {
  QueryBuilder<DailyLogSummary, DailyLogSummary, QDistinct>
      distinctByCaloriesConsumed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'caloriesConsumed');
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QDistinct>
      distinctByCarbsConsumed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'carbsConsumed');
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QDistinct> distinctByDateKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dateKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QDistinct>
      distinctByFatConsumed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fatConsumed');
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QDistinct>
      distinctByGoalsMet() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'goalsMet');
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QDistinct>
      distinctByGoalsMetCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'goalsMetCount');
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QDistinct>
      distinctByNoteWritten() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'noteWritten');
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QDistinct>
      distinctByProteinConsumed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'proteinConsumed');
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QDistinct>
      distinctByWaterConsumed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'waterConsumed');
    });
  }

  QueryBuilder<DailyLogSummary, DailyLogSummary, QDistinct>
      distinctByWorkoutCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'workoutCompleted');
    });
  }
}

extension DailyLogSummaryQueryProperty
    on QueryBuilder<DailyLogSummary, DailyLogSummary, QQueryProperty> {
  QueryBuilder<DailyLogSummary, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DailyLogSummary, double, QQueryOperations>
      caloriesConsumedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'caloriesConsumed');
    });
  }

  QueryBuilder<DailyLogSummary, double, QQueryOperations>
      carbsConsumedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'carbsConsumed');
    });
  }

  QueryBuilder<DailyLogSummary, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<DailyLogSummary, String, QQueryOperations> dateKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dateKey');
    });
  }

  QueryBuilder<DailyLogSummary, double, QQueryOperations>
      fatConsumedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fatConsumed');
    });
  }

  QueryBuilder<DailyLogSummary, List<String>, QQueryOperations>
      goalsMetProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'goalsMet');
    });
  }

  QueryBuilder<DailyLogSummary, int, QQueryOperations> goalsMetCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'goalsMetCount');
    });
  }

  QueryBuilder<DailyLogSummary, bool, QQueryOperations> noteWrittenProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'noteWritten');
    });
  }

  QueryBuilder<DailyLogSummary, double, QQueryOperations>
      proteinConsumedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'proteinConsumed');
    });
  }

  QueryBuilder<DailyLogSummary, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<DailyLogSummary, double, QQueryOperations>
      waterConsumedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'waterConsumed');
    });
  }

  QueryBuilder<DailyLogSummary, bool, QQueryOperations>
      workoutCompletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'workoutCompleted');
    });
  }
}
