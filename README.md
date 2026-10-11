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
6. DDL and Data Insertion
7. Queries
8. Presentation

## Database Setup and SQL Execution

### TA / Professor First-Time Setup

These instructions assume the evaluator is running the project for the first time and does **not** already have an `amazon_ecommerce` database.

1. Download or clone the project repository and make sure these four raw data files are available locally:

```text
state.txt
NST-EST2023-ALLDATA.csv
survey.csv
amazon-purchases.csv
```

#### Where to get `amazon-purchases.csv` and `survey.csv`

Download these two files from the project dataset on **Harvard Dataverse**:

**Dataset page:** [Open e-commerce 1.0: Five years of crowdsourced U.S. Amazon purchase histories with user demographics](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/YGLYDY)

1. Open the Harvard Dataverse dataset page above.
2. Near the top of the page, click **Access Dataset**.
3. Under **Download Options**, click **Original Format ZIP (301.5 MB)**.
4. Wait for the ZIP file to finish downloading.
5. Extract the ZIP file:
   - **macOS:** double-click the ZIP file.
   - **Windows:** right-click the ZIP file and choose **Extract All**.
6. In the extracted dataset folder, locate:
   - `amazon-purchases.csv`
   - `survey.csv`
7. Copy both files into the local data folder you will use for this project.
8. Keep the filenames exactly as shown above.

> Use **Original Format ZIP**, not the archival `.tab` download, because the SQL loading script expects the original CSV files.

#### Where to get the two U.S. Census files

The project uses two small reference files originally obtained from the **U.S. Census Bureau**. To make setup easier for the TA/professor and to ensure the exact same files used by our group are used during evaluation, download both files from the shared Google Drive folder below:

