CREATE DATABASE dannys_diner;
USE dannys_diner;

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INT
);

INSERT INTO sales (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', 1),
  ('A', '2021-01-01', 2),
  ('A', '2021-01-07', 2),
  ('A', '2021-01-10', 3),
  ('A', '2021-01-11', 3),
  ('A', '2021-01-11', 3),
  ('B', '2021-01-01', 2),
  ('B', '2021-01-02', 2),
  ('B', '2021-01-04', 1),
  ('B', '2021-01-11', 1),
  ('B', '2021-01-16', 3),
  ('B', '2021-02-01', 3),
  ('C', '2021-01-01', 3),
  ('C', '2021-01-01', 3),
  ('C', '2021-01-07', 3);

CREATE TABLE menu (
  product_id INT,
  product_name VARCHAR(10),
  price INT
);

INSERT INTO menu (product_id, product_name, price)
VALUES
  (1, 'sushi', 10),
  (2, 'curry', 15),
  (3, 'ramen', 12);

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
 -- 1.¿Cuál es el monto total que gastó cada cliente en el restaurante? 
  SELECT s.customer_id, SUM(m.price) AS total_gastado
FROM sales s, menu m
WHERE s.product_id = m.product_id
GROUP BY s.customer_id;
-- 2.¿Cuántos días ha visitado cada cliente el restaurante?
SELECT customer_id, COUNT(DISTINCT order_date) AS dias_visitados
FROM sales
GROUP BY customer_id;
-- 3.¿Cuál fue el primer artículo del menú que compró cada cliente?
SELECT s.customer_id, s.order_date, m.product_name
FROM sales s, menu m
WHERE s.product_id = m.product_id
AND (s.customer_id, s.order_date) IN (
  SELECT customer_id, MIN(order_date)
  FROM sales
  GROUP BY customer_id
);
-- 4.¿Cuál es el artículo más comprado del menú y cuántas veces lo compraron todos los clientes?
SELECT m.product_name, COUNT(*) AS veces
FROM sales s, menu m
WHERE s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY veces DESC
LIMIT 1;
-- 5. ¿Qué artículo fue el más popular para cada cliente?
SELECT s.customer_id, m.product_name, COUNT(*) AS veces
FROM sales s, menu m
WHERE s.product_id = m.product_id
GROUP BY s.customer_id, m.product_name
ORDER BY s.customer_id, veces DESC;
-- 6.¿Qué artículo compró primero el cliente después de hacerse miembro?
SELECT s.customer_id, s.order_date, m.product_name
FROM sales s
JOIN menu m ON s.product_id = m.product_id
JOIN members mem ON s.customer_id = mem.customer_id
WHERE s.order_date >= mem.join_date
AND s.order_date = (
  SELECT MIN(order_date)
  FROM sales
  WHERE customer_id = s.customer_id
  AND order_date >= mem.join_date
);
-- 7.¿Qué artículo se compró justo antes de que el cliente se convirtiera en miembro?
SELECT s.customer_id, s.order_date, m.product_name
FROM sales s
JOIN menu m ON s.product_id = m.product_id
JOIN members mem ON s.customer_id = mem.customer_id
WHERE s.order_date < mem.join_date
AND s.order_date = (
  SELECT MAX(order_date)
  FROM sales
  WHERE customer_id = s.customer_id
  AND order_date < mem.join_date
);
-- 8.¿Cuál es el total de artículos y monto gastado por cada miembro antes de convertirse en miembro?
SELECT s.customer_id, COUNT(*) AS total_articulos, SUM(m.price) AS monto
FROM sales s, menu m, members mem
WHERE s.product_id = m.product_id
AND s.customer_id = mem.customer_id
AND s.order_date < mem.join_date
GROUP BY s.customer_id;
-- 9. Si cada $1 gastado equivale a 10 puntos y el sushi tiene un multiplicador de puntos de 2x, ¿cuántos puntos tendría cada cliente?
SELECT s.customer_id,
  SUM(
    CASE
      WHEN m.product_name = 'sushi' THEN m.price * 10 * 2
      ELSE m.price * 10
    END
  ) AS puntos
FROM sales s, menu m
WHERE s.product_id = m.product_id
GROUP BY s.customer_id;
-- 10.En la primera semana después de que un cliente se une al programa (incluida su fecha de unión), gana 2x puntos en todos los artículos, no solo en sushi: ¿cuántos puntos tienen los clientes A y B al final de enero?
SELECT s.customer_id,
  SUM(
    CASE
      WHEN s.order_date BETWEEN mem.join_date AND DATE_ADD(mem.join_date, INTERVAL 6 DAY)
        THEN m.price * 10 * 2
      WHEN m.product_name = 'sushi' THEN m.price * 10 * 2
      ELSE m.price * 10
    END
  ) AS puntos
FROM sales s, menu m, members mem
WHERE s.product_id = m.product_id
AND s.customer_id = mem.customer_id
AND s.order_date <= '2021-01-31'
AND s.customer_id IN ('A', 'B')
GROUP BY s.customer_id;




