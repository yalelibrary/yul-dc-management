# Changelog

## [v2.8.0](https://github.com/yalelibrary/yul-dc-management/tree/v2.8.0) (2020-08-05)

[Full Changelog](https://github.com/yalelibrary/yul-dc-management/compare/v2.7.2...v2.8.0)

**New Features:**

- Index \# of images associated with a work [\#197](https://github.com/yalelibrary/yul-dc-management/pull/197) ([dylansalay](https://github.com/dylansalay))

**Fixed bugs:**

- Fix merge problem with previous PR [\#196](https://github.com/yalelibrary/yul-dc-management/pull/196) ([maxkadel](https://github.com/maxkadel))
- Refactor tests to use tag for prepping metadata sources [\#195](https://github.com/yalelibrary/yul-dc-management/pull/195) ([maxkadel](https://github.com/maxkadel))
- Call method in controller to create ParentObject [\#193](https://github.com/yalelibrary/yul-dc-management/pull/193) ([maxkadel](https://github.com/maxkadel))
- Oid Logger [\#192](https://github.com/yalelibrary/yul-dc-management/pull/192) ([dylansalay](https://github.com/dylansalay))
- Will not error out if there is not goobi namespace in xml [\#191](https://github.com/yalelibrary/yul-dc-management/pull/191) ([maxkadel](https://github.com/maxkadel))

**Technical Enhancements:**

- Only log errors for test environment [\#194](https://github.com/yalelibrary/yul-dc-management/pull/194) ([maxkadel](https://github.com/maxkadel))

## [v2.7.2](https://github.com/yalelibrary/yul-dc-management/tree/v2.7.2) (2020-08-03)

[Full Changelog](https://github.com/yalelibrary/yul-dc-management/compare/v2.7.1...v2.7.2)

**Fixed bugs:**

- Does not try to fetch from MetadataCloud if VPN is set to empty string [\#187](https://github.com/yalelibrary/yul-dc-management/pull/187) ([maxkadel](https://github.com/maxkadel))

**Technical Enhancements:**

- Prep for v2.7.2 release [\#190](https://github.com/yalelibrary/yul-dc-management/pull/190) ([maxkadel](https://github.com/maxkadel))
- Circle ci wait on release [\#188](https://github.com/yalelibrary/yul-dc-management/pull/188) ([JzGo](https://github.com/JzGo))
- Added camerata instructions to management readme [\#180](https://github.com/yalelibrary/yul-dc-management/pull/180) ([jpengst](https://github.com/jpengst))

## [v2.7.1](https://github.com/yalelibrary/yul-dc-management/tree/v2.7.1) (2020-08-03)

[Full Changelog](https://github.com/yalelibrary/yul-dc-management/compare/v2.7.0...v2.7.1)

**Technical Enhancements:**

- Earlier commit reverted, re-create changelog for 2.7.0 release [\#186](https://github.com/yalelibrary/yul-dc-management/pull/186) ([maxkadel](https://github.com/maxkadel))
- Revert "Circle ci wait on release" [\#185](https://github.com/yalelibrary/yul-dc-management/pull/185) ([maxkadel](https://github.com/maxkadel))

## [v2.7.0](https://github.com/yalelibrary/yul-dc-management/tree/v2.7.0) (2020-08-03)

[Full Changelog](https://github.com/yalelibrary/yul-dc-management/compare/v2.7.0.pre...v2.7.0)

**New Features:**

- Load samples from S3 if no VPN, cache them to S3 when VPN is on [\#183](https://github.com/yalelibrary/yul-dc-management/pull/183) ([orangewolf](https://github.com/orangewolf))

**Security fixes:**

- Bump elliptic from 6.5.2 to 6.5.3 [\#182](https://github.com/yalelibrary/yul-dc-management/pull/182) ([dependabot[bot]](https://github.com/apps/dependabot))

**Technical Enhancements:**

- Prep for v2.7.0 release [\#184](https://github.com/yalelibrary/yul-dc-management/pull/184) ([maxkadel](https://github.com/maxkadel))
- Circle ci wait on release [\#181](https://github.com/yalelibrary/yul-dc-management/pull/181) ([JzGo](https://github.com/JzGo))
- Logging [\#166](https://github.com/yalelibrary/yul-dc-management/pull/166) ([mlooney](https://github.com/mlooney))

## [v2.7.0.pre](https://github.com/yalelibrary/yul-dc-management/tree/v2.7.0.pre) (2020-08-02)

[Full Changelog](https://github.com/yalelibrary/yul-dc-management/compare/v2.6.0...v2.7.0.pre)

## [v2.6.0](https://github.com/yalelibrary/yul-dc-management/tree/v2.6.0) (2020-07-30)

[Full Changelog](https://github.com/yalelibrary/yul-dc-management/compare/v2.5.0...v2.6.0)

**New Features:**

- Add solr field types tesim [\#177](https://github.com/yalelibrary/yul-dc-management/pull/177) ([dylansalay](https://github.com/dylansalay))
- Create new method to index from the database to Solr [\#172](https://github.com/yalelibrary/yul-dc-management/pull/172) ([maxkadel](https://github.com/maxkadel))
- Index more fields [\#169](https://github.com/yalelibrary/yul-dc-management/pull/169) ([maxkadel](https://github.com/maxkadel))
- METs upload creates parent object [\#168](https://github.com/yalelibrary/yul-dc-management/pull/168) ([maxkadel](https://github.com/maxkadel))
- Upload mets file [\#159](https://github.com/yalelibrary/yul-dc-management/pull/159) ([maxkadel](https://github.com/maxkadel))

**Fixed bugs:**

- Fix metadata\_cloud\_host in development environment [\#174](https://github.com/yalelibrary/yul-dc-management/pull/174) ([maxkadel](https://github.com/maxkadel))
- remove sourcemaps from Webpack [\#167](https://github.com/yalelibrary/yul-dc-management/pull/167) ([dylansalay](https://github.com/dylansalay))

**Technical Enhancements:**

- Fix simplecov line [\#179](https://github.com/yalelibrary/yul-dc-management/pull/179) ([orangewolf](https://github.com/orangewolf))
- prep for 2.6.0 [\#178](https://github.com/yalelibrary/yul-dc-management/pull/178) ([orangewolf](https://github.com/orangewolf))
- Oid Imports controller spec [\#176](https://github.com/yalelibrary/yul-dc-management/pull/176) ([dylansalay](https://github.com/dylansalay))
- Use Metadata Cloud UAT for Dev Environment [\#175](https://github.com/yalelibrary/yul-dc-management/pull/175) ([orangewolf](https://github.com/orangewolf))
- 378 code coverage [\#173](https://github.com/yalelibrary/yul-dc-management/pull/173) ([jpengst](https://github.com/jpengst))
- Reapplying "Sanitize branch name in CI \(\#158\)" [\#171](https://github.com/yalelibrary/yul-dc-management/pull/171) ([fnibbit](https://github.com/fnibbit))
- Address test warning and deprecation [\#170](https://github.com/yalelibrary/yul-dc-management/pull/170) ([maxkadel](https://github.com/maxkadel))
- 392 metadata cloud url change [\#165](https://github.com/yalelibrary/yul-dc-management/pull/165) ([martinlovell](https://github.com/martinlovell))
- Revert "Sanitize branch name in CI \(\#158\)" [\#164](https://github.com/yalelibrary/yul-dc-management/pull/164) ([maxkadel](https://github.com/maxkadel))
- Refactor metadata cloud service [\#163](https://github.com/yalelibrary/yul-dc-management/pull/163) ([maxkadel](https://github.com/maxkadel))
- make code coverage skip the metadata\_sampling service [\#162](https://github.com/yalelibrary/yul-dc-management/pull/162) ([orangewolf](https://github.com/orangewolf))
- seeds will not error when ran a second time [\#161](https://github.com/yalelibrary/yul-dc-management/pull/161) ([jpengst](https://github.com/jpengst))
- Seed production and dev on load, run OID Minter on seed [\#160](https://github.com/yalelibrary/yul-dc-management/pull/160) ([orangewolf](https://github.com/orangewolf))
- Sanitize branch name in CI [\#158](https://github.com/yalelibrary/yul-dc-management/pull/158) ([fnibbit](https://github.com/fnibbit))
- Remove dead code [\#156](https://github.com/yalelibrary/yul-dc-management/pull/156) ([maxkadel](https://github.com/maxkadel))
- added value descriptions [\#155](https://github.com/yalelibrary/yul-dc-management/pull/155) ([jpengst](https://github.com/jpengst))
- Fix coveralls by allowing git to be present in build [\#152](https://github.com/yalelibrary/yul-dc-management/pull/152) ([orangewolf](https://github.com/orangewolf))

## [v2.5.0](https://github.com/yalelibrary/yul-dc-management/tree/v2.5.0) (2020-07-20)

[Full Changelog](https://github.com/yalelibrary/yul-dc-management/compare/v2.4.0...v2.5.0)

**New Features:**

- OID request logger and spec [\#151](https://github.com/yalelibrary/yul-dc-management/pull/151) ([dylansalay](https://github.com/dylansalay))
- Refactor parent objects [\#144](https://github.com/yalelibrary/yul-dc-management/pull/144) ([maxkadel](https://github.com/maxkadel))

**Security fixes:**

- Bump lodash from 4.17.15 to 4.17.19 [\#153](https://github.com/yalelibrary/yul-dc-management/pull/153) ([dependabot[bot]](https://github.com/apps/dependabot))

**Technical Enhancements:**

- prep for v2.5.0 release [\#154](https://github.com/yalelibrary/yul-dc-management/pull/154) ([maxkadel](https://github.com/maxkadel))
- Goobi parent objects [\#150](https://github.com/yalelibrary/yul-dc-management/pull/150) ([maxkadel](https://github.com/maxkadel))
- Set honeybadger key from env var [\#149](https://github.com/yalelibrary/yul-dc-management/pull/149) ([JzGo](https://github.com/JzGo))
- Coveralls test coverage badge [\#146](https://github.com/yalelibrary/yul-dc-management/pull/146) ([jpengst](https://github.com/jpengst))
- Update to latest Solr image for dev [\#145](https://github.com/yalelibrary/yul-dc-management/pull/145) ([maxkadel](https://github.com/maxkadel))

## [v2.4.0](https://github.com/yalelibrary/yul-dc-management/tree/v2.4.0) (2020-07-13)

[Full Changelog](https://github.com/yalelibrary/yul-dc-management/compare/v2.3.0...v2.4.0)

**New Features:**

- 322 Authenticate oid request [\#141](https://github.com/yalelibrary/yul-dc-management/pull/141) ([dylansalay](https://github.com/dylansalay))

**Technical Enhancements:**

- Prep for v2.4.0 release [\#143](https://github.com/yalelibrary/yul-dc-management/pull/143) ([bess](https://github.com/bess))
- Configure yarn correctly, set up volumes to boost dev speed [\#142](https://github.com/yalelibrary/yul-dc-management/pull/142) ([orangewolf](https://github.com/orangewolf))

## [v2.3.0](https://github.com/yalelibrary/yul-dc-management/tree/v2.3.0) (2020-07-10)

[Full Changelog](https://github.com/yalelibrary/yul-dc-management/compare/v2.2.0...v2.3.0)

**New Features:**

- Add an OID minter service and controller [\#137](https://github.com/yalelibrary/yul-dc-management/pull/137) ([mikeapp](https://github.com/mikeapp))

**Technical Enhancements:**

- Prep for v2.3.0 [\#140](https://github.com/yalelibrary/yul-dc-management/pull/140) ([FCRodriguez7](https://github.com/FCRodriguez7))
- For development pull master docker tag not the version docker tag [\#139](https://github.com/yalelibrary/yul-dc-management/pull/139) ([orangewolf](https://github.com/orangewolf))
- Sample and save [\#138](https://github.com/yalelibrary/yul-dc-management/pull/138) ([dylansalay](https://github.com/dylansalay))

## [v2.2.0](https://github.com/yalelibrary/yul-dc-management/tree/v2.2.0) (2020-07-07)

[Full Changelog](https://github.com/yalelibrary/yul-dc-management/compare/v2.1.0...v2.2.0)

**New Features:**

- Automate categories in change log & Release Notes [\#135](https://github.com/yalelibrary/yul-dc-management/pull/135) ([jpengst](https://github.com/jpengst))
- Don't save responses from MetadataCloud if they are not successful [\#133](https://github.com/yalelibrary/yul-dc-management/pull/133) ([maxkadel](https://github.com/maxkadel))
- Ladybird statistics [\#129](https://github.com/yalelibrary/yul-dc-management/pull/129) ([maxkadel](https://github.com/maxkadel))

**Fixed bugs:**

- Increase development and production parity by always using /management [\#134](https://github.com/yalelibrary/yul-dc-management/pull/134) ([orangewolf](https://github.com/orangewolf))

**Technical Enhancements:**

- Version bump for 2.2.0 [\#136](https://github.com/yalelibrary/yul-dc-management/pull/136) ([orangewolf](https://github.com/orangewolf))
- Parallel naming for app and spec directories [\#132](https://github.com/yalelibrary/yul-dc-management/pull/132) ([maxkadel](https://github.com/maxkadel))
- Update version in .env and update readme to include in release process [\#131](https://github.com/yalelibrary/yul-dc-management/pull/131) ([maxkadel](https://github.com/maxkadel))

## [v2.1.0](https://github.com/yalelibrary/yul-dc-management/tree/v2.1.0) (2020-07-06)

[Full Changelog](https://github.com/yalelibrary/yul-dc-management/compare/v2.0.0...v2.1.0)

**New Features:**

- 257 oid csv upload [\#124](https://github.com/yalelibrary/yul-dc-management/pull/124) ([jpengst](https://github.com/jpengst))

**Technical Enhancements:**

- release 2.1.0 [\#130](https://github.com/yalelibrary/yul-dc-management/pull/130) ([jpengst](https://github.com/jpengst))
- Pass ability to set logs to stdout [\#128](https://github.com/yalelibrary/yul-dc-management/pull/128) ([orangewolf](https://github.com/orangewolf))

## [v2.0.0](https://github.com/yalelibrary/yul-dc-management/tree/v2.0.0) (2020-07-02)

[Full Changelog](https://github.com/yalelibrary/yul-dc-management/compare/v1.8.0...v2.0.0)

**New Features:**

- Activity stream performance [\#122](https://github.com/yalelibrary/yul-dc-management/pull/122) ([maxkadel](https://github.com/maxkadel))
- Add dependent object model method to populate [\#117](https://github.com/yalelibrary/yul-dc-management/pull/117) ([maxkadel](https://github.com/maxkadel))

**Fixed bugs:**

- Normalize db names [\#126](https://github.com/yalelibrary/yul-dc-management/pull/126) ([maxkadel](https://github.com/maxkadel))
- Pass Rails relative url root in to app [\#123](https://github.com/yalelibrary/yul-dc-management/pull/123) ([orangewolf](https://github.com/orangewolf))
- Remove unused base file [\#121](https://github.com/yalelibrary/yul-dc-management/pull/121) ([orangewolf](https://github.com/orangewolf))
- Update wiki with info about test coverage [\#120](https://github.com/yalelibrary/yul-dc-management/pull/120) ([bess](https://github.com/bess))
- Report coverage from CircleCI [\#119](https://github.com/yalelibrary/yul-dc-management/pull/119) ([bess](https://github.com/bess))

**Technical Enhancements:**

- Prep for 2.0.0 release [\#127](https://github.com/yalelibrary/yul-dc-management/pull/127) ([maxkadel](https://github.com/maxkadel))

## [v1.8.0](https://github.com/yalelibrary/yul-dc-management/tree/v1.8.0) (2020-06-26)

[Full Changelog](https://github.com/yalelibrary/yul-dc-management/compare/v1.7.2...v1.8.0)

**Security fixes:**

- Bump rack from 2.2.2 to 2.2.3 [\#110](https://github.com/yalelibrary/yul-dc-management/pull/110) ([dependabot[bot]](https://github.com/apps/dependabot))

**Technical Enhancements:**

- prep for release 1.8.0 [\#116](https://github.com/yalelibrary/yul-dc-management/pull/116) ([maxkadel](https://github.com/maxkadel))
- Refactor Metadata cloud service - put parsing tasks in own class [\#114](https://github.com/yalelibrary/yul-dc-management/pull/114) ([maxkadel](https://github.com/maxkadel))
- update actionpack [\#113](https://github.com/yalelibrary/yul-dc-management/pull/113) ([maxkadel](https://github.com/maxkadel))
- Refactor, return hash so file doesn't have to be parsed subsequently [\#112](https://github.com/yalelibrary/yul-dc-management/pull/112) ([maxkadel](https://github.com/maxkadel))
- Upgrade webpacker due to failing local tests & peer dependency [\#111](https://github.com/yalelibrary/yul-dc-management/pull/111) ([maxkadel](https://github.com/maxkadel))
- added dropdown for solr indexing [\#109](https://github.com/yalelibrary/yul-dc-management/pull/109) ([jpengst](https://github.com/jpengst))
- Update fixture objects from MetadataCloud [\#108](https://github.com/yalelibrary/yul-dc-management/pull/108) ([maxkadel](https://github.com/maxkadel))
- Calculate code coverage [\#106](https://github.com/yalelibrary/yul-dc-management/pull/106) ([bess](https://github.com/bess))
- Add visibility from SOA Ladybird for all items [\#105](https://github.com/yalelibrary/yul-dc-management/pull/105) ([maxkadel](https://github.com/maxkadel))
- Add Camerata to versions dashboard [\#104](https://github.com/yalelibrary/yul-dc-management/pull/104) ([maxkadel](https://github.com/maxkadel))
- Add temporary fix for Box pending more detailed requirements [\#103](https://github.com/yalelibrary/yul-dc-management/pull/103) ([maxkadel](https://github.com/maxkadel))

## [v1.7.2](https://github.com/yalelibrary/yul-dc-management/tree/v1.7.2) (2020-06-22)

[Full Changelog](https://github.com/yalelibrary/yul-dc-management/compare/v1.7.1...v1.7.2)

**Technical Enhancements:**

- Prep for v1.7.2 release [\#101](https://github.com/yalelibrary/yul-dc-management/pull/101) ([maxkadel](https://github.com/maxkadel))
- Just don't set hosts for now to get it running in production, can re-… [\#100](https://github.com/yalelibrary/yul-dc-management/pull/100) ([maxkadel](https://github.com/maxkadel))

## [v1.7.1](https://github.com/yalelibrary/yul-dc-management/tree/v1.7.1) (2020-06-22)

[Full Changelog](https://github.com/yalelibrary/yul-dc-management/compare/v1.7.0...v1.7.1)

**Technical Enhancements:**

- Prep for v1.7.1 release [\#99](https://github.com/yalelibrary/yul-dc-management/pull/99) ([maxkadel](https://github.com/maxkadel))
- Correct earlier migration error - never replace all [\#98](https://github.com/yalelibrary/yul-dc-management/pull/98) ([maxkadel](https://github.com/maxkadel))

## [v1.7.0](https://github.com/yalelibrary/yul-dc-management/tree/v1.7.0) (2020-06-22)

[Full Changelog](https://github.com/yalelibrary/yul-dc-management/compare/v1.6.0...v1.7.0)

**Technical Enhancements:**

- Prepare for 1.7.0 release [\#96](https://github.com/yalelibrary/yul-dc-management/pull/96) ([maxkadel](https://github.com/maxkadel))
- Dashboard formatting [\#95](https://github.com/yalelibrary/yul-dc-management/pull/95) ([maxkadel](https://github.com/maxkadel))
- Read ArchiveSpace and Voyager non-bib updates from activity stream [\#94](https://github.com/yalelibrary/yul-dc-management/pull/94) ([maxkadel](https://github.com/maxkadel))

## [v1.6.0](https://github.com/yalelibrary/yul-dc-management/tree/v1.6.0) (2020-06-19)

[Full Changelog](https://github.com/yalelibrary/yul-dc-management/compare/v1.5.2...v1.6.0)

**Technical Enhancements:**

- Generate the changelog for a v1.6.0 release [\#93](https://github.com/yalelibrary/yul-dc-management/pull/93) ([mark-dce](https://github.com/mark-dce))
- Rename crosswalk method to more specific find\_source\_ids\_for\(oid\) [\#91](https://github.com/yalelibrary/yul-dc-management/pull/91) ([maxkadel](https://github.com/maxkadel))
- Add honeybader for execption reporting in production [\#90](https://github.com/yalelibrary/yul-dc-management/pull/90) ([mark-dce](https://github.com/mark-dce))
- Process Activity Stream Updates for Voyager bibs [\#89](https://github.com/yalelibrary/yul-dc-management/pull/89) ([maxkadel](https://github.com/maxkadel))
- Speed up CircleCi With Caching [\#86](https://github.com/yalelibrary/yul-dc-management/pull/86) ([orangewolf](https://github.com/orangewolf))
- Complete the crosswalk between oids and other identifiers [\#85](https://github.com/yalelibrary/yul-dc-management/pull/85) ([maxkadel](https://github.com/maxkadel))
- Save objects from activity stream [\#84](https://github.com/yalelibrary/yul-dc-management/pull/84) ([maxkadel](https://github.com/maxkadel))
- Only process items that are relevant [\#83](https://github.com/yalelibrary/yul-dc-management/pull/83) ([maxkadel](https://github.com/maxkadel))

## [v1.5.2](https://github.com/yalelibrary/yul-dc-management/tree/v1.5.2) (2020-06-18)

[Full Changelog](https://github.com/yalelibrary/yul-dc-management/compare/v1.5.1...v1.5.2)

**Technical Enhancements:**

- Determine if an item from the activity stream is relevant [\#82](https://github.com/yalelibrary/yul-dc-management/pull/82) ([maxkadel](https://github.com/maxkadel))
- Resolve discrepancies in the v1.5.2 changelog [\#81](https://github.com/yalelibrary/yul-dc-management/pull/81) ([mark-dce](https://github.com/mark-dce))
- Add the changelog for release v1.5.2 [\#79](https://github.com/yalelibrary/yul-dc-management/pull/79) ([mark-dce](https://github.com/mark-dce))
- use same db configuration as blacklight [\#78](https://github.com/yalelibrary/yul-dc-management/pull/78) ([maxkadel](https://github.com/maxkadel))
- Fix url for Voyager records with barcode so full record is retrieved [\#77](https://github.com/yalelibrary/yul-dc-management/pull/77) ([maxkadel](https://github.com/maxkadel))
- Activity stream given date [\#75](https://github.com/yalelibrary/yul-dc-management/pull/75) ([maxkadel](https://github.com/maxkadel))

## [v1.5.1](https://github.com/yalelibrary/yul-dc-management/tree/v1.5.1) (2020-06-17)

[Full Changelog](https://github.com/yalelibrary/yul-dc-management/compare/v1.5.0...v1.5.1)

**Technical Enhancements:**

- Release prep for v1.5.1 [\#76](https://github.com/yalelibrary/yul-dc-management/pull/76) ([FCRodriguez7](https://github.com/FCRodriguez7))
- Rename methods to make process flow more clear [\#74](https://github.com/yalelibrary/yul-dc-management/pull/74) ([maxkadel](https://github.com/maxkadel))
- Move activity stream reader to lib [\#73](https://github.com/yalelibrary/yul-dc-management/pull/73) ([maxkadel](https://github.com/maxkadel))
- Use Yale postgres image [\#72](https://github.com/yalelibrary/yul-dc-management/pull/72) ([maxkadel](https://github.com/maxkadel))
- Configure hosts for production [\#71](https://github.com/yalelibrary/yul-dc-management/pull/71) ([JzGo](https://github.com/JzGo))
- yul-dc-base 1.0 version bump, no feature changes [\#70](https://github.com/yalelibrary/yul-dc-management/pull/70) ([orangewolf](https://github.com/orangewolf))
- CI Image Tag instead of Rebuild for Branches and Image Tag on Releases [\#69](https://github.com/yalelibrary/yul-dc-management/pull/69) ([orangewolf](https://github.com/orangewolf))
- Dockerfile Consolidation [\#67](https://github.com/yalelibrary/yul-dc-management/pull/67) ([orangewolf](https://github.com/orangewolf))

## [v1.5.0](https://github.com/yalelibrary/yul-dc-management/tree/v1.5.0) (2020-06-15)

[Full Changelog](https://github.com/yalelibrary/yul-dc-management/compare/v1.4.1...v1.5.0)

**Technical Enhancements:**

- generate changelog for 1.5.0 [\#68](https://github.com/yalelibrary/yul-dc-management/pull/68) ([martinlovell](https://github.com/martinlovell))
- Parse activity stream [\#66](https://github.com/yalelibrary/yul-dc-management/pull/66) ([maxkadel](https://github.com/maxkadel))
- Clean up fixtures and enhance parent object documentation [\#65](https://github.com/yalelibrary/yul-dc-management/pull/65) ([maxkadel](https://github.com/maxkadel))
- Separate vpn-only tests more cleanly [\#64](https://github.com/yalelibrary/yul-dc-management/pull/64) ([maxkadel](https://github.com/maxkadel))
- Normalize environment variables for tagged versions to match Camerata [\#63](https://github.com/yalelibrary/yul-dc-management/pull/63) ([maxkadel](https://github.com/maxkadel))
- Replace credentials.yml.enc with new file encoded with a known key [\#62](https://github.com/yalelibrary/yul-dc-management/pull/62) ([mark-dce](https://github.com/mark-dce))
- Service Status Display Table [\#57](https://github.com/yalelibrary/yul-dc-management/pull/57) ([dylansalay](https://github.com/dylansalay))

## [v1.4.1](https://github.com/yalelibrary/yul-dc-management/tree/v1.4.1) (2020-06-11)

[Full Changelog](https://github.com/yalelibrary/yul-dc-management/compare/v1.4.0...v1.4.1)

**Technical Enhancements:**

- Remove the prefix for Ladybird records, restore to previous state [\#61](https://github.com/yalelibrary/yul-dc-management/pull/61) ([maxkadel](https://github.com/maxkadel))
- Creates a crosswalk for parent objects based on their Ladybird records [\#60](https://github.com/yalelibrary/yul-dc-management/pull/60) ([maxkadel](https://github.com/maxkadel))
- Create a model for ParentObjects and seed the database with example oids [\#59](https://github.com/yalelibrary/yul-dc-management/pull/59) ([maxkadel](https://github.com/maxkadel))
- Ensure Bootstrap is added to asset pipeline correctly [\#55](https://github.com/yalelibrary/yul-dc-management/pull/55) ([maxkadel](https://github.com/maxkadel))

## [v1.4.0](https://github.com/yalelibrary/yul-dc-management/tree/v1.4.0) (2020-06-09)

[Full Changelog](https://github.com/yalelibrary/yul-dc-management/compare/v1.3.0...v1.4.0)

**Technical Enhancements:**

- Prep for v1.4.0 [\#56](https://github.com/yalelibrary/yul-dc-management/pull/56) ([FCRodriguez7](https://github.com/FCRodriguez7))
- Slight refactor, more specific name [\#54](https://github.com/yalelibrary/yul-dc-management/pull/54) ([maxkadel](https://github.com/maxkadel))
- Fixture indexing service takes metadata\_source [\#53](https://github.com/yalelibrary/yul-dc-management/pull/53) ([maxkadel](https://github.com/maxkadel))

## [v1.3.0](https://github.com/yalelibrary/yul-dc-management/tree/v1.3.0) (2020-06-08)

[Full Changelog](https://github.com/yalelibrary/yul-dc-management/compare/v1.2.0...v1.3.0)

**Technical Enhancements:**

- Prep for 1.3.0 release [\#52](https://github.com/yalelibrary/yul-dc-management/pull/52) ([bess](https://github.com/bess))
- Re-worked Solr task button [\#51](https://github.com/yalelibrary/yul-dc-management/pull/51) ([dylansalay](https://github.com/dylansalay))

## [v1.2.0](https://github.com/yalelibrary/yul-dc-management/tree/v1.2.0) (2020-06-08)

[Full Changelog](https://github.com/yalelibrary/yul-dc-management/compare/v1.1.4...v1.2.0)

**Technical Enhancements:**

- Allows us to refresh fixture data from the metadata cloud from ArchiveSpace, Voyager, or Ladybird [\#50](https://github.com/yalelibrary/yul-dc-management/pull/50) ([maxkadel](https://github.com/maxkadel))
- Bump websocket-extensions from 0.1.3 to 0.1.4 [\#47](https://github.com/yalelibrary/yul-dc-management/pull/47) ([maxkadel](https://github.com/maxkadel))
- Bump websocket-extensions from 0.1.4 to 0.1.5 [\#46](https://github.com/yalelibrary/yul-dc-management/pull/46) ([maxkadel](https://github.com/maxkadel))
- refactor solr connection [\#45](https://github.com/yalelibrary/yul-dc-management/pull/45) ([maxkadel](https://github.com/maxkadel))

## [v1.1.4](https://github.com/yalelibrary/yul-dc-management/tree/v1.1.4) (2020-06-05)

[Full Changelog](https://github.com/yalelibrary/yul-dc-management/compare/v1.1.3...v1.1.4)

**Technical Enhancements:**

- Update base docker image and Ruby for latest passenger [\#42](https://github.com/yalelibrary/yul-dc-management/pull/42) ([maxkadel](https://github.com/maxkadel))
- add additional author field [\#40](https://github.com/yalelibrary/yul-dc-management/pull/40) ([K8Sewell](https://github.com/K8Sewell))

## [v1.1.3](https://github.com/yalelibrary/yul-dc-management/tree/v1.1.3) (2020-06-04)

[Full Changelog](https://github.com/yalelibrary/yul-dc-management/compare/v1.1.2...v1.1.3)

**Technical Enhancements:**

- make sure gemfile.lock matches gemfile [\#39](https://github.com/yalelibrary/yul-dc-management/pull/39) ([maxkadel](https://github.com/maxkadel))

## [v1.1.2](https://github.com/yalelibrary/yul-dc-management/tree/v1.1.2) (2020-06-03)

[Full Changelog](https://github.com/yalelibrary/yul-dc-management/compare/v1.1.1...v1.1.2)

**Technical Enhancements:**

- Add basic management page so there's somewhere to land on deploy [\#37](https://github.com/yalelibrary/yul-dc-management/pull/37) ([maxkadel](https://github.com/maxkadel))

## [v1.1.1](https://github.com/yalelibrary/yul-dc-management/tree/v1.1.1) (2020-06-03)

[Full Changelog](https://github.com/yalelibrary/yul-dc-management/compare/v1.1.0...v1.1.1)

**Technical Enhancements:**

- add hosts for deployment [\#36](https://github.com/yalelibrary/yul-dc-management/pull/36) ([maxkadel](https://github.com/maxkadel))

## [v1.1.0](https://github.com/yalelibrary/yul-dc-management/tree/v1.1.0) (2020-06-02)

[Full Changelog](https://github.com/yalelibrary/yul-dc-management/compare/v1.0.2...v1.1.0)

**Technical Enhancements:**

- Use port 3001 for management app so it doesn't run into Blacklight ap… [\#35](https://github.com/yalelibrary/yul-dc-management/pull/35) ([maxkadel](https://github.com/maxkadel))
- README and update tag [\#34](https://github.com/yalelibrary/yul-dc-management/pull/34) ([maxkadel](https://github.com/maxkadel))

## [v1.0.2](https://github.com/yalelibrary/yul-dc-management/tree/v1.0.2) (2020-05-29)

[Full Changelog](https://github.com/yalelibrary/yul-dc-management/compare/v1.0.1...v1.0.2)

**Technical Enhancements:**

- Comment out vernacular until we get mappings [\#33](https://github.com/yalelibrary/yul-dc-management/pull/33) ([maxkadel](https://github.com/maxkadel))
- remove outdated rake task / service [\#32](https://github.com/yalelibrary/yul-dc-management/pull/32) ([maxkadel](https://github.com/maxkadel))
- Dependabot puma branch rename [\#31](https://github.com/yalelibrary/yul-dc-management/pull/31) ([maxkadel](https://github.com/maxkadel))

## [v1.0.1](https://github.com/yalelibrary/yul-dc-management/tree/v1.0.1) (2020-05-28)

[Full Changelog](https://github.com/yalelibrary/yul-dc-management/compare/v1.0.0...v1.0.1)

**Technical Enhancements:**

- update gems for security [\#29](https://github.com/yalelibrary/yul-dc-management/pull/29) ([maxkadel](https://github.com/maxkadel))
- use the same Solr mapping as Blacklight, same ordering [\#28](https://github.com/yalelibrary/yul-dc-management/pull/28) ([maxkadel](https://github.com/maxkadel))
- Exclude RuboCop MethodLength check for specs and specific files [\#27](https://github.com/yalelibrary/yul-dc-management/pull/27) ([mark-dce](https://github.com/mark-dce))
- Add private/restricted fixtures plus specs [\#26](https://github.com/yalelibrary/yul-dc-management/pull/26) ([dylansalay](https://github.com/dylansalay))

## [v1.0.0](https://github.com/yalelibrary/yul-dc-management/tree/v1.0.0) (2020-05-28)

[Full Changelog](https://github.com/yalelibrary/yul-dc-management/compare/a0afd98bfebf46bce17fd8c79dbffa5fd5209790...v1.0.0)

**Technical Enhancements:**

- attempt multiple tags [\#25](https://github.com/yalelibrary/yul-dc-management/pull/25) ([maxkadel](https://github.com/maxkadel))
- tag separate from image name [\#24](https://github.com/yalelibrary/yul-dc-management/pull/24) ([maxkadel](https://github.com/maxkadel))
- Update documentation & image info [\#23](https://github.com/yalelibrary/yul-dc-management/pull/23) ([maxkadel](https://github.com/maxkadel))
- CI Spike - circleci new attempt [\#22](https://github.com/yalelibrary/yul-dc-management/pull/22) ([maxkadel](https://github.com/maxkadel))
- 132 include additional fields when indexing fixture [\#18](https://github.com/yalelibrary/yul-dc-management/pull/18) ([maxkadel](https://github.com/maxkadel))
- Use .secrets for secrets. [\#16](https://github.com/yalelibrary/yul-dc-management/pull/16) ([maxkadel](https://github.com/maxkadel))
- Index fixure data to solr [\#15](https://github.com/yalelibrary/yul-dc-management/pull/15) ([martinlovell](https://github.com/martinlovell))
- First test workflow with docker [\#13](https://github.com/yalelibrary/yul-dc-management/pull/13) ([maxkadel](https://github.com/maxkadel))
- tyop, update documentation [\#12](https://github.com/yalelibrary/yul-dc-management/pull/12) ([maxkadel](https://github.com/maxkadel))
- Update readme, don't try to do dev outside container [\#11](https://github.com/yalelibrary/yul-dc-management/pull/11) ([maxkadel](https://github.com/maxkadel))
- Refresh data from mc [\#10](https://github.com/yalelibrary/yul-dc-management/pull/10) ([maxkadel](https://github.com/maxkadel))
- Metadata cloud rake [\#9](https://github.com/yalelibrary/yul-dc-management/pull/9) ([maxkadel](https://github.com/maxkadel))
- 134 rake task max [\#7](https://github.com/yalelibrary/yul-dc-management/pull/7) ([maxkadel](https://github.com/maxkadel))
- Set up Capybara & fixture files for testing & rsolr for solr connection [\#6](https://github.com/yalelibrary/yul-dc-management/pull/6) ([maxkadel](https://github.com/maxkadel))
- Rspec ci integration [\#4](https://github.com/yalelibrary/yul-dc-management/pull/4) ([maxkadel](https://github.com/maxkadel))
- Dockerize [\#2](https://github.com/yalelibrary/yul-dc-management/pull/2) ([maxkadel](https://github.com/maxkadel))
- remove artifacts from original creation [\#1](https://github.com/yalelibrary/yul-dc-management/pull/1) ([maxkadel](https://github.com/maxkadel))



\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)*
