Below is a code-free, bullet-level “construction manual” for your **Findability demonstration slice**.  It is organised by work-stream so you—or a collaborator—can tick items off chronologically.  A one-page deliverable matrix follows at the end.

---

## Executive outline

This mini-project creates a public GitHub repo that (1) ingests a CSV containing DOIs, repository URLs and accession numbers, (2) resolves each identifier to a canonical landing page using Crossref, re3data or a URL template, (3) issues a lightweight `aiohttp` GET request and awards a binary Findability score, (4) saves results to disk, renders an HTML report with **nbconvert**, and (5) re-runs on every push via GitHub Actions—all under the MIT licence.  Each task below is phrased as an action item with clear exit criteria.

---

## 1  Repository boot-strapping

* **Create repo** → initialise with `README.md`, `LICENSE` (MIT), and `.gitignore`.
* **Add scaffolding folders**:

  * `src/`  (helper functions)
  * `notebooks/`  (single parameterised notebook)
  * `data/`  (`sample_identifiers.csv`)
  * `reports/`  (auto-generated HTML)
  * `.github/workflows/`  (CI file)
* **Write README first**—state goals, quick-start command, and link to the NIH S-Index Phase-1 brief, following Readme-Driven Development best practice. ([Papermill][1])

---

## 2  Environment & dependencies

* Declare runtime in `pyproject.toml` or `requirements.txt`: **aiohttp**, **pandas**, **nbconvert**, **papermill**, **python-dotenv** (for future secrets injection).
* Pin Python ≥3.9; GitHub Actions will matrix-test 3.9 and 3.11 to demonstrate portability. ([GitHub Docs][2])
* Document local setup: `python -m venv .venv && pip install -r requirements.txt`.

---

## 3  Sample identifier list

* Place `sample_identifiers.csv` in `data/` with three columns: `id`, `identifier`, `type`.
* Populate with your approved five-item starter set:

  * Zenodo URL `https://zenodo.org/record/7673768` (Findable in NIH list). ([Zenodo][3])
  * OpenNeuro URL `https://openneuro.org/datasets/ds004470/about`. ([OpenNeuro][4])
  * DOI `10.5061/dryad.4j0zpc8p9` (Dryad).
  * DOI `10.6084/m9.figshare.6025748` (Figshare).
  * Accession `NC_045512` (GenBank). ([NCBI][5])

---

## 4  Notebook architecture (`notebooks/findability_demo.ipynb`)

* **Parameters cell**: path to CSV (default `data/sample_identifiers.csv`).
* **Step 1 – Type detection**: simple regex or string prefixes to label as DOI/URL/Accession.
* **Step 2 – Resolution**

  * DOI → query Crossref REST (`https://api.crossref.org/works/{doi}`) to retrieve `URL` field. ([www.crossref.org][6])
  * URL → use as-is.
  * Accession → format into template `https://www.ncbi.nlm.nih.gov/nuccore/{acc}` for GenBank. ([NCBI][5])
  * If the accession is from another database later, look up re3data to fetch repository landing-page prefix. ([re3data][7])
* **Step 3 – Landing-page probe**

  * Open one **aiohttp.ClientSession()** for all requests to minimise TCP overhead. ([AIOHTTP][8])
  * For each URL, issue GET with `allow_redirects=True`, 10-second timeout, 2-retry wrapper.
  * Capture status code, final URL after redirects, response time-ms.
* **Step 4 – Scoring**: add column `findable = 1 if 200 ≤ status < 300 else 0`.
* **Step 5 – Output**

  * Write tidy CSV to `reports/findability_results.csv`.
  * Generate nice HTML via `jupyter nbconvert --execute --to html` and save into `reports/`. ([nbconvert.readthedocs.io][9])

---

## 5  Command-line interface

* Provide a short Bash or Make target `make findability` to run:

  1. `papermill notebooks/findability_demo.ipynb notebooks/output.ipynb -p csv_path $FILE` (executes with parameters). ([Papermill][1])
  2. `jupyter nbconvert --to html notebooks/output.ipynb --output reports/latest.html`.
* Echo a concise table (id, score) to stdout so headless CI logs remain readable.

---

## 6  Continuous Integration (GitHub Actions)

