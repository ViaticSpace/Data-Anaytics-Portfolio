--Preview of the uploaded table CovidDeaths
SELECT *
FROM PortfolioProject..CovidDeaths
ORDER BY location, date

--Preview of the uploaded table CovidVaccinations
SELECT *
FROM PortfolioProject..CovidVaccinations
ORDER BY location, date


--Looking at the total cases vs total deaths
SELECT location, date, total_cases, new_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
ORDER BY 1, 2

--Filtering for country
SELECT location, date, total_cases, new_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%slovenia%'
ORDER BY 1, 2

--The query shows the probability of dying if you contract covid in a country
SELECT location, date, total_cases, new_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%italy%'
ORDER BY 1, 2

--Looking at the total cases vs. total population
--Shows what % of the population is affected by covid
SELECT location, date, total_cases, population, total_deaths, (total_cases/population)*100 AS CasesPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%italy%'
ORDER BY 1, 2

--Looking at countries with highest AVERAGE infection rate
SELECT location, AVG(total_cases/population)*100 AS InfectionRate
FROM PortfolioProject..CovidDeaths
GROUP BY location
ORDER BY InfectionRate DESC

--Looking at countries with highest PEAK infection rate
SELECT location, population, MAX(total_cases) AS InfectedCount, MAX(total_cases/population)*100 AS InfectionRatePeak
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY InfectionRatePeak DESC

--Ordering countries for the highest average death rate
SELECT location, population, MAX(total_cases) AS MaxTotalCases, MAX(total_deaths) AS MaxTotalDeaths, AVG(total_deaths/total_cases) AS MortalityRate, MAX(total_cases/population)*100 AS InfectionRatePeak
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY MortalityRate DESC

--Ordering countries for the HIGHEST DEATH COUNT
SELECT location, MAX(CAST (total_deaths AS int)) AS DeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY DeathCount DESC

--Break up of DEATH COUNT by CONTINENT
SELECT continent, MAX(CAST(total_deaths AS int)) AS DeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY DeathCount DESC

--Global numbers group by DAY
SELECT date, SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS INT)) AS TotalDeaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases) AS DeathRate
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

--Global numbers OVERALL
SELECT SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS INT)) AS TotalDeaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases) AS DeathRate
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2

--Looking at the CovidVaccinations table
SELECT *
FROM PortfolioProject..CovidVaccinations

--Joining CovidDeaths and CovidVaccinations tables ON location and date
SELECT *
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
  ON dea.location = vac.location AND dea.date = vac.date

--Final Goal: Verifying total vaccination rate in the world
--Starting with selecting and viewing the columns with useful data
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
  ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 1,2

--Introducing a PARTITION BY location (country)
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location) AS TotalVaccinations
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
  ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2

--Adding a rolling count to TotalVaccinations PARTITION by location
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS VacRollingCount
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
  ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3

--Verifying total vaccination rate in the world
--By using a CTE
--Creating and checking the CTE
WITH CTE_VacRollingCount AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS VacRollingCount
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
  ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (VacRollingCount/population)*100 AS VacPerc
FROM CTE_VacRollingCount

--Verifying total vaccination rate in the world
--By using a TEMP TABLE
--Creating and checking A TEMP TABLE
DROP TABLE IF EXISTS #VacTotalCount
CREATE TABLE #VacTotalCount
(Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
NewVaccinations numeric,
VacRollingCount numeric
)
INSERT INTO #VacTotalCount
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS VacRollingCount
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
  ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (VacRollingCount/population)*100 AS VacPerc
FROM #VacTotalCount

--Verifying total vaccination rate in the world
--By using a SUBQUERY

SELECT *, (VacRolCount.VacRollingCount/VacRolCount.population)*100 AS VacPerc
FROM (
  SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS VacRollingCount
  FROM PortfolioProject..CovidDeaths AS dea
  JOIN PortfolioProject..CovidVaccinations AS vac
    ON dea.location = vac.location AND dea.date = vac.date
  WHERE dea.continent IS NOT NULL
  ) AS VacRolCount

--Verifying the highest VACCINATION RATE by Country
--By using a TEMP TABLE
--Creating and checking A TEMP TABLE
DROP TABLE IF EXISTS #VacTotalCount
CREATE TABLE #VacTotalCount
(Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
NewVaccinations numeric,
VacRollingCount numeric,
)
INSERT INTO #VacTotalCount
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS VacRollingCount
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
  ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT location, population, MAX(VacRollingCount) as VacCountryCount, (MAX(VacRollingCount)/population)*100 AS VacPerc
FROM #VacTotalCount
GROUP BY location, population
HAVING MAX(VacRollingCount) IS NOT NULL
ORDER BY VacPerc DESC

--There are some countries, like Gibraltar and Israel, where the sum of performed vaccinations is bigger than their population
--These countries were ahead of the rest of the world and started performing booster doses of vaccines

-- CREATING VIEWS to store data for later visualizations
-- View for Total Vaccination Rate by Country

CREATE VIEW TotVacRate AS
WITH CTE_VacTotCount AS
(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS VacRollingCount
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
  ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT location, population, MAX(VacRollingCount) as VacCountryCount, (MAX(VacRollingCount)/population)*100 AS VacPerc
FROM CTE_VacTotCount
GROUP BY location, population
HAVING MAX(VacRollingCount) IS NOT NULL



