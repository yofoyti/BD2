-- Crear la base de datos y usarla
Create database foodie_fi;
Use foodie_fi;

-- Crear tabla plans
Create table plans (
    plan_id INT PRIMARY KEY,
    plan_name VARCHAR(50),
    price DECIMAL(10,2)
);

-- Insertar datos en plans
Insert into plans (plan_id, plan_name, price) VALUES
(0, 'trial', 0),
(1, 'basic monthly', 9.90),
(2, 'pro monthly', 19.90),
(3, 'pro annual', 199.00),
(4, 'churn', NULL);

-- Crear tabla subscriptions
Create table subscriptions (
    customer_id INT,
    plan_id INT,
    start_date DATE,
    PRIMARY KEY (customer_id, start_date),
    FOREIGN KEY (plan_id) REFERENCES plans(plan_id)
);

-- Insertar datos en subscriptions
Insert into subscriptions (customer_id, plan_id, start_date) VALUES
(1, 0, '2020-08-01'),
(1, 1, '2020-08-08'),
(2, 0, '2020-09-20'),
(2, 3, '2020-09-27'),
(11, 0, '2020-11-19'),
(11, 4, '2020-11-26'),
(13, 0, '2020-12-15'),
(13, 1, '2020-12-22'),
(13, 2, '2021-03-29'),
(15, 0, '2020-03-17'),
(15, 2, '2020-03-24'),
(15, 4, '2020-04-29'),
(16, 0, '2020-05-31'),
(16, 1, '2020-06-07'),
(16, 3, '2020-10-21'),
(18, 0, '2020-07-06'),
(18, 2, '2020-07-13'),
(19, 0, '2020-06-22'),
(19, 2, '2020-06-29'),
(19, 3, '2020-08-29');

-- Crear tabla payments para gestionar pagos en 2020
Create table payments (
    customer_id INT,
    plan_id INT,
    plan_name VARCHAR(50),
    payment_date DATE,
    amount DECIMAL(10,2),
    payment_order INT,
    PRIMARY KEY (customer_id, payment_date, payment_order)
);

-- ----------------------------------------
-- CONSULTAS PARA RESPONDER LAS PREGUNTAS
-- ----------------------------------------

-- 1. NÚMERO TOTAL DE CLIENTES ÚNICOS QUE HAN TENIDO SUSCRIPCIONES
Select COUNT(DISTINCT customer_id) AS total_customers
From subscriptions;

-- 2. DISTRIBUCIÓN MENSUAL DE INICIOS DE PRUEBA
Select DATE_FORMAT(start_date, '%Y-%m') AS month, COUNT(*) AS start_count
From subscriptions
Where plan_id = 0 -- plan trial
Group By month
Order By month;

-- 3. PLANES QUE COMIENZAN DESPUÉS DE 2020 Y SU DISTRIBUCIÓN
Select p.plan_name, COUNT(*) AS count_events
From subscriptions s
Join plans p ON s.plan_id = p.plan_id
Where s.start_date > '2020-12-31'
Group By p.plan_name;

-- 4. NÚMERO Y PORCENTAJE DE CLIENTES QUE HAN CHURNEADO
Select 
    COUNT(DISTINCT customer_id) AS total_customers,
    ROUND(
        (COUNT(DISTINCT CASE WHEN plan_id = 4 THEN customer_id END) * 100.0) / COUNT(DISTINCT customer_id),
        1
    ) AS churn_percentage
From subscriptions;

-- 5. CLIENTES QUE CHURNERARON JUSTO DESPUÉS DE LA PRUEBA GRATUITA Y PORCENTAJE
With first_sub AS (
    Select customer_id, MIN(start_date) AS first_start
    From subscriptions
    Group By customer_id
),
churn_after_trial AS (
    Select s.customer_id
    From subscriptions s
    Join first_sub f ON s.customer_id = f.customer_id
    Where s.start_date > f.first_start
      AND s.plan_id = 4
)
Select 
    COUNT(DISTINCT customer_id) AS churned_after_trial,
    ROUND(
        (COUNT(DISTINCT customer_id) * 100.0) / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions WHERE plan_id = 0),
        0
    ) AS percentage
From churn_after_trial;

-- 6. PLANES DESPUÉS DE LA PRUEBA INICIAL
Select 
    s.customer_id,
    p.plan_name,
    COUNT(*) AS plan_changes
From subscriptions s
Join plans p ON s.plan_id = p.plan_id
Where s.customer_id IN (
    Select customer_id From subscriptions Where plan_id = 0 -- clientes que tuvieron prueba
)
Group By s.customer_id, p.plan_name;

