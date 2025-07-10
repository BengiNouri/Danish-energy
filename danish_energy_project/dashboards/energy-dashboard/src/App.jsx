import { useState, useEffect } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { 
  LineChart, Line, AreaChart, Area, BarChart, Bar, PieChart, Pie, Cell,
  XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer 
} from 'recharts'
import { 
  Zap, Wind, Sun, Factory, TrendingUp, TrendingDown, 
  Activity, DollarSign, Leaf, AlertTriangle, Calendar, Clock
} from 'lucide-react'
import './App.css'

const API_BASE_URL = 'http://localhost:5000/api'

function App() {
  const [kpis, setKpis] = useState({})
  const [renewableTrends, setRenewableTrends] = useState([])
  const [co2Analysis, setCo2Analysis] = useState([])
  const [priceAnalysis, setPriceAnalysis] = useState([])
  const [hourlyPatterns, setHourlyPatterns] = useState([])
  const [energyMix, setEnergyMix] = useState([])
  const [loading, setLoading] = useState(true)
  const [selectedDays, setSelectedDays] = useState(30)
  const [lastUpdated, setLastUpdated] = useState(new Date())

  const fetchData = async () => {
    setLoading(true)
    try {
      const aggregate = selectedDays >= 365 ? 'month' : 'day'
      const [kpisRes, renewableRes, co2Res, priceRes, hourlyRes, mixRes] = await Promise.all([
        fetch(`${API_BASE_URL}/kpis?days=${selectedDays}`),
        fetch(`${API_BASE_URL}/renewable-trends?days=${selectedDays}&aggregate=${aggregate}`),
        fetch(`${API_BASE_URL}/co2-analysis?days=${selectedDays}&aggregate=${aggregate}`),
        fetch(`${API_BASE_URL}/price-analysis?days=${selectedDays}&aggregate=${aggregate}`),
        fetch(`${API_BASE_URL}/hourly-patterns`),
        fetch(`${API_BASE_URL}/energy-mix?days=${selectedDays}&aggregate=${aggregate}`)
      ])

      const [kpisData, renewableData, co2Data, priceData, hourlyData, mixData] = await Promise.all([
        kpisRes.json(),
        renewableRes.json(),
        co2Res.json(),
        priceRes.json(),
        hourlyRes.json(),
        mixRes.json()
      ])

      setKpis(kpisData)
      setRenewableTrends(renewableData)
      setCo2Analysis(co2Data)
      setPriceAnalysis(priceData)
      setHourlyPatterns(hourlyData)
      setEnergyMix(mixData)
      setLastUpdated(new Date())
    } catch (error) {
      console.error('Error fetching data:', error)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchData()
  }, [selectedDays])

  const formatNumber = (num, decimals = 1) => {
    if (num === undefined || num === null) return 'N/A'
    return Number(num).toLocaleString('en-US', { 
      minimumFractionDigits: decimals, 
      maximumFractionDigits: decimals 
    })
  }

  const formatDate = (dateStr) => {
    return new Date(dateStr).toLocaleDateString('en-US', { 
      month: 'short', 
      day: 'numeric' 
    })
  }

  // Prepare data for charts
  const renewableChartData = renewableTrends.map(item => ({
    date: formatDate(item.date_actual),
    renewable: Number(item.renewable_percentage || 0),
    wind: Number(item.wind_percentage || 0),
    solar: Number(item.solar_percentage || 0),
    area: item.price_area_code
  }))

  const co2ChartData = co2Analysis.map(item => ({
    date: formatDate(item.date_actual),
    co2: Number(item.avg_co2_intensity || 0),
    peak: Number(item.peak_co2_intensity || 0),
    offpeak: Number(item.offpeak_co2_intensity || 0),
    area: item.price_area_code
  }))

  const priceChartData = priceAnalysis.map(item => ({
    date: formatDate(item.date_actual),
    price: Number(item.avg_price_eur || 0),
    volatility: Number(item.price_volatility || 0),
    area: item.price_area_code
  }))

  const hourlyChartData = hourlyPatterns.map(item => ({
    hour: `${item.hour}:00`,
    co2: Number(item.avg_co2_intensity || 0),
    renewable: Number(item.avg_renewable_percentage || 0),
    price: Number(item.avg_price_eur || 0),
    production: Number(item.total_production_mwh || 0),
    area: item.price_area_code
  }))

  // Energy mix pie chart data
  const latestEnergyMix = energyMix.length > 0 ? energyMix[energyMix.length - 1] : {}
  const pieData = [
    { name: 'Offshore Wind', value: Number(latestEnergyMix.offshore_wind_mwh || 0), color: '#0ea5e9' },
    { name: 'Onshore Wind', value: Number(latestEnergyMix.onshore_wind_mwh || 0), color: '#06b6d4' },
    { name: 'Solar', value: Number(latestEnergyMix.solar_mwh || 0), color: '#eab308' },
    { name: 'Hydro', value: Number(latestEnergyMix.hydro_mwh || 0), color: '#3b82f6' },
    { name: 'Conventional', value: Number(latestEnergyMix.conventional_mwh || 0), color: '#6b7280' }
  ].filter(item => item.value > 0)

  if (loading) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="text-center">
          <Activity className="h-8 w-8 animate-spin mx-auto mb-4" />
          <p className="text-muted-foreground">Loading Danish Energy Analytics...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <header className="border-b bg-card">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-4">
              <div className="flex items-center space-x-2">
                <Zap className="h-8 w-8 text-primary" />
                <h1 className="text-2xl font-bold">Danish Energy Analytics</h1>
              </div>
              <Badge variant="secondary" className="flex items-center space-x-1">
                <Clock className="h-3 w-3" />
                <span>Last updated: {lastUpdated.toLocaleTimeString()}</span>
              </Badge>
            </div>
            <div className="flex items-center space-x-2">
              <Button 
                variant="outline" 
                size="sm"
                onClick={() => setSelectedDays(7)}
                className={selectedDays === 7 ? 'bg-primary text-primary-foreground' : ''}
              >
                7 Days
              </Button>
              <Button 
                variant="outline" 
                size="sm"
                onClick={() => setSelectedDays(30)}
                className={selectedDays === 30 ? 'bg-primary text-primary-foreground' : ''}
              >
                30 Days
              </Button>
              <Button
                variant="outline"
                size="sm"
                onClick={() => setSelectedDays(90)}
                className={selectedDays === 90 ? 'bg-primary text-primary-foreground' : ''}
              >
                90 Days
              </Button>
              <Button
                variant="outline"
                size="sm"
                onClick={() => setSelectedDays(180)}
                className={selectedDays === 180 ? 'bg-primary text-primary-foreground' : ''}
              >
                6 Months
              </Button>
              <Button
                variant="outline"
                size="sm"
                onClick={() => setSelectedDays(365)}
                className={selectedDays === 365 ? 'bg-primary text-primary-foreground' : ''}
              >
                1 Year
              </Button>
              <Button
                variant="outline"
                size="sm"
                onClick={() => setSelectedDays(1825)}
                className={selectedDays === 1825 ? 'bg-primary text-primary-foreground' : ''}
              >
                5 Years
              </Button>
              <Button onClick={fetchData} size="sm">
                Refresh
              </Button>
            </div>
          </div>
        </div>
      </header>

      <main className="container mx-auto px-4 py-6">
        {/* KPI Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Renewable Energy</CardTitle>
              <Leaf className="h-4 w-4 text-green-600" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-green-600">
                {formatNumber(kpis.avg_renewable_percentage)}%
              </div>
              <p className="text-xs text-muted-foreground">Average renewable mix</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">CO₂ Intensity</CardTitle>
              <Factory className="h-4 w-4 text-orange-600" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-orange-600">
                {formatNumber(kpis.avg_co2_intensity)} g/kWh
              </div>
              <p className="text-xs text-muted-foreground">Average emissions</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Electricity Price</CardTitle>
              <DollarSign className="h-4 w-4 text-blue-600" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-blue-600">
                €{formatNumber(kpis.avg_electricity_price)}
              </div>
              <p className="text-xs text-muted-foreground">Average EUR/MWh</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Energy Production</CardTitle>
              <Zap className="h-4 w-4 text-purple-600" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-purple-600">
                {formatNumber(kpis.total_energy_production / 1000, 0)}k MWh
              </div>
              <p className="text-xs text-muted-foreground">Total production</p>
            </CardContent>
          </Card>
        </div>

        {/* Main Charts */}
        <Tabs defaultValue="renewable" className="space-y-6">
          <TabsList className="grid w-full grid-cols-4">
            <TabsTrigger value="renewable">Renewable Energy</TabsTrigger>
            <TabsTrigger value="emissions">CO₂ Emissions</TabsTrigger>
            <TabsTrigger value="prices">Electricity Prices</TabsTrigger>
            <TabsTrigger value="patterns">Daily Patterns</TabsTrigger>
          </TabsList>

          <TabsContent value="renewable" className="space-y-6">
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center space-x-2">
                    <Wind className="h-5 w-5 text-green-600" />
                    <span>Renewable Energy Trends</span>
                  </CardTitle>
                  <CardDescription>
                    Renewable energy percentage over time by region
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <ResponsiveContainer width="100%" height={300}>
                    <LineChart data={renewableChartData}>
                      <CartesianGrid strokeDasharray="3 3" />
                      <XAxis dataKey="date" />
                      <YAxis />
                      <Tooltip />
                      <Legend />
                      <Line 
                        type="monotone" 
                        dataKey="renewable" 
                        stroke="#10b981" 
                        strokeWidth={2}
                        name="Renewable %"
                      />
                      <Line 
                        type="monotone" 
                        dataKey="wind" 
                        stroke="#0ea5e9" 
                        strokeWidth={2}
                        name="Wind %"
                      />
                      <Line 
                        type="monotone" 
                        dataKey="solar" 
                        stroke="#eab308" 
                        strokeWidth={2}
                        name="Solar %"
                      />
                    </LineChart>
                  </ResponsiveContainer>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center space-x-2">
                    <Sun className="h-5 w-5 text-yellow-600" />
                    <span>Energy Mix Breakdown</span>
                  </CardTitle>
                  <CardDescription>
                    Current energy production by source
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <ResponsiveContainer width="100%" height={300}>
                    <PieChart>
                      <Pie
                        data={pieData}
                        cx="50%"
                        cy="50%"
                        labelLine={false}
                        label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                        outerRadius={80}
                        fill="#8884d8"
                        dataKey="value"
                      >
                        {pieData.map((entry, index) => (
                          <Cell key={`cell-${index}`} fill={entry.color} />
                        ))}
                      </Pie>
                      <Tooltip />
                    </PieChart>
                  </ResponsiveContainer>
                </CardContent>
              </Card>
            </div>
          </TabsContent>

          <TabsContent value="emissions" className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center space-x-2">
                  <Factory className="h-5 w-5 text-orange-600" />
                  <span>CO₂ Emissions Analysis</span>
                </CardTitle>
                <CardDescription>
                  Carbon intensity trends and peak vs off-peak comparison
                </CardDescription>
              </CardHeader>
              <CardContent>
                <ResponsiveContainer width="100%" height={400}>
                  <AreaChart data={co2ChartData}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="date" />
                    <YAxis />
                    <Tooltip />
                    <Legend />
                    <Area 
                      type="monotone" 
                      dataKey="co2" 
                      stackId="1"
                      stroke="#f97316" 
                      fill="#fed7aa"
                      name="Average CO₂ (g/kWh)"
                    />
                    <Line 
                      type="monotone" 
                      dataKey="peak" 
                      stroke="#dc2626" 
                      strokeWidth={2}
                      name="Peak Hours"
                    />
                    <Line 
                      type="monotone" 
                      dataKey="offpeak" 
                      stroke="#16a34a" 
                      strokeWidth={2}
                      name="Off-Peak Hours"
                    />
                  </AreaChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="prices" className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center space-x-2">
                  <DollarSign className="h-5 w-5 text-blue-600" />
                  <span>Electricity Price Analysis</span>
                </CardTitle>
                <CardDescription>
                  Market prices and volatility trends
                </CardDescription>
              </CardHeader>
              <CardContent>
                <ResponsiveContainer width="100%" height={400}>
                  <LineChart data={priceChartData}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="date" />
                    <YAxis yAxisId="left" />
                    <YAxis yAxisId="right" orientation="right" />
                    <Tooltip />
                    <Legend />
                    <Line 
                      yAxisId="left"
                      type="monotone" 
                      dataKey="price" 
                      stroke="#3b82f6" 
                      strokeWidth={2}
                      name="Price (EUR/MWh)"
                    />
                    <Line 
                      yAxisId="right"
                      type="monotone" 
                      dataKey="volatility" 
                      stroke="#ef4444" 
                      strokeWidth={2}
                      strokeDasharray="5 5"
                      name="Volatility"
                    />
                  </LineChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="patterns" className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center space-x-2">
                  <Clock className="h-5 w-5 text-purple-600" />
                  <span>Daily Energy Patterns</span>
                </CardTitle>
                <CardDescription>
                  Hourly patterns for renewable energy, CO₂ emissions, and prices
                </CardDescription>
              </CardHeader>
              <CardContent>
                <ResponsiveContainer width="100%" height={400}>
                  <BarChart data={hourlyChartData}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="hour" />
                    <YAxis yAxisId="left" />
                    <YAxis yAxisId="right" orientation="right" />
                    <Tooltip />
                    <Legend />
                    <Bar 
                      yAxisId="left"
                      dataKey="renewable" 
                      fill="#10b981" 
                      name="Renewable %"
                    />
                    <Bar 
                      yAxisId="left"
                      dataKey="co2" 
                      fill="#f97316" 
                      name="CO₂ (g/kWh)"
                    />
                    <Bar 
                      yAxisId="right"
                      dataKey="price" 
                      fill="#3b82f6" 
                      name="Price (EUR/MWh)"
                    />
                  </BarChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
      </main>
    </div>
  )
}

export default App

