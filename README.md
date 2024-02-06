
# Imperative Query

## About 
Imperative Query is a small DSL, whose aim is to make it easier to create compiled queries for the [WebDP API](https://github.com/dpella/WebDP/tree/main). The queries are written in `.iq` files, and are compiled to `.json` files that adhere to the [query WebDP API](https://editor.swagger.io/?url=https://webdp.dev/api/WebDP-1.0.0.yml). 


## Disclaimer 
There is no validation done of the queries themselves. Imperative Query is simply a mean to write the `.json` queries faster and with fewer errors. If the syntactical rules of Imperative Query are followed, then a valid `.json` will be created. The contents of the `.json` may be rejected by the WebDP backend. 

## Syntax

### Query
An Imperative Query program is defined as a list of queries. Each query is written on the form:
```
NAME DATASET_ID BUDGET = ([QUERY_STEP])
```
Where `NAME` is the name of your query, `DATASET_ID` the ID number of you dataset and `BUDGET` is the [budget](#budget) of your dataset.

The query will then compile to `NAME.json`. If multiple queries are defined in the same file, then multiple `.json` files will be created. At the current moment, there is no check in place for unique names. If multiple queries share a common name, then only one of the queries will be compiled. Code with caution.

### QueryStep
A QueryStep can be any of the following:
* [SELECT](#select)
* [RENAME](#rename)
* [FILTER](#filter) 
* [MAP](#map) 
* [BIN](#bin) 
* [COUNT](#count) 
* [MIN](#min) 
* [MAX](#max) 
* [SUM](#sum) 
* [MEAN](#mean)

And each QueryStep is terminated by a `;`. 


#### SELECT 
The syntactical rule for `SELECT` is:
```
SELECT [String];
```
where the Strings are column names of you dataset. The list of strings is comma-separated, i.e.:
```
SELECT ["foo", "bar"];
SELECT ["foo"];
```

#### RENAME
The syntactical rule for `RENAME` is:
```
RENAME [String] TO [String];
```
As for [SELECT](#select), the lists of strings are the old and the new column names, respectively. E.g:
```
RENAME ["foo", "bar"] TO ["newFoo", "newBar"];
```
which renames `foo` to `newFoo` etc, i.e., the lists are zipped and each tuple represents a mapping. 


#### FILTER
The syntactical rule for `FILTER` is:
```
FILTER [String];
```
The strings in the list are SQL-type queries, e.g., `"foo > 10"`, where `foo` is a column name in your dataset. 
```
FILTER ["bar == 69", "foobar > 420"];
```

#### MAP
The syntactical rule for MAP is:
```
MAP String [ColumnSchema];
```
where the String is a function string. (See [ColumnSchema](#column-schema))

```
MAP "{'baz': boo + baa}" ["baz" Int 1 25];
```

#### BIN
The syntactical rule for binning is:
```
BIN [BinMap];
```
Where a BinMap is:
```
BinMap ::= ColumnName [Value]
```
for example:
```
BIN [
    "myColumn" [0, 5, 10, 15],
    "myColumn2" [0.1, 0.2, 0.3]
    ];

```