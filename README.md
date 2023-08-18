# CdmOnboarding
R Package to support the onboarding process of new CDMs in the DARWIN EU Data Network

# Introduction
The DARWIN EU Coordination Center (CC) is resposonsible for building a data network to support EMA and stakeholders to answer regulatory research questions. To support the onboarding process of data sources, the CdmOnboarding R package will generate an onboarding document that is used by the CC and EMA to assess the quality and readiness of the CDM for participating in regulatory studies. 

The goal of the onboarding report is to provide insight into the completeness, transparency and quality of the performed Extraction Transform, and Load (ETL) process and the readiness of the data partner to be onboarded in the DARWIN EU® data network and participate in research studies.

An example of an onboarding report for a OMOP Synthea database can be found in [extras/CdmOnboarding-Synthea.docx](https://github.com/darwin-eu/CdmOnboarding/blob/master/extras).

Main repository on [DARWIN-EU/CdmOnboarding](https://github.com/darwin-eu/cdmonboarding).

# CdmOnboarding Checks
The CdmOnboarding R Package performs the following checks on top of the required [Data Quality Dashboard](https://github.com/OHDSI/DataQualityDashboard) step.

## Data table counts
 - Extraction of the CDM Source table
 - The number of records and persons per OMOP table
 - Achilles data density plots are inserted
 - For each domain, the distinct concepts per person
 - Observation Period length
 - Type concepts
 - Date ranges per domain

## Vocabulary counts
 - For each domain generate mapping completeness statistics with the number of unmapped codes and and unmapped records
 - For each domain extract the top 25 mapped and unmapped codes (counts are round up to the nearest 100)
 - Extract the number of records in all vocabulary tables
 - Count of concepts per vocabulary by standard, classification and non-standard
 - Mapping levels of drugs (Clinical Drug etc.)
 - Extracts the source_to_concept map

## Technical Infrastructure Checks
 - Extract the timings of the Achilles queries (Achilles results need to be present in the database)
 - Checks on the number of CPUs, memory available in R
 - Extract the versions of all installed R packages, checks if core [HADES](https://ohdsi.github.io/Hades/) packages are installed
 - Check if ATLAS is installed and WebAPI is running

## Data Quality Dashboard
 - Overview of number of passed/failed checks

## Drug Exposure Diagnostics
 - Summary for set of 11 ingredients:
 
   Concept ID | Drug name (ATLAS)
   -- | --
   1125315 | acetaminophen
   1139042 | acetylcysteine
   1703687 | acyclovir
   1119119 | adalimumab
   1154343 | albuterol
   528323 | hepatitis B surface antigen vaccine
   954688 | latanoprost
   968426 | mesalamine
   1550557 | prednisolone
   1140643 | sumatriptan
   40225722 | ulipristal

# Results Document Generation
Produces a word document in a DARWIN EU template that contains all the results and can be added as Annex 1 to the DARWIN-EU© Onboarding document.

# Technology
The CdmOnboarding package is an R package.

# System Requirements
Requires R. Some of the packages used by CdmOnboarding require Java.

# Installation

1. See the instructions [here](https://ohdsi.github.io/Hades/rSetup.html) for configuring your R environment, including Java.

2. Make sure dependencies from Github are installed:

```R
remotes::install_github("OHDSI/ROhdsiWebApi")
remotes::install_github("DARWIN-EU/CDMConnector")
remotes::install_github("DARWIN-EU/DrugExposureDiagnostics")
```

3. Use the following commands to download and install CdmOnboarding:

```R
remotes::install_github("DARWIN-EU/CdmOnboarding")
```

# Execution instructions
Performing the checks and exporting the CdmOnboarding results is done by executing the `cdmOnboarding(...)` function.
Ideally, run the CdmOnboarding package on the same machine you will perform actual analyses so we can test its performance.

Make sure that Achilles has run in the results schema you select when calling the `cdmOnboarding` function.
Ideally, all Achilles analyses are run before running CdmOnboarding. 
However, the following Achilles analyses are required for CdmOnboarding to create a complete report: 
`analysisIds = c(105, 110, 111, 117, 220, 420, 502, 620, 720, 820, 920, 1020, 1820, 2102, 2120, 203, 403, 603, 703, 803, 903, 920, 1003, 1020, 1320, 1411, 1803, 1820)`

For a template execution script, see [extras/CodeToRun.R](extras/CodeToRun.R).

# User documentation
PDF versions of the documentation are available:
* Package manual: [Link](https://github.com/darwin-eu/CdmOnboarding/blob/master/extras/CdmOnboarding.pdf)
* CodeToRun Example: [Link](https://github.com/darwin-eu/CdmOnboarding/blob/master/extras/CodeToRun.R)
* Report Example: [Link](https://github.com/darwin-eu/CdmOnboarding/blob/master/extras/CdmOnboarding-Synthea.docx)

# Support and contributing
This package is maintained by the Darwin EU Coordination Centre as part of its quality control procedures.
We use the <a href="https://github.com/darwin-eu/CdmOnboarding/issues">GitHub issue tracker</a> for all bugs/issues/enhancements/questions/feedback
Additions are welcome through pull requests. 
We suggest to first create an issue and discuss with the maintainer before implementing additional functionality.

# License
CdmOnboarding is licensed under Apache License 2.0

# Development
CdmOnboarding is being developed in R Studio.

# Acknowledgements
- The package is build upon the CdmInspection R package used and developed by The European Health Data & Evidence Network has received funding from the Innovative Medicines Initiative 2 Joint Undertaking (JU) under grant agreement No 806968. The JU receives support from the European Union’s Horizon 2020 research 
- We also like to thank the [contributors](https://github.com/OHDSI/Achilles/graphs/contributors) of the OHDSI community for their fantastic work
