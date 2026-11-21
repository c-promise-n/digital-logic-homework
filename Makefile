VERILATOR ?= verilator
PYTHON    ?= python3

RTL := $(wildcard rtl/core/*.v) \
       $(wildcard rtl/soc/*.v) \
       $(wildcard rtl/top/*.v)

.PHONY: lint test clean

lint:
	$(VERILATOR) --lint-only -Wall -Wno-fatal -Irtl/core $(RTL)

test:
	$(PYTHON) scripts/run_regression.py

clean:
	rm -rf obj_dir
	rm -rf sim/build