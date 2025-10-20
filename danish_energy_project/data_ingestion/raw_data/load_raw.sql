TRUNCATE raw.co2_emissions;
\copy raw.co2_emissions     FROM '/mnt/c/Users/sajad/OneDrive/Skole/DevRepos/Danish energy/danish_energy_project/data_ingestion/raw_data/co2_emissions_raw.csv'     CSV HEADER;

TRUNCATE raw.electricity_prices;
\copy raw.electricity_prices FROM '/mnt/c/Users/sajad/OneDrive/Skole/DevRepos/Danish energy/danish_energy_project/data_ingestion/raw_data/electricity_prices_raw.csv' CSV HEADER;

TRUNCATE raw.renewable_energy;
\copy raw.renewable_energy   FROM '/mnt/c/Users/sajad/OneDrive/Skole/DevRepos/Danish energy/danish_energy_project/data_ingestion/raw_data/renewable_energy_raw.csv'   CSV HEADER;
