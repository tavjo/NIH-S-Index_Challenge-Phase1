# NIH S-Index - Phase 1: Findability Demonstration Slice

This project is a minimal demonstration slice focusing on **Phase 1: Findability (F) score calculation** for the NIH S-Index initiative. It aims to provide a working proof-of-concept for determining if a dataset is findable based on its identifier.

## Goals

The primary objectives of this demonstration are to:

1.  Ingest a list of dataset identifiers (DOIs, repository URLs, accession numbers) from a CSV file.
2.  Resolve each identifier to its canonical landing page URL using appropriate methods (e.g., Crossref API for DOIs, predefined templates for accessions).
3.  Perform a lightweight HTTP GET request (using `aiohttp`) to check the reachability of the landing page.
4.  Award a binary Findability score (1 if reachable, 0 otherwise).
5.  Save the results, including the Findability score, to a CSV file.
6.  Render an HTML report summarizing the findability checks (using `nbconvert` from a Jupyter Notebook).
7.  Demonstrate automated re-runs and testing on every code push via GitHub Actions.

This project follows Readme-Driven Development. For more details on the plan for this demonstration slice, please see the [Phase 1 Demo Slice Plan](phase1_demo_slice_plan.md).

## Quick Start

To run the findability analysis:

1.  **Set up the environment:**
    ```bash
    uv venv  # Create a virtual environment with uv
    source .venv/bin/activate  # On Windows use `.venv\Scripts\activate`
    uv pip sync  # Install dependencies from pyproject.toml and uv.lock
    ```
    *(Note: Dependencies are managed in `pyproject.toml`)*

2.  **Run the analysis:**
    ```bash
    make findability
    ```
    *(Note: A `Makefile` with the `findability` target will need to be created as per the project plan)*

This command will:
*   Execute the parameterized Jupyter Notebook (`notebooks/findability_demo.ipynb`) using `papermill`.
*   Generate an output notebook (`notebooks/output.ipynb`).
*   Convert the output notebook to an HTML report (`reports/latest.html`).
*   Save the detailed results to `reports/findability_results.csv`.
*   Print a concise summary table to the console.

## NIH S-Index Phase-1 Brief

The detailed plan, architecture, and methodology for this Phase 1 Findability demonstration are outlined in the [Phase 1 Demo Slice Plan (phase1_demo_slice_plan.md)](phase1_demo_slice_plan.md) document within this repository. 

## How It Works (Current Implementation)

The findability check involves the following key steps:

1.  **Input:** A CSV file (`data/sample_identifiers.csv` by default) is read, containing columns for `Repo`, `Asset` (the identifier), and `AssetType` (e.g., URL, DOI, Accession). If `AssetType` is not provided, it's detected based on the identifier's format.
2.  **Identifier Resolution:**
    *   **URLs:** If the asset type is a URL, it is used directly as the landing page.
    *   **DOIs:** For DOIs, the system first attempts to resolve them by querying the Crossref API (`https://api.crossref.org/works/{doi}`). If Crossref returns a 404 error, or if it returns a 200 OK response but does not include a `URL` in its message, a fallback mechanism is triggered. This fallback attempts to resolve the DOI using the general DOI resolver (`https://doi.org/{doi}`).
    *   **Accession Numbers:** Accession numbers are resolved using a predefined dictionary of URL templates. This dictionary maps common accession prefixes (e.g., for NCBI services like GenBank, GEO, SRA; EMBL-EBI services like ENA, ArrayExpress, PRIDE; and ENCODE) to their corresponding landing page URL structures.
3.  **Landing Page Probe:** Each resolved URL is then probed using an asynchronous HTTP GET request via `aiohttp`. The request follows redirects, has a 10-second timeout.
4.  **Scoring:** A `findable` score is assigned: `1` if the HTTP status code is between 200 and 299 (inclusive), and `0` otherwise.
5.  **Output:**
    *   The results, including the resolved URL, HTTP status, response time, and findability score, are compiled into a pandas DataFrame.
    *   This DataFrame is saved as a CSV file to `reports/findability_results.csv`.
    *   A summary table of `Asset` and `findable` score is printed to standard output.
    *   The executed notebook (with all outputs) is also prepared for conversion to an HTML report. 