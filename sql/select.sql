show tables;

# Select文を打ってみよう
##　テーブルの検索
## limitをつけると取得する件数を制限できる
select * from orders limit 10;

## 取得するカラムを設定できる
select id,tax from orders limit 10;

# 四則演算
# as で別名を付ける事ができる
# テーブルにも付ける事ができる
select (tax + tax) as 2tax from orders limit 10;

# 演習
Product_id、quantitiy、taxを使ってtotalカラムと数値が一致することを確認してみよう

# 条件付き
select * from orders where id = 74
# 値の比較もできます
select * from orders where created_at > '2018-11-11'
# 複数条件(and 且つ条件)
select * from orders where id > 70 and tax < 4
# 複数条件(or または条件)
select * from orders where id > 70 or tax < 4
# Like
# %はなんでもありという意味
select Product_id from orders where Product_id like '%36%'

# 副問い合わせ
# テーブルの検索結果を条件にして検索をする事ができる

select * from orders 
where id in (
    select id from orders where id % 2 = 0 and id < 10
)

select 
 * 
from 
 (select 1 ) hoge

# withによる繰り返しの回避と処理途中結果の中間点作成
# 繰り返し行うような処理におすすめです

WITH orders_with AS (
  SELECT tax,created_at
  FROM
    orders od
  WHERE
    od.tax > 4
)
    select *
    from 
    orders_with
union all 
    select *
    from orders_with

# Case分
# もしXXXであったら？というように条件分岐をする事ができる

select 
    CASE id
        WHEN 1 THEN 'hoge'
        WHEN 3 THEN 'peke'
        ELSE 'gggggg'
    END as peken
    , id
from
 orders
where
 id in(1,2,3)

# 演習
product_idが100以上だったら、Product_id、quantitiy、taxを利用してtotalを計算し、
そうでなければ、100を固定で入れるようにしてみよう

# 複数テーブルを操作する join
# inner joinとleft join
# product_idはproduct テーブルのidと紐ついています。そのためproduct_idとidを結合してみます。
# product_idだけではわからなかった、productの名前がわかるようになります。

select distinct od.PRODUCT_ID,pd.TITLE
from 
ORDERS as od
inner join PRODUCTS as pd on od.PRODUCT_ID = pd.id 

## 演習
PEOPLEテーブルがあります。ordersテーブルのuser_idとpeopleテーブルのidを結合して
誰がどのような商品を購入したのか確認してみましょう。
さらに、productsテーブルとも紐つけて商品名もわかるようにしてみましょう。

select distinct od.PRODUCT_ID,pd.TITLE,p.name
from 
ORDERS as od
inner join PRODUCTS as pd on od.PRODUCT_ID = pd.id 
inner join PEOPLE as p on p.id = od.USER_ID
order by p.name

# 集計関数(Group By)
# Excelでいう小計であったり合計を出したりすることに使う
# order byは並び替えの方法ascは昇順(小 -> 大)、descは逆

#以下はuserごとに購入金額の合計を出すSQL
select  
    USER_ID,
    sum(total) as user_sum
from 
    ORDERS
group by USER_ID
order by user_sum asc

# 演習
product_idごとに集計し、最も売れていないProduct_idを絞り出そう
select  
    PRODUCT_ID,
    sum(total) as product_sum
from 
    ORDERS
group by PRODUCT_ID
order by product_sum asc

# 欠損処理
## null 除外
## where is not null で除外する

## null を別の値で置き換える
## 平均値などで埋め合わせることもある
with hoge as (
    select 1 as seq
    union all select 2 as seq
    union all select null as seq
)
SELECT COALESCE(seq, 99) FROM hoge;

## lpad
### 先ほどのleft joinとくっつけると強力

## rpadという右から詰める方法もある
select distinct lpad( cast(USER_ID as varchar) , 8 , '0') from orders

# sign
# 0超過なら1
# 0なら0
# 0未満なら-1
with hoge as (
    select 1 as seq
    union all select 2 as seq
    union all select null as seq
)
,
peke as(
    SELECT SIGN(COALESCE(seq, -1)) as signs FROM hoge
) 
select 
    count(signs),signs 
from peke group by signs

# 擬似的に欠損データを作ります
# こちらが新たなorders テーブルだと一時的に思ってください
select * from (
select 
    CASE id
        WHEN 1 THEN '123'
        WHEN 3 THEN 'peke'
        ELSE null
    END as peken
    , product_id
from
 orders
where
 id in(1,2,3)
 ) as orders

# COALESCEを使って穴埋めしてきます
select 
    COALESCE(orders.peken, 
    cast(orders.product_id as character)), 
    orders.product_id 
from (
    select 
        CASE id
            WHEN 1 THEN '123'
            WHEN 3 THEN 'peke'
            ELSE null
        END as peken
        , product_id
    from
    orders
    where
    id in(1,2,3)
) as orders

# 桁合わせ
# product sumが桁が揃っていなくてわかりずらいので分析の際には桁数などの「揺れ」を統一させることが大事
select  
    PRODUCT_ID,
    round(sum(total),1) as product_sum
from 
    ORDERS
group by PRODUCT_ID
order by product_sum asc
# 他にも「1」「男」みたいな状況であれば、Case文を使って揺れを統一させていきます
# 非常に骨の折れる作業ですが使いやすさのため、欠損処理も含めとっても大切な作業です

# 重複削除
select distinct(orders.peken) from (
select 
    CASE id
        WHEN 1 THEN '123'
        WHEN 3 THEN 'peke'
        ELSE '123'
    END as peken
from
 orders
where
 id in(1,2,3)
 ) as orders

 # 擬似テーブル
with hoge as (
    select 1 as seq
    union all select 2 as seq
)
select * from hoge

# 演習：２つのカラムを持つ擬似テーブルを作成してみよう