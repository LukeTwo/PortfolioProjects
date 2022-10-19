Select location, date, total_cases, total_deaths, population
From Portfolio..CovidDeaths
order by 1,2

-- Total Cases vs Total Deaths
-- Likelihood of dying if you contracted covid
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 DeathPercentage
From Portfolio..CovidDeaths
where location like 'Ireland'
order by 1,2

-- Total Cases Vs Population
-- Percentage of population that is infected
Select location, date, total_cases, population, (total_cases/population)*100 InfectionPercentage
From Portfolio..CovidDeaths
where location like 'Ireland'
order by 1,2

-- Countries with highest infection rates
Select location, MAX(total_cases) HighestInfectionCount, population, MAX((total_cases/population))*100 HighestInfectionPercentage
From Portfolio..CovidDeaths
group by location, population
order by HighestInfectionPercentage desc

-- Total deaths per country
Select location, MAX(CAST(total_deaths AS int)) TotalDeaths
From Portfolio..CovidDeaths
where continent is not null
group by location
order by TotalDeaths desc

-- Mortality rate per country
Select location, MAX(CAST(total_deaths AS int)) TotalDeaths, population, MAX((CAST(total_deaths AS int)/population))*100 MortalityRate
From Portfolio..CovidDeaths
where continent is not null
group by location, population
order by MortalityRate desc

-- Total deaths per continent
Select location, MAX(CAST(total_deaths AS int)) TotalDeaths
From Portfolio..CovidDeaths
where continent is null
group by location
order by TotalDeaths desc

-- Mortality rate per continent
Select location, MAX(CAST(total_deaths AS int)) TotalDeaths, population, MAX((CAST(total_deaths AS int)/population))*100 MortalityRate
From Portfolio..CovidDeaths
where continent is null
group by location, population
order by MortalityRate desc

-- New cases, new deaths global
select date, sum(new_cases) NewCases, sum(CAST(new_deaths AS int)) NewDeaths
From Portfolio..CovidDeaths
where continent is not null AND location != 'world'
group by date
order by date

-- Total deaths global
select date, sum(CAST(total_deaths AS int)) TotalDeaths
From Portfolio..CovidDeaths
where continent is not null AND location != 'world'
group by date
order by date

-- Covid death rate global
Select date, sum(total_cases) TotalCases, sum(CAST(total_deaths AS int)) TotalDeaths, sum(CAST(total_deaths AS int))/sum(total_cases)*100 DeathRate
From Portfolio..CovidDeaths
where continent is not null AND location != 'world'
group by date
order by date

-- joining death and vaccination tables
select *
From Portfolio..CovidDeaths deaths
inner join Portfolio..CovidVaccinations vac
on deaths.location = vac.location and deaths.date = vac.date
where deaths.continent is not null
order by deaths.location, deaths.date

-- Total Vaccination Percentage per country using CTE
With VacInfo(location, date, population, new_vaccinations, total_vaccinations)
as
(
Select deaths.location, deaths.date, deaths.population, vac.new_vaccinations, sum(CAST(vac.new_vaccinations as int)) OVER (Partition by deaths.location order by deaths.location, deaths.date ) TotalVaccinated
From Portfolio..CovidDeaths deaths
inner join Portfolio..CovidVaccinations vac
on deaths.location = vac.location and deaths.date = vac.date
where deaths.continent is not null
)
Select location, population, max(total_vaccinations) total_vaccinations, max(total_vaccinations) / population * 100 PercentVaccinated
from VacInfo
Group by location, population

-- Daily Vaccination Percentage per country using Temp Table
Drop table if exists #VaccinationInfo
Create table #VaccinationInfo
(
location nvarchar(255),
date datetime,
population int,
new_vaccinations int,
total_vaccinated numeric
)

Insert into #VaccinationInfo
Select deaths.location, deaths.date, deaths.population, vac.new_vaccinations, sum(CAST(vac.new_vaccinations as int)) OVER (Partition by deaths.location order by deaths.location, deaths.date ) TotalVaccinated
From Portfolio..CovidDeaths deaths
inner join Portfolio..CovidVaccinations vac
on deaths.location = vac.location and deaths.date = vac.date
where deaths.continent is not null

Select *, (total_vaccinated/population)*100 PercentVaccinated
From #VaccinationInfo
where new_vaccinations is not null

-- Create a view for visualization
Create View InfectionRate as
Select location, MAX(total_cases) HighestInfectionCount, population, MAX((total_cases/population))*100 HighestInfectionPercentage
From Portfolio..CovidDeaths
group by location, population

