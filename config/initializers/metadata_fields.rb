# frozen_string_literal: true

METADATA_FIELDS = [
  {
    label: 'Abstract',
    field: 'abstract',
    solr_fields: [
      'abstract_tesim',
      'abstract_ssim'
    ]
  },
  {
    label: 'Alternative Title',
    field: 'alternativeTitle',
    solr_fields: [
      'alternativeTitle_tesim',
      'alternativeTitle_ssim',
      'alternative_title_tsm'
    ]
  },
  {
    label: 'Description',
    field: 'description',
    solr_fields: [
      'description_tesim'
    ]
  },
  {
    label: 'Extent',
    field: 'extent',
    solr_fields: [
      'extent_ssim'
    ]
  },
  {
    label: 'Extent of Digitization',
    field: 'extentOfDigitization',
    solr_fields: [
      'extentOfDigitization_ssim'
    ]
  },
  {
    label: 'Number of Pages',
    field: 'number_of_pages_ss',
    solr_fields: [
      'numberOfPages_ssim'
    ]
  },
  {
    label: 'References',
    field: 'preferredCitation',
    solr_fields: [
      'preferredCitation_tesim'
    ]
  },
  {
    label: 'Projection',
    field: 'projection',
    solr_fields: [
      'projection_tesim'
    ]
  },
  {
    label: 'Scale',
    field: 'scale',
    solr_fields: [
      'scale_tesim'
    ]
  },
  {
    label: 'Format',
    field: 'format',
    solr_fields: [
      'format_tesim',
      'format'
    ]
  },
  {
    label: 'Genre',
    field: 'genre',
    solr_fields: [
      'genre_ssim',
      'genre_tesim'
    ]
  },
  {
    label: 'Subject (Geographic)',
    field: 'subjectGeographic',
    solr_fields: [
      'subjectGeographic_tesim'
    ]
  },
  {
    label: 'Material',
    field: 'material',
    solr_fields: [
      'material_tesim'
    ]
  },
  {
    label: 'Resource Type',
    field: 'resourceType',
    solr_fields: [
      'resourceType_ssim',
      'resourceType_tesim'
    ]
  },
  {
    label: 'Subject (Name)',
    field: 'subjectName',
    solr_fields: [
      'subjectName_ssim',
      'subjectName_tesim'
    ]
  },
  {
    label: 'Subject (Topic)',
    field: 'subjectTopic',
    solr_fields: [
      'subjectTopic_tesim',
      'subjectTopic_ssim'
    ]
  },
  {
    label: 'Creator',
    field: 'creator',
    solr_fields: [
      'creator_ssim',
      'creator_tesim'
    ]
  },
  {
    label: 'Copyright Date',
    field: 'copyrightDate',
    solr_fields: [
      'copyrightDate_ssim'
    ]
  },
  {
    label: 'Coordinates',
    field: 'coordinate',
    solr_fields: [
      'coordinates_ssim'
    ]
  },
  {
    label: 'Date',
    field: 'date',
    solr_fields: [
      'date_ssim'
    ]
  },
  {
    label: 'Digital',
    field: 'digital',
    solr_fields: [
      'digital_ssim'
    ]
  },
  {
    label: 'Edition',
    field: 'edition',
    solr_fields: [
      'edition_ssim'
    ]
  },
  {
    label: 'Language',
    field: 'language',
    solr_fields: [
      'language_ssim'
    ]
  },
  {
    label: 'Publication Place',
    field: 'creationPlace',
    solr_fields: [
      'creationPlace_ssim',
      'creationPlace_tesim'
    ]
  },
  {
    label: 'Publisher',
    field: 'publisher',
    solr_fields: [
      'publisher_ssim',
      'publisher_ssim'
    ]
  },
  {
    label: 'Source Created',
    field: 'sourceCreated',
    solr_fields: [
      'sourceCreated_tesim'
    ]
  },
  {
    label: 'Source Date',
    field: 'sourceDate',
    solr_fields: [
      'sourceDate_tesim'
    ]
  },
  {
    label: 'Source Edition',
    field: 'sourceEdition',
    solr_fields: [
      'sourceEdition_tesim'
    ]
  },
  {
    label: 'Source Note',
    field: 'sourceNote',
    solr_fields: [
      'sourceNote_tesim'
    ]
  },
  {
    label: 'Source Title',
    field: 'sourceTitle',
    solr_fields: [
      'sourceTitle_tesim'
    ]
  },
  {
    label: 'Container / Volume Information',
    field: 'extract_container_information',
    solr_fields: [
      'containerGrouping_ssim'
    ],
    digital_only: true
  },
  {
    label: 'Finding Aid',
    field: 'findingAid',
    solr_fields: [
      'findingAid_ssim'
    ]
  },
  {
    label: 'Call Number',
    field: 'callNumber',
    solr_fields: [
      'callNumber_ssim',
      'callNumber_tesim'
    ]
  },
  {
    label: 'Orbis Bib ID',
    field: 'bib',
    solr_fields: [
      'orbisBibId_ssi'
    ],
    digital_only: true
  },
  {
    label: 'OID',
    field: 'oid',
    solr_fields: [
      'oid_ssi'
    ],
    digital_only: true
  },
  {
    label: 'URI',
    field: 'uri',
    solr_fields: [
      'uri_ssim'
    ]
  },
  {
    label: 'More Information',
    field: 'relatedUrl',
    solr_fields: [
      'url_suppl_ssim'
    ]
  },
  {
    label: 'Access',
    field: 'visibility',
    solr_fields: [
      'visibility_ssi'
    ],
    digital_only: true
  },
  {
    label: 'Rights',
    field: 'rights',
    solr_fields: [
      'rights_ssim',
      'rights_tesim'
    ]
  },
  {
    label: 'Record Type',
    field: 'recordType',
    solr_fields: [
      'recordType_ssi'
    ]
  },
  {
    label: 'Source',
    field: 'source',
    solr_fields: [
      'source_ssim'
    ]
  }
].freeze
