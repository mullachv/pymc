# Makefile for Sphinx documentation and essential dev/CI scripts
#

# You can set these variables from the command line.
SPHINXBUILD   = sphinx-build
SOURCEDIR     = docs/source
BUILDDIR      = docs/build
SCRIPTS       = scripts
CONTAINER_NAME = pymc
PORT          = 8888

rtd: export READTHEDOCS=true

# User-friendly check for sphinx-build
ifeq ($(shell which $(SPHINXBUILD) >/dev/null 2>&1; echo $$?), 1)
$(error The '$(SPHINXBUILD)' command was not found. Make sure you have Sphinx installed, then set the SPHINXBUILD environment variable to point to the full path of the '$(SPHINXBUILD)' executable. Alternatively you can add the directory with the executable to your PATH. If you don't have Sphinx installed, grab it from http://sphinx-doc.org/)
endif

.PHONY: help clean html rtd view
.PHONY: mypy check-tests pip-deps test
.PHONY: docker-build docker-bash docker-jupyter

help:
	@echo "Please use \`make <target>' where <target> is one of"
	@echo ""
	@echo "Documentation:"
	@echo "  html         to make standalone HTML files"
	@echo "  rtd          to build the website without any cache"
	@echo "  clean        to clean cache and intermediate files"
	@echo "  view         to open the built html files"
	@echo ""
	@echo "Essential scripts (CI / pre-commit):"
	@echo "  mypy         run type checker (scripts/run_mypy.py)"
	@echo "  check-tests  check all tests are covered in workflow (scripts/check_all_tests_are_covered.py)"
	@echo "  pip-deps     generate/check requirements from conda (scripts/generate_pip_deps_from_conda.py)"
	@echo "  test         run pytest with coverage (scripts/test.sh); use TEST=path to run a subset, e.g. make test TEST=tests/test_util.py)"
	@echo ""
	@echo "Docker:"
	@echo "  docker-build    build the pymc image (required before docker-bash/docker-jupyter)"
	@echo "  docker-bash     run a bash shell in the pymc container"
	@echo "  docker-jupyter  run Jupyter in the pymc container (port $(PORT))"

clean:
	rm -rf $(BUILDDIR)/*
	rm -rf $(SOURCEDIR)/api/generated
	rm -rf $(SOURCEDIR)/api/**/generated
	rm -rf $(SOURCEDIR)/api/**/classmethods
	rm -rf docs/jupyter_execute

html:
	$(SPHINXBUILD) $(SOURCEDIR) $(BUILDDIR) -b html
	@echo
	@echo "Build finished. The HTML pages are in $(BUILDDIR)."

rtd: clean
	$(SPHINXBUILD) $(SOURCEDIR) $(BUILDDIR) -b html -E
	@echo
	@echo "Build finished. The HTML pages are in $(BUILDDIR)."

view:
	python -m webbrowser $(BUILDDIR)/index.html

# --- Essential scripts (CI / pre-commit) ---

mypy:
	python $(SCRIPTS)/run_mypy.py --verbose

check-tests:
	python $(SCRIPTS)/check_all_tests_are_covered.py

pip-deps:
	python $(SCRIPTS)/generate_pip_deps_from_conda.py conda-envs/environment-dev.yml

test:
	bash $(SCRIPTS)/test.sh $(TEST)

# --- Docker ---
# Override: make docker-jupyter CONTAINER_NAME=myimage PORT=9999

docker-build:
	CONTAINER_NAME=$(CONTAINER_NAME) SRC_DIR=$(CURDIR) bash $(SCRIPTS)/docker_container.sh build

docker-bash:
	CONTAINER_NAME=$(CONTAINER_NAME) SRC_DIR=$(CURDIR) bash $(SCRIPTS)/docker_container.sh bash

docker-jupyter:
	CONTAINER_NAME=$(CONTAINER_NAME) PORT=$(PORT) SRC_DIR=$(CURDIR) bash $(SCRIPTS)/docker_container.sh jupyter
