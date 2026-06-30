
 -- ПРОЕКТ: Аналитическая система сети фитнес-клубов
 
 
USE FitnessClubs;
GO


-- 1. Список всех клиентов (с сортировкой по дате регистрации)
SELECT 
    client_id,
    full_name,
    phone,
    birth_date,
    registration_date
FROM Clients
ORDER BY registration_date DESC;

-- 2. Количество зарегистрированных клиентов по месяцам
SELECT 
    YEAR(registration_date) AS year,
    MONTH(registration_date) AS month,
    COUNT(*) AS new_clients_count
FROM Clients
GROUP BY YEAR(registration_date), MONTH(registration_date)
ORDER BY year DESC, month DESC;

-- 3. Клиенты без единого посещения (ни разу не были в клубе)
SELECT 
    c.client_id,
    c.full_name,
    c.phone,
    c.registration_date
FROM Clients c
LEFT JOIN Visits v ON c.client_id = v.client_id
WHERE v.visit_id IS NULL
ORDER BY c.registration_date;

-- 4. Топ-5 клиентов по количеству посещений
SELECT TOP 5
    c.client_id,
    c.full_name,
    COUNT(v.visit_id) AS visits_count
FROM Clients c
INNER JOIN Visits v ON c.client_id = v.client_id
GROUP BY c.client_id, c.full_name
ORDER BY visits_count DESC;

-- 5. Количество посещений по филиалам
SELECT 
    b.branch_id,
    b.branch_name,
    COUNT(v.visit_id) AS total_visits
FROM Branches b
LEFT JOIN Classes cl ON b.branch_id = cl.branch_id
LEFT JOIN Visits v ON cl.class_id = v.class_id
GROUP BY b.branch_id, b.branch_name
ORDER BY total_visits DESC;

-- 6. Посещаемость по месяцам (динамика)
SELECT 
    YEAR(v.visit_date) AS year,
    MONTH(v.visit_date) AS month,
    COUNT(*) AS visits_count
FROM Visits v
GROUP BY YEAR(v.visit_date), MONTH(v.visit_date)
ORDER BY year DESC, month DESC;

-- 7. Самые популярные занятия (по количеству посещений)
SELECT TOP 5
    cl.class_id,
    cl.class_name,
    COUNT(v.visit_id) AS visits_count
FROM Classes cl
INNER JOIN Visits v ON cl.class_id = v.class_id
GROUP BY cl.class_id, cl.class_name
ORDER BY visits_count DESC;

-- 8. Среднее количество посещений на клиента
SELECT 
    COUNT(DISTINCT client_id) AS total_clients,
    COUNT(*) AS total_visits,
    CAST(COUNT(*) AS DECIMAL(10,2)) / COUNT(DISTINCT client_id) AS avg_visits_per_client
FROM Visits;

-- 9. Посещаемость по дням недели (какие дни самые загруженные)
SELECT 
    DATEPART(dw, visit_date) AS day_of_week,
    DATENAME(dw, visit_date) AS day_name,
    COUNT(*) AS visits_count
FROM Visits
GROUP BY DATEPART(dw, visit_date), DATENAME(dw, visit_date)
ORDER BY visits_count DESC;

-- 10. Рейтинг тренеров по количеству проведённых занятий
SELECT 
    t.trainer_id,
    t.full_name,
    COUNT(DISTINCT cl.class_id) AS classes_count,
    COUNT(v.visit_id) AS total_visits
FROM Trainers t
LEFT JOIN Classes cl ON t.trainer_id = cl.trainer_id
LEFT JOIN Visits v ON cl.class_id = v.class_id
GROUP BY t.trainer_id, t.full_name
ORDER BY total_visits DESC;

-- 11. Сколько клиентов посетило каждого тренера (уникальные клиенты)
SELECT 
    t.trainer_id,
    t.full_name,
    COUNT(DISTINCT v.client_id) AS unique_clients_count
FROM Trainers t
INNER JOIN Classes cl ON t.trainer_id = cl.trainer_id
INNER JOIN Visits v ON cl.class_id = v.class_id
GROUP BY t.trainer_id, t.full_name
ORDER BY unique_clients_count DESC;

-- 12. Самая популярная специализация тренеров
SELECT TOP 1
    specialization,
    COUNT(*) AS trainers_count
FROM Trainers
WHERE specialization IS NOT NULL
GROUP BY specialization
ORDER BY trainers_count DESC;

-- 13. Количество проданных абонементов по типам
SELECT 
    membership_type,
    COUNT(*) AS count_sold,
    COUNT(DISTINCT client_id) AS unique_clients
FROM Memberships
GROUP BY membership_type
ORDER BY count_sold DESC;

-- 14. Выручка по типам абонементов
SELECT 
    membership_type,
    COUNT(*) AS count_sold,
    SUM(price) AS total_revenue
FROM Memberships
GROUP BY membership_type
ORDER BY total_revenue DESC;

-- 15. Общая выручка (все абонементы)
SELECT 
    SUM(price) AS total_revenue,
    AVG(price) AS avg_price,
    COUNT(*) AS total_sold
FROM Memberships;

-- 16. Средняя стоимость абонемента по типам
SELECT 
    membership_type,
    AVG(price) AS avg_price,
    MIN(price) AS min_price,
    MAX(price) AS max_price
FROM Memberships
GROUP BY membership_type
ORDER BY avg_price DESC;

-- 17. Абонементы, срок действия которых скоро закончится (в течение 30 дней)
SELECT 
    m.membership_id,
    c.full_name,
    m.membership_type,
    m.start_date,
    m.end_date,
    DATEDIFF(day, GETDATE(), m.end_date) AS days_until_expiry
FROM Memberships m
INNER JOIN Clients c ON m.client_id = c.client_id
WHERE m.end_date > GETDATE() 
  AND DATEDIFF(day, GETDATE(), m.end_date) <= 30
ORDER BY days_until_expiry ASC;

-- 18. Топ-5 клиентов по сумме потраченных денег (все абонементы)
SELECT TOP 5
    c.client_id,
    c.full_name,
    SUM(m.price) AS total_spent,
    COUNT(m.membership_id) AS memberships_count
FROM Clients c
INNER JOIN Memberships m ON c.client_id = m.client_id
GROUP BY c.client_id, c.full_name
ORDER BY total_spent DESC;

-- 19. Для каждого клиента: количество посещений + место в рейтинге (DENSE_RANK)
WITH ClientVisits AS (
    SELECT 
        c.client_id,
        c.full_name,
        COUNT(v.visit_id) AS visits_count
    FROM Clients c
    LEFT JOIN Visits v ON c.client_id = v.client_id
    GROUP BY c.client_id, c.full_name
)
SELECT 
    client_id,
    full_name,
    visits_count,
    DENSE_RANK() OVER (ORDER BY visits_count DESC) AS rank_position
FROM ClientVisits
ORDER BY rank_position, full_name;

-- 20. Загруженность филиалов по часам (час-пик)
SELECT 
    b.branch_name,
    DATEPART(hour, v.visit_date) AS hour,
    COUNT(*) AS visits_count
FROM Branches b
INNER JOIN Classes cl ON b.branch_id = cl.branch_id
INNER JOIN Visits v ON cl.class_id = v.class_id
GROUP BY b.branch_name, DATEPART(hour, v.visit_date)
ORDER BY b.branch_name, hour;
