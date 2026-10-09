<!-- # DATA 201 Group 3 Project -->

San Jose State University  
Fall 2026

## Team Members
- Kashif Ahmed Mohammed
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


## Project Goal
Turn real-world raw dataset into a normalized MySQL database that we can query (basic + advanced SQL) to extract valuable insights.

## Steps
1. Dataset Selection 
2. Understanding dataset 
3. ER/EER diagram 
4. Normalization to 3NF 
5. Documentation 
5. DDL and Data Insertion
6. Queries
7. Presentation

## GitHub Guide

### First-Time Setup

Run these commands once:

```bash
git config --global pull.rebase true
git config --global rebase.autoStash true
```

### Everyday Workflow

1. Get the latest changes:

```bash
git pull
```

2. Make your changes.

3. Check what changed:

```bash
git status
```

4. Stage only the files you changed:

```bash
git add file1 file2
```

5. Commit your changes:

```bash
git commit -m "Describe what you changed"
```

6. Get any new teammate changes:

```bash
git pull
```

7. Push your changes:

```bash
git push
```

> **Tip:** Avoid `git add .` when possible. Add only the files you intentionally changed.
