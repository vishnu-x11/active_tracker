
part of 'body_weight_log.dart';

extension GetBodyWeightLogCollection on Isar {
  IsarCollection<BodyWeightLog> get bodyWeightLogs => this.collection();
}

const bodyWeightLogSchema = CollectionSchema(
  name: r'BodyWeightLog',
  id: 4217662832063541940,
  properties: {
    r'dailyTotal': PropertySchema(
      id: 0,
      name: r'dailyTotal',
      type: IsarType.long,
    ),
    r'dateKey': PropertySchema(
      id: 1,
      name: r'dateKey',
      type: IsarType.string,
    ),
    r'exerciseType': PropertySchema(
      id: 2,
      name: r'exerciseType',
      type: IsarType.string,
    ),
    r'setsReps': PropertySchema(
      id: 3,
      name: r'setsReps',
      type: IsarType.string,
    ),
    r'timestamp': PropertySchema(
      id: 4,
      name: r'timestamp',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _bodyWeightLogEstimateSize,
  serialize: _bodyWeightLogSerialize,
  deserialize: _bodyWeightLogDeserialize,
  deserializeProp: _bodyWeightLogDeserializeProp,
  idName: r'id',
  indexes: {
    r'dateKey': IndexSchema(
      id: 7975223786082927131,
      name: r'dateKey',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'dateKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _bodyWeightLogGetId,
  getLinks: _bodyWeightLogGetLinks,
  attach: _bodyWeightLogAttach,
  version: '3.1.0+1',
);

int _bodyWeightLogEstimateSize(
  BodyWeightLog object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.dateKey.length * 3;
  bytesCount += 3 + object.exerciseType.length * 3;
  bytesCount += 3 + object.setsReps.length * 3;
  return bytesCount;
}

void _bodyWeightLogSerialize(
  BodyWeightLog object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.dailyTotal);
  writer.writeString(offsets[1], object.dateKey);
  writer.writeString(offsets[2], object.exerciseType);
  writer.writeString(offsets[3], object.setsReps);
  writer.writeDateTime(offsets[4], object.timestamp);
}

BodyWeightLog _bodyWeightLogDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = BodyWeightLog();
  object.dailyTotal = reader.readLong(offsets[0]);
  object.dateKey = reader.readString(offsets[1]);
  object.exerciseType = reader.readString(offsets[2]);
  object.id = id;
  object.setsReps = reader.readString(offsets[3]);
  object.timestamp = reader.readDateTime(offsets[4]);
  return object;
}

P _bodyWeightLogDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _bodyWeightLogGetId(BodyWeightLog object) {
  return object.id ?? Isar.autoIncrement;
}

List<IsarLinkBase<dynamic>> _bodyWeightLogGetLinks(BodyWeightLog object) {
  return [];
}

void _bodyWeightLogAttach(
    IsarCollection<dynamic> col, Id id, BodyWeightLog object) {
  object.id = id;
}

extension BodyWeightLogQueryWhereSort
    on QueryBuilder<BodyWeightLog, BodyWeightLog, QWhere> {
  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension BodyWeightLogQueryWhere
    on QueryBuilder<BodyWeightLog, BodyWeightLog, QWhereClause> {
  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterWhereClause> idBetween(
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

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterWhereClause> dateKeyEqualTo(
      String dateKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'dateKey',
        value: [dateKey],
      ));
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterWhereClause>
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
}

extension BodyWeightLogQueryFilter
    on QueryBuilder<BodyWeightLog, BodyWeightLog, QFilterCondition> {
  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterFilterCondition>
      dailyTotalEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dailyTotal',
        value: value,
      ));
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterFilterCondition>
      dailyTotalGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dailyTotal',
        value: value,
      ));
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterFilterCondition>
      dailyTotalLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dailyTotal',
        value: value,
      ));
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterFilterCondition>
      dailyTotalBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dailyTotal',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterFilterCondition>
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

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterFilterCondition>
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

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterFilterCondition>
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

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterFilterCondition>
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

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterFilterCondition>
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

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterFilterCondition>
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

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterFilterCondition>
      dateKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterFilterCondition>
      dateKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'dateKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterFilterCondition>
      dateKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dateKey',
        value: '',
      ));
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterFilterCondition>
      dateKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'dateKey',
        value: '',
      ));
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterFilterCondition>
      exerciseTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'exerciseType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterFilterCondition>
      exerciseTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'exerciseType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterFilterCondition>
      exerciseTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'exerciseType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterFilterCondition>
      exerciseTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'exerciseType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterFilterCondition>
      exerciseTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'exerciseType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterFilterCondition>
      exerciseTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'exerciseType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterFilterCondition>
      exerciseTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'exerciseType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterFilterCondition>
      exerciseTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'exerciseType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterFilterCondition>
      exerciseTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'exerciseType',
        value: '',
      ));
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterFilterCondition>
      exerciseTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'exerciseType',
        value: '',
      ));
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterFilterCondition> idIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterFilterCondition>
      idIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterFilterCondition> idEqualTo(
      Id? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterFilterCondition>
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

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterFilterCondition> idBetween(
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

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterFilterCondition>
      setsRepsEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'setsReps',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterFilterCondition>
      setsRepsGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'setsReps',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterFilterCondition>
      setsRepsLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'setsReps',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterFilterCondition>
      setsRepsBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'setsReps',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterFilterCondition>
      setsRepsStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'setsReps',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterFilterCondition>
      setsRepsEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'setsReps',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterFilterCondition>
      setsRepsContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'setsReps',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterFilterCondition>
      setsRepsMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'setsReps',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterFilterCondition>
      setsRepsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'setsReps',
        value: '',
      ));
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterFilterCondition>
      setsRepsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'setsReps',
        value: '',
      ));
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterFilterCondition>
      timestampEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterFilterCondition>
      timestampGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterFilterCondition>
      timestampLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterFilterCondition>
      timestampBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timestamp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension BodyWeightLogQueryObject
    on QueryBuilder<BodyWeightLog, BodyWeightLog, QFilterCondition> {}

