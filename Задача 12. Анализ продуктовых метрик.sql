/*Задача 4.
Давайте посчитаем те же показатели, но в другом разрезе — не просто по дням, а по дням недели.

Задание:
Для каждого дня недели в таблицах orders и user_actions рассчитайте следующие показатели:

Выручку на пользователя (ARPU).
Выручку на платящего пользователя (ARPPU).
Выручку на заказ (AOV).
При расчётах учитывайте данные только за период с 26 августа 2022 года по 8 сентября 2022 года включительно — так, чтобы в анализ попало одинаковое количество всех дней недели (ровно по два дня).

В результирующую таблицу включите как наименования дней недели (например, Monday), так и порядковый номер дня недели (от 1 до 7, где 1 — это Monday, 7 — это Sunday).
Колонки с показателями назовите соответственно arpu, arppu, aov. Колонку с наименованием дня недели назовите weekday, а колонку с порядковым номером дня недели weekday_number.
При расчёте всех показателей округляйте значения до двух знаков после запятой.
Результат должен быть отсортирован по возрастанию порядкового номера дня недели.
Поля в результирующей таблице: weekday, weekday_number, arpu, arppu, aov */

--на день недели вывести
--1.число всех пользователей уникальных
--2.число пользователей, которые совершили заказ и не отменили его
--3.число заказов, которые совершили платящие пользователи 
with 
cost_orders as (SELECT to_char(creation_time,'Day') as weekday,
                       date_part('isodow', creation_time) as weekday_number,
                       unnest(product_ids) as product_id, order_id
                FROM   orders
                WHERE  order_id not in (SELECT order_id
                                        FROM   user_actions
                                        WHERE  action = 'cancel_order') and creation_time between '2022-08-26' and '2022-09-09'), 

paying_values as (SELECT weekday, weekday_number, sum(price) as revenue,
                         count(distinct user_id) as paying_users,
                         count(distinct order_id) as paying_users_orders
                  FROM   cost_orders
                  LEFT JOIN products using (product_id)
                  LEFT JOIN user_actions using (order_id)
                  GROUP BY weekday_number, weekday
                  ORDER BY weekday_number), 

all_users as (SELECT to_char(time,'Day') as weekday,
                     date_part('isodow', time) as weekday_number,
                     count(distinct user_id) as all_users
              FROM   user_actions
              WHERE  time between '2022-08-26' and '2022-09-09'
              GROUP BY weekday_number, weekday)

  
SELECT weekday,
       weekday_number,
       round((revenue::decimal/all_users), 2) as arpu,
       round((revenue::decimal/paying_users), 2) as arppu,
       round((revenue::decimal/paying_users_orders), 2) as aov
FROM   paying_values
LEFT JOIN all_users using(weekday_number, weekday)
