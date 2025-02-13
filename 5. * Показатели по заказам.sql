/* Задача 5.*
Продолжим изучать наш сервис и рассчитаем несколько показателей, связанных с заказами.

Задание:

Для каждого дня, представленного в таблице user_actions, рассчитайте следующие показатели:

Общее число заказов.
Число первых заказов (заказов, сделанных пользователями впервые).
Число заказов новых пользователей (заказов, сделанных пользователями в тот же день, 
когда они впервые воспользовались сервисом).
Долю первых заказов в общем числе заказов (долю п.2 в п.1).
Долю заказов новых пользователей в общем числе заказов (долю п.3 в п.1).
Колонки с показателями назовите соответственно orders, first_orders, new_users_orders, 
first_orders_share, new_users_orders_share. Колонку с датами назовите date. 
Проследите за тем, чтобы во всех случаях количество заказов было выражено целым числом. 
Все показатели с долями необходимо выразить в процентах. 
При расчёте долей округляйте значения до двух знаков после запятой.

Результат должен быть отсортирован по возрастанию даты.
Поля в результирующей таблице: date, orders, first_orders, new_users_orders, first_orders_share, new_users_orders_share */

with 
gen_order as (SELECT time::date as date, count(distinct order_id) as orders
              FROM   user_actions
              WHERE  order_id not in (SELECT order_id
                                      FROM   user_actions
                                      WHERE  action = 'cancel_order')
              GROUP BY date), 
  
first_orders as (SELECT date, count(user_id) as first_orders
                 FROM   (SELECT DISTINCT user_id, min(time)::date as date
                         FROM   user_actions
                         WHERE  order_id not in (SELECT order_id
                                                 FROM   user_actions
                                                 WHERE  action = 'cancel_order')
                                                 GROUP BY user_id)t1
                         GROUP BY date
                         ORDER BY date), 
  
first_action_date as (SELECT user_id, min(time::date) as date
                      FROM   user_actions
                      GROUP BY user_id), 
  
without_cancel_order as (SELECT date, user_id, order_id, num
                         FROM   (SELECT user_id, order_id, action, time::date as date,
                                        dense_rank() OVER (PARTITION BY user_id ORDER BY time::date) as num
                                 FROM   user_actions
                                 WHERE  order_id not in (SELECT order_id
                                                         FROM   user_actions
                                                         WHERE  action = 'cancel_order')
                                                         ORDER BY user_id, date) t1
                         WHERE  num = 1), 
  
new_users_orders as (SELECT without_cancel_order.date, count(order_id) as new_users_orders
                     FROM   without_cancel_order
                     LEFT JOIN first_action_date using(user_id)
                     WHERE  without_cancel_order.date = first_action_date.date
                     GROUP BY without_cancel_order.date)

SELECT date, orders, first_orders, new_users_orders,
       round((first_orders::decimal/orders *100), 2) as first_orders_share,
       round((new_users_orders::decimal/orders *100), 2) as new_users_orders_share
FROM   gen_order
LEFT JOIN first_orders using (date)
LEFT JOIN new_users_orders using (date)
