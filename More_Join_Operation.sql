-- pregunta 1 --
SELECT id, title
 FROM movie
 WHERE yr=1962
-- pregunta 2 -- 
SELECT yr
 FROM movie
 WHERE title = 'Citizen Kane'
-- pregunta 3 -- 
SELECT id, title, yr
 FROM movie
 WHERE title Like 'Star Trek%'
Order By yr 
-- pregunta 4 -- 
SELECT id
 FROM actor
 WHERE name = 'Glenn Close' 
-- pregunta 5 -- 
SELECT id
 FROM movie
 WHERE title = 'Casablanca' 
-- pregunta 6 -- 
SELECT a.name
 FROM casting c left Join actor a ON c.actorid = a.id
 WHERE movieid = 11768 
-- pregunta 7 --
SELECT a.name
FROM movie m
JOIN casting c ON m.id = c.movieid
JOIN actor a ON c.actorid = a.id
WHERE m.title = 'Alien'
ORDER BY c.ord
-- pregunta 8 -- 
Select title
From casting c left Join movie m ON c.movieid = m.id
Where actorid = (select id from actor Where name = 'Harrison Ford')
-- pregunta 9 --
Select m.title
From movie m 
Join casting c ON m.id = c.movieid
Join actor a ON c.actorid = a.id
Where a.name = 'Harrison Ford' and c.ord !=1
-- pregunta 10 -- 
select m.title, a.name
from movie m
join casting c on m.id =c.movieid
join actor a on c.actorid = a.id
where yr = 1962 and c.ord=1;
-- Pregunta 11
SELECT yr,COUNT(title) FROM
  movie JOIN casting ON movie.id=movieid
        JOIN actor   ON actorid=actor.id
WHERE name='Rock Hudson'
GROUP BY yr
HAVING COUNT(title) > 2;
-- Pregunta 12
select title, name
from movie join casting on (movieid=movie.id and ord=1)
join actor on (actorid=actor.id)
where movie.id in (
SELECT movieid FROM casting
WHERE actorid IN (
  SELECT id FROM actor
  WHERE name='Julie Andrews'));
-- pregunta 13 --
SELECT a.name
FROM actor a
JOIN casting c ON a.id = c.actorid
WHERE c.ord = 1
GROUP BY a.id, a.name
HAVING COUNT(*) >= 15
ORDER BY a.name;
-- pregunta 14 --
SELECT m.title,
    COUNT(c.actorid) AS actor_count
FROM movie m
JOIN casting c ON m.id = c.movieid
WHERE m.yr = 1978
GROUP BY m.id, m.title
ORDER BY  actor_count DESC,m.title ASC;
-- pregunta 15 -- 
SELECT DISTINCT a2.name
FROM actor a1
JOIN casting c1 ON a1.id = c1.actorid
JOIN movie m ON c1.movieid = m.id
JOIN casting c2 ON m.id = c2.movieid
JOIN actor a2 ON c2.actorid = a2.id
WHERE a1.name = 'Art Garfunkel'
    AND a2.name != 'Art Garfunkel'