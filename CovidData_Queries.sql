-- DROP TABLE IF EXISTS #NAME_OF_TEMP_TABLE


-- COVID DEATHS


SELECT * 
FROM CovidData_PortfolioProject.dbo.CovidDeaths$
ORDER BY 3, 4

SELECT COUNT(date) as TOTAL_COUNT
FROM CovidData_PortfolioProject.dbo.CovidDeaths$

SELECT COUNT(date) as TOTAL_COUNT
FROM CovidData_PortfolioProject.dbo.CovidVaccinations$

--SELECT *
--FROM CovidData_PortfolioProject.dbo.CovidVaccinations$

-- Select the data that we are going to be using.
--SELECT location, date, total_cases, new_cases, total_deaths, population
--FROM CovidData_PortfolioProject.dbo.CovidDeaths$
--ORDER BY 1,2

-- Looking at the Total Cases vs. Total Deaths
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidData_PortfolioProject.dbo.CovidDeaths$
WHERE location like 'United States'
ORDER BY 1,2

-- Show over time what percentage of the (U.S.) Population Got Covid?
SELECT location, date, total_cases, Population, (total_cases/Population)*100 AS PercentPopulationInfected
FROM CovidData_PortfolioProject.dbo.CovidDeaths$
WHERE location like 'United States'
ORDER BY 1,2

-- What countries have the highest infection rates (compared to population)?
SELECT location, Population, MAX(total_cases) as HighestInfectionCount, 
	MAX(total_cases/Population)*100 as PercentPopulationInfected
FROM CovidData_PortfolioProject.dbo.CovidDeaths$
GROUP BY location, Population
ORDER BY PercentPopulationInfected DESC

-- What countries have the highest death rates (compared to population)?
-- to cast a datatype, you do can use the casting function:
-- cast(total_deaths as int)
-- note that 'WHERE continent IS NOT NULL' query comes from 
-- exploratory data analysis and understanding the data.
SELECT location as Country, MAX(total_deaths) as HighestDeathCount
FROM CovidData_PortfolioProject.dbo.CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location 
ORDER BY HighestDeathCount DESC

-- Breaking things down by continent: However THESE ARE NOT THE CORRECT NUMBERS.
SELECT continent, MAX(cast(total_deaths AS INT)) as TotalDeathCounts
FROM CovidData_PortfolioProject.dbo.CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCounts DESC

-- This query might represent the correct continent numbers
-- The continents with the highest death count
SELECT location, MAX(cast(total_deaths AS INT)) as TotalDeathCounts
FROM CovidData_PortfolioProject.dbo.CovidDeaths$
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCounts DESC

-- GLOBAL NUMBERS
-- be careful with the GROUPBY here. Make sure that you're using aggregate functions 
-- when you need to.
SELECT date, total_deaths, total_cases, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidData_PortfolioProject.dbo.CovidDeaths$
WHERE location LIKE 'World'
ORDER BY date

SELECT location, 
       SUM(total_deaths) AS TotalDeaths, 
	   SUM(total_cases) AS TotalCases, 
	   (SUM(total_deaths)/SUM(total_cases))*100 AS DeathPercentage
FROM CovidData_PortfolioProject.dbo.CovidDeaths$
WHERE location LIKE 'World'
GROUP BY location


-- COVID VACCINATIONS

SELECT * FROM CovidData_PortfolioProject.dbo.CovidVaccinations$

-- General Join
SELECT *
FROM CovidData_PortfolioProject.dbo.CovidDeaths$ dea
JOIN CovidData_PortfolioProject.dbo.CovidVaccinations$ vac
	ON dea.location = vac.location
	 AND dea.date = vac.date

-- Looking at Total Population vs. Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM CovidData_PortfolioProject.dbo.CovidDeaths$ dea
JOIN CovidData_PortfolioProject.dbo.CovidVaccinations$ vac
	ON dea.location = vac.location 
	 AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- Create a rolling sum of vaccinations
