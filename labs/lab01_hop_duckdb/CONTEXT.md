# CONTEXT - Lab 1 Hop + DuckDB

## Canonical Architecture

```text
CSV sources -> Hop native ETL -> staging.* -> Hop native ETL -> warehouse.*
```

DuckDB stores the local tables. Apache Hop is the primary ETL tool. SQL scripts are validation or backup paths.

## Glossary

**ETL**  
Extract, Transform, Load. In this lab, Hop extracts CSV sources, transforms rows with native Hop steps, and loads DuckDB tables.

**staging**  
Typed landing layer in DuckDB. It is a minimal copy of source CSVs with type conversion, schema alignment, and technical rejects. It does not apply city normalization, business filtering, orphan filtering, analytical deduplication, surrogate-key mapping, or measure calculation.

**warehouse**  
Cleaned and conformed dimensional layer in DuckDB. Dimensions and facts live here. Business rules, joins, deduplication, normalization, surrogate keys, and measures are applied while loading this layer.

**Hop native transform**  
A visible Apache Hop step such as `CSV Input`, `Select Values`, `Filter Rows`, `Value Mapper`, `Calculator`, `Database Lookup`, `Merge Join`, `Unique Rows`, `Add Sequence`, or `Table Output`.

**SQL oracle / backup**  
SQL scripts that validate expected results or allow the lab to run when Hop is unavailable. They are not the primary transformation workflow.
