# CdmOnboarding
R Package to support the onboarding process of new CDMs in the DARWIN EU Data Network

# Introduction
The DARWIN EU Coordination Center (CC) is resposonsible for building a data network to support EMA and stakeholders to answer regulatory research questions. To support the onboarding process of data sources, the CdmOnboarding R package will generate an onboarding document that is used by the CC and EMA to assess the quality and readiness of the CDM for participating in regulatory studies. 

The goal of the onboarding report is to provide insight into the completeness, transparency and quality of the performed Extraction Transform, and Load (ETL) process and the readiness of the data partner to be onboarded in the EHDEN and OHDSI data networks and participate in research studies. Additional procedural steps can be added before the data sources is added to the the data network. 

An example of an onboarding report for the Synpuf database can be found here: [link](https://github.com/darwin-eu/CdmOnboarding/blob/master/extras/SYNPUF-results.docx).

The CdmOnboarding R Package performs the following checks on top of the required [Data Quality Dashboard](https://github.com/OHDSI/DataQualityDashboard) step:

# Features

**Vocabulary Checks**  
1. For all custom mapped vocabularies extract the top 50 codes order by frequency from the source_to_concept map. The SME has to approve these top 50 codes. All custom mappings will be extracted as well as part of the package output. Note if the source_to_concept map is not used in the ETL process this information still has to be provided manually for the inspection.
2. For each domain generate statistics on the number of unmapped codes and and unmapped records.
3. For each domain extract the top 25 mapped and unmapped codes (counts are round up to the nearest 100).
3. Extract the vocabulary table.
4. Extract the number of rows in all vocabulary tables
4. Count of concepts per vocabulary by standard, classification and non-standard.
5. Mapping levels of drugs (Clinical Drug etc.)
6. Extracts the source_to_concept map

**Technical Infrastructure Checks**
1. Execution of short and longer running queries to test the performance of the system. This information is useful for the SME to provide further guidance on optimizing the infrastructure.
2. Extract the timings of the Achilles queries (Achilles results need to be present in the database)
3. Checks on the number of CPUs, memory available in R.
4. Extract the versions of all installed R packages, checks if core [HADES](https://ohdsi.github.io/Hades/) packages are installed.
5. Check if ATLAS is installed and WebAPI is running
6. Extraction of CDM_Source table

**Results Document Generation**

Produces a word document in a DARWIN EU template that contains all the results. This template needs to be completed by the data partner team.

Technology
==========
The CdmOnboarding package is an R package.

System Requirements
===================
Requires R. Some of the packages used by CdmOnboarding require Java.

Installation
=============

1. See the instructions [here](https://ohdsi.github.io/Hades/rSetup.html) for configuring your R environment, including Java.

2. Make sure RohdsiWebApi is installed

```r
  remotes::install_github("OHDSI/ROhdsiWebApi")
```

3. In R, use the following commands to download and install CdmOnboarding:

```r
  remotes::install_github("darwin-eu/CdmOnboarding")
```

User Documentation
==================

You should run the CdmOnboarding package ideally on the same machine you will perform actual anlyses so we can test its performance.

Make sure that Achilles has run in the results schema you select when calling the cdmOnboarding function.

PDF versions of the documentation are available:
* Package manual: [Link](https://github.com/darwin-eu/CdmOnboarding/blob/master/extras/CdmOnboarding.pdf)
* CodeToRun Example: [Link](https://github.com/darwin-eu/CdmOnboarding/blob/master/extras/CodeToRun.R)
* Report Example: [Link](https://github.com/darwin-eu/CdmOnboarding/blob/master/extras/SYNPUF-results.docx)

Support
=======
* We use the <a href="https://github.com/darwin-eu/CdmOnbording/issues">GitHub issue tracker</a> for all bugs/issues/enhancements/questions/feedback

Contributing
============
This package is maintained by the Darwin EU Coordination Centre as part of its quality control procedures. Additions are welcome through pull requests. We suggest to first create an issue and discuss with the maintainer before implementing additional functionality.

The roadmap of this tool can be found [here](https://github.com/darwin-eu/CdmOnboarding/projects/1)

License
=======
CdmOnboarding is licensed under Apache License 2.0

Development
===========
CdmOnboarding is being developed in R Studio.

### Development status

The Package is currently under development and should not should be used in production.

## Acknowledgements
- The package is build upon the CdmInspection R package used and developed by The European Health Data & Evidence Network has received funding from the Innovative Medicines Initiative 2 Joint Undertaking (JU) under grant agreement No 806968. The JU receives support from the European Union’s Horizon 2020 research 
- We also like to thank the [contributors](https://github.com/OHDSI/Achilles/graphs/contributors) of the OHDSI community for their fantastic work
