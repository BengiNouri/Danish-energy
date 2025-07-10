"""
Azure Data Factory Pipeline Configuration
========================================

This module contains configuration and templates for Azure Data Factory pipelines
to orchestrate the Danish energy data ingestion process.

Author: Manus AI
Date: 2025-06-15
"""

import json
from datetime import datetime, timedelta

class AzureDataFactoryConfig:
    """
    Configuration class for Azure Data Factory pipelines
    """
    
    def __init__(self, subscription_id: str, resource_group: str, factory_name: str):
        """
        Initialize ADF configuration
        
        Args:
            subscription_id: Azure subscription ID
            resource_group: Resource group name
            factory_name: Data factory name
        """
        self.subscription_id = subscription_id
        self.resource_group = resource_group
        self.factory_name = factory_name
        
    def create_linked_service_config(self):
        """
        Create linked service configuration for external APIs
        """
        linked_service = {
            "name": "EnergiDataServiceAPI",
            "type": "Microsoft.DataFactory/factories/linkedservices",
            "properties": {
                "type": "RestService",
                "typeProperties": {
                    "url": "https://api.energidataservice.dk",
                    "enableServerCertificateValidation": True,
                    "authenticationType": "Anonymous"
                }
            }
        }
        return linked_service
    
    def create_dataset_config(self, dataset_name: str, endpoint: str):
        """
        Create dataset configuration for API endpoints
        
        Args:
            dataset_name: Name of the dataset
            endpoint: API endpoint path
        """
        dataset = {
            "name": f"DS_{dataset_name}",
            "type": "Microsoft.DataFactory/factories/datasets",
            "properties": {
                "type": "RestResource",
                "linkedServiceName": {
                    "referenceName": "EnergiDataServiceAPI",
                    "type": "LinkedServiceReference"
                },
                "typeProperties": {
                    "relativeUrl": endpoint
                }
            }
        }
        return dataset
    
    def create_data_lake_dataset(self, container: str, folder_path: str, file_name: str):
        """
        Create Azure Data Lake dataset configuration
        
        Args:
            container: Storage container name
            folder_path: Folder path in the container
            file_name: File name pattern
        """
        dataset = {
            "name": f"DS_DataLake_{file_name.replace('.', '_')}",
            "type": "Microsoft.DataFactory/factories/datasets",
            "properties": {
                "type": "DelimitedText",
                "linkedServiceName": {
                    "referenceName": "AzureDataLakeStorage",
                    "type": "LinkedServiceReference"
                },
                "typeProperties": {
                    "location": {
                        "type": "AzureBlobFSLocation",
                        "fileName": file_name,
                        "folderPath": folder_path,
                        "fileSystem": container
                    },
                    "columnDelimiter": ",",
                    "escapeChar": "\\\\",
                    "firstRowAsHeader": True,
                    "quoteChar": "\""
                }
            }
        }
        return dataset
    
    def create_copy_activity(self, source_dataset: str, sink_dataset: str, activity_name: str):
        """
        Create copy activity configuration
        
        Args:
            source_dataset: Source dataset name
            sink_dataset: Sink dataset name
            activity_name: Activity name
        """
        activity = {
            "name": activity_name,
            "type": "Copy",
            "typeProperties": {
                "source": {
                    "type": "RestSource",
                    "httpRequestTimeout": "00:01:40",
                    "requestInterval": "00.00:00:00.010",
                    "requestMethod": "GET"
                },
                "sink": {
                    "type": "DelimitedTextSink",
                    "storeSettings": {
                        "type": "AzureBlobFSWriteSettings"
                    },
                    "formatSettings": {
                        "type": "DelimitedTextWriteSettings",
                        "quoteAllText": False,
                        "fileExtension": ".csv"
                    }
                },
                "enableStaging": False
            },
            "inputs": [
                {
                    "referenceName": source_dataset,
                    "type": "DatasetReference"
                }
            ],
            "outputs": [
                {
                    "referenceName": sink_dataset,
                    "type": "DatasetReference"
                }
            ]
        }
        return activity
    
    def create_pipeline_config(self):
        """
        Create complete pipeline configuration for Danish energy data ingestion
        """
        pipeline = {
            "name": "PL_DanishEnergyDataIngestion",
            "type": "Microsoft.DataFactory/factories/pipelines",
            "properties": {
                "activities": [
                    {
                        "name": "Extract_CO2_Emissions",
                        "type": "Copy",
                        "typeProperties": {
                            "source": {
                                "type": "RestSource",
                                "httpRequestTimeout": "00:01:40",
                                "requestInterval": "00.00:00:00.010",
                                "requestMethod": "GET",
                                "additionalHeaders": {
                                    "Accept": "application/json"
                                }
                            },
                            "sink": {
                                "type": "DelimitedTextSink",
                                "storeSettings": {
                                    "type": "AzureBlobFSWriteSettings"
                                },
                                "formatSettings": {
                                    "type": "DelimitedTextWriteSettings",
                                    "quoteAllText": False,
                                    "fileExtension": ".csv"
                                }
                            }
                        },
                        "inputs": [
                            {
                                "referenceName": "DS_CO2Emissions",
                                "type": "DatasetReference"
                            }
                        ],
                        "outputs": [
                            {
                                "referenceName": "DS_DataLake_CO2_Raw",
                                "type": "DatasetReference"
                            }
                        ]
                    },
                    {
                        "name": "Extract_Renewable_Energy",
                        "type": "Copy",
                        "dependsOn": [
                            {
                                "activity": "Extract_CO2_Emissions",
                                "dependencyConditions": ["Succeeded"]
                            }
                        ],
                        "typeProperties": {
                            "source": {
                                "type": "RestSource",
                                "httpRequestTimeout": "00:01:40",
                                "requestInterval": "00.00:00:00.010",
                                "requestMethod": "GET"
                            },
                            "sink": {
                                "type": "DelimitedTextSink",
                                "storeSettings": {
                                    "type": "AzureBlobFSWriteSettings"
                                },
                                "formatSettings": {
                                    "type": "DelimitedTextWriteSettings",
                                    "quoteAllText": False,
                                    "fileExtension": ".csv"
                                }
                            }
                        },
                        "inputs": [
                            {
                                "referenceName": "DS_RenewableEnergy",
                                "type": "DatasetReference"
                            }
                        ],
                        "outputs": [
                            {
                                "referenceName": "DS_DataLake_Renewable_Raw",
                                "type": "DatasetReference"
                            }
                        ]
                    },
                    {
                        "name": "Extract_Electricity_Prices",
                        "type": "Copy",
                        "dependsOn": [
                            {
                                "activity": "Extract_Renewable_Energy",
                                "dependencyConditions": ["Succeeded"]
                            }
                        ],
                        "typeProperties": {
                            "source": {
                                "type": "RestSource",
                                "httpRequestTimeout": "00:01:40",
                                "requestInterval": "00.00:00:00.010",
                                "requestMethod": "GET"
                            },
                            "sink": {
                                "type": "DelimitedTextSink",
                                "storeSettings": {
                                    "type": "AzureBlobFSWriteSettings"
                                },
                                "formatSettings": {
                                    "type": "DelimitedTextWriteSettings",
                                    "quoteAllText": False,
                                    "fileExtension": ".csv"
                                }
                            }
                        },
                        "inputs": [
                            {
                                "referenceName": "DS_ElectricityPrices",
                                "type": "DatasetReference"
                            }
                        ],
                        "outputs": [
                            {
                                "referenceName": "DS_DataLake_Prices_Raw",
                                "type": "DatasetReference"
                            }
                        ]
                    }
                ],
                "parameters": {
                    "StartDate": {
                        "type": "string",
                        "defaultValue": "2020-01-01"
                    },
                    "EndDate": {
                        "type": "string",
                        "defaultValue": "2024-12-31"
                    }
                },
                "annotations": [
                    "Danish Energy Data Ingestion Pipeline"
                ]
            }
        }
        return pipeline
    
    def create_trigger_config(self):
        """
        Create trigger configuration for scheduled pipeline execution
        """
        trigger = {
            "name": "TR_DailyEnergyDataIngestion",
            "type": "Microsoft.DataFactory/factories/triggers",
            "properties": {
                "type": "ScheduleTrigger",
                "typeProperties": {
                    "recurrence": {
                        "frequency": "Day",
                        "interval": 1,
                        "startTime": "2025-01-01T02:00:00Z",
                        "timeZone": "UTC"
                    }
                },
                "pipelines": [
                    {
                        "pipelineReference": {
                            "referenceName": "PL_DanishEnergyDataIngestion",
                            "type": "PipelineReference"
                        },
                        "parameters": {
                            "StartDate": "@formatDateTime(addDays(utcNow(), -1), 'yyyy-MM-dd')",
                            "EndDate": "@formatDateTime(utcNow(), 'yyyy-MM-dd')"
                        }
                    }
                ]
            }
        }
        return trigger
    
    def export_all_configs(self, output_dir: str = "adf_configs"):
        """
        Export all ADF configurations to JSON files
        
        Args:
            output_dir: Directory to save configuration files
        """
        import os
        os.makedirs(output_dir, exist_ok=True)
        
        # Export linked service
        linked_service = self.create_linked_service_config()
        with open(os.path.join(output_dir, 'linkedservice_energi_api.json'), 'w') as f:
            json.dump(linked_service, f, indent=2)
        
        # Export datasets
        datasets = [
            ("CO2Emissions", "/dataset/CO2Emis"),
            ("RenewableEnergy", "/dataset/ProductionConsumptionSettlement"),
            ("ElectricityPrices", "/dataset/Elspotprices")
        ]
        
        for name, endpoint in datasets:
            dataset = self.create_dataset_config(name, endpoint)
            with open(os.path.join(output_dir, f'dataset_{name.lower()}.json'), 'w') as f:
                json.dump(dataset, f, indent=2)
        
        # Export Data Lake datasets
        data_lake_datasets = [
            ("raw/co2_emissions", "co2_emissions_@{formatDateTime(utcNow(), 'yyyyMMdd')}.csv"),
            ("raw/renewable_energy", "renewable_energy_@{formatDateTime(utcNow(), 'yyyyMMdd')}.csv"),
            ("raw/electricity_prices", "electricity_prices_@{formatDateTime(utcNow(), 'yyyyMMdd')}.csv")
        ]
        
        for folder, filename in data_lake_datasets:
            dataset = self.create_data_lake_dataset("energydata", folder, filename)
            with open(os.path.join(output_dir, f'dataset_datalake_{folder.split("/")[1]}.json'), 'w') as f:
                json.dump(dataset, f, indent=2)
        
        # Export pipeline
        pipeline = self.create_pipeline_config()
        with open(os.path.join(output_dir, 'pipeline_energy_ingestion.json'), 'w') as f:
            json.dump(pipeline, f, indent=2)
        
        # Export trigger
        trigger = self.create_trigger_config()
        with open(os.path.join(output_dir, 'trigger_daily_ingestion.json'), 'w') as f:
            json.dump(trigger, f, indent=2)
        
        print(f"All ADF configurations exported to {output_dir}/")

def main():
    """Main execution function"""
    # Initialize ADF configuration
    adf_config = AzureDataFactoryConfig(
        subscription_id="your-subscription-id",
        resource_group="rg-danish-energy-analytics",
        factory_name="adf-danish-energy-data"
    )
    
    # Export all configurations
    adf_config.export_all_configs()
    
    print("Azure Data Factory configuration files generated successfully!")

if __name__ == "__main__":
    main()

