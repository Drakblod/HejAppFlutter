// Presets are data only. All rendering and validation uses generic definitions.
Map<String, dynamic> blankRatingConfig() => {
  'title': 'Betyg & ranking',
  'itemTypeName': 'Objekt',
  'primaryLabel': 'Helhetsbetyg',
  'min': 0,
  'max': 10,
  'showSummary': true,
  'criteria': <Map<String, dynamic>>[],
  'metadataFields': <Map<String, dynamic>>[],
};

Map<String, dynamic> sardineRatingConfig() => {
  ...blankRatingConfig(),
  'title': 'Sardinarkivet',
  'itemTypeName': 'Sardin',
  'criteria': [
    {
      'id': 'tenderness',
      'label': 'Mörhet',
      'min': 0,
      'max': 10,
      'showInRanking': true,
      'highlightLabel': 'Mörast',
    },
    {
      'id': 'juiciness',
      'label': 'Saftighet',
      'min': 0,
      'max': 10,
      'showInRanking': false,
      'highlightLabel': '',
    },
    {
      'id': 'flavour',
      'label': 'Smak',
      'min': 0,
      'max': 10,
      'showInRanking': false,
      'highlightLabel': '',
    },
    {
      'id': 'value',
      'label': 'Prisvärdhet',
      'min': 0,
      'max': 10,
      'showInRanking': true,
      'highlightLabel': 'Bästa prisvärdhet',
    },
  ],
  'metadataFields': [
    {'id': 'producer', 'label': 'Producent', 'type': 'text', 'required': false},
    {'id': 'country', 'label': 'Land', 'type': 'text', 'required': false},
    {
      'id': 'price',
      'label': 'Pris',
      'type': 'currency',
      'currency': 'SEK',
      'required': false,
    },
    {
      'id': 'sauce',
      'label': 'Olja/sås',
      'type': 'dropdown',
      'options': ['Olivolja', 'Tomatsås', 'Chili', 'Citron', 'Annat'],
      'required': false,
    },
    {
      'id': 'size',
      'label': 'Fiskstorlek',
      'type': 'dropdown',
      'options': ['Små', 'Medel', 'Stora'],
      'required': false,
    },
    {
      'id': 'buyAgain',
      'label': 'Skulle köpa igen',
      'type': 'boolean',
      'required': false,
    },
    {
      'id': 'testedOn',
      'label': 'Datum testad',
      'type': 'date',
      'required': false,
    },
  ],
};
