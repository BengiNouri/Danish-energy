.PHONY: setup start stop up test

setup:
	bash danish_energy_project/quick_setup.sh

start:
	bash danish_energy_project/start_services.sh

stop:
	bash danish_energy_project/stop_services.sh

up: setup start

test:
	pip install -q pytest pandas psycopg2-binary flask flask-cors
	pytest -q
