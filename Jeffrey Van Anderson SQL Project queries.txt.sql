

/* Query 1 - query used for first insight */
SELECT film_title,
       category_name,
       MAX(rental_count1) rental_count
FROM (SELECT f.title film_title,
             c.name category_name,
             COUNT(R.*) OVER (PARTITION BY f.title ORDER BY r.rental_date) AS rental_count1
      FROM category c
      JOIN film_category fc
      ON c.category_id = fc.category_id
      JOIN film f
      ON fc.film_id = f.film_id
      JOIN inventory i
      ON i.film_id = f.film_id
      JOIN rental r
      ON i.inventory_id = r.inventory_id
      WHERE c.name = 'Animation' OR c.name = 'Children' OR c.name = 'Classics' OR c.name = 'Comedy' OR c.name = 'Family' OR c.name = 'Music') SUB
GROUP BY 1,2
ORDER BY 1,2;


/* Query 2 - query used for second insight */
WITH quartile_table AS (SELECT f.title film_title,
                               c.name category_name,
                               f.rental_duration,
                               ntile(4) OVER (ORDER BY f.rental_duration)
                        FROM category c
                        JOIN film_category fc
                        ON c.category_id = fc.category_id
                        JOIN film f
                        ON fc.film_id = f.film_id)

SELECT category_name,
       CASE
         WHEN ntile = 1 THEN 'first_quarter'
         WHEN ntile = 2 THEN 'second_quarter'
         WHEN ntile = 3 THEN 'third_quarter'
         ELSE 'final_quarter' END AS rental_length_category,
       COUNT(*)
FROM quartile_table
WHERE category_name = 'Animation' OR category_name = 'Children' OR category_name = 'Classics' OR category_name = 'Comedy' OR category_name = 'Family' OR category_name = 'Music'
GROUP BY 1,ntile
ORDER BY 1,ntile;


/* Query 3 - query used for third insight */
SELECT DATE_PART('month', (DATE_TRUNC('month',rental_date))) rental_month,
       DATE_PART('year', (DATE_TRUNC('month',rental_date))) rental_year,
       i.store_id,
       COUNT(r.*) count_rentals
FROM inventory i
JOIN rental r
ON i.inventory_id = r.inventory_id
GROUP BY 1,2,3
ORDER BY 4 DESC;


/* Query 4 - query used for fourth insight */
SELECT t2.payment_month,
       t1.fullname,
       t2.payment_amount,
       t2.payment_count_per_month
FROM (SELECT c.first_name || ' ' || c.last_name fullname,
             SUM(p.amount) payment_amount
      FROM customer c
      JOIN payment p
      ON c.customer_id = p.customer_id
      GROUP BY 1
      ORDER BY 2 DESC
      LIMIT 10)t1
JOIN (SELECT DATE_TRUNC('month',p.payment_date) payment_month,
             c.first_name || ' ' || c.last_name fullname,
             COUNT(p.*) payment_count_per_month,
             SUM(p.amount) payment_amount
      FROM customer c
      JOIN payment p
      ON c.customer_id = p.customer_id
      GROUP BY 1,2
      ORDER BY  2,1)t2
ON t1.fullname = t2.fullname
ORDER BY 2,1;