**Google Drive folder:** [U.S. Census reference files](https://drive.google.com/drive/folders/1u3l4_tRV8_aKfR68ggDC3VLjBKWbmA3o?usp=sharing)

The folder contains:

- `state.txt` — U.S. state and territory FIPS codes, abbreviations, and names.
- `NST-EST2023-ALLDATA.csv` — 2023 Vintage state population estimates file used to map states to Census regions and divisions.

Download **both files** and keep their filenames unchanged. Then place them in the same local data folder as `survey.csv` and `amazon-purchases.csv`. The exact folder location does not matter, because you will update the file paths in `02_dataloading_staging.sql` before running it.

For project evaluation, use the shared Google Drive folder above so the exact copies used by our group are used.

2. Open MySQL Workbench and connect to a MySQL server.

3. **Do not manually create the `amazon_ecommerce` database.** Run `04_schema_normalized.sql` first. That script creates the database automatically with `CREATE DATABASE IF NOT EXISTS amazon_ecommerce` and then creates the normalized tables.

4. Run the scripts in this exact order:

```text
04_schema_normalized.sql
01_schema_staging.sql
02_dataloading_staging.sql
03_datacleaning_staging.sql
05_dataloading_normalized.sql
06_analytical_queries.sql
```

5. Before running `02_dataloading_staging.sql`, configure the four `LOAD DATA INFILE` paths so they point to the directory MySQL allows for server-side imports. See the instructions below. If `LOAD DATA INFILE` is inconvenient on your system, especially on macOS, you can instead use the documented `LOAD DATA LOCAL INFILE` alternative.

6. Compare the row counts produced by Scripts 2, 3, and 5 with the validation tables below. If the counts match and there are no MySQL errors, the database loaded successfully.

### Starting Fresh for a Re-run

If `amazon_ecommerce` already exists from an earlier run and you want to rebuild everything completely from scratch, first run:

```sql
DROP DATABASE IF EXISTS amazon_ecommerce;
```

Then use the same execution order:

```text
04_schema_normalized.sql
01_schema_staging.sql
02_dataloading_staging.sql
03_datacleaning_staging.sql
05_dataloading_normalized.sql
06_analytical_queries.sql
```

The order begins with `04_schema_normalized.sql` because after a fresh start the database does not exist yet. `04_schema_normalized.sql` creates `amazon_ecommerce`, and `01_schema_staging.sql` then creates the staging tables inside it.

### Before Running `02_dataloading_staging.sql`

The submitted GitHub version of `02_dataloading_staging.sql` uses **`LOAD DATA INFILE`**. This is the primary setup method documented below.

#### Primary Method: `LOAD DATA INFILE`

`LOAD DATA INFILE` reads files from the MySQL server's permitted import directory. First, check which directory your MySQL installation allows:

```sql
SHOW VARIABLES LIKE 'secure_file_priv';
```

Copy these four source files into the directory returned by MySQL:

```text
state.txt
NST-EST2023-ALLDATA.csv
survey.csv
amazon-purchases.csv
```

Then update all four file paths in `02_dataloading_staging.sql` so they match that directory.

For example, a Windows MySQL installation may use a path similar to:

```sql
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/state.txt'
```

> **Windows note:** Forward slashes (`/`) are recommended in MySQL file paths. The exact `secure_file_priv` directory depends on your MySQL installation, so use the value returned by `SHOW VARIABLES LIKE 'secure_file_priv';`.

On macOS, the permitted server-side import directory varies depending on how MySQL was installed. Use the exact directory returned by `secure_file_priv`, copy the four files there, and update the paths in Script 2 accordingly.

#### Alternative Method: `LOAD DATA LOCAL INFILE`

If using MySQL's server-side import directory is inconvenient, you may instead load the files directly from a normal folder on your own computer. To do this, change each `LOAD DATA INFILE` statement in `02_dataloading_staging.sql` to `LOAD DATA LOCAL INFILE` and use the actual local path to each file.

**macOS example:**

```sql
LOAD DATA LOCAL INFILE '/Users/<username>/path/to/project/data/state.txt'
```

**Windows example:**

```sql
LOAD DATA LOCAL INFILE 'C:/Users/<username>/path/to/project/data/state.txt'
```

Apply the same change to all four source files:

```text
state.txt
NST-EST2023-ALLDATA.csv
survey.csv
amazon-purchases.csv
```

If local file loading is disabled, check the setting:

```sql
SHOW VARIABLES LIKE 'local_infile';
```

If the value is `OFF`, enable it:

```sql
SET GLOBAL local_infile = 1;
```

Then disconnect and reconnect MySQL Workbench before running `02_dataloading_staging.sql` again.

If MySQL Workbench still rejects `LOAD DATA LOCAL INFILE`, edit the connection in Workbench and enable the local-infile client option (for example, `OPT_LOCAL_INFILE=1` under the connection's advanced settings), then reconnect.

> **Why two methods?** `LOAD DATA INFILE` matches the submitted GitHub script and is therefore the primary method. `LOAD DATA LOCAL INFILE` is provided as an environment-specific alternative when server-side file placement or permissions make the primary method difficult.

### Expected Validation Results

After `02_dataloading_staging.sql`, the staging row counts should be:

| Table | Expected Rows |
| --- | ---: |
| `stg_census_codes` | 57 |
| `stg_census_areas` | 66 |
| `stg_survey` | 5,027 |
| `stg_purchase` | 1,850,717 |

After `03_datacleaning_staging.sql`:

| Result | Expected Rows |
| --- | ---: |
| `stg_survey_race` | 5,329 |
| `stg_survey_life_change` | 2,055 |
| `stg_census` | 52 |

After `05_dataloading_normalized.sql`, the final tables should contain:

| Table | Expected Rows |
| --- | ---: |
| `census_region` | 4 |
| `census_division` | 9 |
| `state` | 52 |
| `customer` | 5,027 |
| `customer_race` | 5,329 |
| `customer_life_change` | 2,055 |
| `product` | 939,072 |
| `purchase_line` | 1,849,726 |

If these counts match and MySQL Workbench shows no errors, proceed to `06_analytical_queries.sql`.

## GitHub Guide for Team Members

> **For project contributors only:** This section is for team members who are making changes to the repository and pushing them to GitHub. **TA, professor, and other evaluators can skip this entire GitHub Guide** unless they specifically plan to contribute changes to the repository. To review and run the project, follow the **TA / Professor First-Time Setup** under **Database Setup and SQL Execution** above.

### First-Time Contributor Setup

If you are a team member contributing to the repository, run these commands once:

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

**Original U.S. Census Bureau sources (optional):**

- `state.txt`: [ANSI Codes for States](https://www.census.gov/library/reference/code-lists/ansi/ansi-codes-for-states.html) — [direct ](https://www2.census.gov/geo/docs/reference/state.txt)[`state.txt`](https://www2.census.gov/geo/docs/reference/state.txt)[ file](https://www2.census.gov/geo/docs/reference/state.txt)
- `NST-EST2023-ALLDATA.csv`: [Vintage 2023 National and State Population Estimates](https://www.census.gov/newsroom/press-kits/2023/national-state-population-estimates.html) — [direct CSV file](https://www2.census.gov/programs-surveys/popest/datasets/2020-2023/state/totals/NST-EST2023-ALLDATA.csv)
