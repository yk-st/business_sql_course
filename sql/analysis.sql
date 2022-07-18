# greatest least関数
select  greatest(od.PRODUCT_ID,od.USER_ID)
from 
ORDERS as od
inner join PRODUCTS as pd on od.PRODUCT_ID = pd.id 
inner join PEOPLE as p on p.id = od.USER_ID
order by p.name


# 要約統計量
# sum(col)
# avg(col)
# min(col)
# max(col)
# 最頻値

# あとは変更するだけ
select sum(total) from ORDERS

# 中央値
# 平均値
# ばらつきが多い場合は平均値の方が良かったりする
SELECT mode() WIHTHIN GROUP (ORDER BY product_id) AS hoge FROM orders

# 最頻値
SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY tax)
FROM ORDERS

# window関数
select 
product_id,total,
row_number() over(
    partition by product_id
    order by total
)
from 
orders

# 移動平均
# 先ほど学んだwindow関数を使うとこのようなこともできます。
with hoge as (

select * from (
    SELECT product_id,total,to_char(created_at, 'YYYY-MM') AS sa_month
    FROM orders
)  peke

)

select 
    product_id
    , sa_month
    , AVG(total) OVER (
        partition by product_id
        order by sa_month
        rows between 5 preceding and current row
    ) moving_avg
from hoge ;

# lag関数/lead関数
with hoge as (

select * from (
    SELECT product_id,total,to_char(created_at, 'YYYY-MM') AS sa_month
    FROM orders
)  peke

)
select 
    product_id
    , sa_month
    , total
    , lag(total) OVER (
        partition by product_id
        order by sa_month
    ) as lagss
from hoge ;


#＃ 演習：lag関数を使って売上の先回比を出してみましょう
with hoge as (

select * from (
    SELECT product_id,total,to_char(created_at, 'YYYY-MM') AS sa_month
    FROM orders
)  peke

)

select 
    product_id
    , sa_month
    , total
    , sum(total) OVER(
        partition by product_id, sa_month
    ) 
    / lag(total) OVER (
        partition by product_id
        order by sa_month
    ) as last_month_ratio
from hoge ;

# ヒストグラム
SELECT wb * 100 as range, count(wb) FROM 
  (SELECT width_bucket(reviews, 1, 4000, 40) as wb FROM users WHERE reviews > 0) as t 
  GROUP BY wb;

# 単純にグラフを書いてみる
with hoge as (
    select * from (
        SELECT product_id,total,to_char(created_at, 'YYYY-MM') AS sa_month
        FROM orders
    )  peke
)
select 
    sa_month,count(product_id)
from hoge 
group by sa_month,product_id
;

# roll up/cube/

with hoge as (
    select * from (
        SELECT product_id,total,to_char(created_at, 'YYYY-MM') AS sa_month
        FROM orders
    )  peke
)
select 
    sa_month,product_id,sum(total),count(*)
from hoge 
group by rollup(sa_month,product_id)
;

# 縦持ち/横持ち
# 昔ながらの運用などで分析に向かないデータの持ち方をしている場合もある
# その場合は、既出の擬似テーブルを利用して縦持ち/横持ちを変換していきます
select
    sub.*
from
(
    select
         q.employee_id
        ,case p.seq
            when 1 then q.qualification_id_1
            when 2 then q.qualification_id_2
            when 3 then q.qualification_id_3
            when 4 then q.qualification_id_4
        end as qualification_id
    from
        qualifications_horizontal as q
    cross join
        pivot as p
) sub
where
    sub.qualification_id is not null
order by
     sub.employee_id
    ,sub.qualification_id
;


select
     tmp.employee_id
    ,max(case tmp.seq when 1 then tmp.qualification_id else null end) as qualification_id1
    ,max(case tmp.seq when 2 then tmp.qualification_id else null end) as qualification_id2
    ,max(case tmp.seq when 3 then tmp.qualification_id else null end) as qualification_id3
    ,max(case tmp.seq when 4 then tmp.qualification_id else null end) as qualification_id4
from
(
    select
         employee_id
        ,qualification_id
        ,row_number() over (partition by employee_id) as seq
    from
        qualifications_vertical
) tmp
group by
    tmp.employee_id
;

# 集合演算とベン図

# 差集合
SELECT
-- 0,2,4,6,8,10
generate_series( 0, 10, 2 )

EXCEPT

SELECT
-- 0,3,6,9
generate_series( 0, 10, 3 )

# 和集合
UNION
# 積集合
INTERSECT



# ユークリッド距離と類似度

# データの妥当性にも気を付けてみよう
# データエンジニアとも協力を考えてみよう。いわゆる「データ品質」
# まずは、自身が考えるデータのあるべき姿をチェックする
# AVG(CASE)