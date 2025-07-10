import os
import sys
import pandas as pd
from unittest.mock import patch

# Ensure project root is on sys.path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from danish_energy_project.dashboards.dashboard_api import DashboardDataService


def test_get_renewable_trends_calls_execute_query():
    service = DashboardDataService({'host': 'h', 'database': 'd', 'user': 'u', 'password': 'p'})
    df = pd.DataFrame({'a': [1]})
    with patch.object(service, 'execute_query', return_value=df) as mock_exec:
        result = service.get_renewable_trends(days=7)
        mock_exec.assert_called_once()
        args, _ = mock_exec.call_args
        assert args[1] == (7,)
        assert result.equals(df)


def test_get_hourly_patterns_with_dates():
    service = DashboardDataService({})
    df = pd.DataFrame({'a': []})
    with patch.object(service, 'execute_query', return_value=df) as mock_exec:
        result = service.get_hourly_patterns('2023-01-01', '2023-01-02')
        mock_exec.assert_called_once()
        args, _ = mock_exec.call_args
        assert args[1] == ('2023-01-01', '2023-01-02')
        assert result is df
