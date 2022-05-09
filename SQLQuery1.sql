/*
Covid 19 Data Exploration 
Skills used: Cleaning Tables, Joining tables, Using Common Table Expressions (CTE's), Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

-- Removing the unneccesary rows from CovidDeaths  
DELETE FROM Covid..CovidDeaths
WHERE total_cases IS NULL

-- Removing the unneccesary rows from CovidVaccinations
DELETE FROM Covid..CovidVaccinations
WHERE total_tests IS NULL

-- Select all information of all countries
SELECT *
From Covid..CovidDeaths
Where continent is not null

-- To get the continents
Select continent
From Covid..CovidDeaths
Where continent is not null
Group by continent

--The likelihood of dying in Netherlands when contracting COVID per day
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
FROM Covid..CovidDeaths
WHERE location like 'Netherlands'
ORDER BY 1,2

-- Percentage of population of every country that has/got COVID per day
SELECT location, date, total_cases, population, (total_cases/population)*100 as infected_percentage
FROM Covid..CovidDeaths
ORDER BY 1,2

-- Total cases of per country
SELECT location, sum(new_cases) as total_cases
From Covid..CovidDeaths
Group by location
Order by 2 desc

-- Countries with highest infection rate (compared to population)
SELECT location, population, MAX(total_cases) as HighestInfection, MAX((total_cases/population))*100 as max_infected_percentage
FROM Covid..CovidDeaths
GROUP BY location, population
ORDER BY max_infected_percentage desc

-- Countries with highest infection rate (compared to population)
SELECT location, population, date, MAX(total_cases) as HighestInfection, MAX((total_cases/population))*100 as max_infected_percentage
FROM Covid..CovidDeaths
GROUP BY location, population, date
ORDER BY max_infected_percentage desc

-- Countries highest total deaths
SELECT location, MAX(cast(total_deaths as int)) as total_deaths
FROM Covid..CovidDeaths
Where continent is not null
GROUP BY location
ORDER BY total_deaths desc

-- Showing continents with highest total deaths
SELECT location, MAX(cast(total_deaths as int)) as total_deaths
FROM Covid..CovidDeaths
Where continent is null and location not like '%income'
GROUP BY location
ORDER BY total_deaths desc

-- Showing incomes with highest total deaths
SELECT location, MAX(cast(total_deaths as int)) as total_deaths
FROM Covid..CovidDeaths
Where location like '%income'
GROUP BY location
ORDER BY total_deaths desc

-- Showing only continents with highest total deaths
SELECT location, SUM(cast(new_deaths as int)) as total_deaths
FROM Covid..CovidDeaths
Where continent is null 
	and location not like '%income'
	and location not in ('World', 'European Union', 'International') 
GROUP BY location
ORDER BY total_deaths desc

-- Global numbers of death percentage per day
Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as death_percentage
From Covid..CovidDeaths
Where continent is not null and location not like '%income' 
Group by date
Order by 1,2

-- Total global numbers covid for cases and deaths
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as death_percent
From Covid..CovidDeaths
Where continent is not null

-- Total global numbers for new tests and fully vaccinated
Select SUM(cast(new_tests as bigint)) as total_tests, SUM(Convert(bigint, new_people_vaccinated_smoothed)) as people_vaccinated, SUM(Convert(bigint, new_vaccinations)) as total_doses
From Covid..CovidVaccinations  
Where continent is not null

-- The amount of vaccinations (every dose counts as 1) 
SELECT vac.location, sum(cast(vac.new_vaccinations as int)) as total_vaccinations
From Covid..CovidDeaths death Join Covid..CovidVaccinations vac 
	On death.location = vac.location 
	and death.date = vac.date
Where death.continent is not null
Group by vac.location
Order by 1 desc

-- Looking at the cummalative vaccinations and percentage vaccinated of population per day per country
With populationVsVaccinations (continent, location, date, population, new_vaccinations, cummulativeVaccinations)
as(
Select death.continent, death.location, death.date, death.population, vac.new_vaccinations, 
SUM(cast(vac.new_vaccinations as int)) OVER (Partition by death.location Order by death.location, death.date, death.population) as cummulativeVaccinations
From Covid..CovidDeaths death
	 Join Covid..CovidVaccinations vac
	 On death.location = vac.location 
	 and death.date = vac.date
Where death.continent is not null
)
Select *, (cummulativeVaccinations/population)*100 as percentageVaccinated
From populationVsVaccinations
Order by 2,3

-- The amount of people fully vaccinated per country vs population
Select deaths.continent, deaths.location, deaths.population, MAX(cast(vac.people_fully_vaccinated as int)) as maxvacinated, (MAX(Convert(int, vac.people_fully_vaccinated))/ deaths.population)*100 as vaccinationPercent
From Covid..CovidDeaths deaths 
	Join Covid..CovidVaccinations vac
	On deaths.location = vac.location 
	and deaths.date = vac.date
Group by deaths.continent, deaths.location, deaths.population
Order by 5 desc

-- The amount of people fully vaccinated in Netherlands per day
With VaccinationsNetherlands (continent, location, date, population, maxvaccinated, vaccinationPercent)
as(
Select deaths.continent, deaths.location, deaths.date, deaths.population, MAX(cast(vac.people_fully_vaccinated as int)) as maxvaccinated, (MAX(Convert(int, vac.people_fully_vaccinated))/ deaths.population)*100 as vaccinationPercent
From Covid..CovidDeaths deaths 
	Join Covid..CovidVaccinations vac
	On deaths.location = vac.location 
	and deaths.date = vac.date
Where deaths.location like 'Netherlands'
Group by deaths.continent, deaths.location, deaths.date, deaths.population
)
Select * 
From VaccinationsNetherlands
Where maxvaccinated is not null
Order by 3 

 -- Comparing death percentage to people aged above 65
With deaths as
(Select location, population , SUM(Convert(int, new_deaths)) as total_deaths
From Covid..CovidDeaths
Group by location, population
),
aged as 
(Select location, aged_65_older
From Covid..CovidVaccinations
Group by location, aged_65_older
)
Select deaths.location, deaths.population, deaths.total_deaths, aged.aged_65_older, (deaths.total_deaths/deaths.population)*100 as death_percentage, (total_deaths/(population/aged_65_older))*100 as age_metric 
From deaths join aged on deaths.location = aged.location
Order by 6 desc

-- Life expectancy and GDP
Select continent, location, life_expectancy, gdp_per_capita
From Covid..CovidVaccinations
Where life_expectancy is not null
      and gdp_per_capita is not null
Group by location, life_expectancy, gdp_per_capita, continent
Order by 3 desc

-- Creating a view for later visualizations
Create View cummalativeVaccinations as 
With populationVsVaccinations (continent, location, date, population, new_vaccinations, cummulativeVaccinations)
as(
Select death.continent, death.location, death.date, death.population, vac.new_vaccinations, 
SUM(cast(vac.new_vaccinations as int)) OVER (Partition by death.location Order by death.location, death.date, death.population) as cummulativeVaccinations
From Covid..CovidDeaths death
	 Join Covid..CovidVaccinations vac
	 On death.location = vac.location 
	 and death.date = vac.date
Where death.continent is not null
)
Select *, (cummulativeVaccinations/population)*100 as percentageVaccinated
From populationVsVaccinations

-- Creating a view for later visualizations
Create View populationVSvaccination as 
With populationVSvaccination (continent, location, population, maxvacinated, vaccinationPercent)
as(
Select deaths.continent, deaths.location, deaths.population, MAX(cast(vac.people_fully_vaccinated as int)) as maxvacinated, (MAX(Convert(int, vac.people_fully_vaccinated))/ deaths.population)*100 as vaccinationPercent
From Covid..CovidDeaths deaths 
	Join Covid..CovidVaccinations vac
	On deaths.location = vac.location 
	and deaths.date = vac.date
Group by deaths.continent, deaths.location, deaths.population
)
Select *
From populationVSvaccination