-- 7. ESTADO DE PLANES AL 31-12-2020
With plan_periods AS (
    Select
        s.customer_id,
        s.plan_id,
        s.start_date,
        LEAD(s.start_date) OVER (Partition By s.customer_id Order By s.start_date) AS next_start
    From subscriptions s
)
Select
    p.plan_name,
    COUNT(*) AS num_customers,
    ROUND((COUNT(*) * 100.0) / (Select COUNT(DISTINCT customer_id) FROM subscriptions), 2) AS percentage
From (
    Select
        customer_id,
        plan_id,
        start_date,
        COALESCE(next_start, '2020-12-31') AS end_date
    From plan_periods
) pp
Join plans p ON pp.plan_id = p.plan_id
Where start_date <= '2020-12-31'
  AND end_date > '2020-12-31'
Group By p.plan_name;

-- 8. CLIENTES QUE ACTUALIZARON A PLAN ANUAL EN 2020
Select COUNT(DISTINCT s.customer_id) AS customers_upgrade_annual
From subscriptions s
Join plans p ON s.plan_id = p.plan_id
Where p.plan_name LIKE '%annual%'
  AND s.start_date BETWEEN '2020-01-01' AND '2020-12-31'
  AND s.start_date > (
      Select MIN(start_date) From subscriptions s2 Where s2.customer_id = s.customer_id And s2.plan_id IN (1,2,3)
  );

-- 9. DÍAS PROMEDIO PARA UPGRADAR A PLAN ANUAL DESDE EL INICIO
With first_trial AS (
    Select customer_id, MIN(start_date) AS join_date
    From subscriptions
    Where plan_id = 0
    Group By customer_id
),
annual_start AS (
    Select s.customer_id, s.start_date AS annual_date
    From subscriptions s
    Join plans p ON s.plan_id = p.plan_id
    Where p.plan_name LIKE '%annual%'
)
Select ROUND(AVG(DATEDIFF(a.annual_date, f.join_date)), 2) AS avg_days_to_annual
From first_trial f
Join annual_start a ON f.customer_id = a.customer_id;

-- 10. BREAKDOWN EN PERIODOS DE 30 DÍAS PARA EL TIEMPO HASTA PLAN ANUAL
With first_trial AS (
    Select customer_id, MIN(start_date) AS join_date
    From subscriptions
    Where plan_id = 0
    Group By customer_id
),
annual_start AS (
    Select s.customer_id, s.start_date AS annual_date
    From subscriptions s
    Join plans p ON s.plan_id = p.plan_id
    Where p.plan_name LIKE '%annual%'
)
Select
    FLOOR(DATEDIFF(a.annual_date, f.join_date) / 30) AS period_bucket,
    COUNT(*) AS num_customers,
    ROUND((COUNT(*) * 100.0) / (Select COUNT(*) FROM first_trial), 2) AS percentage
From first_trial f
Join annual_start a ON f.customer_id = a.customer_id
Group By period_bucket
Order By period_bucket;

-- 11. CLIENTES QUE BAJARON DE PRO MENSUAL A BÁSICO MENSUAL EN 2020
Select COUNT(DISTINCT s1.customer_id) AS downgraded_customers
From subscriptions s1
Join subscriptions s2 ON s1.customer_id = s2.customer_id
Join plans p1 ON s1.plan_id = p1.plan_id
Join plans p2 ON s2.plan_id = p2.plan_id
Where p1.plan_name = 'pro monthly'
  AND p2.plan_name = 'basic monthly'
  AND s2.start_date BETWEEN '2020-01-01' AND '2020-12-31'
  AND s2.start_date > s1.start_date;

-- ----------------------------------------
-- Ejemplo de cómo generar los pagos en 2020
-- Este proceso requiere lógica adicional para reflejar cambios de plan y cancelaciones
-- Aquí se muestra un ejemplo simplificado para crear pagos mensuales
-- ----------------------------------------

Insert into payments (customer_id, plan_id, plan_name, payment_date, amount, payment_order)
Select
    s.customer_id,
    s.plan_id,
    p.plan_name,
    DATE_ADD(s.start_date, INTERVAL (n.n - 1) MONTH),
    p.price,
    n.n
From
    subscriptions s
Join plans p ON s.plan_id = p.plan_id
Join (
    Select 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
    UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    UNION ALL SELECT 11 UNION ALL SELECT 12
) n
Where s.start_date >= '2020-01-01' AND s.start_date <= '2020-12-31'
-- Para mayor precisión, agregar lógica para considerar cambios y cancelaciones
;
