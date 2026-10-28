use imdb;

-- segment 1

-- q1. total rows in each table
select 'movie' as table_name, count(*) as total_rows from movie
union all select 'genre', count(*) from genre
union all select 'ratings', count(*) from ratings
union all select 'names', count(*) from names
union all select 'director_mapping', count(*) from director_mapping
union all select 'role_mapping', count(*) from role_mapping;

-- q2. columns in movie table that contain null values
select 'year' as column_name, sum(year is null) as null_count from movie
union all select 'date_published', sum(date_published is null) from movie
union all select 'duration', sum(duration is null) from movie
union all select 'country', sum(country is null) from movie
union all select 'worlwide_gross_income', sum(worlwide_gross_income is null) from movie
union all select 'languages', sum(languages is null) from movie
union all select 'production_company', sum(production_company is null) from movie;

-- q3a. movies released each year
select `year`, count(*) as movie_count
from movie
where `year` is not null
group by `year`
order by `year`;

-- q3b. movies released each month
select month(date_published) as month_number, count(*) as movie_count
from movie
where date_published is not null
group by month(date_published)
order by month_number;

-- q4. movies produced in usa or india in 2019
select count(*) as movie_count
from movie
where `year` = 2019 and (country like '%usa%' or country like '%india%');

-- q5. unique genres
select distinct genre from genre where genre is not null order by genre;

-- q6. genre with the most movies
select genre, count(distinct movie_id) as movie_count
from genre
group by genre
order by movie_count desc
limit 1;

-- q7. movies that belong to only one genre
select count(*) as movie_count
from (select movie_id from genre group by movie_id having count(distinct genre) = 1) as one_genre;

-- q8. average duration in each genre
select g.genre, round(avg(m.duration), 2) as avg_duration
from genre g join movie m on g.movie_id = m.id
group by g.genre
order by avg_duration desc;

-- q9. thriller genre rank by number of movies
select genre, movie_count,
       (select count(*) + 1 from
          (select genre, count(distinct movie_id) as movie_count from genre group by genre) x
        where x.movie_count > gc.movie_count) as genre_rank
from (select genre, count(distinct movie_id) as movie_count from genre group by genre) gc
where lower(genre) = 'thriller';

-- segment 2

-- q10. minimum and maximum values in ratings columns
select min(avg_rating) as min_avg_rating, max(avg_rating) as max_avg_rating,
       min(total_votes) as min_total_votes, max(total_votes) as max_total_votes,
       min(median_rating) as min_median_rating, max(median_rating) as max_median_rating
from ratings;

-- q11. top 10 movies by average rating
select m.title, r.avg_rating
from movie m join ratings r on m.id = r.movie_id
order by r.avg_rating desc
limit 10;

-- q12. movie count by median rating
select median_rating, count(*) as movie_count
from ratings
group by median_rating
order by median_rating;

-- q13. production companies with the most movies rated above 8
select m.production_company, count(*) as movie_count
from movie m join ratings r on m.id = r.movie_id
where r.avg_rating > 8 and m.production_company is not null
group by m.production_company
order by movie_count desc
limit 10;


-- q14. usa movies released in march 2017 with more than 1000 votes, by genre
select g.genre, count(distinct m.id) as movie_count
from movie m join genre g on m.id = g.movie_id
join ratings r on m.id = r.movie_id
where m.date_published >= '2017-03-01' and m.date_published < '2017-04-01'
  and m.country like '%usa%' and r.total_votes > 1000
group by g.genre
order by movie_count desc;

-- q15. movies starting with 'the' rated above 8
select m.title, g.genre, r.avg_rating
from movie m join genre g on m.id = g.movie_id
join ratings r on m.id = r.movie_id
where m.title like 'the %' and r.avg_rating > 8
order by r.avg_rating desc;

-- q16. movies rated median 8 released between the given dates
select count(*) as movie_count
from movie m join ratings r on m.id = r.movie_id
where m.date_published between '2018-04-01' and '2019-04-01'
  and r.median_rating = 8;

-- q17. compare total votes for german and italian movies
select sum(case when m.languages like '%german%' then r.total_votes else 0 end) as german_votes,
       sum(case when m.languages like '%italian%' then r.total_votes else 0 end) as italian_votes
from movie m join ratings r on m.id = r.movie_id;

-- segment 3

-- q18. null values in names table
select sum(name is null) as name_nulls,
       sum(height is null) as height_nulls,
       sum(date_of_birth is null) as date_of_birth_nulls,
       sum(known_for_movies is null) as known_for_movies_nulls
from names;

-- q19. top three directors in the top three genres for movies rated above 8

