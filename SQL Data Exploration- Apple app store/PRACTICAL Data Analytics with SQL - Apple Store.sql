-- inserting data from excel in to database

-- creating table
DROP TABLE IF EXISTS #appleStore_description_combined
CREATE TABLE #appleStore_description_combined ( -- temp table
    id FLOAT,
    track_name NVARCHAR(255),
    size_bytes FLOAT,
    app_desc NVARCHAR(MAX)
)

--inserting data into new table
insert into	#appleStore_description_combined
SELECT * FROM appleStore_description1$
UNION ALL
SELECT * FROM appleStore_description2$
UNION ALL
SELECT * FROM appleStore_description3$
UNION ALL
SELECT * FROM appleStore_description4$

-- check table is correct
select * from AppleStore$
select * from #appleStore_description_combined


-- EDA

--check the number of unique apps in both applestore and description
SELECT COUNT(DISTINCT(ID)) AS UniqueAppIDs
FROM #appleStore_description_combined

SELECT COUNT(DISTINCT(ID)) AS UniqueAppIDs
FROM AppleStore$

-- check for missing values
SELECT COUNT(*) AS MissingValues
FROM AppleStore$
WHERE track_name IS NULL OR user_rating IS NULL OR prime_genre IS NULL

SELECT COUNT(*) AS MissingValues
FROM #appleStore_description_combined
WHERE app_desc IS NULL

--find number of apps per genre
SELECT prime_genre, COUNT(*) AS NUMB
FROM AppleStore$
GROUP BY prime_genre
ORDER BY NUMB DESC

-- Get an overview of app's rating
SELECT MIN(user_rating) AS MinRating, MAX(user_rating) AS MaxRating, AVG(user_rating) AS AvgRating
FROM AppleStore$

-- Determine whether paid or free aps have higher ratings
SELECT CASE
		WHEN PRICE > 0 THEN 'Paid'
		ELSE 'Free'
	   END AS App_Type,
AVG(user_rating) as Avg_Rating
FROM AppleStore$
GROUP BY CASE
		  WHEN PRICE > 0 THEN 'Paid'
		  ELSE 'Free'
	     END

--check if apps with more languages have higher ratings
SELECT CASE
		WHEN lang_num < 10 THEN '< 10 languages'
		WHEN lang_num BETWEEN 10 AND 30 THEN '10 - 30 languages'
		ELSE '> 30 languages'
	   END AS language_bucket,
AVG(user_rating) AS Avg_Rating
FROM AppleStore$
GROUP BY CASE
		WHEN lang_num < 10 THEN '< 10 languages'
		WHEN lang_num BETWEEN 10 AND 30 THEN '10 - 30 languages'
		ELSE '> 30 languages'
	   END
ORDER BY Avg_Rating DESC

--check genre with low ratings
SELECT TOP 10 prime_genre, AVG(user_rating) AS Avg_Rating
FROM AppleStore$
GROUP BY prime_genre
ORDER BY Avg_Rating ASC

--check if there is correlation b/w length of app desc and user rating
SELECT CASE
			WHEN LEN(B.app_desc) < 500 THEN 'Short'
			WHEN LEN(B.app_desc) BETWEEN 500 AND 1000 THEN 'Medium'
			ELSE 'Long'
		END AS desc_length_bucket,
AVG(user_rating) AS Avg_Rating

FROM AppleStore$ a
JOIN #appleStore_description_combined b
on a.id = b.id
GROUP BY CASE
			WHEN LEN(B.app_desc) < 500 THEN 'Short'
			WHEN LEN(B.app_desc) BETWEEN 500 AND 1000 THEN 'Medium'
			ELSE 'Long'
		END
ORDER BY Avg_Rating DESC

--check top rated app for each genre
SELECT prime_genre, track_name, user_rating
FROM (	
	  SELECT prime_genre, 
	  track_name, 
	  user_rating,
	  RANK() OVER (PARTITION BY prime_genre ORDER BY user_rating DESC, rating_count_tot DESC) AS rank --ranks each app in genre by user rating and total rating count
	  FROM
	  AppleStore$
	) AS a
WHERE A.rank = 1 -- select first rank
