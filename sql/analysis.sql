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

SELECT mode() WIHTHIN GROUP (ORDER BY カラム名) AS お好きな名前 FROM テーブル名

SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY col)
FROM tbl

# window関数


# 移動平均
# 先ほど学んだwindow関数を使うとこのようなこともできます。
SELECT
    sales_month
    , shop_id
    , sales_amount
    , AVG(sales_amount) OVER (
        partition by shop_id
        order by sales_month
        rows between 5 preceding and current row
    ) moving_avg
FROM
    monthly_sales
;

# 擬似テーブル
with hoge as (
    select 1 as seq
    union all select 2 as seq
)
select * from hoge

# lag関数


#＃ 演習：lag関数を使って売上の先月比を出してみましょう

# ヒストグラム
SELECT wb * 100 as range, count(wb) FROM 
  (SELECT width_bucket(reviews, 1, 4000, 40) as wb FROM users WHERE reviews > 0) as t 
  GROUP BY wb;

# roll up/cube/(group select)
# 小計を出したい時に使う
https://qiita.com/tlokweng/items/a15b67f3475e38282dca

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

# データの妥当性にも気を付けてみよう
# データエンジニアとも協力を考えてみよう。いわゆる「データ品質」
# まずは、自身が考えるデータのあるべき姿をチェックする
# AVG(CASE)

# 集合演算とベン図

# さ集合
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