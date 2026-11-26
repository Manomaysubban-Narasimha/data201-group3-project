# DATA 201 Group 3 Project

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
**Source:** [Harvard Dataverse](https://doi.org/10.7910/DVN/YGLYDY) (CC0 1.0 Universal Public Domain Dedication)  
**Paper:** [Berke, Calacci, et al., *Scientific Data* (2024)](https://doi.org/10.1038/s41597-024-03329-6)

| Table | Rows |
| --- | ---: |
| `amazon-purchases.csv` | 1,850,717 |
| `survey.csv` | 5,027 |

The tables are linked by `Survey ResponseID`.  
**Period:** 2018–2022

## Project Goal

Turn a real-world dataset into a normalized MySQL database, analyze it using basic and advanced SQL, demonstrate query performance with indexes, and present the results through interactive Streamlit dashboards.

## Local Setup

Follow Steps 1–8 in order. Run shell commands in **Terminal on macOS** or **PowerShell on Windows**; run SQL in a **MySQL Workbench query tab** unless otherwise stated. The commands use `Projects/data201-group3-project` inside your user folder.

1. [Install prerequisites](#1-install-prerequisites).
2. [Get the project](#2-get-the-project).
3. [Download the source data](#3-download-the-source-data).
4. [Connect to MySQL and configure imports](#4-connect-to-mysql-and-configure-imports).
5. [Create, load, and validate the database](#5-create-load-and-validate-the-database).
6. [Run the required index demonstration](#6-run-the-required-index-demonstration).
7. [Run analytical queries and create views](#7-run-analytical-queries-and-create-views).
8. [Configure and launch the dashboards](#8-configure-and-launch-the-dashboards).

**`SqlScripts/indexes.sql` is a mandatory project requirement. Do not skip it.**

## 1. Install Prerequisites

Skip installations you already have. Use a plain-text editor such as Visual Studio Code to edit configuration files; no editor-specific setup is required.

| Software | Version / download |
| --- | --- |
| MySQL Community Server | MySQL 8.4, or an existing MySQL 8.0 installation at version 8.0.18 or later. [Download](https://dev.mysql.com/downloads/mysql/). |
| MySQL Workbench | [Download the build for your operating system](https://dev.mysql.com/downloads/workbench/). Install separately from the server if needed. |
| Python | The commands below use Python 3.12. [Python 3.12 installer downloads](https://www.python.org/downloads/release/python-31210/), under **Files**. |
| Git | Required for cloning; optional for the ZIP route. [Download](https://git-scm.com/downloads). |

### 1.1 Python

1. Download the installer from the Python link above:
   - **macOS:** **macOS 64-bit universal2 installer**; run the `.pkg`.
   - **Windows:** **Windows installer (64-bit)** for Intel/AMD computers; run the `.exe`. Enable **Add python.exe to PATH** and keep the Python launcher enabled.
2. Complete installation and reopen Terminal/PowerShell.
3. Verify:

**macOS:**

```bash
python3.12 --version
```

**Windows PowerShell:**

```powershell
py -3.12 --version
```

Both should report `Python 3.12.x`. If Windows has no `py` launcher but `python --version` reports 3.12, use `python` instead of `py -3.12` in the commands below.

### 1.2 MySQL Server

On the [MySQL download page](https://dev.mysql.com/downloads/mysql/), select the **8.4** release series and your operating system. If shown an Oracle login page, select **No thanks, just start my download**.

**macOS:**

1. Check **Apple menu → About This Mac** to identify Apple silicon versus Intel. Download the matching **ARM 64-bit** or **x86 64-bit DMG** for your macOS version.
2. Open the DMG and run the `.pkg` installer.
3. Set and record the MySQL `root` password when prompted. Keep the default authentication method.
4. After installation, open **System Settings/System Preferences → MySQL** and click **Start MySQL Server** if stopped.

If you already use Homebrew MySQL, use that installation instead. Run `brew services list` to identify its formula, then start that formula; for example, `brew services start mysql@8.4` if the listed formula is `mysql@8.4`.

**Windows:**

1. Download and run the **MySQL 8.4 MSI Installer**.
2. At the end, launch **MySQL Configurator**.
3. Enable **TCP/IP**, retain port **3306** unless it is occupied, and record any different port.
4. Set and record the MySQL `root` password; keep the default authentication method.
5. Enable **Configure MySQL Server as a Windows Service**, note the service name, and apply the configuration using **Execute/Apply**.
6. Open **Services** (`Windows+R` → `services.msc`). Find the recorded service, such as `MySQL84`, and choose **Start** if it is not running.

Official instructions: [macOS](https://dev.mysql.com/doc/refman/8.4/en/macos-installation-pkg.html) · [Windows](https://dev.mysql.com/doc/refman/8.4/en/windows-installation.html).

### 1.3 Workbench and Git

1. Install **MySQL Workbench** from the link above:
   - **macOS:** open the DMG and drag Workbench to **Applications**.
   - **Windows:** run the MSI installer. If a prerequisite runtime is requested, install it using the prerequisite link on the Workbench download page, then retry.
2. If cloning, install/verify Git:
   - **macOS:** run `git --version`; if prompted, install Apple's command-line developer tools and rerun it.
   - **Windows:** run the [Git for Windows installer](https://git-scm.com/download/win), retain its command-line defaults, reopen PowerShell, and run `git --version`.
3. Confirm Git reports a version before using the clone route.

## 2. Get the Project

Choose **one** route. Open Terminal/PowerShell and run the matching commands.

### Option A: Clone

**macOS Terminal:**

```bash
mkdir -p "$HOME/Projects"
cd "$HOME/Projects"
git clone https://github.com/Manomaysubban-Narasimha/data201-group3-project.git data201-group3-project
cd data201-group3-project
mkdir -p data results
```

**Windows PowerShell:**

```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\Projects"
Set-Location "$env:USERPROFILE\Projects"
git clone https://github.com/Manomaysubban-Narasimha/data201-group3-project.git data201-group3-project
Set-Location data201-group3-project
New-Item -ItemType Directory -Force -Path data,results
```

If the destination already exists, use the existing clone or choose a separate location; do not clone into an unrelated nonempty folder. Private repository access requires an authorized GitHub account.

### Option B: Download ZIP

1. Open [the repository](https://github.com/Manomaysubban-Narasimha/data201-group3-project), then choose **Code → Download ZIP**.
2. Extract it: double-click on macOS, or **right-click → Extract All** on Windows.
3. Rename the extracted folder that directly contains `README.md`, `SqlScripts`, and `dashboard` to `data201-group3-project`.
4. Move that folder into a `Projects` folder in your user/home directory. Create `Projects` if needed.
5. In Terminal/PowerShell, enter the project folder and create the data/results folders:

**macOS:**

```bash
cd "$HOME/Projects/data201-group3-project"
mkdir -p data results
```

**Windows PowerShell:**

```powershell
Set-Location "$env:USERPROFILE\Projects\data201-group3-project"
New-Item -ItemType Directory -Force -Path data,results
```

Run later terminal commands from this **project root**. Check with `pwd` and `ls` on macOS, or `Get-Location` and `Get-ChildItem` in PowerShell. The listing should contain `README.md`, `SqlScripts`, and `dashboard`.

### Relevant files

| Path | Purpose |
| --- | --- |
| `SqlScripts/` | Database creation/loading, cleaning, indexing, and analyses. |
| `dashboard/app.py` | Combined dashboard entry point. |
| `dashboard/db.py` | Shared database access. |
| `dashboard/.env.example` | Template for local connection settings. |
| `dashboard/requirements.txt` | Pinned Python dependencies. |
| `dashboard/<member>/dashboard.py` | Individual dashboard sections. |
| `ER Diagram.drawio.xml` | Database diagram source. |
| `data/` | Downloaded raw files; excluded from Git. |
| `results/` | Local index-comparison output. |

## 3. Download the Source Data

### 3.1 Amazon purchases and survey

1. Open [the Harvard Dataverse dataset](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/YGLYDY).
2. Choose **Access Dataset → Original Format ZIP** and complete any download acknowledgment.
3. Extract the ZIP and locate `amazon-purchases.csv` and `survey.csv`.
4. Copy both into the project's `data/` folder. Use the original CSV files, not archival `.tab` files.

### 3.2 Census reference files

1. Open [the shared Census reference folder](https://drive.google.com/drive/folders/1u3l4_tRV8_aKfR68ggDC3VLjBKWbmA3o?usp=sharing).
2. Right-click `state.txt` and choose **Download**; repeat for `NST-EST2023-ALLDATA.csv`.
3. Extract any ZIP created by Drive and copy both files into `data/`.
4. Retain the exact filenames; remove browser-added suffixes such as `(1)`.

For evaluation, use these shared copies to match the team's source files. If access is blocked, request access from the team; original Census sources are linked at the end.

### 3.3 Verify all four files

Run `ls data` on macOS or `Get-ChildItem data` in PowerShell. Confirm these exact names:

```text
state.txt
NST-EST2023-ALLDATA.csv
survey.csv
amazon-purchases.csv
```

Do not resave the source files in Excel or change their encoding/line endings. The loading script uses `\r\n` for the Census population CSV and `\n` for the other files, independent of your operating system.

## 4. Connect to MySQL and Configure Imports

### 4.1 Create the Workbench connection

1. Open **MySQL Workbench** and click **+** beside **MySQL Connections**.
2. Enter:

| Field | Local setup value |
| --- | --- |
| Connection Name | `DATA201 Local` |
| Connection Method | `Standard (TCP/IP)` |
| Hostname | `127.0.0.1` |
| Port | `3306`, or your configured port. |
| Username | `root`, or your setup account. |
| Password | Your MySQL password; use **Store in Vault/Keychain** if desired. |
| Default Schema | Leave blank. |

3. Click **Test Connection**, then **OK** after success.
4. Double-click the saved connection.
5. Choose **File → New Query Tab**, paste the following SQL, then choose **Query → Execute (All or Selection)**:

```sql
SELECT VERSION() AS mysql_version, @@hostname AS server_host, @@port AS server_port;
SHOW DATABASES LIKE 'amazon_ecommerce';
SHOW VARIABLES LIKE 'secure_file_priv';
```

Inspect each result tab. The database check should return no rows on a fresh installation. If it already exists, use the existing completed setup or follow **Rebuild the Database** before reloading.

The setup account needs database/table/view/index creation privileges, data-loading/update privileges, and permission to run `ANALYZE TABLE`. The configured local `root` account normally has these.

### 4.2 Choose the import method

The committed `02_dataloading_staging.sql` uses `LOAD DATA INFILE` with Windows-specific paths. Update **all four paths**, even if you use Windows.

| `secure_file_priv` value | Import choice |
| --- | --- |
| Directory path | Method A: put all four files in that exact directory. |
| Empty string | Method A can use absolute paths readable by the MySQL server; Method B avoids server-side folder permissions. |
| `NULL` | Use Method B; server-side imports are disabled. |

Choose one method for all four files.

### Method A: `LOAD DATA INFILE`

1. Copy the four files from `data/` into the directory returned by MySQL:
   - **macOS:** use Finder **Go → Go to Folder**, paste the returned directory, then paste the files there.
   - **Windows:** paste the returned directory into File Explorer's address bar, then copy the files there.
2. In Workbench, choose **File → Open SQL Script** and open `SqlScripts/02_dataloading_staging.sql`.
3. Replace each quoted `LOAD DATA INFILE` path with its actual destination. Keep the matching filename and all following clauses unchanged.
4. Use forward slashes `/` in SQL paths, including on Windows, then choose **File → Save Script**.
5. Do not execute the file yet; create the database and staging tables first in Step 5.

For example, if MySQL returned the corresponding Windows import directory, the four replacement lines would be:

```sql
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.4/Uploads/state.txt'
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.4/Uploads/NST-EST2023-ALLDATA.csv'
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.4/Uploads/survey.csv'
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.4/Uploads/amazon-purchases.csv'
```

These are **individual replacement lines in their existing locations**, not a complete script. Keep each statement's existing `INTO TABLE`, parsing clauses, and final semicolon; do not add a semicolon immediately after a filename.

Use the actual directory returned on your machine. This method requires the MySQL `FILE` privilege and file-read permission for the server process. If copying or server permissions are inconvenient, use Method B.

### Method B: `LOAD DATA LOCAL INFILE`

#### B1. Get the local paths

In your **project-root terminal**, run the appropriate command to print the four absolute paths:

**macOS:**

```bash
python3.12 -c "from pathlib import Path; names=('state.txt','NST-EST2023-ALLDATA.csv','survey.csv','amazon-purchases.csv'); print('\n'.join((Path('data')/name).resolve().as_posix() for name in names))"
```

**Windows PowerShell:**

```powershell
py -3.12 -c "from pathlib import Path; names=('state.txt','NST-EST2023-ALLDATA.csv','survey.csv','amazon-purchases.csv'); print('\n'.join((Path('data')/name).resolve().as_posix() for name in names))"
```

#### B2. Edit the loading script

1. In Workbench, open `SqlScripts/02_dataloading_staging.sql` using **File → Open SQL Script**.
2. Change all four `LOAD DATA INFILE` lines to `LOAD DATA LOCAL INFILE`.
3. Replace each quoted path with its corresponding output from B1.
4. Keep all other clauses and the original statement-ending semicolons unchanged.
5. Save the script without executing it yet.

Examples of a single replacement line—use your actual path, not the example account name:

```sql
-- macOS
LOAD DATA LOCAL INFILE '/Users/alex/Projects/data201-group3-project/data/state.txt'

-- Windows
LOAD DATA LOCAL INFILE 'C:/Users/alex/Projects/data201-group3-project/data/state.txt'
```

Repeat for the other three files. For either import method, double any apostrophe inside a SQL path; for example, `O'Connor` becomes `O''Connor` inside the quoted string.

#### B3. Enable local loading on the server

In a new **Workbench query tab**, execute:

```sql
SHOW VARIABLES LIKE 'local_infile';
```

If it is `OFF`, execute the following using your administrative/setup account:

```sql
SET GLOBAL local_infile = 1;
SHOW VARIABLES LIKE 'local_infile';
```

Confirm `ON`. This setting may need to be enabled again after a server restart.

#### B4. Enable local loading in the client

1. Return to the Workbench home screen, right-click `DATA201 Local`, and choose **Edit Connection**.
2. Under **Advanced → Others**, add `OPT_LOCAL_INFILE=1` on its own line; retain existing unrelated options.
3. Save the settings, close the existing SQL connection tab, and reconnect using the saved connection.
4. If your Workbench version cannot save/accept the option or still rejects local loading, use **MySQL Command-Line Fallback** below.

Local loading must be enabled on **both** the client and server. See [MySQL local-loading settings](https://dev.mysql.com/doc/refman/8.0/en/load-data-local-security.html).

## 5. Create, Load, and Validate the Database

### 5.1 Execute the SQL files in order

Do not create the database manually. `04_schema_normalized.sql` creates it, so that file runs first despite the numeric filenames.

| Order | File inside `SqlScripts/` | Check before proceeding |
| ---: | --- | --- |
| 1 | `04_schema_normalized.sql` | Database and normalized tables created without errors. |
| 2 | `01_schema_staging.sql` | Staging tables created without errors. |
| 3 | `02_dataloading_staging.sql` | All four raw staging counts match below. |
| 4 | `03_datacleaning_staging.sql` | Cleaning/answer counts match below. |
| 5 | `05_dataloading_normalized.sql` | Final-table counts and paired validation values match below. |
| 6 | `indexes.sql` | Mandatory index comparison; follow Step 6. |
| 7 | `06_analytical_queries.sql` | Analytical queries and dashboard views; follow Step 7. |

For each of the first five files:

1. In the connected Workbench window, choose **File → Open SQL Script** and select the file from the project's `SqlScripts` folder.
2. Confirm that the loading file contains your saved path/import-method edits.
3. Clear any text selection and choose **Query → Execute (All or Selection)** to execute the entire file.
4. Wait for completion. Inspect **Action Output** for errors and the result tabs for the checks below before opening the next file.

Use **Query → Stop Script Execution On Errors** when available. Do not substitute the table import wizard or run another copy of a script while it is active. The purchase file contains about 1.85 million rows, so loading/cleaning/indexing can take several minutes depending on the machine.

The scripts are **not all safe to rerun unchanged**. They may append data, recreate staging tables, or create existing objects. After a partial load, inspect the first error and use **Rebuild the Database** if a clean restart is needed.

### 5.2 Validate the data

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

After `05_dataloading_normalized.sql` finishes, open a **new SQL query tab in Workbench** using **File → New Query Tab**. Copy the entire query below into that tab, then choose **Query → Execute (All or Selection)**. Compare the eight rows in the result grid with the final-table count table above:

```sql
USE amazon_ecommerce;

SELECT 'census_region' AS table_name, COUNT(*) AS row_count FROM census_region
UNION ALL
SELECT 'census_division', COUNT(*) FROM census_division
UNION ALL
SELECT 'state', COUNT(*) FROM state
UNION ALL
SELECT 'customer', COUNT(*) FROM customer
UNION ALL
SELECT 'customer_race', COUNT(*) FROM customer_race
UNION ALL
SELECT 'customer_life_change', COUNT(*) FROM customer_life_change
UNION ALL
SELECT 'product', COUNT(*) FROM product
UNION ALL
SELECT 'purchase_line', COUNT(*) FROM purchase_line;
```

Script 5 also checks that the staged purchase rows and spending match the loaded `purchase_line` data, and that the survey row count matches the customer count.

If any count differs, stop and inspect the **Action Output** panel for errors before continuing. If an import was only partly completed, follow **Rebuild the Database** rather than repeatedly loading the same files into existing tables. When the counts match, continue to Step 6.

## 6. Run the Required Index Demonstration

**This step is mandatory.** Complete it after the final-table checks and before `06_analytical_queries.sql`.

1. In Workbench, choose **File → Open SQL Script** and open `SqlScripts/indexes.sql`.
2. Clear any text selection, choose **Query → Execute (All or Selection)**, and wait for completion.
3. Check **Action Output** for errors. The script records plans/timings before index creation, creates `idx_pl_order_date_cover_spend`, then repeats the measurements.
4. Save the comparison:
   - Select the first `EXPLAIN` result tab, choose **Query → Export Results** (or the result grid's **Export** icon), select CSV, and save to `results/index_before_explain.csv`.
   - Export the first `EXPLAIN ANALYZE` result as `results/index_before_analyze.csv`.
   - Export the corresponding results after index creation as `results/index_after_explain.csv` and `results/index_after_analyze.csv`.
5. Open a new query tab and verify:

```sql
USE amazon_ecommerce;
SHOW INDEX FROM purchase_line
WHERE Key_name = 'idx_pl_order_date_cover_spend';
```

Expect four index rows for `(order_date, response_id, unit_price, quantity)` in that order. Keep the before/after outputs for the project's index comparison. Query totals should remain unchanged; plans and timings may differ. Timings depend on hardware and cache state.

If you intentionally repeat only the index experiment, first execute this in Workbench, then rerun **all** of `indexes.sql`:

```sql
USE amazon_ecommerce;
DROP INDEX idx_pl_order_date_cover_spend ON purchase_line;
```

Do not run `CREATE INDEX` repeatedly against an existing index, or leave the index dropped after the final demonstration.

## 7. Run Analytical Queries and Create Views

1. In Workbench, open `SqlScripts/06_analytical_queries.sql` using **File → Open SQL Script**.
2. Clear any selection and execute the entire file using **Query → Execute (All or Selection)**, including its `CREATE OR REPLACE VIEW` statements.
3. Wait for completion and inspect **Action Output** for errors.
4. In a new query tab, execute:

```sql
USE amazon_ecommerce;
SHOW FULL TABLES WHERE Table_type = 'VIEW';
SELECT * FROM vw_mourya_customer_month_activity LIMIT 5;
SELECT * FROM vw_kashif_home_region_shipping LIMIT 5;
```

Both named views must appear and both `SELECT` statements should return rows without errors. Dashboard dependencies include:

| Analysis | Required view |
| --- | --- |
| Mourya, Q21 | `vw_mourya_customer_month_activity` |
| Kashif, Q26 | `vw_kashif_home_region_shipping` |

The dashboard does not create these views automatically. Use the same local MySQL account for Workbench and the dashboard, or ensure the dashboard account can select from the project's tables and views.

## 8. Configure and Launch the Dashboards

### 8.1 Create the environment and install dependencies

Run these in Terminal/PowerShell. If you stored the project elsewhere, substitute its actual location in the first command.

**macOS:**

```bash
cd "$HOME/Projects/data201-group3-project"
python3.12 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r dashboard/requirements.txt
python -m pip check
```

**Windows PowerShell:**

```powershell
Set-Location "$env:USERPROFILE\Projects\data201-group3-project"
py -3.12 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -r dashboard/requirements.txt
python -m pip check
```

Run commands sequentially and resolve errors before continuing. `pip check` should report **No broken requirements found**.

If PowerShell blocks activation, use the environment directly after creating it:

```powershell
.\.venv\Scripts\python.exe -m pip install --upgrade pip
.\.venv\Scripts\python.exe -m pip install -r dashboard/requirements.txt
.\.venv\Scripts\python.exe -m pip check
```

For later Python commands, replace the leading `python` with `.\.venv\Scripts\python.exe` when using this alternative.

### 8.2 Create and edit `dashboard/.env`

1. From the project-root terminal, copy the template **only if `.env` does not already exist**:

**macOS:**

```bash
cp dashboard/.env.example dashboard/.env
```

**Windows PowerShell:**

```powershell
Copy-Item dashboard/.env.example dashboard/.env
```

2. Open `dashboard/.env` in your text editor and update it to match the working Workbench connection:

```dotenv
MYSQL_HOST=127.0.0.1
MYSQL_PORT=3306
MYSQL_USER=root
MYSQL_PASSWORD='your_actual_local_mysql_password'
MYSQL_DATABASE=amazon_ecommerce
```

3. Replace the example password; update the host, port, or username if your installation differs. Keep `MYSQL_DATABASE=amazon_ecommerce`.
4. Save as plain text with the exact filename `.env`, inside `dashboard/`, beside `app.py`. Do not save as `.env.txt`.

Use straight quotes around passwords containing spaces or `#`. If a password contains a single quote, use valid dotenv quoting, such as double quotes when the password contains no double quotes. Do not commit `.env`; it is excluded by `.gitignore`.

Existing `MYSQL_*` operating-system environment variables override `.env`. If the app uses unexpected settings, see **Troubleshooting**.

### 8.3 Test the connection

In the project-root terminal, with the environment activated, run this as one command:

```bash
python -c "from dotenv import load_dotenv; import os, pymysql; load_dotenv('dashboard/.env'); c=pymysql.connect(host=os.getenv('MYSQL_HOST','127.0.0.1'),port=int(os.getenv('MYSQL_PORT','3306')),user=os.getenv('MYSQL_USER','root'),password=os.getenv('MYSQL_PASSWORD',''),database=os.getenv('MYSQL_DATABASE','amazon_ecommerce')); print('Connected to', c.db); c.close()"
```

Expect a message beginning with `Connected to` and containing `amazon_ecommerce`.

If the error specifically requests `cryptography` for `sha256_password` or `caching_sha2_password`, install the extra for the project's pinned PyMySQL version, then retry:

```bash
python -m pip install "PyMySQL[rsa]==1.2.4"
```

See [PyMySQL authentication dependencies](https://pymysql.readthedocs.io/en/latest/user/installation.html).

### 8.4 Launch and verify

1. Keep MySQL Server running and launch from the project root:

```bash
python -m streamlit run dashboard/app.py
```

On Windows without activation:

```powershell
.\.venv\Scripts\python.exe -m streamlit run dashboard/app.py
```

2. Open the **Local URL** printed in the terminal, normally [http://localhost:8501](http://localhost:8501).
3. In the **Analysis section** sidebar, open every section and confirm its charts, controls, and result tables load:

| Section | Check |
| --- | --- |
| Manomay | Q18 annual spending and Q19 retention. |
| Mourya | Q20 monthly spending and Q21 repeat shopping. |
| Kashif | Q26 out-of-state shipping and Q28 multi-state shipping. |
| Waqas | All charts, controls, and result tables in the section. |

4. Keep the terminal open while using the app. Press **Ctrl+C** there to stop it.

Different analyses intentionally use different date ranges. The supplied shared and monthly-query helpers cache results for **15 minutes**. After database changes, stop and restart Streamlit to force fresh results. Restart after `.env` changes as well.

## Subsequent Launches

1. Start/check MySQL using the macOS MySQL preference pane or Windows **Services**, as in Step 1.2.
2. Open Terminal/PowerShell and run:

**macOS:**

```bash
cd "$HOME/Projects/data201-group3-project"
source .venv/bin/activate
python -m streamlit run dashboard/app.py
```

**Windows PowerShell:**

```powershell
Set-Location "$env:USERPROFILE\Projects\data201-group3-project"
.\.venv\Scripts\Activate.ps1
python -m streamlit run dashboard/app.py
```

If activation is blocked on Windows:

```powershell
Set-Location "$env:USERPROFILE\Projects\data201-group3-project"
.\.venv\Scripts\python.exe -m streamlit run dashboard/app.py
```

3. Open the Local URL. Press Ctrl+C in the terminal when finished.

Do not rerun SQL, recreate `.venv`, or overwrite `.env` for an ordinary launch. If `requirements.txt` changes after an update, rerun `python -m pip install -r dashboard/requirements.txt` inside the environment. Apply accompanying database updates as instructed by the team.

## Troubleshooting

| Problem | Action |
| --- | --- |
| Command cannot find project files | Check `pwd` / `Get-Location`, then return to the project root using the commands above. |
| Python 3.12 command unavailable | Recheck Step 1.1, reopen the terminal, and verify the installed interpreter. |
| PowerShell blocks `Activate.ps1` | Use `.\.venv\Scripts\python.exe` directly, as shown above. |
| Missing Python module | Activate `.venv` and rerun `python -m pip install -r dashboard/requirements.txt`, followed by `python -m pip check`. |
| Pinned package unavailable/incompatible | Confirm the selected Python version, upgrade pip as in Step 8.1, and retry. If it persists, send the full error to the team; dependency pins need a verified correction rather than guessed substitutions. |
| Connection refused / error 2003 | Start MySQL Server, test the Workbench connection, and match its host/port in `.env`. |
| Access denied / error 1045 | Verify the MySQL username/password in Workbench, correct `.env`, save, and restart Streamlit. |
| Authentication requests `cryptography` | Install the pinned `PyMySQL[rsa]` extra from Step 8.3. |
| Unknown database / error 1049 | Confirm setup ran on the same server/port used in `.env`; complete database setup if missing. |
| Missing table/view / error 1146 | Check the script order and selected database. For missing dashboard views, execute all of `06_analytical_queries.sql` and repeat Step 7's checks. |
| `secure_file_priv` / error 1290 | Use the returned permitted directory, or Method B if server-side imports are disabled. |
| Local loading rejected / errors 3948 or 2068 | Enable server and client settings, reconnect, or use the command-line fallback below. |
| Import file missing/unreadable | Check all four absolute paths and file permissions; use forward slashes in SQL paths. |
| Wrong counts / invalid or truncated data | Stop, inspect the first import error/warning, and confirm original filenames, encoding, and line endings. Rebuild if a partial load was committed. |
| Duplicate table/key/index | Avoid rerunning initialization/loading unchanged. Rebuild, or follow Step 6's targeted instructions when repeating only the index experiment. |
| Port 8501 occupied | Stop the other Streamlit instance or run `python -m streamlit run dashboard/app.py --server.port 8502` and open the printed URL. |
| Stale chart data | Stop Streamlit using Ctrl+C, rerun the launch command, and refresh the browser. |
| Missing dashboard section | Verify the complete repository includes `dashboard/<member>/dashboard.py`; obtain the current code and restart Streamlit. Preserve `.env` and data when replacing a ZIP download. |
| Slow queries | Verify the required index in Step 6 and let imports/indexing finish before querying. Inspect the page/terminal diagnostic and query plan before changing timeouts. |

### Conflicting environment variables

If `.env` changes are ignored, clear these variables **from the current terminal session**, then restart Streamlit so it reads `.env`:

**macOS:**

```bash
unset MYSQL_HOST MYSQL_PORT MYSQL_USER MYSQL_PASSWORD MYSQL_DATABASE
```

**Windows PowerShell:**

```powershell
Remove-Item Env:MYSQL_HOST,Env:MYSQL_PORT,Env:MYSQL_USER,Env:MYSQL_PASSWORD,Env:MYSQL_DATABASE -ErrorAction SilentlyContinue
```

## MySQL Command-Line Fallback

Use this if Workbench rejects local loading or you prefer command-line execution. Use the same edited SQL files and required order; do not reload completed steps merely because you switch clients.

1. Open Terminal/PowerShell in the project root.
2. Connect using the native-installation path below. Substitute the actual executable path, port, or user if different.

**macOS:**

```bash
/usr/local/mysql/bin/mysql --local-infile=1 -h 127.0.0.1 -P 3306 -u root -p
```

**Windows PowerShell:**

```powershell
& "C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe" --local-infile=1 -h 127.0.0.1 -P 3306 -u root -p
```

3. Enter the MySQL password when prompted. Confirm the `mysql>` prompt appears.
4. For Method B, confirm the server's `local_infile` is also `ON` using Step 4/B3's SQL.
5. From a **fresh database**, enter the following **one statement at a time** at `mysql>`, checking errors and the same validation points as above:

```sql
SOURCE SqlScripts/04_schema_normalized.sql;
SOURCE SqlScripts/01_schema_staging.sql;
SOURCE SqlScripts/02_dataloading_staging.sql;
SOURCE SqlScripts/03_datacleaning_staging.sql;
SOURCE SqlScripts/05_dataloading_normalized.sql;
tee results/index_comparison.txt
SOURCE SqlScripts/indexes.sql;
notee
SOURCE SqlScripts/06_analytical_queries.sql;
```

`tee`/`notee` record the required index comparison to `results/index_comparison.txt`; the `results` folder must exist. Do not run the index script a second time after this sequence.

If switching clients only for the rejected import, resume at `02_dataloading_staging.sql` only when the schema/staging tables already exist and the failed attempt left no partially loaded rows. Otherwise rebuild first.

6. When finished, run `exit;` to return to Terminal/PowerShell, then continue with dashboard setup.

## Rebuild the Database

**This deletes every table, view, index, and row in `amazon_ecommerce`.** Preserve anything needed before resetting.

1. Stop Streamlit using Ctrl+C.
2. Connect in Workbench and open **File → New Query Tab**.
3. Paste and execute:

```sql
DROP DATABASE IF EXISTS amazon_ecommerce;
```

4. Rerun all seven files in this order, repeating the validation/index/view checks:

```text
SqlScripts/04_schema_normalized.sql
SqlScripts/01_schema_staging.sql
SqlScripts/02_dataloading_staging.sql
SqlScripts/03_datacleaning_staging.sql
SqlScripts/05_dataloading_normalized.sql
SqlScripts/indexes.sql
SqlScripts/06_analytical_queries.sql
```

5. Relaunch the dashboards using **Subsequent Launches**. Reuse `.venv`, `.env`, and downloaded files if dependencies/settings are unchanged. Recheck local-loading settings after a server restart.

## GitHub Guide for Team Members

For contributors using a Git clone; evaluators can skip this section. Run commands from the project root in Terminal/PowerShell.

### First-time contributor configuration

```bash
git config pull.rebase true
git config rebase.autoStash true
```

If needed, configure your commit identity, replacing the quoted examples:

```bash
git config user.name "Your Name"
git config user.email "your-email@example.com"
```

### Contribution workflow

1. Get current changes:

```bash
git pull
```

2. Edit/save your files, then review:

```bash
git status
git diff
```

3. Stage only intended files; for a README-only edit:

```bash
git add README.md
```

4. Commit, obtain any intervening updates, then push when ready:

```bash
git commit -m "Clarify local setup instructions"
git pull
git push
```

Resolve any pull/rebase conflicts before pushing. Do not stage `.env` or raw data. ZIP downloads must be transferred intentionally into a Git clone before using this workflow.

## Original Census Sources

Use the shared Drive copies in Step 3 for evaluation. Original sources:

- `state.txt`: [ANSI Codes for States](https://www.census.gov/library/reference/code-lists/ansi/ansi-codes-for-states.html) — [direct source file](https://www2.census.gov/geo/docs/reference/state.txt).
- `NST-EST2023-ALLDATA.csv`: [Vintage 2023 National and State Population Estimates](https://www.census.gov/newsroom/press-kits/2023/national-state-population-estimates.html) — [direct CSV](https://www2.census.gov/programs-surveys/popest/datasets/2020-2023/state/totals/NST-EST2023-ALLDATA.csv).
