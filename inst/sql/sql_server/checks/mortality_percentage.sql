SELECT ROUND(CAST(COUNT(death.person_id)AS NUMERIC)/CAST(COUNT(person.person_id)AS NUMERIC)*100, 2)
AS Mortality FROM @cdmDatabaseSchema.person
LEFT JOIN @cdmDatabaseSchema.death ON death.person_id = person.person_id;