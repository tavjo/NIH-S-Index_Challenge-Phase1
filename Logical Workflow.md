**Quick-look summary** 

Starting from a unique identifier (DOI, accession, or direct URL), the pipeline moves—**sequentially and without branching**—through *Findable → Accessible → Knowledge-base Loading → Interoperable → Reusable → Researcher Portfolio Weighting*.  
Automation elements:

* **Playwright** headless browsers for resilient link checks with exponential back-off [Playwright](https://playwright.dev/python/docs/library?utm_source=chatgpt.com).  
* Repository-specific handlers (Zenodo, Figshare, Dataverse, Dryad) for manifest pulls via documented REST endpoints [Zenodo Developers](https://developers.zenodo.org/?utm_source=chatgpt.com)[GitHub](https://github.com/zenodo/developers.zenodo.org/blob/master/source/includes/overview/_introduction.md?utm_source=chatgpt.com).  
* Rapid ontology look-ups through OLS-v4 and nightly‐mirrored OBO Foundry dumps [EMBL-EBI](https://www.ebi.ac.uk/ols4/help?utm_source=chatgpt.com)[OBO Foundry](https://obofoundry.org/?utm_source=chatgpt.com).  
* **Cosine-similarity tests** on embedded metadata strings to award points against FAIR criteria (Sentence-Transformer embeddings).  
* Empty-file detection via a configurable MIME→min-bytes map; proprietary-format detection via a weekly refreshed “vendor-locked” table seeded from FAIRsharing and Wikipedia lists [Wikipedia](https://en.wikipedia.org/wiki/Proprietary_file_format?utm_source=chatgpt.com).  
* Researcher-level S-index \= weighted average of dataset scores; weights are produced by a *piece-wise sigmoid* band whose slope-parameter *k* is tuned through a validation-curve (rank-stability) analysis [ScienceDirect](https://www.sciencedirect.com/topics/computer-science/sigmoid-function?utm_source=chatgpt.com).

The remainder of this document expands every phase in turn.

**Phase 1: Findable (F) score starts \= 0 / 1**

**1 Narrative (detailed)**

1. **Identifier normalisation & URL synthesis.**  
   * If the user supplies a **DOI**, construct a canonical URL via the DOI proxy (`https://doi.org/<doi>`), or resolve it with the Crossref REST endpoint for metadata confirmation ([www.crossref.org](https://www.crossref.org/documentation/retrieve-metadata/rest-api/?utm_source=chatgpt.com), [CrossRef](https://dx.crossref.org/help.html?utm_source=chatgpt.com)).  
   * If the input looks like a **repository-specific accession** (regex match against a pre-compiled table of common patterns, e.g. `EGA\d+`, `SRP\d+`, `GEO\d+`), plug the ID into a *repo→URL* mapping. The mapping is auto-generated offline from re3data records that list URL templates for ≈4 000 data resources ([re3data](https://www.re3data.org/repository/r3d100010413?utm_source=chatgpt.com)).  
   * For identifiers the map cannot handle, the system asks the user to specify the repository or provide a full link; failing that, a browsing agent scrapes the repo’s developer docs to discover a pattern and caches it for future runs.  
2. **Broken-link probe.** A headless Playwright Chromium instance navigates to the constructed URL; three attempts with exponential back-off (1 s, 4 s, 9 s) guard against transient outages. *page.goto()* returns an HTTP response object, whose `.status` is checked (≥ 200 ≤ 299\) ([Stack Overflow](https://stackoverflow.com/questions/69596102/how-to-check-response-in-playwright?utm_source=chatgpt.com), [LambdaTest](https://www.lambdatest.com/learning-hub/playwright-headless?utm_source=chatgpt.com)).  
3. **Outcome.** HTTP 200 (or any 2xx) ⇒ **\+1 F**; otherwise F remains 0 and a “Not findable” report is returned.

**1 Score table**

| Step | Decision point | Points |
| ----- | ----- | ----- |
| F-1 | Landing page reachable (HTTP 2xx) | **\+1 F** |

---

**Phase 2 Accessible (A)  score starts \= 0 / 3**

**2 Narrative (detailed)**

* **Manifest retrieval.**  
  * For **well-known repositories** the handler calls their lightest “record” endpoint (e.g., `GET /api/records/{id}` on Zenodo) to list files with size & MIME type ([developers.zenodo.org](https://developers.zenodo.org/?utm_source=chatgpt.com)).  
  * For **unknown repos** the handler queries re3data’s API to get the `apiUrl` or `metadataIdentifier` template, then fetches the manifest ([re3data](https://www.re3data.org/repository/r3d100010413?utm_source=chatgpt.com)).  
* **Fast availability check (Essential).** Fire asynchronous `HEAD` or `Range: bytes=0-0` requests with *aiohttp*; a 200/206 proves retrievability and a SHA-256 of the first KB is stored for integrity verification ([re3data](https://www.re3data.org/repository/r3d100010413?utm_source=chatgpt.com)).  
* **Empty-file guard (Important).** Compare each file’s size to a **MIME→min-bytes JSON map** (e.g., XLSX ≥ 4096 B, CSV ≥ 100 B, FASTQ ≥ 512 B). The map will be filled empirically during implementation but is referenced here as part of the design.  
* **Proprietary-format audit (Useful).** Look up each extension in a **vendor-locked table** seeded weekly from FAIRsharing format records ([FAIRsharing](https://fairsharing.org/FAIRsharing.mg1mdc?utm_source=chatgpt.com)) and supplemented by the Wikipedia list of proprietary formats ([Wikipedia](https://en.wikipedia.org/wiki/Proprietary_file_format?utm_source=chatgpt.com)). Unknown extensions trigger a quick web probe; results are cached.

**2 Score table**

| Tier | Decision point | Points |
| ----- | ----- | ----- |
| Essential | All manifest URLs return 200/206 to `HEAD`/`Range` | **\+2 A** |
| Important | Every file size ≥ MIME-specific minimum | **\+0.5 A** |
| Useful | No proprietary/closed formats detected | **\+0.5 A** |

---

**Phases 3 & 4 Knowledge-base Loading & Progressive Metadata Lists**

*(no direct score; prepares input for I & R)*

**3 Narrative (detailed)**

1. **Data-type inference.** An LLM prompt classifies the dataset modality (omics, imaging, clinical, etc.) by embedding the repository abstract and top-level keywords.  
2. **Repository documentation cache.**  
   * **Known repos:** Link to pre-harvested OpenAPI or Swagger spec.  
   * **Unknown repos:** Spider “API”, “developer” and “docs” pages; save raw HTML for downstream prompt engineering.  
3. **Ontology harvest.** Nightly cron pulls .obo/.owl from OBO Foundry mirrors and indexes them in an OLS-compatible service [OBO Foundry](https://obofoundry.org/?utm_source=chatgpt.com)[EMBL-EBI](https://www.ebi.ac.uk/ols4/help?utm_source=chatgpt.com).  
4. **Policy embeddings.** NIH Data-Management policy paragraphs and NIH Common Data Elements (CDE) registry terms are embedded and stored [sharing.nih.gov](https://sharing.nih.gov/data-management-and-sharing-policy/data-management?utm_source=chatgpt.com)[cde.nlm.nih.gov](https://cde.nlm.nih.gov/?utm_source=chatgpt.com).

| Step | Product | Implementation detail |
| ----- | ----- | ----- |
| 3-1 | **Data-type tag** | LLM prompt embeds repo abstract & keywords; top cosine match to a small “dataset-type” ontology (omics, imaging, clinical, …) via Sentence-Transformers ([SentenceTransformers](https://www.sbert.net/examples/applications/cross-encoder/README.html?utm_source=chatgpt.com)). |
| 3-2 | **Repo docs cache** | Known repos: link to pre-harvested OpenAPI spec; unknown: spider “/api”, “developer” pages. |
| 3-3 | **Ontology harvest** | Quarterly cron pulls `.owl`/`.obo` from OBO Foundry mirrors ([OBO Foundry](https://obofoundry.org/ontology/ro.html?utm_source=chatgpt.com)) and indexes them in OLS-v4 for fast CURIE search ([EMBL-EBI](https://www.ebi.ac.uk/ols4/?utm_source=chatgpt.com)). |
| 3-4 | **Policy embeddings** | NIH Data-Management policy & NIH CDE registry terms embedded and version-tracked ([NIH Data Sharing](https://sharing.nih.gov/data-management-and-sharing-policy?utm_source=chatgpt.com)). |

**Metadata-list construction steps**

| List ID | Source recipe |
| ----- | ----- |
| **1** | Raw *required \+ optional* repo fields, filtered for the inferred data type. |
| **2** | List 1 ∪ NIH DMS-recommended fields for that modality. |
| **3** | For every label in List 2, retrieve CURIEs & exact synonyms from the top-three ontologies (ranked by OLS fuzzy-match score). |
| **4** | Dedup(List 2 ∪ List 3\); keep the single synonym per concept with the highest \[frequency × ontology-depth\] utility weight. |
| **5** | List 2 ∪ ISA-Tab Investigation/Study/Assay core fields ∪ NIH CDE terms to emphasize provenance ([DCC](https://www.dcc.ac.uk/resources/metadata-standards/isa-tab?utm_source=chatgpt.com)). |

 

---

**Phase 5 Interoperable (I)  score starts \= 0 / 2**

**5 Narrative (common steps)**

* **Metadata-file discovery.**  
  * Quick LLM pass over filenames ranks likely metadata files (e.g., “dictionary”, “codebook”, “metadata”, “README”).  
  * Fallback: open up to the first 20 KB of `.txt`, `.docx`, `.pdf`, `.xlsx`, `.csv` in that priority order.

* **Dictionary processing.** If a glossary is found, its terms are stripped, normalised, and embedded for later similarity checks.

**Option A (*\+1 \+0.5 \+0.25 \+0.25 \= 2 pts*)**

| Tier | Decision point | Points |
| ----- | ----- | ----- |
| Essential | Cosine sim(**List 1 ↔ List 3**) ≥ 0.80 | **\+1 I** |
| Important | At least one data-dictionary / metadata table file detected | **\+0.5 I** |
| Useful \#1 | Cosine sim(dictionary ↔ List 3\) ≥ 0.70 | **\+0.25 I** |
| Useful \#2 | For repo fields with CV drop-downs, submitter chose a controlled term (not “other”) | **\+0.25 I** |

**Option B (*\+1 \+0.75 \+0.25 \= 2 pts*)**

| Tier | Decision point | Points |
| ----- | ----- | ----- |
| Essential | Cosine sim(**List 1 ↔ List 3**) ≥ 0.80 | **\+1 I** |
| Important | Data-dictionary / glossary detected | **\+0.75 I** |
| Useful | Cosine sim(dictionary ↔ List 3\) ≥ 0.70 | **\+0.25 I** |

---

**Phase 6 Reusable (R)  score starts \= 0 / 4**

**6 Narrative (detailed)**

* **Richness test.** Embed consolidated metadata and compare to **List 4**; cosine ≥ 0.85 ⇒ \+2 R.  
* **Provenance test.** Compare same embeddings to **List 5**; cosine ≥ 0.85 ⇒ \+2 R.  
* SPDX licence & PROV-O workflow triples are detected and recorded in the gap report (no score impact yet).

**6 Score table**

| Tier | Decision point | Points |
| ----- | ----- | ----- |
| Essential | Cosine sim(metadata ↔ List 4\) ≥ 0.85 | **\+2 R** |
| Essential | Cosine sim(metadata ↔ List 5\) ≥ 0.85 | **\+2 R** |

---

**Phase 7 Per-dataset Score & Researcher Portfolio Weighting**

1. **Dataset S-index** \= F 1 \+ A 3 \+ I 2 \+ R 4 \= **10**.  
2. **Piece-wise sigmoid weighting.** Age percentiles → σ(p;k); *k* chosen by stability curve analysis so that rank-ordering of researchers stabilises at k ≈  6 – 8\. No passive decay; weights rescale only when a new dataset arrives.

---

**Implementation-phase placeholders (documented here for feasibility)**

* **MIME→min-bytes map** will be assembled empirically and stored as JSON; thresholds in this plan are illustrative.  
* **Proprietary-format table** will start with FAIRsharing format metadata \+ Wikipedia “proprietary” list and be extended automatically by a weekly crawler.  
* **Similarity thresholds (0.80, 0.70, 0.85)** are deliberately conservative and can be tuned once a validation corpus is available.

---

**Key external references**

* Crossref DOI REST API ([www.crossref.org](https://www.crossref.org/documentation/retrieve-metadata/rest-api/?utm_source=chatgpt.com), [CrossRef](https://dx.crossref.org/help.html?utm_source=chatgpt.com))  
* re3data metadata registry & API ([re3data](https://www.re3data.org/repository/r3d100010413?utm_source=chatgpt.com))  
* Zenodo records endpoint ([developers.zenodo.org](https://developers.zenodo.org/?utm_source=chatgpt.com))  
* Playwright headless navigation & status access ([Stack Overflow](https://stackoverflow.com/questions/69596102/how-to-check-response-in-playwright?utm_source=chatgpt.com), [LambdaTest](https://www.lambdatest.com/learning-hub/playwright-headless?utm_source=chatgpt.com))  
* OBO Foundry ontology downloads ([OBO Foundry](https://obofoundry.org/ontology/ro.html?utm_source=chatgpt.com))  
* OLS-v4 portal & REST API ([EMBL-EBI](https://www.ebi.ac.uk/ols4/?utm_source=chatgpt.com))  
* NIH Data-Management & Sharing Policy portal ([NIH Data Sharing](https://sharing.nih.gov/data-management-and-sharing-policy?utm_source=chatgpt.com))  
* FAIRsharing format entries ([FAIRsharing](https://fairsharing.org/FAIRsharing.mg1mdc?utm_source=chatgpt.com))  
* Wikipedia list of proprietary formats for bootstrap ([Wikipedia](https://en.wikipedia.org/wiki/Proprietary_file_format?utm_source=chatgpt.com))  
* Sentence-Transformers similarity docs ([SentenceTransformers](https://www.sbert.net/examples/applications/cross-encoder/README.html?utm_source=chatgpt.com))

