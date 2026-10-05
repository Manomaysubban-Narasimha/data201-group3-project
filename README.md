<!-- # DATA 201 Group 3 Project -->

San Jose State University  
Fall 2026

## Team Members
- Kashif Ahmed
- Waqas Ahmed
- Manomay Subban Narasimha
- Mourya Arnepalli

## Dataset Source

**Group 3**

**Dataset:** Open e-commerce 1.0: Five years of crowdsourced U.S. Amazon purchase histories with user demographics  
**Source:** [Harvard Dataverse](https://doi.org/10.7910/DVN/YGLYDY) (CC0 public domain license)  
**Paper:** [Berke, Calacci, et al., *Scientific Data* (2024)](https://doi.org/10.1038/s41597-024-03329-6)

| Table | Rows |
| --- | ---: |
| `amazon-purchases.csv` | 1,850,717 |
| `survey.csv` | 5,027 |

The tables are linked by `Survey ResponseID`.  
**Period:** 2018–2022

## Mid-Project Presentation Link
https://docs.google.com/presentation/d/1xdit__9CUikImNtztxCeRcT1ZUJxbLQDneEiSmSHSyM/edit?slide=id.h37ed3da09027b5ac_0_125#slide=id.h37ed3da09027b5ac_0_125 

## Project Goal
TBD

## Steps
1. Dataset Selection - Done
2. Understanding dataset - Done
3. ER/EER diagram - Done - https://drive.google.com/file/d/19VbYl2XTWtWEDNvoZBGTug6klbM_-23z/view?usp=sharing Kindly access using this link and make required changes and replace in assets/ folder with latest version
4. Normalization to 3NF - Done
5. Documentation - In Progress
5. DDL and Data Insertion
6. Queries
7. Presentation

## Github Guide
## First time
git config --global pull.rebase true
git config --global rebase.autoStash true

## Every commit
git pull                      # 1. get the latest
# ... do your work ...
git status                    # 2. see what changed
git add file1 file2           # 3. add only your files (avoid "git add .")
git commit -m "What I changed"   # 4. commit
git pull                      # 5. get any new teammate changes
git push                      # 6. share your work

