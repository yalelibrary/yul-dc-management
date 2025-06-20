# frozen_string_literal: true

METADATA_FIELDS = {
  alternativeTitle: {
    label: 'Alternative Title',
    solr_fields: [
      'alternativeTitle_tesim'
    ]
  },
  all_creators: {
    label: 'Creator',
    solr_fields: [
      'creator_ssim',
      'creator_tesim'
    ],
    digital_only: true
  },
  all_contributors: {
    label: 'Contributor',
    solr_fields: [
      'contributor_tsim'
    ],
    digital_only: true
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
      'abstract_tesim'
    ]
  },
  description: {
    label: 'Description',
    solr_fields: [
      'description_tesim'
    ]
  },
  provenanceUncontrolled: {
    label: 'Provenance',
    solr_fields: [
      'provenanceUncontrolled_tesi'
    ]
  },
  digitization_note: {
    label: 'Digitization Note',
    solr_fields: [
      'digitization_note_tesi'
    ]
  },
  digitization_funding_source: {
    label: 'Digitization Funding Source',
    solr_fields: [
      'digitization_funding_source_tesi'
    ]
  },
  extent: {
    label: 'Extent',
    solr_fields: [
      'extent_ssim'
    ]
  },
  projection: {
    label: 'Projection',
    solr_fields: [
      'projection_tesim'
    ]
  },
  project_identifier: {
    label: 'Project ID',
    solr_fields: [
      'project_identifier_tesi'
    ]
  },
  scale: {
    label: 'Scale',
    solr_fields: [
      'scale_tesim'
    ]
  },
  coordinateDisplay: {
    label: 'Coordinates',
    backup_field: 'coordinate', # use coordinate from authoritative_metadata in IIIF presentation if coordinateDisplay is not present
    solr_fields: [
      'coordinateDisplay_ssim'
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
  repository: {
    label: "Repository",
    solr_fields: [
      'repository_ssi'
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
  ancestorTitles: {
    label: 'Collection Note',
    solr_fields: [
      'sourceNote_tesim',
      'ancestorTitles_tesim'
    ],
    join_char: ' > ',
    reverse_array: true
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
  extent_of_digitization_text: {
    label: 'Extent of Digitization',
    solr_fields: [
      'extentOfDigitization_ssim'
    ],
    digital_only: true
  },
  findingAid: {
    label: 'Finding Aid',
    solr_fields: [
      'findingAid_ssim'
    ],
    is_url: true
  },
  archiveSpaceUri: {
    label: 'Archives at Yale Item Page',
    solr_fields: [
      'archiveSpaceUri_ssi'
    ],
    is_url: true,
    prefix: "https://archives.yale.edu"
  },
  format: {
    label: 'Format',
    solr_fields: [
      'format_tesim',
      'format'
    ]
  },
  related_resource_online_links: {
    label: 'Related Resources Online',
    solr_fields: [
      'relatedResourceOnline_ssim'
    ],
    digital_only: true
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
  viewingHint: {
    label: 'Viewing Hint',
    solr_fields: [
      'viewing_hint_ssi'
    ]
  },
  caption: {
    label: 'Caption',
    solr_fields: [
      'caption_tesim'
    ]
  },
  rights_statement: {
    label: 'Rights',
    solr_fields: [
      'rights_ssim',
      'rights_tesim'
    ],
    digital_only: true
  },
  preferredCitation: {
    label: 'Citation',
    solr_fields: [
      'preferredCitation_tesim'
    ]
  },
  mms_id: {
    label: 'Alma MMS ID',
    solr_fields: [
      'mmsId_ssi'
    ],
    digital_only: true
  },
  bib: {
    label: 'Orbis ID',
    solr_fields: [
      'orbisBibId_ssi'
    ],
    digital_only: true
  },
  oid: {
    label: 'Object ID (OID)',
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
