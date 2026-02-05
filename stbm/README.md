# STBM Workflow Validation Documentation

## Overview
The STBM (Science-based Tourism Business Model) workflow is designed to ensure that the workflow follows best practices in tourism science and data handling. This document provides an overview of the validation process.

## Syntax Validation
Syntax validation is conducted to confirm that the code meets the required syntactical standards.
- **Validation Tool Used**: [Tool Name]
- **Results**: 
  - [Result Summary: e.g., Passed/Failed]
  - [Details of errors or warnings]

## Test Run Plan
The following plan outlines how the tests are executed to ensure the workflow functions as expected:
1. **Test Case 1**: [Description]
   - **Expected Outcome**: [Description]
   - **Methodology**: [Description of how the test is performed]
   
2. **Test Case 2**: [Description]
   - **Expected Outcome**: [Description]
   - **Methodology**: [Description of how the test is performed]

## Workflow Dependencies Diagram
![Workflow Dependencies Diagram](path_to_diagram)

## STMB ANALYSIS PIPELINE

                         ┌────────────────┐
                         │ 00_INSTALL.R   │
                         │ Install Packages
                         └────────┬────────┘
                                  │
                                  ▼
                         ┌────────────────┐
                         │ 01_SETUP.R     │
                         │ Create Folders │
                         └────────┬────────┘
                                  │
                    ┌─────────────┴──────────────┐
                    │                            │
                    ▼                            ▼
         ┌────────────────────┐      ┌─────────────────────┐
         │ MANUAL: Data       │      │ test_data_generator │
         │ Export from DBs    │      │ (for validation)    │
         │ - WoS export       │      │                     │
         │ - Scopus export    │      │ Creates 15 records  │
         │ - OpenAlex export  │      └──────────┬──────────┘
         └────────┬───────────┘                 │
                  │                             │
                  └──────────────┬──────────────┘
                                 │
                                 ▼
                    ┌────────────────────────┐
                    │  02_IMPORT.R           │
                    │ Import from 3 Sources  │
                    │ • convert2df(WoS)      │
                    │ • convert2df(Scopus)   │
                    │ • convert2df(OpenAlex) │
                    └──────────┬─────────────┘
                               │
                    Input: 01_Raw_Data/*.txt, *.csv
                    Output: wos_data, scopus_data, openalex_data
                    Save: 02_Processed_Data/all_imported_data.RData
                               │
                               ▼
                    ┌────────────────────────┐
                    │  03_MERGING.R          │
                    │ Merge Multi-source     │
                    │ • mergeDbSources()     │
                    │ • Auto-dedup           │
                    └──────────┬─────────────┘
                               │
                    Input: wos_data, scopus_data, openalex_data
                    Output: merged_data (combined dataset)
                    Save: 02_Processed_Data/merged_data.RData
                               │
                               ▼
                    ┌────────────────────────┐
                    │  04_DEDUP.R            │
                    │ Advanced Deduplication │
                    │ • Normalize titles     │
                    │ • Match by: TI+AU+PY   │
                    │ • Keep best record     │
                    └──────────┬─────────────┘
                               │
                    Input: merged_data.RData
                    Output: final_data_clean (deduped)
                    Save: 02_Processed_Data/final_dataset_clean.RData
                               │
                               ▼
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
        ▼                      ▼                      ▼
   ┌─────────┐         ┌──────────────┐      ┌─────────────┐
   │ 05_DESC │         │ 06_THEMATIC  │      │ 07_SEMANTIC │
   │ RIPTIVE │         │   (CORE)     │      │ (DISTINCTIVE│
   │   .R   │         │              │      │    )        │
   │         │         │ Co-word      │      │             │
   │ Stats  │         │ Analysis     │      │ Semantic    │
   └────┬────┘         │ Strategic    │      │ Fields      │
        │              │ Diagrams     │      │ Paradigms   │
        │              └──────┬───────┘      └──────┬──────┘
        │                     │                     │
        └─────────────────────┼─────────────────────┘
                              │
                              ▼
                    ┌────────────────────┐
                    │  08_NETWORK.R      │
                    │ Network Analysis   │
                    │ • Co-authorship    │
                    │ • Keyword networks │
                    │ • Visualizations   │
                    └────────┬───────────┘
                             │
                    Input: final_dataset_clean.RData
                    Output: PNG visualizations
                    Save: 04_Results/Figures/
                             │
                             ▼
                    ┌────────────────────┐
                    │  09_SYNTHESIS.R    │
                    │ Final Integration  │
                    │ • STBM matrix      │
                    │ • Comprehensive    │
                    │   report           │
                    └────────┬───────────┘
                             │
        Input: all previous results
        Output: Integrated STBM report
        Save: 04_Results/STBM_Comprehensive_Report.json
                             │
                             ▼
                    ┌────────────────────┐
                    │ FINAL OUTPUT       │
                    │ Complete STBM      │
                    │ Analysis Package   │
                    └────────────────────┘



## Package Compatibility Assessment
The STBM workflow relies on several packages. The assessment of their compatibility is as follows:
- **Package 1**: [Version] - Compatible with [List of versions or package details]
- **Package 2**: [Version] - Compatible with [List of versions or package details]

### Conclusion
This document serves as a comprehensive guide to the STBM workflow validation process, ensuring that all necessary steps are meticulously documented.