select n.name as director_name,
count(distinct dm.movie_id) as movie_count
from director_mapping dm
join names n on dm.name_id = n.id
join genre g on dm.movie_id = g.movie_id
join ratings r on dm.movie_id = r.movie_id
join (
select genre
from genre
group by genre
order by count(distinct movie_id) desc
limit 3
) top_genres on g.genre = top_genres.genre
where r.avg_rating > 8
group by n.id, n.name
order by movie_count desc
limit 3;
-- q20. top two actors in movies with median rating at least 8
select n.name as actor_name, count(distinct rm.movie_id) as movie_count
from role_mapping rm join names n on rm.name_id = n.id
join ratings r on rm.movie_id = r.movie_id
where rm.category = 'actor' and r.median_rating >= 8
group by n.name
order by movie_count desc
limit 2;

-- q21. top three production companies by total votes
select m.production_company, sum(r.total_votes) as total_votes
from movie m join ratings r on m.id = r.movie_id
where m.production_company is not null
group by m.production_company
order by total_votes desc
limit 3;

-- q22. actors in indian movies ranked by average rating (at least 5 movies)
select n.name as actor_name, round(avg(r.avg_rating), 2) as avg_rating,
       count(distinct m.id) as movie_count
from movie m join ratings r on m.id = r.movie_id
join role_mapping rm on m.id = rm.movie_id
join names n on rm.name_id = n.id
where m.country like '%india%' and rm.category = 'actor'
group by n.name
having count(distinct m.id) >= 5
order by avg_rating desc
limit 10;

-- q23. top five actresses in indian hindi movies by average rating
select n.name as actress_name, round(avg(r.avg_rating), 2) as avg_rating,
       count(distinct m.id) as movie_count
from movie m join ratings r on m.id = r.movie_id
join role_mapping rm on m.id = rm.movie_id
join names n on rm.name_id = n.id
where m.country like '%india%' and m.languages like '%hindi%' and rm.category = 'actress'
group by n.name
having count(distinct m.id) >= 3
order by avg_rating desc
limit 5;

-- q24. classify thriller movies by average rating
select m.title, r.avg_rating,
       case when r.avg_rating > 8 then 'superhit movies'
            when r.avg_rating >= 7 then 'hit movies'
            when r.avg_rating >= 5 then 'one-time-watch movies'
            else 'flop movies' end as movie_category
from movie m join ratings r on m.id = r.movie_id
join genre g on m.id = g.movie_id
where lower(g.genre) = 'thriller'
order by r.avg_rating desc;

-- segment 4

-- q25. genre-wise average duration, running total and moving average
select genre, round(avg_duration, 2) as avg_duration,
       round(sum(avg_duration) over (order by genre), 2) as running_total,
       round(avg(avg_duration) over (order by genre rows between 2 preceding and current row), 2) as moving_average
from (select g.genre, avg(m.duration) as avg_duration
      from genre g join movie m on g.movie_id = m.id
      where m.duration is not null group by g.genre) as genre_durations
order by genre;

-- q26. five highest-grossing movies per year from the top three genres

select genre, year, title, gross_income
from (select g.genre,m.year,m.title,cast(replace(replace(m.worlwide_gross_income, '$', ''), ',', '') as unsigned) as gross_income,row_number() over (partition by m.year
order by cast(replace(replace(m.worlwide_gross_income, '$', ''), ',', '') as unsigned) desc
) as movie_rank
from movie m
join genre g on m.id = g.movie_id
join (
select genre
from genre
group by genre
order by count(distinct movie_id) desc
limit 3
) top_genres on g.genre = top_genres.genre
where m.worlwide_gross_income is not null
and m.year is not null
) ranked_movies
where movie_rank <= 5
order by year, movie_rank;

-- q27. top two production companies for multilingual hit movies
select m.production_company, count(distinct m.id) as movie_count
from movie m join ratings r on m.id = r.movie_id
where r.median_rating >= 8 and m.languages like '%,%' and m.production_company is not null
group by m.production_company
order by movie_count desc
limit 2;

-- q28. top three actresses in superhit drama movies
select n.name as actress_name, count(distinct m.id) as movie_count
from movie m join ratings r on m.id = r.movie_id
join genre g on m.id = g.movie_id
join role_mapping rm on m.id = rm.movie_id
join names n on rm.name_id = n.id
where lower(g.genre) = 'drama' and r.avg_rating > 8 and rm.category = 'actress'
group by n.name
order by movie_count desc
limit 3;

-- q29. top nine directors and their movie statistics
select dm.name_id as director_id, n.name as director_name,
       count(distinct m.id) as number_of_movies,
       round(avg(r.avg_rating), 2) as avg_rating,
       sum(r.total_votes) as total_votes,
       min(r.avg_rating) as min_rating,
       max(r.avg_rating) as max_rating,
       sum(m.duration) as total_duration
from director_mapping dm join names n on dm.name_id = n.id
join movie m on dm.movie_id = m.id
join ratings r on m.id = r.movie_id
group by dm.name_id, n.name
order by number_of_movies desc
limit 9;
