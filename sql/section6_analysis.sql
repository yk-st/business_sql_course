# greatest least関数
select 
    GREATEST(od.PRODUCT_ID,od.USER_ID)
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
# ばらつきが多い場合は平均値より中央値の方が良かったりする
SELECT MODE() WITHIN GROUP(ORDER BY user_id) AS MODE FROM orders;
SELECT product_id,MODE() WITHIN GROUP(ORDER BY user_id) AS MODE FROM orders group by product_id;

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
,
base_data as (
select
    product_id,
    sa_month,
    sum(total) as total
from hoge
where 
    product_id in(1)
group by product_id,sa_month
order by sa_month
)

select 
    product_id
    , sa_month
    , AVG(total) OVER (
        partition by product_id
        order by sa_month
        rows between 5 preceding and current row
    ) moving_avg
from base_data

# lag関数/lead関数
# lag(total,2)のようにする事で、2つ前のデータを取得することも可能です
with hoge as (
    select * from (
        SELECT product_id,total,to_char(created_at, 'YYYY-MM') AS sa_month
        FROM orders
    )  peke
)
,
base_data as (
select
    product_id,
    sa_month,
    sum(total) as total
from hoge
where 
    product_id in(1)
group by product_id,sa_month
order by sa_month
)

select 
    product_id
    , sa_month
    , total
    , lag(total) OVER (
        partition by product_id
        order by sa_month
    ) as lagss
from base_data ;

#＃ 演習：lag関数を使って売上の先回比を出してみましょう
with hoge as (
    select * from (
        SELECT product_id,total,to_char(created_at, 'YYYY-MM') AS sa_month
        FROM orders
    )  peke
)
,
base_data as (
select
    product_id,
    sa_month,
    sum(total) as total
from hoge
where 
    product_id in(1)
group by product_id,sa_month
order by sa_month
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
from base_data ;

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

# ヒストグラムを書いてみよう

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

# ヒストグラム
with hoge as (
    select * from (
        SELECT product_id,total,to_char(created_at, 'YYYY-MM') AS sa_month
        FROM orders
    )  peke
)
, peke as (
select 
    sa_month,product_id,sum(total) as total_month,count(*)
from hoge 
group by rollup(sa_month,product_id)
)

SELECT total_months * 100 as range, count(total_months) FROM 
  (SELECT width_bucket(total_month, 1, 4000, 5) as total_months FROM peke) as t 
  GROUP BY total_months
order by range desc;

# 縦持ち/横持ち
# 昔ながらの運用などで分析に向かないデータの持ち方をしている場合もある
# その場合は、既出の擬似テーブルを利用して縦持ち/横持ちを変換していきます

#　横持ちデータを調べてみる
with henkan as (
    select 1 as seq
    union all select 2 as seq
    union all select 3 as seq
)
,yokomoti as (
    select 'hoge' as id, 1 as qualification_id_1, 2 as qualification_id_2, 3 as qualification_id_3
    union all select 'hoge2' as id, 4 as qualification_id_1, 5 as qualification_id_2, 6 as qualification_id_3
    union all select 'hoge3' as id, 19 as qualification_id_1, 12 as qualification_id_2, 11 as qualification_id_3
)

select * from yokomoti;

# 変換
with henkan as (
    select 1 as seq
    union all select 2 as seq
    union all select 3 as seq
)
,yokomoti as (
    select 'hoge' as id, 1 as qualification_id_1, 2 as qualification_id_2, 3 as qualification_id_3
    union all select 'hoge2' as id, 4 as qualification_id_1, 5 as qualification_id_2, 6 as qualification_id_3
    union all select 'hoge3' as id, 19 as qualification_id_1, 12 as qualification_id_2, 11 as qualification_id_3
)

select
    sub.*
from
(
    select
         q.id
        ,case p.seq
            when 1 then q.qualification_id_1
            when 2 then q.qualification_id_2
            when 3 then q.qualification_id_3
        end as qualification_id
    from
        yokomoti as q
    cross join
        henkan as p
) sub
order by
    sub.qualification_id
;

# どういう仕組み？
with henkan as (
    select 1 as seq
    union all select 2 as seq
    union all select 3 as seq
)
,yokomoti as (
    select 'hoge' as id, 1 as qualification_id_1, 2 as qualification_id_2, 3 as qualification_id_3
    union all select 'hoge2' as id, 4 as qualification_id_1, 5 as qualification_id_2, 6 as qualification_id_3
    union all select 'hoge3' as id, 19 as qualification_id_1, 12 as qualification_id_2, 11 as qualification_id_3
)

select
    sub.*
from
(
    select
         q.id,
         p.seq
         qualification_id_1, qualification_id_2, qualification_id_3
    from
        yokomoti as q
    cross join
        henkan as p
) sub
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

# 演習： peopleテーブルとordersテーブルを使ってsourceがTwitterの人とFacebookの人がどちらも購入している商品のproduct_idを出力しよう

with facebook as (
    select 
        product_id 
    from 
        orders o
    inner join people p on p.id = user_id
    where
        source in ('Facebook')
)
,
twitter as (
    select 
        product_id 
    from 
        orders o
    inner join people p on p.id = user_id
    where
        source in ('Twitter')
)

select
 * 
from 
twitter

-- 積集合
intersect

select
 * 
from 
facebook

# データの妥当性にも気を付けてみよう
# データエンジニアとも協力を考えてみよう。いわゆる「データ品質」
# まずは、自身が考えるデータのあるべき姿をチェックする
# AVG(CASE)

select 
AVG(CASE WHEN id is NOT NULL THEN 1.0 ELSE 0.0 END) AS id
from 
orders

# ユーニークかどうか
# mysqlなどキー制約としてPKになっている時もあるがそうなっていない時もあるので
select not exists (
    select id, count(*)
    from orders
    group by id
    having count(*) > 1
);

# total はプラス
select 
    AVG(CASE WHEN total < 0 THEN 1.0 ELSE 0.0 END) AS total
from 
orders

-- 組み合わせることも可能
select 
    AVG(CASE WHEN id is NOT NULL THEN 1.0 ELSE 0.0 END) AS id,
    AVG(CASE WHEN total <0 THEN 1.0 ELSE 0.0 END) AS total
from 
orders