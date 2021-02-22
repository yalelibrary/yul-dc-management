# frozen_string_literal: true

METADATA_FIELDS = {
  alternativeTitle: {
    label: 'Alternative Title',
    solr_fields: [
      'alternativeTitle_tesim',
      'alternativeTitle_ssim',
      'alternative_title_tsm'
    ]
  },
  creator: {
    label: 'Creator',
    solr_fields: [
      'creator_ssim',
      'creator_tesim'
    ]
  },
  date: {
    label: 'Published/Created Date',
    solr_fields: [
      'date_ssim'
    ]
  },
  copyrightDate: {
    label: 'Copyright Date',
    solr_fields: [
      'copyrightDate_ssim'
    ]
  },
  creationPlace: {
    label: 'Publication Place',
    solr_fields: [
      'creationPlace_ssim',
      'creationPlace_tesim'
    ]
  },
  publisher: {
    label: 'Publisher',
    solr_fields: [
      'publisher_ssim',
      'publisher_ssim'
    ]
  },
  abstract: {
    label: 'Abstract',
    solr_fields: [
      'abstract_tesim',
      'abstract_ssim'
    ]
  },
  description: {
    label: 'Description',
    solr_fields: [
      'description_tesim'
    ]
  },
  extent: {
    label: 'Extent',
    solr_fields: [
      'extent_ssim'
    ]
  },
  extentOfDigitization: {
    label: 'Extent of Digitization',
    solr_fields: [
      'extentOfDigitization_ssim'
    ]
  },
  projection: {
    label: 'Projection',
    solr_fields: [
      'projection_tesim'
    ]
  },
  scale: {
    label: 'Scale',
    solr_fields: [
      'scale_tesim'
    ]
  },
  coordinate: {
    label: 'Coordinates',
    solr_fields: [
      'coordinates_ssim'
    ]
  },
  digital: {
    label: 'Digital',
    solr_fields: [
      'digital_ssim'
    ]
  },
  edition: {
    label: 'Edition',
    solr_fields: [
      'edition_ssim'
    ]
  },
  language: {
    label: 'Language',
    solr_fields: [
      'language_ssim'
    ]
  },
  callNumber: {
    label: 'Call Number',
    solr_fields: [
      'callNumber_ssim',
      'callNumber_tesim'
    ]
  },
  sourceTitle: {
    label: 'Collection Title',
    solr_fields: [
      'sourceTitle_tesim'
    ]
  },
  sourceCreated: {
    label: 'Collection Created',
    solr_fields: [
      'sourceCreated_tesim'
    ]
  },
  sourceDate: {
    label: 'Collection Date',
    solr_fields: [
      'sourceDate_tesim'
    ]
  },
  sourceNote: {
    label: 'Collection Note',
    solr_fields: [
      'sourceNote_tesim'
    ]
  },
  sourceEdition: {
    label: 'Collection Edition',
    solr_fields: [
      'sourceEdition_tesim'
    ]
  },
  extract_container_information: {
    label: 'Container / Volume Information',
    solr_fields: [
      'containerGrouping_ssim'
    ],
    digital_only: true
  },
  findingAid: {
    label: 'Finding Aid',
    solr_fields: [
      'findingAid_ssim'
    ]
  },
  format: {
    label: 'Format',
    solr_fields: [
      'format_tesim',
      'format'
    ]
  },
  genre: {
    label: 'Genre',
    solr_fields: [
      'genre_ssim',
      'genre_tesim'
    ]
  },
  material: {
    label: 'Material',
    solr_fields: [
      'material_tesim'
    ]
  },
  itemType: {
    label: 'Resource Type',
    solr_fields: [
      'resourceType_ssim',
      'resourceType_tesim'
    ]
  },
  subjectGeographic: {
    label: 'Subject (Geographic)',
    solr_fields: [
      'subjectGeographic_tesim'
    ]
  },
  subjectName: {
    label: 'Subject (Name)',
    solr_fields: [
      'subjectName_ssim',
      'subjectName_tesim'
    ]
  },
  subjectTopic: {
    label: 'Subject (Topic)',
    solr_fields: [
      'subjectTopic_tesim',
      'subjectTopic_ssim'
    ]
  },
  visibility: {
    label: 'Access',
    solr_fields: [
      'visibility_ssi'
    ],
    digital_only: true
  },
  rights: {
    label: 'Rights',
    solr_fields: [
      'rights_ssim',
      'rights_tesim'
    ]
  },
  preferredCitation: {
    label: 'Citation',
    solr_fields: [
      'preferredCitation_tesim'
    ]
  },
  bib: {
    label: 'Orbis ID',
    solr_fields: [
      'orbisBibId_ssi'
    ],
    digital_only: true
  },
  oid: {
    label: 'OID',
    solr_fields: [
      'oid_ssi'
    ],
    digital_only: true
  },
  relatedUrl: {
    label: 'More Information',
    solr_fields: [
      'url_suppl_ssim'
    ]
  }

}.freeze