-- Using the 'OVER' Query
-- Note that you can use either CAST or CONVERT to change datatypes.
SELECT dea.continent, 
	   dea.location,
	   dea.date,
	   dea.population,
	   vac.new_vaccinations,
	   SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER 
			(PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingSum_PeopleVaccinated--,
	   --SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER  BY dea.location AND dea.date) as RollingSum2
FROM CovidData_PortfolioProject.dbo.CovidDeaths$ dea
JOIN CovidData_PortfolioProject.dbo.CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- Join Deaths and Vaccinations
SELECT CovidData_PortfolioProject.dbo.CovidVaccinations$.location,
	   CovidData_PortfolioProject.dbo.CovidDeaths$.total_deaths,
	   total_tests, 
	   total_vaccinations 
FROM CovidData_PortfolioProject.dbo.CovidVaccinations$
Inner Join CovidData_PortfolioProject.dbo.CovidDeaths$
 ON CovidData_PortfolioProject.dbo.CovidDeaths$.location = CovidData_PortfolioProject.dbo.CovidVaccinations$.location

-- USE CTE
WITH PopvsVac (Continent, Location, Date, Population, New_Vacciations, RollingSum)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingSum_PeopleVaccinated
FROM CovidData_PortfolioProject.dbo.CovidDeaths$ dea
JOIN CovidData_PortfolioProject.dbo.CovidVaccinations$ vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
-- The key thing to remember when defining a CTE in SQL Server, 
-- is that in its definition, you must always include a SELECT, DELETE, INSERT or UPDATE statement, 
-- that references one or more columns returned by the CTE.
-- So this acts like a 'return' for the CTE
SELECT *, (RollingSum/Population)*100 as RollingPercentage FROM PopvsVac
ORDER BY 2, 3


-- Temp Table
DROP TABLE IF EXISTS #PercentPopulationVaccinated

CREATE TABLE #PercentPopulationVaccinated
(Continent NVARCHAR(255),
 Location NVARCHAR(255),
 Date DATETIME,
 Population NUMERIC,
 NewVaccinations NUMERIC,
 RollingPeopleVaccinated NUMERIC
 )

INSERT INTO #PercentPopulationVaccinated
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingSum_PeopleVaccinated
	FROM CovidData_PortfolioProject.dbo.CovidDeaths$ dea
	JOIN CovidData_PortfolioProject.dbo.CovidVaccinations$ vac
	ON dea.location = vac.location AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated/Population)*100 as RollingPercentage
FROM #PercentPopulationVaccinated
ORDER BY 2, 3


-- Create a  View (Go Back and Create Multiple Views)
-- Used to store data for later
--	These will be used in Tableau.
CREATE VIEW PercentagePplVaccinated
AS
	SELECT dea.continent, 
		   dea.location,
		   dea.date,
		   dea.population,
		   vac.new_vaccinations,
		   SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingSum_PeopleVaccinated
	FROM CovidData_PortfolioProject.dbo.CovidDeaths$ dea
	JOIN CovidData_PortfolioProject.dbo.CovidVaccinations$ vac
	ON dea.location = vac.location AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL

CREATE VIEW DeathsAndVaccinations
AS
SELECT CovidData_PortfolioProject.dbo.CovidVaccinations$.location,
	   CovidData_PortfolioProject.dbo.CovidDeaths$.total_deaths,
	   total_tests, 
	   total_vaccinations 
FROM CovidData_PortfolioProject.dbo.CovidVaccinations$
Inner Join CovidData_PortfolioProject.dbo.CovidDeaths$
 ON CovidData_PortfolioProject.dbo.CovidDeaths$.location = CovidData_PortfolioProject.dbo.CovidVaccinations$.location

CREATE VIEW GlobalNumbers
AS
SELECT date, total_deaths, total_cases, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidData_PortfolioProject.dbo.CovidDeaths$
WHERE location LIKE 'World'