extension BodyWeightLogQueryLinks
    on QueryBuilder<BodyWeightLog, BodyWeightLog, QFilterCondition> {}

extension BodyWeightLogQuerySortBy
    on QueryBuilder<BodyWeightLog, BodyWeightLog, QSortBy> {
  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterSortBy> sortByDailyTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailyTotal', Sort.asc);
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterSortBy>
      sortByDailyTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailyTotal', Sort.desc);
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterSortBy> sortByDateKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.asc);
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterSortBy> sortByDateKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.desc);
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterSortBy>
      sortByExerciseType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exerciseType', Sort.asc);
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterSortBy>
      sortByExerciseTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exerciseType', Sort.desc);
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterSortBy> sortBySetsReps() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'setsReps', Sort.asc);
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterSortBy>
      sortBySetsRepsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'setsReps', Sort.desc);
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterSortBy> sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterSortBy>
      sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension BodyWeightLogQuerySortThenBy
    on QueryBuilder<BodyWeightLog, BodyWeightLog, QSortThenBy> {
  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterSortBy> thenByDailyTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailyTotal', Sort.asc);
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterSortBy>
      thenByDailyTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailyTotal', Sort.desc);
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterSortBy> thenByDateKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.asc);
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterSortBy> thenByDateKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.desc);
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterSortBy>
      thenByExerciseType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exerciseType', Sort.asc);
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterSortBy>
      thenByExerciseTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exerciseType', Sort.desc);
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterSortBy> thenBySetsReps() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'setsReps', Sort.asc);
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterSortBy>
      thenBySetsRepsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'setsReps', Sort.desc);
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterSortBy> thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QAfterSortBy>
      thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension BodyWeightLogQueryWhereDistinct
    on QueryBuilder<BodyWeightLog, BodyWeightLog, QDistinct> {
  QueryBuilder<BodyWeightLog, BodyWeightLog, QDistinct> distinctByDailyTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dailyTotal');
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QDistinct> distinctByDateKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dateKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QDistinct> distinctByExerciseType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'exerciseType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QDistinct> distinctBySetsReps(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'setsReps', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BodyWeightLog, BodyWeightLog, QDistinct> distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }
}

extension BodyWeightLogQueryProperty
    on QueryBuilder<BodyWeightLog, BodyWeightLog, QQueryProperty> {
  QueryBuilder<BodyWeightLog, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<BodyWeightLog, int, QQueryOperations> dailyTotalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dailyTotal');
    });
  }

  QueryBuilder<BodyWeightLog, String, QQueryOperations> dateKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dateKey');
    });
  }

  QueryBuilder<BodyWeightLog, String, QQueryOperations> exerciseTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'exerciseType');
    });
  }

  QueryBuilder<BodyWeightLog, String, QQueryOperations> setsRepsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'setsReps');
    });
  }

  QueryBuilder<BodyWeightLog, DateTime, QQueryOperations> timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }
}
