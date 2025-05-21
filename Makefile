.PHONY: findability

# Default path to the CSV file, can be overridden
FILE ?= data/sample_identifiers.csv
# Default output directory for reports
OUTPUT_DIR ?= reports
# Notebook files
NOTEBOOK_DIR = notebooks
SOURCE_NOTEBOOK = $(NOTEBOOK_DIR)/findability_demo.ipynb
OUTPUT_NOTEBOOK = $(NOTEBOOK_DIR)/output.ipynb
HTML_REPORT = $(OUTPUT_DIR)/latest.html
LOG_FILE = $(OUTPUT_DIR)/findability_demo.log

findability:
	@echo "Running Findability Analysis..."
	@echo "Input CSV: $(CURDIR)/$(FILE)"
	@echo "Output Directory: $(CURDIR)/$(OUTPUT_DIR)"
	# Ensure output directory exists
	@mkdir -p $(CURDIR)/$(OUTPUT_DIR)
	# Step 1: Execute notebook with papermill
	@papermill $(SOURCE_NOTEBOOK) $(OUTPUT_NOTEBOOK) -p csv_path $(CURDIR)/$(FILE) -p output_dir $(CURDIR)/$(OUTPUT_DIR)
	# Step 2: Convert output notebook to HTML
	@jupyter nbconvert --to html --Exporter.preprocessors=[] $(OUTPUT_NOTEBOOK) --output $(CURDIR)/$(HTML_REPORT)
	@echo "Findability analysis complete."
	@echo "HTML report generated at: $(CURDIR)/$(HTML_REPORT)"
	@echo "CSV results saved in: $(CURDIR)/$(OUTPUT_DIR)/findability_results.csv"
	# Step 3: Echo a concise table (id, score) to stdout
	# This part relies on the notebook's last cell printing the summary.
	# We can't directly capture and re-print it here without more complex scripting.
	# The notebook itself prints this to stdout during papermill execution.
	@echo "Summary table (id, score) was printed during notebook execution."

clean:
	@echo "Cleaning up generated files..."
	@rm -f $(OUTPUT_NOTEBOOK)
	@rm -f $(HTML_REPORT)
	@rm -f $(CURDIR)/$(OUTPUT_DIR)/findability_results.csv
	@rm -f $(LOG_FILE)
	@echo "Cleanup complete."

help:
	@echo "Available targets:"
	@echo "  findability    - Run the full findability analysis pipeline."
	@echo "                 - Override input CSV: make findability FILE=path/to/your.csv"
	@echo "                 - Override output dir: make findability OUTPUT_DIR=path/to/your/reports"
	@echo "  clean          - Remove generated report files and logs."
	@echo "  help           - Show this help message."

# Set default goal
.DEFAULT_GOAL := help 