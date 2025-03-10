# CdmOnboarding 3.3.4

 * Fix DED issue when using older verison
 * Fix getCdmConnection
 * Use camel case versions of CDMConnector functions

# CdmOnboarding 3.3.3

 * Fix execution of CohortBenchmark and CdmConnectorBenchmark

# CdmOnboarding 3.3.2

 * Fix generating applied indexes section when no indexes have been applied
 * Set sample to NULL in DeD execution (fix for https://github.com/darwin-eu-dev/DrugExposureDiagnostics/issues/268)

# CdmOnboarding 3.3.1

* Fix display of DQD overview

# CdmOnboarding 3.3.0

* Add Episode mapping coverage and top25 mapped/unmapped
* Add Cohort Benchmark and CdmConnector benchmark
* Add DED concept class mapping
* Update reporting of applied indexes
* Update package list

# CdmOnboarding 3.2.1

* Fix bug in generation on SQL Server.
* Soft validate CdmConnection when executing DED

# CdmOnboarding 3.2.0

* Export DrugExposureDiagnostics results to csv
* Make document generation robust for missing data by @MaximMoinat
* Improve generation of observation periods table by @MaximMoinat
* Refactoring for CRAN submission by @MaximMoinat
* Support DED v1.0.6 by @MaximMoinat

# CdmOnboarding 3.1.0

* Update Word template
* Update version compatibility

# CdmOnboarding 3.0.1

* Move formatting for date range by type concept to R by @MaximMoinat
* Total runtime Achilles results in NA if missing values #133
* Specificy write schema for cdm_from_con #135

# CdmOnboarding 3.0.0

* compatibility with new release DrugExposureDiagnostics  by @ginberg
* use tableExists to check Achilles results by @MaximMoinat
* Fix captions by @MaximMoinat
* Setup tests by @MaximMoinat
* Add day of week and day of month figures by @MaximMoinat
* Add observation period statistics by @MaximMoinat
* add visit detail to completeness and mapped codes by @Anne0507
* Mortality statistics by @Anne0507
* Add distribution of day, month and year of birth fields by @MaximMoinat
* Darwin packages by @MaximMoinat
* Add date range by type concept id by @MaximMoinat
* add visit length analysis by @MaximMoinat
* Add mapped/unmapped observation and measurement values by @MaximMoinat
* Applied Indexes by @Anne0507
* Remove support for separate vocab database schema by @SofiaMp
* Release candidate v3.0.0 by @MaximMoinat

## New Contributors
* @ginberg made their first contribution
* @Anne0507 made their first contribution
* @SofiaMp made their first contribution

# CdmOnboarding v2.2.0


* Update mapped/unmapped observation units by @MaximMoinat
* Summarise achilles query performance #60 
* Refactor DrugExposureDiagnostics check, new parameter `runDedChecks`, removed parameter `dedIngredientIds`. `getDedIngredients()` to retrieve list of drug ingredients used in DedCheck. #71
* Exponential y-axis on data density figures #77 
* DBMS version #81 
* Type concepts marked standard yes/no #80
* Other minor improvements #75, #76, #72 #78 


# CdmOnboarding v2.1.0

* Refactor field aliasing by @MaximMoinat
* Consider 2B+ concepts unmapped by @MaximMoinat
* Drug exposure diagnostics by @MaximMoinat
* Counting non-distinct source values for mapping coverage by @MaximMoinat
* Several refactorings


# CdmOnboarding v2.0.0
## New Features
### New Data tables and DQD checks
- Number of 'Active persons' in last 6mo #22
- Observation period lengths #27 
- Overview of type concepts #32
- First and last start date per table #25 
- DataQualityDashboard overview from DQD json #26

### Improvements
- Each check marked with generation source (CDM, Achilles, System) #51 
- Colourblind friendly plots #37 
- Percentage records per concept mapped/unmapped #23
- Achilles execution details #35
- Move vocabulary counts to end of document

### Optimizations
Optional toggle to speed-up queries using system tables, an optional person count and replace UNIONs by temporary tables #19, #48 #18

## Fixes
- Corrupt Word document #21
- Data table count for OMOP v5.4 #31
- Remove document generation date#20

# CdmOnboarding v1.0.1
## Fixes
 - Mapped/unmapped units query #13
 - Printing query execution time #12 

# CdmOnboarding v1.0.0
## New features:
- Include onboarding document in the zip bundle #6
- Support for CDM v5.4 by scanning episode/episode_event #8
- Sorting on count to drug level and vocabulary count tables #9 
- Add visit occurrence to concepts per person #7

## Fixes:
- Make `databaseId` a required argument #5
- Several control flow and logging improvements
- Code cleanup