* **Workflow trigger**: `on: [push, pull_request]`.
* **Jobs**

  * **setup** – checkout, set up Python 3.x.
  * **install** – cache dependencies, run `pip install -r requirements.txt`.
  * **test-notebook** – call `make findability`. Fail the job on non-zero exit.
  * **upload artefact** – archive `reports/latest.html`.
* Add Shields-io badge for workflow status in README.
* Runtime expectations: < 30 s with `aiohttp`, well under free-minutes quota for public repos. ([GitHub Docs][10])

---

## 7  Quality assurance

* **Unit tests** in `tests/` for:

  * Identifier type detection.
  * DOI → URL resolver (mock Crossref).
  * Successful 2xx classification.
* **Notebook smoke test** part of CI; failure blocks merge.
* **Manual test checklist**: run `make findability` locally with and without VPN, to catch geo-specific blocks.

---

## 8  Documentation & community

* Expand README with sections: Background, Quick-start, How It Works, Identifier Templates, Contributing, Roadmap.
* Add `docs/architecture.md`: ASCII diagram of data flow.
* Open first Issue: “Add more NIH-approved repositories to template lookup”.
* Licence is MIT—include full text plus one-line notice in each source file header. ([tldrlegal.com][11])

---

## 9  Future-proof hooks (optional but noted)

* Keep a placeholder `.env.example` for future API keys (e.g., private repositories).
* Note that if pages rely on heavy JavaScript, upgrade probe layer from `aiohttp` to **Playwright**; footprint trade-off is documented for later decision. ([AIOHTTP][12])

---

## 10  Deliverable matrix

| Phase  | Artefact                    | Location       | “Done” test             |
| ------ | --------------------------- | -------------- | ----------------------- |
| Setup  | Repo skeleton & MIT licence | GitHub main    | Repo clones cleanly     |
| Data   | `sample_identifiers.csv`    | `data/`        | 5 rows present          |
| Logic  | `findability_demo.ipynb`    | `notebooks/`   | Runs end-to-end locally |
| CLI    | `make findability`          | root           | Command exits 0         |
| CI     | `.github/workflows/ci.yml`  | workflows/     | Green badge             |
| Report | `reports/latest.html`       | default branch | Renders in browser      |

---

### You’re ready to build

Follow the work-streams in order; each bullet has an unambiguous exit criterion, so progress is measurable.  Once everything turns the GitHub Actions badge green, you’ll have a polished, reproducible demonstration slice that satisfies Phase 1’s “proof-of-concept” requirement. 🎯

[1]: https://papermill.readthedocs.io/en/latest/usage-execute.html?utm_source=chatgpt.com "Execute - papermill 2.4.0 documentation"
[2]: https://docs.github.com/billing/managing-billing-for-github-actions/about-billing-for-github-actions?utm_source=chatgpt.com "About billing for GitHub Actions"
[3]: https://help.zenodo.org/docs/deposit/about-records/?utm_source=chatgpt.com "About records | Zenodo"
[4]: https://openneuro.org/?utm_source=chatgpt.com "OpenNeuro"
[5]: https://www.ncbi.nlm.nih.gov/nuccore/1798174254?utm_source=chatgpt.com "1798174254 - Nucleotide Result - NCBI"
[6]: https://www.crossref.org/documentation/retrieve-metadata/rest-api/?utm_source=chatgpt.com "REST API - Crossref"
[7]: https://www.re3data.org/api/doc/?utm_source=chatgpt.com "API Documentation - Re3data.org"
[8]: https://docs.aiohttp.org/?utm_source=chatgpt.com "Welcome to AIOHTTP — aiohttp 3.11.18 documentation"
[9]: https://nbconvert.readthedocs.io/en/latest/usage.html?utm_source=chatgpt.com "Using as a command line tool — nbconvert 7.16.6 documentation"
[10]: https://docs.github.com/en/actions/administering-github-actions/usage-limits-billing-and-administration?utm_source=chatgpt.com "Usage limits, billing, and administration - GitHub Actions"
[11]: https://www.tldrlegal.com/license/mit-license?utm_source=chatgpt.com "MIT License (Expat) Explained in Plain English - TLDRLegal"
[12]: https://docs.aiohttp.org/en/stable/client_quickstart.html?utm_source=chatgpt.com "Client Quickstart — aiohttp 3.11.18 documentation"
