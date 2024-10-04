-- Joining Tables
SELECT
	ord.order_id,
	CONCAT(cus.first_name, ' ',cus.last_name) AS 'customers',
	cus.city,
	cus.state,
	ord.order_date,
	SUM(ite.quantity) AS 'total_units',
	SUM(ite.quantity * ite.list_price) AS 'revenue',
	pro.product_name,
	cat.category_name,
	sto.store_name,
	CONCAT(sta.first_name, ' ',sta.last_name) AS 'sales rep'
FROM sales.orders ord
JOIN sales.customers cus
ON ord.customer_id = cus.customer_id
JOIN sales.order_items ite
ON ord.order_id = ite.order_id
JOIN production.products pro
ON ite.product_id = pro.product_id
JOIN production.categories cat
ON pro.category_id = cat.category_id
JOIN sales.stores sto
ON ord.store_id = sto.store_id
JOIN sales.staffs sta
ON ord.staff_id = sta.staff_id
GROUP BY 
	ord.order_id,
	CONCAT(cus.first_name, ' ',cus.last_name),
	cus.city,
	cus.state,
	ord.order_date,
	pro.product_name,
	cat.category_name,
	sto.store_name,
	CONCAT(sta.first_name, ' ',sta.last_name)


-- Find the top 5 customers who have spent the most money.
SELECT
	TOP(5) CONCAT(cus.first_name, ' ',cus.last_name) AS 'customers',
	ROUND(SUM(ite.quantity * ite.list_price),0) AS 'amount spent'
FROM sales.orders ord
JOIN sales.customers cus
ON ord.customer_id = cus.customer_id
JOIN sales.order_items ite
ON ord.order_id = ite.order_id
GROUP BY 
	CONCAT(cus.first_name, ' ',cus.last_name)
ORDER BY 'amount spent' DESC


-- Calculate the average order value and number of orders for each store in the last 3 month.
WITH LastOrderDate AS (
    SELECT MAX(order_date) AS max_date
    FROM sales.orders
)
SELECT
	sto.store_id,
	sto.store_name,	
	ord.order_date,
	COUNT(ord.order_id) AS 'num of orders',
	AVG(ite.quantity * ite.list_price) AS 'avg order value'
FROM sales.stores sto 
LEFT JOIN sales.orders ord
ON sto.store_id = ord.store_id
LEFT JOIN sales.order_items ite
ON ord.order_id = ite.order_id
WHERE ord.order_date > DATEADD(month, -3, (select LastOrderDate.max_date from LastOrderDate))
GROUP BY 
	sto.store_id,
	sto.store_name,
	ord.order_date
