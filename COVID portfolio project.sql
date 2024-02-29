select * from PortfolioProject..['covid death data latest$']
order by 3,4

-- Select the data we are going to use

select location,
date,
total_cases,
new_cases,
total_deaths,
population
from PortfolioProject..['covid death data latest$']
order by 1,2

-- Looking at  total cases vs total deaths

select location,
date,
total_cases,
total_deaths,
(cast(total_deaths as numeric)/cast(total_cases as numeric))*100 as death_percentage
from PortfolioProject..['covid death data latest$']
where location like '%india%'
order by 1,2

-- Total cases vs population

select location,
date,
population,
total_cases,
(cast(total_cases as numeric)/ cast(population as numeric)) * 100 as percent_of_popuation_affected
from PortfolioProject..['covid death data latest$']
--where location like '%india%'
order by 1,2

-- Looking at countries with highest infection rate compared to population

select location,
population,
max(total_cases) as h_infection_count,
max(cast(total_cases as numeric)/ cast(population as numeric)) * 100 as percent_of_popuation_affected
from PortfolioProject..['covid death data latest$']
--where population is not null and location in ('South Korea','India','United States')
--where location like '%india%'
group by location,
population
order by percent_of_popuation_affected desc

-- showing the countries with highest death count per populaiton

select location,
max(cast(total_deaths as int)) as total_death_count
from PortfolioProject..['covid death data latest$']
--where population is not null and location in ('South Korea','India','United States')
--where location like '%india%'
where continent is not null
group by location
order by total_death_count desc

-- beaking  things by continent

select continent,
max(cast(total_deaths as int)) as total_death_count
from PortfolioProject..['covid death data latest$']
--where population is not null and location in ('South Korea','India','United States')
--where location like '%india%'
where continent is not null
group by continent
order by total_death_count desc

-- showing the continents with the highest death count per population

select continent,
max(cast(total_deaths as int)) as total_death_count
from PortfolioProject..['covid death data latest$']
--where population is not null and location in ('South Korea','India','United States')
--where location like '%india%'
where continent is not null
group by continent
order by total_death_count desc

-- global numbers


SET ANSI_WARNINGS OFF
GO

select 
--date,
sum(new_cases) as total_cases,
sum(new_deaths) as total_deaths,
(sum(new_deaths)/NULLIF(sum(new_cases),0))*100 as death_percentage
-- using nullif here to avoid the divide by zero error
from PortfolioProject..['covid death data latest$']
where continent is not null
--group by date
order by 1,2,3


-- Looking at total population vs vaccination

select dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations,
sum(convert(numeric, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as rolling_people_vaccinated
--, rolling_people_vaccinated/dea.population
-- This is not possible as we cannot use a field which we ceated in the same query
-- To achieve this we are going to use temp table or CTE(common table expression)
from 
PortfolioProject..['covid death data latest$'] dea
join
PortfolioProject..['covid vaccination$'] vac
on
dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2,3


-- USE CTE

with popvsvac(continent, location, date, population, new_vaccinations,rolling_people_vaccinated)
as
(
select dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations,
sum(convert(numeric, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as rolling_people_vaccinated
from 
PortfolioProject..['covid death data latest$'] dea
join
PortfolioProject..['covid vaccination$'] vac
on
dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
)
select * , (rolling_people_vaccinated/population)*100 
from
popvsvac
order by 2,3

-- Temp table
drop table if exists #percentpopulationvaccinated

-- Dropping the table if it exists already

create table #percentpopulationvaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_people_vaccinated numeric
)
insert into #percentpopulationvaccinated
select dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations,
sum(convert(numeric, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as rolling_people_vaccinated
from 
PortfolioProject..['covid death data latest$'] dea
join
PortfolioProject..['covid vaccination$'] vac
on
dea.location = vac.location
and dea.date = vac.date

select * , (rolling_people_vaccinated/population)*100 
from
#percentpopulationvaccinated
order by 2,3


-- Creating view to store data for later visual


drop view if exists percentpopulationvaccinated

-- Dropping the table if it exists already

Create view percentpopulationvaccinated as
select dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations,
sum(convert(numeric, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as rolling_people_vaccinated
from 
PortfolioProject..['covid death data latest$'] dea
join
PortfolioProject..['covid vaccination$'] vac
on
dea.location = vac.location
and dea.date = vac.date

select * from percentpopulationvaccinated
