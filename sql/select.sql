show tables;

#　テーブルの検索
# limitをつけると取得する件数を制限できる
select * from orders limit 10;

# 四則演算
# as で別名を付ける事ができる
# テーブルにも付ける事ができる
select (tax + tax) as 2tax from orders limit 10;


# 取得するカラムを設定できる
select id,tax from orders limit 10;

# 条件付き
select * from orders where id = 74
select * from orders where created_at > '2018-11-11'
# 複数条件(and 且つ条件)
select * from orders where id > 70 and tax < 4
# 複数条件(or または条件)
select * from orders where id > 70 or tax < 4

# with
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

# 副問い合わせ
# テーブルの検索結果を条件にして検索をする事ができる

select * from orders 
where id in (
    select id from orders where id % 2 = 0 and id < 10
)