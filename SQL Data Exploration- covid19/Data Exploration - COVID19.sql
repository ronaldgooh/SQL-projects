select * from PortfolioProject..CovidDeaths
Where continent is not null 
order by 3,4

select * from PortfolioProject..CovidVaccinations
order by 3,4

--Select data to be used
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
Where continent IS NOT NULL
ORDER BY 1,2


-- total cases VS total deaths (Death Percentage)
-- Likelihood of dying if contracted COVID
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%States%'
AND continent IS NOT NULL
ORDER BY 1,2

-- total cases VS population
-- % of population with COVID
SELECT Location, date, total_cases, population, (total_cases/population)*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%States%'
ORDER BY 1,2

-- Countries with Highest Infection Rate compared to Population
SELECT Location,  population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected 
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

-- Countries with Highest Death Count per Population
SELECT Location,  MAX(CAST(total_deaths as int)) AS TotalDeathCount -- CAST() function converts a value (of any type) into the specified datatype
FROM PortfolioProject..CovidDeaths
Where continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC



-- BREAKING THINGS DOWN BY CONTINENT

-- contintents with the highest death count per population
SELECT continent,  MAX(CAST(total_deaths as int)) AS TotalDeathCount 
FROM PortfolioProject..CovidDeaths
Where continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- correct method to search contintents with the highest death count per population
SELECT location,  MAX(CAST(total_deaths as int)) AS TotalDeathCount 
FROM PortfolioProject..CovidDeaths
Where continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Global total case vs total death
SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths as int)) AS total_deaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2




-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location,dea.date) AS RollingPeopleVaccinated
--,RollingPeopleVaccinated/Population)*100       -- can't call RollingPeopleVaccinated in the same query, use CTE or temp table
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location 
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- Using CTE to perform Calculation on Partition By in previous query
-- faster if doing only 1 query calculation
WITH PopvsVac (Continent,Location,Date,Population,new_vaccinations,RollingPeopleVaccinated)
AS(
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location,dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location 
AND dea.date=vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercentPopVaccinated
FROM PopvsVac 


-- Using Temp Table to perform Calculation on Partition By in previous query
--abit slow if you only doing 1 calculation
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated (
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location,dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location 
AND dea.date=vac.date
WHERE dea.continent IS NOT NULL	

SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercentPopVaccinated
FROM #PercentPopulationVaccinated




-- Creating View to store data for later visualizations
DROP VIEW IF EXISTS PercentPopulationVaccinated
Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
